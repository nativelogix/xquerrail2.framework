xquery version "1.0-ml";

module namespace extension = "http://xquerrail.com/controller/extension";

import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace domain = "http://xquerrail.com/domain"  at "/main/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/controller/base" at "/main/_framework/base/base-controller.xqy";

declare option xdmp:mapping "false";

(:~
 : Here is the initialize function invoked by dispatcher before any other custom functions
~:)
declare function extension:initialize(
  $request as map:map?
) as empty-sequence() {
  base:initialize($request)
};

(:~
 : Implementation of a custom function
~:)
declare function extension:delete-all() {
  let $model := base:model()
  return
    if ($model/@persistence eq "directory") then
      xdmp:directory-delete($model/domain:directory)
    else
      ()
};
