xquery version "1.0-ml";

module namespace generator  = "http://xquerrail.com/generator/module";

import module namespace xdmp-api = "http://xquerrail.com/xdmp/api" at "../lib/xdmp-api.xqy";

declare variable $XQUERY-EXTENSIONS := "(xqy|xq|xquery|xqm)$";

declare option xdmp:mapping "false";

declare variable $CACHE := map:new();

(:~
 : Recursively processes a filesystem path and returns all files matching the criteria specified
 :)
declare function generator:recurse-fs(
  $path as xs:string,
  $filter as xs:string,
  $exclude as xs:string?
) {
 let $entries := xdmp:filesystem-directory($path)
 return
    for $entry in $entries/dir:entry[
      (
        fn:matches(dir:filename, $filter) and
        (if (fn:exists($exclude)) then fn:not(fn:matches(dir:pathname, $exclude)) else fn:true())
      ) or dir:type = "directory"]
    return
      switch($entry/dir:type)
        case "file" return <file name="{$entry/dir:filename}" path="{$entry/dir:pathname}"/>
        case "directory" return generator:recurse-fs($entry/dir:pathname,$filter,$exclude)
        default return ()
};

(:~
 : Gets a list of filesystem resources
 :)
declare function generator:get-filesystem-modules(
  $path as xs:string,
  $filter as xs:string*,
  $excludes as xs:string?
) {
  generator:recurse-fs($path,$filter,$excludes)
};

declare function generator:get-database-modules(
  $base-path as xs:string
) {
  cts:uris() ! <file name="{fn:tokenize(.,"/")[fn:last()]}" path="{.}"/>
};

(:~
 : Get a list of all the modules located in a directory
~:)
declare function generator:get-modules(
  $base-path as xs:string
) {
  if(xdmp:modules-database() = 0)
  then generator:get-filesystem-modules(xdmp:modules-root() || $base-path, $XQUERY-EXTENSIONS, ())
  else generator:get-database-modules(xdmp:modules-root() || $base-path)
};

declare function generator:key-cache(
  $module-namespace as xs:string,
  $module-location as xs:string,
  $attributes as attribute()*,
  $annotations as xs:QName*
) {
  fn:string-join((
    $module-namespace,
    $module-location,
    $attributes ! (
      ./local-name(),
      ./fn:string()
    ),
    $annotations ! (
      xs:string(.)
    )
    ),""
  )
};

(:~
 : Extracts the definition of an configured xquery-extension
~:)
declare function generator:get-module-definition(
  $module-namespace as xs:string,
  $module-location as xs:string
) as element(library)? {
  generator:get-module-definition($module-namespace, $module-location, ())
};

declare function generator:get-module-definition(
  $module-namespace as xs:string,
  $module-location as xs:string,
  $attributes as attribute()*
) as element(library)? {
  generator:get-module-definition($module-namespace, $module-location, $attributes, ())
};

declare function generator:get-module-definition(
  $module-namespace as xs:string,
  $module-location as xs:string,
  $attributes as attribute()*,
  $annotations as xs:QName*
) as element(library)? {
  let $key := generator:key-cache($module-namespace, $module-location, $attributes, $annotations)
  return
    if (map:contains($CACHE, $key)) then
      map:get($CACHE, $key)
    else
      try {
        let $library :=
        if (xdmp-api:is-javascript-modules($module-location)) then
          generator:get-javascript-module-definition($module-location, $attributes)
        else
          let $functions :=
            xdmp:eval(
              fn:concat(
                "import module namespace ns = '", $module-namespace, "' at '", $module-location, "'; ",
                "xdmp:functions()[fn:namespace-uri-from-QName(fn:function-name(.))= '", $module-namespace , "']"
              )
            )
          let $functions :=
            for $function in $functions
            let $arity := fn:function-arity($function)
            let $function-name := fn:function-name($function)
            return
              <function name="{fn:local-name-from-QName($function-name)}" arity="{$arity}">
                <return>{xdmp:function-return-type($function)}</return>
                {
                  for $anntype in $annotations
                  let $annotation := xdmp:annotation($function,$anntype)
                  return
                    if($annotation)
                    then <implements name="{fn:local-name-from-QName($anntype)}" namespace="{fn:namespace-uri-from-QName($anntype)}">{$annotation}</implements>
                    else ()
                }
                <parameters>
                {
                  for $pos in (1 to $arity)
                  let $name := xdmp:function-parameter-name($function,$pos)
                  let $type := xdmp:function-parameter-type($function,$pos)
                  return <parameter name="{$name}" type="{$type}"/>
                }
                </parameters>
             </function>
          return
            element library {
              attribute namespace {$module-namespace},
              attribute location {$module-location},
              $attributes,
              $functions
            }
        return (
          map:put($CACHE, $key, $library),
          $library
        )
      } catch ($ex) {
        xdmp:log($ex, "warning"),
        xdmp:trace("xquerrail.generator", $ex),
        xdmp:rethrow()
      }
};

declare function generator:get-javascript-module-definition(
  $module-location as xs:string,
  $attributes as attribute()*
) as element(library)? {
  let $key := generator:key-cache("", $module-location, $attributes, ())
  return
    if (map:contains($CACHE, $key)) then
      map:get($CACHE, $key)
    else
      try {
        let $functions :=
          xdmp:function(xs:QName("xdmp:javascript-eval"))(
            '
            var functions = [];
            var definition = require(location)["$definition"];
            Object.keys(require(location)).forEach(
              function(key) {
                if (key === "$definition")
                  return
                else
                    if (definition &amp;&amp; definition[key])
                      functions.push(definition[key])
                    else
                      functions.push({"name": key, "arity": require(location)[key].length})
              }
            )
            functions
            ',
            map:entry("location", $module-location)
          )
        let $functions :=
          for $function in json:array-values($functions)
          let $arity := map:get($function, "arity")
          let $function-name := map:get($function, "name")
          return
            <function name="{$function-name}" arity="{$arity}">
              <return>{map:get($function, "return")}</return>
              <parameters>
              {
                let $parameters := map:get($function, "parameters")
                return
                  if ($parameters instance of json:array) then
                    for $parameter in json:array-values($parameters)
                    let $name := map:get($parameter,"name")
                    let $type := map:get($parameter,"type")
                    return <parameter name="{$name}" type="{$type}"/>
                  else
                    ()
              }
              </parameters>
           </function>
        let $library :=
          element library {
            (:attribute namespace {$module-namespace},:)
            attribute location {$module-location},
            $attributes,
            $functions
          }
        return (
          map:put($CACHE, $key, $library),
          $library
        )
      } catch ($ex) {
        xdmp:log($ex, "warning"),
        xdmp:trace("xquerrail.generator", $ex),
        xdmp:rethrow()
      }
};

declare function generator:function-contains-annotation(
  $function as element(function),
  $annotations as xs:QName*
) as xs:boolean {
  cts:contains(
    $function,
    cts:and-query((
      for $annotation in $annotations
      return (
        cts:element-attribute-value-query(
          xs:QName("implements"),
          xs:QName("name"),
          fn:local-name-from-QName($annotation),
          ("exact")
        ),
        cts:element-attribute-value-query(
          xs:QName("implements"),
          xs:QName("namespace"),
          fn:namespace-uri-from-QName($annotation),
          ("exact")
        )
      )
    ))
  )
};

declare function generator:get-xdmp-function(
  $function as element(function)
) as xdmp:function {
  xdmp:function(fn:QName($function/../@namespace, $function/@name), $function/../@location)
};
