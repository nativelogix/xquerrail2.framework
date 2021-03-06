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
import module namespace xdmp-api = "http://xquerrail.com/xdmp/api" at "lib/xdmp-api.xqy";

(:Options Definition:)
declare option xdmp:mapping "false";

declare variable $EVENT-NAME := "xquerrail.module";

declare variable $CACHE := json:object();
declare variable $MEMOIZE-CACHE := cache:get-server-field-cache-map("module-memoize-cache");
declare variable $GLOBAL-FUNCTION-CACHE-KEY := "global-function-cache";
declare variable $FUNCTION-CACHE := cache:get-server-field-cache-map("module-function-cache");
declare variable $FUNCTION-DEFINITION-CACHE := cache:get-server-field-cache-map("module-function-definition-cache");
declare variable $GLOBAL-FUNCTION-CACHE := cache:get-server-field-cache-map($GLOBAL-FUNCTION-CACHE-KEY);
declare variable $FUNCTION-NOT-FOUND := "function-not-found";
declare variable $CONTROLLER-EXTENSION-TYPE := "controller-extension";
declare variable $DOMAIN-EXTENSION-TYPE := "domain-extension";
declare variable $ENGINE-EXTENSION-TYPE := "engine-extension";
declare variable $MODEL-EXTENSION-TYPE := "model-extension";
declare variable $MODEL-EXPRESSION-TYPE := "model-expression";
declare variable $CONTROLLER-TYPE := "controller";
declare variable $ENGINE-TYPE := "engine";
declare variable $EVENT-TYPE := "event";
declare variable $MODEL-TYPE := "model";

(: List of XQuerrail modules dynamically loaded :)
declare variable $XQUERRAIL-MODULES := map:new((
  map:entry("http://xquerrail.com/domain", "domain.xqy"),
  map:entry("http://xquerrail.com/model/base", "base/base-model.xqy"),
  map:entry("http://xquerrail.com/controller/base", "base/base-controller.xqy"),
  map:entry("http://xquerrail.com/controller/domains", "services/domains-controller.xqy")
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
            <database>{$config:MODULES-DB}</database>
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
   module:normalize-uri($parts, "")
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
  let $final := fn:string-join(($base, $parts) ! fn:replace(., "^/|/$", ""), "/")
  return
     if(fn:not($config:USE-MODULES-DB) or fn:matches($final,"^(http(s)?://|/)")) then
      $final
     else
      fn:concat("/", $final)
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
  $module-type as xs:string?,
  $function-name as xs:string?,
  $function-arity as xs:integer?,
  $namespace as xs:string?,
  $location as xs:string?
) as xdmp:function* {
  module:lookup-functions-module((), $module-type, $function-name, $function-arity, $namespace, $location)
};

declare function module:lookup-functions-module(
  $application as xs:string?,
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
  fn:string-join(
    (
      "function-key-cache",
      $application,
      $module-type,
      $function-name,
      $function-arity,
      $namespace,
      $location
    ),
    ":"
  )
};

declare function module:load-function-module(
  $application as xs:string?,
  $module-type as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string?,
  $location as xs:string?
) as xdmp:function? {
  module:load-function-module($application, $module-type, $function-name, $function-arity, $namespace, $location, ())
};

declare function module:load-function-module(
  $application as xs:string?,
  $module-type as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string?,
  $location as xs:string?,
  $interface as xs:boolean?
) as xdmp:function? {
  let $key := fn:string-join(($application, $module-type, $function-name, fn:string($function-arity), $namespace, $location, fn:string($interface)), ":")
  let $cache := (
    if (fn:exists($application)) then
      (
        $FUNCTION-CACHE,
        $GLOBAL-FUNCTION-CACHE
      )
    else
      (
        $GLOBAL-FUNCTION-CACHE,
        $FUNCTION-CACHE
      )
    (:,
    $GLOBAL-FUNCTION-CACHE:)

  )
  let $function := fn:head($cache ! map:get(., $key))
  return
    if (fn:exists($function)) then
      (:if ($function instance of xdmp:function) then:)
        $function
      (:else:)
        (:():)
    else
      let $namespace :=
        if (fn:exists($location)) then
          if (fn:exists($namespace) and fn:not(xdmp-api:is-javascript-modules($location))) then
            $namespace
          else
            ()
        else
          $namespace
      let $libraries :=
        if (fn:exists($application)) then
        (
          module:get-modules($application),
          module:get-modules()
        )
        else
        (
          module:get-modules(),
          module:get-modules(
            if (fn:exists($application)) then
              $application
            else if (fn:count(config:get-applications()) eq 1) then
              config:default-application()
            else
              ()
          )
        )
      let $function := fn:head((
        $libraries ! (./library[
          (if (fn:exists($module-type)) then @type eq $module-type else fn:true()) and
          (if (fn:exists($namespace)) then @namespace eq $namespace else fn:true()) and
          (if (fn:exists($location)) then @location eq $location else fn:true()) and
          (if (fn:exists($interface)) then @interface eq $interface else fn:true())
        ]/function[@name eq $function-name and @arity eq $function-arity])
        (:module:get-modules($application)/library[
          (if (fn:exists($module-type)) then @type eq $module-type else fn:true()) and
          (if (fn:exists($namespace)) then @namespace eq $namespace else fn:true()) and
          (if (fn:exists($location)) then @location eq $location else fn:true()) and
          (if (fn:exists($interface)) then @interface eq $interface else fn:true())
        ]/function[@name eq $function-name and @arity eq $function-arity]
        ,
        module:get-modules()/library[
          (if (fn:exists($module-type)) then @type eq $module-type else fn:true()) and
          (if (fn:exists($namespace)) then @namespace eq $namespace else fn:true()) and
          (if (fn:exists($location)) then @location eq $location else fn:true()) and
          (if (fn:exists($interface)) then @interface eq $interface else fn:true())
        ]/function[@name eq $function-name and @arity eq $function-arity]:)
      ))
      let $function :=
        if (fn:exists($function)) then
          let $function :=
            if (fn:count($function) ne 1) then (
              xdmp:trace($EVENT-NAME, (text{"Found multiple functions with params", $function-name, $function-arity, $module-type}, $function)),
              $function[1]
            ) else
              $function
          return generator:get-xdmp-function($function)
        else
          ()
      return (
        map:put(fn:head($cache), $key, $function(:($function, $FUNCTION-NOT-FOUND)[1]:)),
        $function
      )
};

declare function module:get-function-module-definition(
  $module-type as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string?,
  $location as xs:string?
) as element(function)* {
  module:get-function-module-definition((), $module-type, $function-name, $function-arity, $namespace, $location, ())
};

declare function module:get-function-module-definition(
  $application as xs:string?,
  $module-type as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string?,
  $location as xs:string?,
  $interface as xs:boolean?
) as element(function)* {
  let $key := fn:string-join(("get-function-module-definition", "$application", $application, "$module-type", $module-type, "$function-name", $function-name, "$function-arity", xs:string($function-arity), "$namespace", $namespace, "$location", $location), ":")
  return
    if (cache:contains-cache-map($FUNCTION-DEFINITION-CACHE, $key)) then
      cache:get-cache-map($FUNCTION-DEFINITION-CACHE, $key)
    else
      cache:set-cache-map(
        $FUNCTION-DEFINITION-CACHE,
        $key,
        let $namespace :=
          if (fn:exists($location)) then
            if (fn:exists($namespace) and fn:not(xdmp-api:is-javascript-modules($location))) then
              $namespace
            else
              ()
          else
            $namespace
        let $libraries :=
          if (fn:exists($application)) then
          (
            module:get-modules($application),
            module:get-modules()
          )
          else
          (
            module:get-modules(),
            module:get-modules(
              if (fn:exists($application)) then
                $application
              else if (fn:count(config:get-applications()) eq 1) then
                config:default-application()
              else
                ()
            )
          )
        return fn:head((
          $libraries ! (./library[
            (if (fn:exists($module-type)) then @type eq $module-type else fn:true()) and
            (if (fn:exists($namespace)) then @namespace eq $namespace else fn:true()) and
            (if (fn:exists($location)) then @location eq $location else fn:true()) and
            (if (fn:exists($interface)) then @interface eq $interface else fn:true())
          ]/function[@name eq $function-name and @arity eq $function-arity])
        ))
        (:module:get-modules($application)/library[
          (if (fn:exists($module-type)) then @type eq $module-type else fn:true()) and
          (if (fn:exists($namespace)) then @namespace eq $namespace else fn:true()) and
          (if (fn:exists($location)) then @location eq $location else fn:true())
        ]/function[@name eq $function-name and @arity eq $function-arity]:)
      )
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string
) {
  module:apply-function-module($module-type, $name, 0, (), (), (), (), (), (), (), (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*
) {
  module:apply-function-module($module-type, $name, 1, $argument-1, (), (), (), (), (), (), (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*
) {
  module:apply-function-module($module-type, $name, 2, $argument-1, $argument-2, (), (), (), (), (), (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*
) {
  module:apply-function-module($module-type, $name, 3, $argument-1, $argument-2, $argument-3, (), (), (), (), (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*
) {
  module:apply-function-module($module-type, $name, 4, $argument-1, $argument-2, $argument-3, $argument-4, (), (), (), (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*
) {
  module:apply-function-module($module-type, $name, 5, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, (), (), (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*
) {
  module:apply-function-module($module-type, $name, 6, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, (), (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*
) {
  module:apply-function-module($module-type, $name, 7, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, (), (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*
) {
  module:apply-function-module($module-type, $name, 8, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, (), ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*
) {
  module:apply-function-module($module-type, $name, 9, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, ())
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*,
  $argument-10 as item()*
) {
  module:apply-function-module($module-type, $name, 10, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
};

declare function module:apply-function-module(
  $module-type as xs:string?,
  $name as xs:string,
  $arity as xs:integer,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*,
  $argument-10 as item()*
) {
  module:apply-function-module((), $module-type, $name, $arity, (), (), $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
};

declare function module:apply-function-module(
  $application as xs:string?,
  $module-type as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string?,
  $location as xs:string?,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*,
  $argument-10 as item()*
) {
  let $function :=
    module:get-function-module-definition(
      $application,
      $module-type,
      $function-name,
      $function-arity,
      $namespace,
      $location,
      fn:false()
    )
  let $function :=
    if (fn:empty($function)) then
      fn:error(xs:QName("APPLY-FUNCTION-MODULE-ERROR"), text{"Function", $function-name, $function-arity, "from", $module-type ,"module type not found."})
    else
      $function
  return
    if (generator:function-contains-annotation($function, xs:QName("module:memoize"))) then
      module:memoize(generator:get-xdmp-function($function), $function-arity, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
    else
      module:apply-function(generator:get-xdmp-function($function), $function-arity, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
};

declare function module:apply-function(
  $funct,
  $function-arity,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*,
  $argument-10 as item()*
) {
  if ($function-arity eq 0) then
    $funct()
  else if ($function-arity eq 1) then
    $funct($argument-1)
  else if ($function-arity eq 2) then
    $funct($argument-1, $argument-2)
  else if ($function-arity eq 3) then
    $funct($argument-1, $argument-2, $argument-3)
  else if ($function-arity eq 4) then
    $funct($argument-1, $argument-2, $argument-3, $argument-4)
  else if ($function-arity eq 5) then
    $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5)
  else if ($function-arity eq 6) then
    $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6)
  else if ($function-arity eq 7) then
    $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7)
  else if ($function-arity eq 8) then
    $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8)
  else if ($function-arity eq 9) then
    $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9)
  else if ($function-arity eq 10) then
    $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
  else
    fn:error()

  (:if (fn:empty($arguments)) then
    $funct()
  else if (fn:count($arguments) eq 1) then
    $funct($arguments)
  else
    module:apply-function(
      $funct(fn:head($arguments), ?),
      fn:tail($arguments)
    ):)
};

declare function module:hash(
  $items as item()*
) as xs:string? {
  if (fn:empty($items)) then
    ()
  else
    fn:string-join(
      (
        for $item in $items
          return
            if ($item instance of node()) then
              fn:generate-id($item)
            else if ($item instance of binary() or $item instance of xs:string) then
              xdmp:md5($item)
            else
              xdmp:md5(xdmp:describe($item))
      )
      , ":"
    )
};

(:~ TODO: Handle function returning empty-sequence() :)
declare function module:memoize(
  $funct as xdmp:function,
  $arity as xs:positiveInteger,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*,
  $argument-10 as item()*
) {
  let $arity :=
    if ($arity gt 10) then
      fn:error(xs:QName("MEMOIZE-ERROR"), fn:concat("Arity not supported ", $arity))
    else
      $arity
  let $key := fn:string-join((
    xdmp:function-module($funct),
    xdmp:key-from-QName(xdmp:function-name($funct)),
    if ($arity ge 1) then module:hash($argument-1) else (),
    if ($arity ge 2) then module:hash($argument-2) else (),
    if ($arity ge 3) then module:hash($argument-3) else (),
    if ($arity ge 4) then module:hash($argument-4) else (),
    if ($arity ge 5) then module:hash($argument-5) else (),
    if ($arity ge 6) then module:hash($argument-6) else (),
    if ($arity ge 7) then module:hash($argument-7) else (),
    if ($arity ge 8) then module:hash($argument-8) else (),
    if ($arity ge 9) then module:hash($argument-9) else (),
    if ($arity ge 10) then module:hash($argument-10) else ()
  ), ":")
  return
    if (cache:contains-cache-map($MEMOIZE-CACHE, $key)) then
      cache:get-cache-map($MEMOIZE-CACHE, $key)
    else
      cache:set-cache-map(
        $MEMOIZE-CACHE,
        $key,
        if ($arity eq 0) then
          $funct()
        else if ($arity eq 1) then
          $funct($argument-1)
        else if ($arity eq 2) then
          $funct($argument-1, $argument-2)
        else if ($arity eq 3) then
          $funct($argument-1, $argument-2, $argument-3)
        else if ($arity eq 4) then
          $funct($argument-1, $argument-2, $argument-3, $argument-4)
        else if ($arity eq 5) then
          $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5)
        else if ($arity eq 6) then
          $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6)
        else if ($arity eq 7) then
          $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7)
        else if ($arity eq 8) then
          $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8)
        else if ($arity eq 9) then
          $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9)
        else
          $funct($argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
      )
};

declare function module:load-libraries-framework(
  $modules as element(module)*
) as element(library)* {
  for $module in $modules
  return module:load-module-definition(
    $module/@namespace,
    $module/@location,
    ($module/@*[. except ($module/@namespace, $module/@location)])
    (:attribute type { $module/@type }:)
  )
};

declare function module:load-domain-extensions(
) as element(library)* {
  for $module-location in config:domain-extension-location()
  return module:load-module-definition(
    $domain:DOMAIN-EXTENSION-NAMESPACE,
    $module-location,
    attribute type { $module:DOMAIN-EXTENSION-TYPE }
  )
};

declare function module:load-controller-extensions(
) as element(library)* {
  for $module-location in config:controller-extension-location()
  return module:load-module-definition(
    $domain:CONTROLLER-EXTENSION-NAMESPACE,
    $module-location,
    attribute type { $module:CONTROLLER-EXTENSION-TYPE }
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
    attribute type { $module:ENGINE-EXTENSION-TYPE }
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
    attribute type { $module:ENGINE-TYPE }
  )
};

declare function module:load-controller-functions(
  $application as xs:string
) as element(library)* {
  for $controller in domain:get-controllers($application)
  let $controller-name := $controller/@name
  let $controller-namespace := config:controller-uri($application, $controller-name)
  let $controller-locations := config:controller-location($application, $controller-name)
  return
    for $controller-location in $controller-locations
    let $functions := module:load-module-definition(
      $controller-namespace,
      $controller-location,
      (
        attribute name {$controller-name},
        attribute type { $module:CONTROLLER-TYPE }
      )
    )
    return $functions
};

declare function module:load-model-functions(
  $application as xs:string
) as element(library)* {
  for $model in domain:get-models($application, fn:true())
  let $model-name := $model/@name
  let $model-namespace := config:model-uri($application, $model-name)
  let $model-location := config:model-location($application, $model-name)
  return (
    module:load-module-definition(
      $model-namespace,
      $model-location,
      (
        attribute name {$model-name},
        attribute type { $module:MODEL-TYPE }
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
  return (
    module:load-module-definition(
      $model-namespace,
      $model-location,
      (
        attribute name {$model/@name},
        attribute type { $module:EVENT-TYPE }
      )
    )
  )
};

declare function module:load-model-expression-functions(
  $application as xs:string
) as element(library)* {
  for $model in domain:get-models($application, fn:true())
    for $expression in $model//domain:expression
    let $model-namespace := fn:string($expression/@namespace)
    let $model-location := fn:string($expression/@location)
    return
      if ($model-location ne "") then
        module:load-module-definition(
          $model-namespace,
          $model-location,
          (
            attribute name {$model/@name},
            attribute type { $module:MODEL-EXPRESSION-TYPE }
          )
        )
      else
        ()
};

declare function module:load-model-extensions(
) as element(library)* {
  for $module-location in config:model-extension-location()
  return module:load-module-definition(
    $domain:MODEL-EXTENSION-NAMESPACE,
    $module-location,
    attribute type { $module:MODEL-EXTENSION-TYPE }
  )
};

declare function module:library-key-cache(
) as xs:string {
  module:library-key-cache(())
};

declare function module:library-key-cache(
  $application as xs:string?
) as xs:string {
  if (fn:exists($application)) then
    fn:concat($application, "/libraries")
  else
    "libraries"
};

declare function module:get-modules(
) as element(libraries)? {
  module:get-modules(())
};

declare function module:get-modules(
  $application as xs:string?
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

declare %private function module:contains-cache-library(
  $key as xs:string,
  $transient as xs:boolean
) as xs:boolean {
  if ($transient) then
    map:contains($CACHE, $key)
  else
    fn:exists(module:get-cache-library($key, $transient))
};

declare %private function module:get-cache-library(
  $key as xs:string,
  $transient as xs:boolean
) {
  if ($transient) then
    map:get($CACHE, $key)
  else
    cache:get-application-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key)
};

declare %private function module:set-cache-library(
  $key as xs:string,
  $value,
  $transient as xs:boolean
) as empty-sequence() {
  if ($transient) then
    map:put($CACHE, $key, $value)
  else
    cache:set-application-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key, $value)
};

declare function module:load-modules-framework(
) as empty-sequence() {
  let $libraries :=
    element libraries {
      for $module-namespace in map:keys($XQUERRAIL-MODULES)
      let $module-location := config:resolve-framework-path(map:get($XQUERRAIL-MODULES, $module-namespace))
      let $definition := module:get-modules-definition($module-namespace, $module-location)
      return module:load-libraries-framework($definition)
      ,
      module:load-engine-functions(),
      module:load-engine-extensions(),
      module:load-domain-extensions(),
      module:load-controller-extensions(),
      module:load-model-extensions()
    }
  return module:set-cache-library(module:library-key-cache(), $libraries, fn:false())
};

declare function module:load-modules(
  $application as xs:string,
  $transient as xs:boolean
) as empty-sequence() {
  if (config:get-applications()/@name = $application) then
    (
      (
        let $libraries :=
          element libraries {
            attribute application { $application },
              module:load-domain-extensions(),
              module:load-controller-extensions(),
              module:load-model-extensions(),
              if ($transient) then
                ()
              else
                (
                  module:load-model-expression-functions($application),
                  module:load-controller-functions($application),
                  (
                    let $load-model-functions := module:load-model-functions($application)
                    return (
                      $load-model-functions
                      )
                  )
                )
          }
        return module:set-cache-library(module:library-key-cache($application), $libraries, $transient)
      )
    )

  else
    fn:error(xs:QName("LOAD-MODULES-ERROR"), text{"Application", $application, "not defined."})
};

declare %private function module:load-module-definition(
 $module-namespace as xs:string,
 $module-location as xs:string,
 $attributes as attribute()*
) as element(library)? {
  module:load-module-definition($module-namespace, $module-location, $attributes, ())
};

declare %private function module:load-module-definition(
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
      ($annotations, xs:QName("module:memoize"))
    )
  else
    ()
};
