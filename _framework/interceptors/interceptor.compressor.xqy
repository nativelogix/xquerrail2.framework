xquery version "1.0-ml";

module namespace compressor = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "/_framework/interceptor.xqy";
import module namespace request = "http://xquerrail.com/request" at "/_framework/request.xqy";
import module namespace config  = "http://xquerrail.com/config"  at "/_framework/config.xqy";

   
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
)
{
    request:initialize($request),
    let $context := interceptor:get-context()
    let $scope   := interceptor:get-matching-scopes($configuration)[1]
    let $accept-type := request:get-header("Accept-Encoding")
    let $can-zip := fn:contains($accept-type,"gzip")
   return
     if($can-zip and $scope/config:compress = "true") 
     then  
        let $response-fix := 
            if(request:format() = "json") then text {$response} 
            else if(request:format() = "xml") then $response
            else if(request:format() = "html") then 
                if(fn:count($response) gt 1) then text {$response[1], xdmp:quote($response[2])}
                else $response
            else $response
        let $gzipped := xdmp:gzip($response-fix)
        let $bytes := xdmp:binary-size($gzipped)
        return
          (
            xdmp:add-response-header("Content-Encoding","gzip"),
            (:Add back any missing headers:)
            if(request:format() = "xml") then xdmp:set-response-content-type("text/xml")
            else if(request:format() = "html") then xdmp:set-response-content-type("text/html")
            else (),
            
            $gzipped
          )
        
     else $response
};

