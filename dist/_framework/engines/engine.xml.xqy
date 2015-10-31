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

module namespace xml-engine = "http://xquerrail.com/engine/xml";

import module namespace engine  = "http://xquerrail.com/engine" at "engine.base.xqy";
import module namespace config = "http://xquerrail.com/config" at "../config.xqy";
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../response.xqy";

declare namespace tag = "http://xquerrail.com/tag";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:output "method=xml";

(:~
 : You initialize your variables
 :)
declare variable $REQUEST := map:map() ;
declare variable $RESPONSE := map:map();
declare variable $context := map:map();

(:~
   Initialize  Any custom tags your engine handles so the system can call
   your custom transform functions
 :)
declare variable $custom-engine-tags as xs:QName*:=
(
  fn:QName("xml-engine","to-xml")
);
(:Set your engines custom transformer:)
declare variable $custom-transform-function := (
   xdmp:function(xs:QName("xml-engine:custom-transform"),"engine.json.xqy")
);
declare function xml-engine:is-supported(
  $request,
  $response
) as xs:boolean {
  let $_ := response:initialize($response)
  return (response:format() eq "xml")
};

(:~
 : The Main Controller will call your initialize method
 : and register your engine with the engine.base.xqy
 :)
declare function xml-engine:initialize($request, $response){
(
  let $init :=
  (
       response:initialize($response),
       request:initialize($request),
       xdmp:set($RESPONSE,$response),
       engine:set-engine-transformer($custom-transform-function),
       engine:register-tags($custom-engine-tags)
  )
  return
   xml-engine:render()
)
};


declare function xml-engine:render-xml()
{
  response:body()
};
(:~
  Handle your custom tags in this method or the method you have assigned
  initialized with the base.engine
  It is important that you only handle your custom tags and
  any content that is required to be consumed by your tags
 :)
declare function xml-engine:custom-transform($node as item())
{
  $node
};
(:~
 : The Kernel controller will call your render method.
 : From this point it is up to your engine to handle
 : to initialize any specific response settings and
 : and start the rendering process
 :)
declare function xml-engine:render()
{
  if (fn:empty(response:body()) and fn:empty(response:response-code())) then
    response:set-response-code(404, "Resource not found")
  else (
    (:Set the response content type:)
    if (fn:empty(response:content-type())) then
      response:set-content-type("text/xml")
    else
      (),
    let $view := response:view()
    let $exists := engine:view-exists($view)
    return
      if ($exists) then
        engine:render-view()
      else
        xml-engine:render-xml()
  )
};

