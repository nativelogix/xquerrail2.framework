xquery version "1.0-ml";

module namespace test = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "../../../../main/_framework/interceptor.xqy";
import module namespace request = "http://xquerrail.com/request" at "../../../../main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../../../main/_framework/response.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";

declare option xdmp:mapping "false";

declare function test:implements() as xs:QName*
{
   (
     xs:QName("interceptor:after-request"),
     xs:QName("interceptor:before-response")
   )
};

(:~
 : Add something after the request
 :)
declare function test:after-request(
  $request as map:map,
  $configuration as element()?
) {
  (
    request:initialize($request),
    if (fn:exists(request:param("mocha-param-test"))) then
      request:add-param("after-request-test","after-request")
    else
      (),
    request:request()
  )
};

(:~
 : Add something before the response
 :)
declare function test:before-response(
   $request as map:map,
   $response as item()*,
   $configuration as element()?
) {
  let $_ := (
    request:initialize($request),
    response:initialize($response, $request),
    if (fn:exists(request:param("mocha-param-test"))) then
      (
        response:add-header("before-response-test", request:param("mocha-param-test"))
      )
    else
      ()
  )
  return response:response()
};
