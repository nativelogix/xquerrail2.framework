xquery version "1.0-ml";

module namespace compressor = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "../interceptor.xqy";
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../response.xqy";
import module namespace config  = "http://xquerrail.com/config"  at "../config.xqy";


declare function compressor:implements() as xs:QName*
{
   (
     xs:QName("interceptor:after-response")
   )
};

declare function compressor:after-response(
  $request,
  $response,
  $configuration as element()
) {
  request:initialize($request),
  let $context := interceptor:get-context()
  let $scope   := interceptor:get-matching-scopes($configuration)[1]
  let $accept-type := request:get-header("Accept-Encoding")
  let $can-zip := (fn:contains($accept-type,"gzip") or fn:contains($accept-type,"*"))
  return
    if($can-zip and $scope/config:compress = "true") then
      (: TODO: Each engine should be responsible to provide $response as node() :)
      let $response-fix :=
        if(request:format() = "json") then text {$response}
        else if(request:format() = "xml") then $response
        else if(request:format() = "html") then
          if(fn:count($response) gt 1) then text {$response[1], xdmp:quote($response[2])}
          else $response
        else $response
      let $gzipped := xdmp:gzip($response-fix)
      return
      (
        response:add-response-header("Content-Encoding","gzip"),
        $gzipped
      )
    else
      $response
};

