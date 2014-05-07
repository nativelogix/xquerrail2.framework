xquery version "1.0-ml";

module namespace base = "http://xquerrail.com/engine";
    
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
declare variable $request := map:map() ;
declare variable $response := map:map();
declare variable $context := map:map();

(:~
   Initialize  Any custom tags your engine handles so the system can call 
   your custom transform functions
 :)
declare variable $custom-engine-tags as xs:QName*:= 
(
  fn:QName("engine","to-json")
);
(:Set your engines custom transformer:)
declare variable $custom-transform-function := 
   xdmp:function(
     xs:QName("engine:custom-transform"),
     "engine.json.xqy"
);
(:~
 : The Main Controller will call your initialize method
 : and register your engine with the engine.base.xqy
 :)
declare function engine:initialize($_response,$_request){ 
    (
      let $init := 
      (
           response:initialize($_response),
           request:initialize($_request),
           engine:set-engine-transformer($custom-transform-function),
           engine:register-tags($custom-engine-tags)
      )
      return
       engine:render()
    )
};

declare function engine:get-view-uri($response) {
   if(response:base()) 
   then fn:concat("../base/views/base.",response:action(),".json.xqy")
   else fn:concat("/",request:application(),"/views/", request:controller(),"/",request:controller(), ".", response:view(),".json.xqy")
};

declare function engine:render-search-results($node) {
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
declare function engine:render-json($node)
{  
   let $is-listable := $node instance of element(list) 
   let $is-lookup   := $node instance of element(lookups)
   let $is-searchable := $node instance of element(search:response)
   let $is-suggestable := $node instance of element(s)
   let $model := 
      if($is-listable or $is-lookup)
      then domain:get-domain-model($node/@type)
      else if($is-searchable) then () 
      else if($is-suggestable) then ()
      else if(domain:model-exists(fn:local-name($node))) then domain:get-model(fn:local-name($node))
      else ()
   let $_ := xdmp:log(($model,"Body:::",xdmp:describe($node)),"debug")
   return
     if($is-listable and $model) then  
         js:o((       
            js:kv("_type",$node/@type cast as xs:integer),
            js:kv("currentpage",$node/currentpage cast as xs:integer),
            js:kv("pagesize",$node/pagesize cast as xs:integer),
            js:kv("totalpages",$node/totalpages cast as xs:integer),
            js:kv("totalrecords",$node/totalrecords cast as xs:integer),
             
            js:e($node/@type,js:a(
               for $n in $node/*:values/*
               return 
                   model-helper:to-json($model,$n)
            ))
         ))
     else if($is-lookup) then
          js:o ((
             js:e("lookups", js:a(
             for $n in $node/*:lookup
             return js:o((
                js:kv("key",fn:string($n/*:key)),
                js:kv("label",fn:string($n/*:label))
             ))))
          ))     
     else if($is-searchable) then 
        engine:render-search-results($node)
     else if($is-suggestable) then 
        json:to-array($node/* ! fn:string(.))
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
declare function engine:custom-transform($node as item())
{  
   $node
};
(:~
 : The Kernel controller will call your render method.
 : From this point it is up to your engine  
 : to initialize any specific response settings and
 : and start the rendering process 
 :)
declare function engine:render()
{
   if(response:redirect()) 
   then xdmp:redirect-response(response:redirect())
   else 
   (
     (:Set the response content type:)
     if(response:content-type())
     then xdmp:set-response-content-type(response:content-type())
     else xdmp:set-response-content-type("application/json"),  
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
        then  xdmp:to-json(if($view instance of json:object) then $view else json:object($view))
        else if(fn:exists(response:body())) then  engine:render-json(response:body())
        else ()
   )
};

