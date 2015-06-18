xquery version "1.0-ml";
(:~
 : Builds a instance of an element based on a domain:model
 : Provides a caching mechanism to optimize speedup of calling module functions.
 :)
module namespace module = "http://xquerrail.com/module";

import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";

(:Options Definition:)
declare option xdmp:mapping "false";

declare variable $CACHE := map:new();

declare variable $MODULES-DB := xdmp:modules-database();

declare function module:resource-exists(
  $uri as xs:string
) as xs:boolean {
  if ($config:USE-MODULES-DB) then
    xdmp:eval(fn:concat('fn:doc-available("', $uri, '")'), (),
      <options xmlns="xdmp:eval">
        <database>{$MODULES-DB}</database>
      </options>
    )
  else
    xdmp:uri-is-file($uri)
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

declare function module:available-functions(
  $namespace as xs:string,
  $uri as xs:string
) as element(functions) {

  let $cache := xdmp:get-server-field(fn:concat($namespace,$uri))
  return
    if (fn:exists($cache)) then
      $cache
    else
      xdmp:set-server-field(
        fn:concat($namespace,$uri),
        element functions {
          for $function in module:load-functions-module($namespace, $uri)
          return
            element function {
              element name {
                fn:local-name-from-QName(fn:function-name($function))
              },
              element arity {
                fn:function-arity($function)
              }
            }
        }
      )

};

declare function module:base-module-location() as xs:string {
  if (map:contains($CACHE, "base-module-location")) then
    map:get($CACHE, "base-module-location")
  else
    let $base-module-location := config:resolve-framework-path("lib")
    return (
      map:put($CACHE, "base-module-location", $base-module-location),
      $base-module-location
    )
};

declare function module:get-module-uris(
  $base-namespace as xs:string,
  $suffix-location as xs:string
) as map:map {
  let $versions := (
    "v" || xdmp:version(),
    fn:substring-before(xdmp:version(), "-") ! ("v" || .),
    fn:substring-before(xdmp:version(), ".") ! ("v" || .),
    "impl"
  )
  return
    map:new((
      $versions ! (
        let $uri := fn:concat(module:base-module-location(), $suffix-location, ., ".xqy")
        let $namespace := fn:concat($base-namespace, .)
        return
        if (module:resource-exists($uri)) then
          map:entry($namespace, $uri)
        else
          ()
      )
    ))
};

declare function module:load-function(
  $function-name as xs:string,
  $function-arity as xs:integer,
  $base-namespace as xs:string,
  $suffix-location as xs:string
) as function(*)? {
  fn:head(
    map:keys(module:get-module-uris($base-namespace, $suffix-location)) ! (
      let $namespace := .
      let $uri := map:get(module:get-module-uris($base-namespace, $suffix-location), $namespace)
      return
        if (module:available-functions($namespace, $uri)/function[name eq $function-name and arity eq $function-arity]) then
          module:load-function-module($function-name, $function-arity, $namespace, $uri)
        else
          ()
    )
  )
};

declare function module:load-functions-module($namespace as xs:string, $uri as xs:string) {
  xdmp:eval(
  'xquery version "1.0-ml";
  import module namespace ns = "' || $namespace || '" at "' || $uri || '";
  xdmp:functions()[fn:namespace-uri-from-QName(fn:function-name(.)) = ("' || $namespace || '")]'
  )
};

declare function module:load-function-module(
  $function-name as xs:string,
  $function-arity as xs:integer,
  $namespace as xs:string,
  $uri as xs:string
) {
  xdmp:function(fn:QName($namespace, $function-name), $uri)
  (:xdmp:eval(
  'xquery version "1.0-ml";
  import module namespace ns = "' || $namespace || '" at "' || $uri || '";
  ns:' || $function-name || '#' || $function-arity
  ):)
};
