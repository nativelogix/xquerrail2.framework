xquery version "1.0-ml";

module namespace app = "http://xquerrail.com/application";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace cache = "http://xquerrail.com/cache" at "cache.xqy";

import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";

declare option xdmp:mapping "false";

declare function app:bootstrap() as item()* {
  app:bootstrap(())
};

declare function app:bootstrap($application as element(config:application)?) as item()* {
  if (fn:empty($application) and config:get-base-path() and config:get-config-path()) then
    ()
  else
  (
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
  ,
  for $application in config:get-applications()
    return load-application(xs:string($application/@name))
  )
};

declare %private function app:load-application(
  $application-name as xs:string
) as element(domain)?
{
  let $application-path := fn:concat(config:application-directory($application-name), "/domains/application-domain.xml")
  let $_ := xdmp:log(text{"config:load-domain", $application-name, "$application-path", $application-path}, "debug")
  let $domain-config := config:get-resource($application-path)
  let $domain := load-domain($domain-config)
  let $config := config:get-config()
  let $_ := cache:set-domain-cache(config:cache-location($config), $application-name, $domain, config:anonymous-user($config))
  let $domain := update-domain($domain)
  let $_ := cache:set-domain-cache(config:cache-location($config), $application-name, $domain, config:anonymous-user($config))
  return $domain
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
  let $config := element config:config { $config/* }
  let $_ := cache:set-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $config)
  return $config
};

declare %private function app:load-domain(
  $domain as element(domain:domain)
) {
    let $app-path := config:application-directory($domain/*:name)
    let $imports :=
        for $import in $domain/domain:import
        return
        config:get-resource(fn:concat($app-path,"/domains/",$import/@resource))
    return
        element domain {
         namespace domain {"http://xquerrail.com/domain"},
         attribute xmlns {"http://xquerrail.com/domain"},
         $domain/@*,
         $domain/(domain:name|domain:content-namespace|domain:application-namespace|domain:description|domain:author|domain:version|domain:declare-namespace|domain:default-collation|domain:permission),
         ($domain/domain:model,$imports/domain:model),
         ($domain/domain:optionlist,$imports/domain:optionlist),
         ($domain/domain:controller,$imports/domain:controller),
         ($domain/domain:view,$imports/domain:view)
       }
};

declare %private function update-domain(
  $domain
) {
  element domain {
    namespace domain {"http://xquerrail.com/domain"},
    attribute xmlns {"http://xquerrail.com/domain"},
    $domain/@*,
    $domain/*[. except $domain/domain:model],
    $domain/domain:model ! (domain:set-model-field-attributes(.))
  }
};

declare %private function app:get-base() as element(config:application) {
  let $base := (get-base-safe("/base.xqy"), get-base-safe("base.xqy"))[1]
  return
    if ($base) then $base
    else fn:error(xs:QName("BASE-NOTFOUND"), "Cannot find /base.xqy or base.xqy")
};

declare %private function app:get-base-safe($path as xs:string) as element(config:application)? {
  try {
    xdmp:invoke($path)
  }
  catch * {
    ()
  }
}; 

declare function app:reset() as item()* {
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