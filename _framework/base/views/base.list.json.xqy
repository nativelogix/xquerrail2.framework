xquery version "1.0-ml";

import module namespace request = "http://xquerrail.com/request"
   at "/_framework/request.xqy";
   
import module namespace response = "http://xquerrail.com/response"
   at "/_framework/response.xqy";
   
import module namespace model = "http://xquerrail.com/helper/model"
   at "/_framework/helpers/model-helper.xqy";

import module namespace domain = "http://xquerrail.com/domain"
   at "/_framework/domain.xqy";

import module namespace js = "http://xquerrail.com/helper/javascript"
   at "/_framework/helpers/javascript-helper.xqy";

declare variable $response as map:map external;

response:initialize($response),
let $node := response:body()
let $model :=  domain:get-domain-model($node/@type)
return
 if($model) then 
    <x>{js:object((       
        js:keyvalue("type",$node/@type cast as xs:string),
        js:keyvalue("elapsed",$node/@elapsed),
        js:keyvalue("currentpage",$node/currentpage cast as xs:integer),
        js:keyvalue("pagesize",$node/pagesize cast as xs:integer),
        js:keyvalue("totalpages",$node/totalpages cast as xs:integer),
        js:keyvalue("totalrecords",$node/totalrecords cast as xs:integer),
        js:entry($node/@type,(
           for $n in $node/*[local-name(.) eq $model/@name]
           return 
               model:to-json($model,$n)
        ))
     ))}</x>/*
 else ()