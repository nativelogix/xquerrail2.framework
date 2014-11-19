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
  fn:QName("json-engine","to-json")
);
(:Set your engines custom transformer:)
declare variable $custom-transform-function :=
   xdmp:function(
     xs:QName("engine:custom-transform"),
     "engine.json.xqy"
);
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
declare function json-engine:initialize($_request,$_response){
    (
      let $init :=
      (
           response:initialize($_response),
           request:initialize($_request),
           engine:set-engine-transformer($custom-transform-function),
           engine:register-tags($custom-engine-tags)
      )
      return
       json-engine:render()
    )
};

declare function json-engine:get-view-uri($response) {
   if(response:base())
   then fn:concat("../base/views/base.",response:action(),".json.xqy")
   else fn:concat("/",request:application(),"/views/", request:controller(),"/",request:controller(), ".", response:view(),".json.xqy")
};

declare function json-engine:render-search-results($node) {
    js:o((
      js:entry("response",js:o((
            js:kv("page",$node/@page),
            js:kv("snippet_format",$node/@snippet-format),
            js:kv("total",$node/@total),
            js:kv("start",$node/@start),
            js:kv("page_length",$node/@page-length),
            js:entry("results",js:a(
              for $result in $node/search:result
              return
                js:o((
                   js:kv("index",$result/@index),
                   js:kv("uri",$result/@uri),
                   js:kv("path",$result/@start),
                   js:kv("score",$result/@score),
                   js:kv("confidence",$result/@confidence),
                   js:kv("fitness",$result/@fitness),
                   js:entry("metadata",js:o(
                     for $meta in $result/search:metadata/*
                     return
                        js:kv(fn:local-name($meta),fn:data($meta))
                   )),
                   js:entry("snippets",js:a(
                     for $snippet in $result/search:snippet
                     return
                        js:entry("matches",js:a(
                           for $match in $snippet/node()
                           return
                             typeswitch($match)
                               case element(search:match) return
                                  js:o((
                                    js:kv("path",$match/@path),
                                    js:kv("text",$match/text())
                                  ))
                               case text() return $match
                               default return ()
                        ))
                   ))
                ))
             )
         ),
         (:Facets:)
         js:entry("facets",js:a(
            for $facet in $node/search:facet
            return
                js:entry("facet",js:o((
                    js:kv("name",$facet/@name),
                    js:kv("type",$facet/@type),
                    js:entry("values",js:a(
                        for $value in $facet/search:facet-value
                        return js:o((
                            js:kv("name",$value/@name),
                            js:kv("count",$value/@count cast as xs:integer)

                        ))
                    ))
                )))
         )),
         (:QText:)
         js:entry("qtext",js:a(
            for $qtext in $node/search:qtext
            return
              fn:string($qtext)
         )),
         (:QText:)
         js:entry("query",js:a(
            cts:query($node/search:query/node())
         )),
         (:Metrics:)
         js:entry("metrics",js:o(
            $node/search:metrics ! (
                js:kv("query_time",./search:query-resolution-time),
                js:kv("facet_time",./search:facet-resolution-time),
                js:kv("snippet_time",./search:snippet-resolution-time),
                js:kv("metadata_time",./search:metadata-resolution-time),
                js:kv("total_time",./search:total_time)
            )
         ))
      )
    ))
  ))
};
declare function json-engine:render-json($node)
{
   let $is-listable := $node instance of element(list)
   let $is-lookup   := $node instance of element(lookups)
   let $is-searchable := $node instance of element(search:response)
   let $is-suggestable := $node instance of element(s)
   let $model :=
      if(response:model()) then response:model()
      else if($is-listable or $is-lookup)
      then domain:get-domain-model($node/@type)
      else if($is-searchable) then ()
      else if($is-suggestable) then ()
      else if(domain:model-exists(fn:local-name($node))) then domain:get-model(fn:local-name($node))
      else ()
   return
     if($is-listable and $model) then
         xdmp:to-json(js:o((
            js:kv("_type",$node/@type   ),
            js:kv("currentpage",$node/currentpage cast as xs:integer),
            js:kv("pagesize",$node/pagesize cast as xs:integer),
            js:kv("totalpages",$node/totalpages cast as xs:integer),
            js:kv("totalrecords",$node/totalrecords cast as xs:integer),

            js:e($node/@type,js:a(
               for $n in $node/*[fn:local-name(.) = $node/@type]
               return
                   model-helper:to-json($model,$n)
            ))
         )))
     else if($is-lookup) then
         xdmp:to-json( js:o ((
             js:e("lookups", js:a(
             for $n in $node/*:lookup
             return js:o((
                js:kv("key",fn:string($n/*:key)),
                js:kv("label",fn:string($n/*:label))
             ))))
          )))
     else if($is-searchable) then
        json-engine:render-search-results($node)
     else if($is-suggestable) then
        xdmp:to-json(js:o((
            js:e("suggest", js:a($node/* ! fn:string(.)))
        )))
     else if($model) then (
             xdmp:to-json(model-helper:to-json($model,$node))
          )
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
   if(response:redirect())
   then xdmp:redirect-response(response:redirect())
   else
   (
     (:Set the response content type:)
     if(response:content-type())
     then xdmp:set-response-content-type(response:content-type())
     else xdmp:set-response-content-type("application/json"),
     if(response:response-code()) then xdmp:set-response-code(response:response-code()[1], response:response-code()[2])
     else (),
     for $key in map:keys(response:response-headers())
     return xdmp:add-response-header($key,response:response-header($key)),
     let $view-uri := engine:view-uri(response:controller(),(response:action(),response:view())[1],"json",fn:false())
     let $view-uri :=
        if(engine:view-exists($view-uri))
        then $view-uri
        else  engine:view-uri(response:controller(),response:view(),"json",fn:false())
     let $view := if($view-uri and engine:view-exists($view-uri)) then engine:render-view() else ()
     return
        if(fn:exists($view))
        then  xdmp:to-json(if($view instance of json:object or $view instance of json:array) then $view else json:object($view))
        else if(fn:exists(response:body())) then  json-engine:render-json(response:body())
        else ()
   )
};

