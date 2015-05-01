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

module namespace context = "http://xquerrail.com/context";

import module namespace domain  ="http://xquerrail.com/domain" at "domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";

(:Options Definition:)
declare option xdmp:mapping "false";

declare %private variable $_user := xdmp:get-current-user();
declare %private variable $_roles := ();

declare function context:user() as xs:string {
  $_user
};

declare function context:user(
  $user as xs:string?
) as empty-sequence() {
  if (fn:exists($user)) then
    xdmp:set($_user, $user)
  else
    ()
};

declare function context:roles() {
  $_roles
};

declare function context:add-role(
  $role as xs:string?
) as empty-sequence() {
  if (fn:exists($role)) then
    xdmp:set($_roles, ($_roles, $role))
  else
    ()
};

declare function context:remove-role(
  $role as xs:string?
) as empty-sequence() {
  if (fn:exists($role)) then
    xdmp:set($_roles, fn:remove($_roles, fn:index-of($_roles, $role)))
  else
    ()
};

