xquery version "1.0-ml";
(:~
 : Builds a instance of an element based on a domain:model
 : Provides a caching mechanism to optimize speedup of calling module functions.
 :)
module namespace module = "http://xquerrail.com/module";

import module namespace domain  ="http://xquerrail.com/domain" at "domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";

(:Options Definition:)
declare option xdmp:mapping "false";

declare function module:resource-exists(
  $uri as xs:string
) as xs:boolean {
  if ($config:USE-MODULES-DB) then
    xdmp:eval(fn:concat('fn:doc-available("', $uri, '")'), (),
      <options xmlns="xdmp:eval">
        <database>{xdmp:modules-database()}</database>
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
