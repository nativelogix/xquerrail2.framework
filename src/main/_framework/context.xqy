xquery version "1.0-ml";

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

