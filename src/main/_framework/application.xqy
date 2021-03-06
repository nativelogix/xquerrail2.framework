xquery version "1.0-ml";

module namespace app = "http://xquerrail.com/application";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace cache = "http://xquerrail.com/cache" at "cache.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";
import module namespace module-loader = "http://xquerrail.com/module" at "module.xqy";

declare namespace extension = "http://xquerrail.com/application/extension";

declare option xdmp:mapping "false";

declare function app:bootstrap() as item()* {
  app:bootstrap(())
};

declare function app:set-path($application as element(config:application)?) {
  if ($application) then (
    config:set-base-path(xs:string($application/config:base)),
    config:set-config-path((xs:string($application/config:config), "/_config")[1])
  )
  else (
    config:set-base-path(xs:string(get-base()/config:base)),
    config:set-config-path((xs:string(get-base()/config:config), "/_config")[1])
  )
  ,
  xdmp:log(("Bootstrap XQuerrail Application - version [" || config:version() || "] - commit [" || config:last-commit() || "]", "base [" || config:get-base-path() || "] - config [" || config:get-config-path() || "] - framework [" || config:framework-path() || "] - ML version [" || xdmp:version() || "]"), "info")
  ,
  app:load-config()
};

declare function app:bootstrap($application as element(config:application)?) as item()* {
  if (fn:empty($application) and config:get-base-path() and config:get-config-path()) then
    ()
  else
  (
    app:set-path($application),
    module-loader:load-modules-framework(),
    for $application in config:get-applications()
    let $application-name := fn:string($application/@name)
      return (
        module-loader:load-modules($application-name, fn:true()),
        app:load-application($application-name)
      )
  )
};

declare %private function app:load-application(
  $application-name as xs:string
) as element(domain:domain)? {
  let $application-path := fn:concat(config:application-directory($application-name), "/domains/application-domain.xml")
  let $domain-config := config:get-resource($application-path)
  let $domain := app:load-domain($application-name, $domain-config)
  let $config := config:get-config()
  let $_ := cache:set-domain($config, $application-name, $domain, fn:true())
  let $domain := app:custom-models($application-name, app:update-domain($application-name, $domain))
  let $_ := app:validate-domain($application-name, $domain)
  let $_ := cache:set-domain($config, $application-name, $domain, fn:false())
  let $_ := map:clear(cache:domain-model-cache())
  let $_ := module-loader:load-modules($application-name, fn:false())
  let $_ := app:custom-bootstrap($application-name)
  let $_ := app:load-cache-to-task-server()
  return $domain
};

declare %private function app:custom-bootstrap(
  $application-name as xs:string
) {
  for $path in fn:string(config:get-application($application-name)/config:bootstrap/@resource)
  return
    if ($path ne "") then
      try {
        (
          xdmp:lock-for-update(xdmp:integer-to-hex(xdmp:random())),
          xdmp:apply(xdmp:function(xs:QName("extension:initialize"), $path))
        )
      }
      catch ($exception) {xdmp:log($exception, "warning")}
    else ()
};

declare %private function app:load-config(
) as element(config:config) {
  let $config :=
    if(xdmp:modules-database() = 0)
    then xdmp:unquote(
            xdmp:binary-decode(
                xdmp:external-binary(fn:concat(
                    xdmp:modules-root(),
                    if(fn:ends-with(xdmp:modules-root(),"/")) then "" else "/",
                    fn:concat(config:get-config-path(), "/config.xml"))
                )
            ,"utf8")
         )/element()
    else
      xdmp:eval(fn:concat("fn:doc('", config:get-config-path(), "/config.xml')/element()"),
      (),
      <options xmlns="xdmp:eval">
         <database>{xdmp:modules-database()}</database>
      </options>
      )

  let $config := element config:config {
    (:$config/namespace::*,:)
    $config/@*,
    $config/*
  }

  return (
    config:set-config($config),
    $config
  )
};

declare %private function app:load-domain(
  $application-name as xs:string,
  $domain as element(domain:domain)
) as element(domain:domain) {
  let $app-path := config:application-directory($application-name)
  let $imports :=
    for $import in $domain/domain:import
    return
    config:get-resource(fn:concat($app-path,"/domains/",$import/@resource))
  return
    element { fn:QName("http://xquerrail.com/domain", "domain") } {
      ($domain/namespace::*,$imports/namespace::*),
      $domain/attribute::*,
      $domain/(domain:name|domain:content-namespace|domain:application-namespace|domain:description|domain:author|domain:version|domain:declare-namespace|domain:default-collation|domain:permission|domain:language|domain:default-language|domain:navigation|domain:profiles|domain:validator),
      ($domain/domain:model,$imports/domain:model),
      ($domain/domain:optionlist,$imports/domain:optionlist),
      ($domain/domain:enumeration,$imports/domain:enumeration),
      ($domain/domain:controller,$imports/domain:controller),
      ($domain/domain:view,$imports/domain:view)
    }
};

declare %private function app:update-domain(
  $application-name as xs:string,
  $domain as element(domain:domain)
) as element(domain:domain) {
  element { fn:QName("http://xquerrail.com/domain", "domain") } {
    $domain/namespace::*,
    $domain/attribute::*[. except ($domain/@compiled|$domain/@timestamp)],
    attribute compiled {fn:true()},
    attribute timestamp {fn:current-dateTime()},
    $domain/*[. except $domain/domain:model],
    $domain/domain:model ! (domain:compile-model($application-name, .))
  }
};

declare %private function app:custom-models(
  $application-name as xs:string,
  $domain as element(domain:domain)
) as element(domain:domain) {
  let $models-generator := module-loader:load-function-module(
    $application-name,
    $module-loader:DOMAIN-EXTENSION-TYPE,
    "build-domain-extension",
    2,
    $domain:DOMAIN-EXTENSION-NAMESPACE,
    ()
  )
  return
    if (fn:exists($models-generator)) then
      fn:fold-left(
        function($domain, $funct) {
          let $updated-domain := $funct($application-name, $domain)
          return app:update-domain($application-name, $updated-domain)
        },
        $domain,
        $models-generator
      )
    else
      $domain
};

declare %private function app:validate-domain(
  $application-name as xs:string,
  $domain as element(domain:domain)
) as empty-sequence() {
  let $validate-functions := module-loader:load-function-module(
    $application-name,
    $module-loader:DOMAIN-EXTENSION-TYPE,
    "validate-domain-extension",
    2,
    $domain:DOMAIN-EXTENSION-NAMESPACE,
    ()
  )
  return
    if (fn:exists($validate-functions)) then
      let $errors :=
        for $validate-function in $validate-functions
        return $validate-function($application-name, $domain)
      return
        if (fn:exists($errors)) then
          fn:error(xs:QName("VALIDATE-DOMAIN-ERROR"), "Domain is not valid", $errors)
        else
          ()
    else
      ()
};

declare %private function app:get-base() as element(config:application) {
  let $base := (get-base-safe("/base.xqy"), get-base-safe("base.xqy"))[1]
  return
    if ($base) then $base
    else fn:error(xs:QName("BASE-NOT-FOUND"), "Cannot find /base.xqy or base.xqy")
};

declare %private function app:get-base-safe($path as xs:string) as element(config:application)? {
  try {
    xdmp:invoke($path)
  }
  catch * {
    ()
  }
};

declare function app:load-cache-to-task-server() {
  let $cache := map:new((
    for $key in cache:get-cache-keys($cache:SERVER-FIELD-CACHE-LOCATION, cache:cache-base())
    return map:entry($key, cache:get-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key))
  ))
  return xdmp:spawn-function(
    function() {
      for $key in map:keys($cache)
      return cache:set-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key, map:get($cache, $key))
    }
  )
};

declare function app:reset() as item()* {
  try {
    xdmp:function(xs:QName("extension:reset"), "generators/bootstrap-generator.xqy")()
  } catch ($exception) {
    xdmp:log($exception, "warning")
  },
  config:clear-cache()
};

declare function app:get-setting($name as xs:string) {
  app:get-setting(config:default-application(), $name)
};

declare function app:get-setting($application-name as xs:string, $name as xs:string) {
  let $settings := config:resolve-path(config:application-directory($application-name), "settings.xml")
  return
    config:get-resource($settings)/*:setting[*:name/fn:string(.) = $name]/*:value
};
