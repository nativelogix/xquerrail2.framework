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

module namespace json-engine = "http://xquerrail.com/engine/json";

import module namespace engine  = "http://xquerrail.com/engine" at "engine.base.xqy";
import module namespace config = "http://xquerrail.com/config" at "../config.xqy";
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../response.xqy";
import module namespace model-helper = "http://xquerrail.com/helper/model" at "../helpers/model-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace js = "http://xquerrail.com/helper/javascript" at "../helpers/javascript-helper.xqy";
import module namespace jsh = "http://xquerrail.com/helper/json" at "../helpers/json-helper.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace tag = "http://xquerrail.com/tag";
declare namespace jso = "json:options";

(:~
 : You initialize your variables
 :)
declare variable $REQUEST := map:map();
declare variable $RESPONSE := map:map();
declare %private variable $CONTEXT := map:map();

(:~
   Initialize  Any custom tags your engine handles so the system can call
   your custom transform functions
 :)
declare variable $custom-engine-tags as xs:QName*:=
  (
    fn:QName("json-engine","to-json")
  );

(:Set your engines custom transformer:)
declare variable $custom-transform-function := xdmp:function(xs:QName("engine:custom-transform"), "engine.json.xqy");

declare function json-engine:is-supported(
  $request,
  $response
) as xs:boolean {
  let $_ := response:initialize($response)
  return (response:format() eq "json")
};

(:~
 : The Main Controller will call your initialize method
 : and register your engine with the engine.base.xqy
 :)
declare function json-engine:initialize($_request,$_response) {
  let $init := (
    response:initialize($_response),
    request:initialize($_request),
    engine:set-engine-transformer($custom-transform-function),
    engine:register-tags($custom-engine-tags)
  )
  return json-engine:render()
};

declare function json-engine:get-view-uri($response) {
  if(response:base()) then
    fn:concat("../base/views/base.",response:action(),".json.xqy")
  else
    fn:concat("/",request:application(),"/views/", request:controller(),"/",request:controller(), ".", response:view(),".json.xqy")
};

declare function json-engine:render-array(
  $model as element(domain:model)*,
  $node
) as json:object {
  json-engine:render-array($model, $node, ())
};

declare function json-engine:render-array(
  $model as element(domain:model)*,
  $node,
  $options as element(jso:options)?
) as json:object {
  let $types := $model/@name ! fn:string(.)
  let $types :=
    if ($types = "_type") then
      fn:error(xs:QName("INVALID-MODEL-NAME"), text{"Model name cannot be '_type'"})
    else
      $types
  return js:object((
    js:keyvalue("_type",
      if (fn:count($types) eq 1) then
        $types
      else
        js:array($types)
    ),
    for $type in $types
    let $model := $model[./@name eq $type]
    return
    js:entry(
      $type,
      js:array(
        for $n in $node/*[./@xsi:type/fn:string() eq $type or fn:local-name() eq $type]
        return model-helper:to-json( $model, $n, fn:false(), $options )
      )
    )
  ))
};

declare function json-engine:render-json(
  $node
) {
  let $is-multiple := xs:boolean(($node/@multi, fn:false())[1])
  let $is-array := xs:boolean(($node/@array, fn:false())[1])
  let $model :=
    if($is-array) then
      (
        domain:get-model-from-instance($node/element()[1]),
        if(domain:model-exists($node/@type/fn:string())) then
          domain:get-model($node/@type/fn:string())
        else ()
      )[1]
    else if(response:model()) then
      response:model()
    else if(domain:model-exists(fn:local-name($node))) then
      domain:get-model(fn:local-name($node))
    else ()
  return
    if($is-array and fn:exists($model)) then
      json-engine:render-array($model, $node)
    (: Multiple allow heterogenous members, groups by name, and emits an array, recursively calling render-json for each :)
    else if($is-multiple) then
      let $types := fn:distinct-values( $node/element() ! ( domain:get-model-name-from-instance(.) ) )
      let $models := domain:get-domain-model($types)
      return json-engine:render-array($models, $node)
    else if(fn:exists($model)) then
      model-helper:to-json($model,$node)
    else (:fn:error(xs:QName("JSON-PROCESSING-ERROR"),"Cannot generate JSON response without model"):)
      jsh:to-json($node)
};

(:~
  Handle your custom tags in this method or the method you have assigned
  initialized with the base.engine
  It is important that you only handle your custom tags and
  any content that is required to be consumed by your tags
 :)
declare function json-engine:custom-transform($node as item())
{
   $node
};

(:~
 : The Kernel controller will call your render method.
 : From this point it is up to your engine
 : to initialize any specific response settings and
 : and start the rendering process
 :)
declare function json-engine:render()
{
  if (fn:empty(response:body()) and fn:empty(response:response-code())) then
    response:set-response-code(404, "Resounce not found")
  else
  (
    (:Set the response content type:)
    if (fn:empty(response:content-type())) then
      response:set-content-type("application/json")
    else
      (),
    let $view-uri := engine:view-uri(response:controller(),(response:view(),response:action())[1],"json",fn:false())
    let $view-uri :=
      if(engine:view-exists($view-uri)) then
        $view-uri
      else
        engine:view-uri(response:controller(),response:view(),"json",fn:false())
    let $view := if($view-uri and engine:view-exists($view-uri)) then engine:render-view() else ()
    return
      if(fn:exists($view)) then
        xdmp:to-json(
          (:if($view instance of json:object or $view instance of json:array) then $view else json:object($view):)
          if($view instance of json:object or $view instance of json:array) then
            $view else json:object($view)
        )
      else
        let $response := json-engine:render-json(response:body())
        return
          if( $response instance of json:object ) then
            xdmp:to-json($response)
          else
            $response
  )
};

