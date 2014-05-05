xquery version "1.0-ml";

module namespace test = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "/_framework/interceptor.xqy";
import module namespace request  = "http://xquerrail.com/request" at "/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";
import module namespace config   = "http://xquerrail.com/config"  at "/_framework/config.xqy";

declare function test:implements() as xs:QName*
{   
   (
     xs:QName("interceptor:after-response"),
     xs:QName("interceptor:before-response"),
     xs:QName("interceptor:before-request"),
     xs:QName("interceptor:after-request")
   )
};

(:~
 : Add something before the response
 :)
declare function test:before-request(
  $configuration as element()?
)  as map:map {
  prof:enable(xdmp:request()),
  request:add-param("test-before-request","before-request"),
  request:request()
};

(:~
 : Add something before the response
 :)
declare function test:after-request(
  $request as map:map,
  $configuration as element()?
) {(
   request:add-param("test-after-request","after-request"),
   $request
)};

(:~
 : Add something before the response
 :)
declare function test:before-response(
  $request as map:map,
  $response as item(),
  $configuration as element()?
) as item()* {
   let $_ := (
       xdmp:log(("after-request::",request:param("test-before-response"))),
       xdmp:log(("after-request::",request:param("test-after-response"))),
        if($response instance of map:map)
       then map:put($response,"profile:report",prof:report(xdmp:request()))
       else ()
   )
   return
   $response
};
(:~
 : 
 :)
declare function test:after-response(
   $request as map:map,
   $response as item()*,
   $configuration as element()?
) 
{
  (: let $init := request:initialize($request)
   let $enabled := request:param("_profile") = "true"
   return
     if($enabled) then prof:report(xdmp:request())
     else $response
  
   format-report(prof:report(xdmp:request())) :)
   $response
};


declare function test:format-report($report){
    <prof:report>
    {
        $report/prof:metadata,
        <prof:histogram>{
           (for $expr in $report/prof:histogram/prof:expression
            order by $expr/prof:shallow-time descending
            return
             $expr
           )[1 to 20] 
        }</prof:histogram>
    }
    </prof:report>
};
