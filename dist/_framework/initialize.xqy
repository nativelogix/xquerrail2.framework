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
(:~Responsible for refreshing the application cache for all servers including task server.
   The application cache expands all the domains includes and keeps them in a server variable
   corresponding the the configuration uri.
 :)
import module namespace config ="http://xquerrail.com/config" at "config.xqy";
let $http-method := xdmp:get-request-method()
let $application :=
  if ($http-method eq "GET") then
    ()
  else if ($http-method eq "POST") then
    xdmp:get-request-body()/node()
  else
    fn:error(xs:QName("UNSUPPORTED-HTTP-METHOD"), text{"Unsupported HTTP method", $http-method})
return (
  xdmp:set-response-content-type("application/xml"),
  <domains xmlns="http://xquerrail.com/domain">
  {config:refresh-app-cache($application)}</domains>,
  xdmp:spawn(
    "initialize-taskserver.xqy",
    if (fn:exists($application)) then
      (xs:QName("config:application"), $application)
    else
      (xs:QName("config:application"), <config:application/>)
  )
)

