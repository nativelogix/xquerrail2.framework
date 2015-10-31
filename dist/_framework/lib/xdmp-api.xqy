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
 : Handle MarkLogic API incompatibility
~:)
module namespace api = "http://xquerrail.com/xdmp/api";

declare option xdmp:mapping "false";

declare function api:is-ml-8() as xs:boolean {
  fn:starts-with(xdmp:version(), "8")
};

declare function api:from-json(
  $arg as xs:string
) as item()* {

  if (api:is-ml-8()) then
    xdmp:function(xs:QName("xdmp:from-json-string"))($arg)
  else
    xdmp:function(xs:QName("xdmp:from-json"))($arg)
};

(: TODO: Use javascript server-side mime-type - application/vnd.marklogic-javascript :)
declare function api:is-javascript-modules(
  $location as xs:string
) as xs:boolean {
  fn:ends-with(fn:lower-case($location), ".sjs")
};
