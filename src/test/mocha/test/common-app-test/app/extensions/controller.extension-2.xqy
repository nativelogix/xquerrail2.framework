xquery version "1.0-ml";

module namespace extension = "http://xquerrail.com/controller/extension";

import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace domain = "http://xquerrail.com/domain"  at "/main/_framework/domain.xqy";

declare option xdmp:mapping "false";

(:~
 : Here is the initialize function invoked by dispatcher before any other custom functions
~:)
declare function extension:initialize(
  $request as map:map?
) as empty-sequence() {
  ()
};

(:~
 : Implementation of a custom function
~:)
declare function extension:custom-action-2() {
  <response>Custom action #2 - {request:param("name")}</response>
};
