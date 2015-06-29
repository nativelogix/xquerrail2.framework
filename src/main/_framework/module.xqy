xquery version "1.0-ml";

(:~
 : Builds a instance of an element based on a domain:model
 : Provides a caching mechanism to optimize speedup of calling module functions.
 :)
module namespace module = "http://xquerrail.com/module";

import module namespace cache = "http://xquerrail.com/cache" at "cache.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";
import module namespace generator = "http://xquerrail.com/generator/module" at "generators/generator.module.xqy";

(:Options Definition:)
declare option xdmp:mapping "false";

declare variable $CACHE := map:new();
declare variable $MODULES-DB := xdmp:modules-database();

(: List of XQuerrail modules dynamically loaded :)
declare variable $XQUERRAIL-MODULES := map:new((
  map:entry("http://xquerrail.com/domain", "domain.xqy"),
  map:entry("http://xquerrail.com/model/base", "base/base-model.xqy"),
  map:entry("http://xquerrail.com/controller/base", "base/base-controller.xqy")
));

declare function module:resource-exists(
  $uri as xs:string
) as xs:boolean {
  if (map:contains($CACHE, $uri)) then
    map:get($CACHE, $uri)
  else
    let $resource-exists :=
      if ($config:USE-MODULES-DB) then
        xdmp:eval(fn:concat('fn:doc-available("', $uri, '")'), (),
          <options xmlns="xdmp:eval">
            <database>{$MODULES-DB}</database>
          </options>
        )
      else
        xdmp:uri-is-file($uri)
    return (
      map:put($CACHE, $uri, $resource-exists),
      $resource-exists
    )
};

(:~
 : Takes a sequence of parts and builds a uri normalizing out repeating slashes
 : @param $parts URI Parts to join
 :)
declare function module:normalize-uri(
  $parts as xs:string*
) as xs:string {
   module:normalize-uri($parts,"")
 };

(:~
 : Takes a sequence of parts and builds a uri normalizing out repeating slashes
 : @param $parts URI Parts to join
 : @param $base Base path to attach to
~:)
declare function module:normalize-uri(
  $parts as xs:string*,
  $base as xs:string
) as xs:string {
  let $uri :=
    fn:string-join(
        fn:tokenize(
          fn:string-join($parts ! fn:normalize-space(fn:data(.)),"/"),"/+")
    ,"/")
  let $final := fn:concat($base,$uri)
  return
     if(fn:matches($final,"^(http(s)?://|/)"))
     then $final
     else "/" || $final
};

declare function module:get-modules-map(
  $base-namespace as xs:string,
  $suffix-location as xs:string
) as json:object {
  let $module-uris := json:object()
  let $versions := (
    "v" || xdmp:version(),
    fn:substring-before(xdmp:version(), "-") ! ("v" || .),
    fn:substring-before(xdmp:version(), ".") ! ("v" || .),
    "impl"
  )
  let $_ :=
    $versions ! (
      let $uri := module:normalize-uri((config:framework-path(), fn:concat($suffix-location, "-", ., ".xqy")))
      let $namespace := fn:concat($base-namespace, .)
      return
      if (module:resource-exists($uri)) then
        map:put($module-uris, $namespace, $uri)
      else
        ()
    )
  return $module-uris
};

declare function module:lookup-functions-module(
  $application as xs:string,
  $module-type as xs:string?,
  $function-name as xs:string?,
  $function-arity as xs:integer?,
  $namespace as xs:string?,
  $location as xs:string?
) as xdmp:function* {
  module:get-modules($application)/library[
    cts:contains(
      .,
      cts:and-query((
        if (fn:exists($module-type)) then
          cts:element-attribute-value-query(
            xs:QName("library"),
            xs:QName("type"),
            $module-type,
            ("exact")
          )
        else
          (),
        if (fn:exists($namespace)) then
          cts:element-attribute-value-query(
            xs:QName("library"),
            xs:QName("namespace"),
            $namespace,
            ("exact")
          )
        else
          (),
        if (fn:exists($location)) then
          cts:element-attribute-value-query(
            xs:QName("library"),
            xs:QName("location"),
            $location,
            ("exact")
          )
        else
          ()
      ))
    )
  ]/function[
    cts:contains(
      .,
      cts:and-query((
        if (fn:exists($function-name)) then
          cts:element-attribute-value-query(
            xs:QName("function"),
            xs:QName("name"),
            $function-name,
            ("exact")
          )
        else
          (),
        if (fn:exists($function-arity)) then
          cts:element-attribute-value-query(
            xs:QName("function"),
            xs:QName("arity"),
            xs:string($function-arity),
            ("exact")
          )
        else
          ()
      ))
    )
  ] ! (
    xdmp:function(fn:QName(./../@namespace, ./@name), ./../@location)
  )
};

declare function module:function-key-cache(
  $application as xs:string,
  $module-type as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string?,
  $location as xs:string?
  ) as xs:string {
  fn:concat(
    "function-key-cache::",
    $application,
    $module-type,
    $function-name,
    $function-arity,
    $namespace,
    $location
  )
};

declare function module:load-function-module(
  $application as xs:string,
  $module-type as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string?,
  $location as xs:string?
) as xdmp:function? {
  let $key := module:function-key-cache($application, $module-type, $function-name, $function-arity, $namespace, $location)
  return
    if (map:contains($CACHE, $key)) then
      if (map:get($CACHE, $key) instance of xs:string and map:get($CACHE, $key) eq "FUNCTION-NOT-FOUND") then
        ()
      else
        map:get($CACHE, $key)
    else
      let $functions :=
        module:lookup-functions-module(
          $application,
          $module-type,
          $function-name,
          $function-arity,
          $namespace,
          $location
        )
      return
        if (fn:exists($functions)) then
          let $function :=
            if (fn:count($functions) ne 1) then (
              xdmp:trace("xquerrail.module", (text{"Found multiple functions with params", $function-name, $function-arity, $module-type}, $functions)),
              $functions[1]
            ) else
              $functions
          return (
            map:put($CACHE, $key, $function),
            $function
          )
        else
          (map:put($CACHE, $key, "FUNCTION-NOT-FOUND"))
};

declare function module:load-modules-framework(
  $modules as element(module)*
) as element(library)* {
  for $module in $modules
  return module:load-module-definition(
    $module/@namespace,
    $module/@location,
    attribute type {$module/@type}
  )
};

declare function module:load-domain-extensions(
) as element(library)* {
  for $module-location in config:domain-extension-location()
  return module:load-module-definition(
    $domain:DOMAIN-EXTENSION-NAMESPACE,
    $module-location,
    attribute type {"domain-extension"}
  )
};

declare function module:load-controller-extensions(
) as element(library)* {
  for $module-location in config:controller-extension-location()
  return module:load-module-definition(
    $domain:CONTROLLER-EXTENSION-NAMESPACE,
    $module-location,
    attribute type {"controller-extension"}
  )
};

declare function module:load-engine-extensions(
) as element(library)* {
  for $engine in config:get-engine-extensions()/config:engines/config:engine
  let $namespace := fn:string($engine/@namespace)
  let $location := config:resolve-framework-path(fn:string($engine/@uri))
  return module:load-module-definition(
    $namespace,
    $location,
    attribute type {"engine-extension"}
  )
};

declare function module:load-engine-functions(
) as element(library)* {
  for $engine in config:get-engines-configuration()/config:engines/config:engine
  let $namespace := fn:string($engine/@namespace)
  let $location := config:resolve-framework-path(fn:string($engine/@uri))
  return module:load-module-definition(
    $namespace,
    $location,
    attribute type {"engine"}
  )
};

declare function module:load-controller-functions(
  $application as xs:string
) as element(library)* {
  for $controller in domain:get-controllers($application)
  let $controller-name := $controller/@name
  let $controller-namespace := config:controller-uri($application, $controller-name)
  let $controller-location := config:controller-location($application, $controller-name)
  return module:load-module-definition(
    $controller-namespace,
    $controller-location,
    (
      attribute name {$controller-name},
      attribute type {"controller"}
    )
  )
};

declare function module:load-model-functions(
  $application as xs:string
) as element(library)* {
  for $model in domain:get-models($application, fn:false())
  let $model-name := $model/@name
  let $model-namespace := config:model-uri($application, $model-name)
  let $model-location := config:model-location($application, $model-name)
  return (
    module:load-module-definition(
      $model-namespace,
      $model-location,
      (
        attribute name {$model-name},
        attribute type {"model"}
      )
    ),
    module:load-model-event-functions($application, $model)
  )
};

declare function module:load-model-event-functions(
  $application as xs:string,
  $model as element(domain:model)
) as element(library)* {
  for $event in $model/domain:event
  let $model-namespace := fn:string($event/@module-namespace)
  let $model-location := fn:string($event/@module-uri)
  let $function-name := fn:string($event/@function)
  return module:load-module-definition(
    $model-namespace,
    $model-location,
    (
      attribute name {$model/@name},
      attribute type {"event"}
    )
  )
};


declare function module:load-model-extensions(
) as element(library)* {
  for $module-location in config:model-extension-location()
  return module:load-module-definition(
    $domain:MODEL-EXTENSION-NAMESPACE,
    $module-location,
    attribute type {"model-extension"}
  )
};

declare function module:library-key-cache(
  $application as xs:string
) as xs:string {
  fn:concat($application, "/libraries")
};

declare function module:get-modules(
  $application as xs:string
) as element(libraries)? {
  let $cache :=
    if (map:contains($CACHE, module:library-key-cache($application))) then
      map:get($CACHE, module:library-key-cache($application))
    else
      cache:get-application-cache($cache:SERVER-FIELD-CACHE-LOCATION, module:library-key-cache($application))
  return
    if (fn:empty($cache)) then (
      fn:error(xs:QName("GET-MODULES-ERROR"), text{"Cache is empty"})
    ) else
      $cache
};

declare function module:get-modules-definition(
  $module-namespace as xs:string,
  $module-location as xs:string
) as element(module)* {
  let $key := fn:concat("get-modules-definition::", $module-namespace, $module-location)
  return
  if (map:contains($CACHE, $key)) then
    map:get($CACHE, $key)
  else
    let $function :=
      xdmp:function(
        fn:QName(
          $module-namespace,
          module:load-module-definition($module-namespace, $module-location, (), xs:QName("config:module-location"))/function[implements[@name eq "module-location"]]/@name
        ),
        $module-location
      )()
    return (
      map:put($CACHE, $key, $function),
      $function
    )
};

declare function module:load-modules(
  $application as xs:string,
  $transient as xs:boolean
) as empty-sequence() {
  if (config:get-applications()/@name = $application) then
    let $libraries :=
      element libraries {
        attribute application { $application },
        for $module-namespace in map:keys($XQUERRAIL-MODULES)
        let $module-location := config:resolve-framework-path(map:get($XQUERRAIL-MODULES, $module-namespace))
        let $definition := module:get-modules-definition($module-namespace, $module-location)
        return module:load-modules-framework($definition)
        ,
        module:load-engine-functions(),
        module:load-engine-extensions(),
        module:load-domain-extensions(),
        module:load-controller-extensions(),
        module:load-model-extensions(),
        if ($transient) then
          ()
        else
          module:load-controller-functions($application),
        if ($transient) then
          ()
        else
          module:load-model-functions($application)
      }
    return
      if ($transient) then
        map:put($CACHE, module:library-key-cache($application), $libraries)
      else
        cache:set-application-cache(
          $cache:SERVER-FIELD-CACHE-LOCATION,
          module:library-key-cache($application),
          $libraries
        )

  else
    fn:error(xs:QName("LOAD-MODULES-ERROR"), text{"Application", $application, "not defined."})
};

declare function module:load-module-definition(
 $module-namespace as xs:string,
 $module-location as xs:string,
 $attributes as attribute()*
) as element(library)? {
  module:load-module-definition($module-namespace, $module-location, $attributes, ())
};

declare function module:load-module-definition(
 $module-namespace as xs:string,
 $module-location as xs:string,
 $attributes as attribute()*,
 $annotations as xs:QName*
) as element(library)? {
  if (module:resource-exists($module-location)) then
    generator:get-module-definition(
      $module-namespace,
      $module-location,
      $attributes,
      $annotations
    )
  else
    ()
};
