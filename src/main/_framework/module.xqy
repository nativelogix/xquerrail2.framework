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

