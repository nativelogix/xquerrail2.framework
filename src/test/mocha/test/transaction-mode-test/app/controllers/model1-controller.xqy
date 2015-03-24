xquery version "1.0-ml";
(:~
 : Model #1 Controller
~:)
module namespace controller = "http://xquerrail.com/app-test/controllers/model1";

import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace base-controller = "http://xquerrail.com/controller/base" at "/main/_framework/base/base-controller.xqy";
import module namespace base-model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";

declare function controller:fake-get()
{
  <transaction-mode>{if (fn:exists(xdmp:request-timestamp())) then "query" else "update"}</transaction-mode>
};

declare function controller:fake-delete()
{
  <transaction-mode>{if (fn:exists(xdmp:request-timestamp())) then "query" else "update"}</transaction-mode>
};
