xquery version "1.0-ml";
(:~
 : Logger module
 :)
module namespace logger = "http://xquerrail.com/logger";

import module namespace api = "http://xquerrail.com/xdmp/api" at "lib/xdmp-api.xqy";

declare option xdmp:mapping "false";

declare function logger:trace(
  $event-name as xs:string,
  $message as xs:string*
) as empty-sequence() {
  if (api:trace-enabled($event-name)) then
    xdmp:trace($event-name, $message)
  else
    ()
};

declare function logger:info(
  $message as xs:string*
) as empty-sequence() {
  xdmp:log($message, "info")
};

declare function logger:warning(
  $message as xs:string*
) as empty-sequence() {
  xdmp:log($message, "warning")
};

declare function logger:error(
  $message as xs:string*
) as empty-sequence() {
  xdmp:log($message, "error")
};

