xquery version "1.0-ml";

module namespace custom-view = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "../interceptor.xqy";
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../response.xqy";
import module namespace config  = "http://xquerrail.com/config"  at "../config.xqy";


declare function custom-view:implements() as xs:QName*
{  (
     xs:QName("interceptor:before-response")
   )
};

declare function custom-view:before-response(
  $request as map:map,
   $response as item()*,
   $configuration as element()?
) {
  let $_ := (
    request:initialize($request),
    response:initialize($response, $request),
    if (fn:exists(request:param("view"))) then
      response:set-view(request:param("view"))
    else
      ()
  )
  return response:response()
};
