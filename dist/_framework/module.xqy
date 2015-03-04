xquery version "1.0-ml";
(:~ 

Copyright 2011 - NativeLogix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.




 :)
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

