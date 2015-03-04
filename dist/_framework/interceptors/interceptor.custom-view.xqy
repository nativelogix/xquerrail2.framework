xquery version "1.0-ml";
(:~ 

Copyright 2011 - NativeLogix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.




 :)

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
