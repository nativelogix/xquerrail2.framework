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

import module namespace request = "http://xquerrail.com/request" at "../../request.xqy";
   
import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";
   
import module namespace model = "http://xquerrail.com/helper/model" at "../../helpers/model-helper.xqy";

import module namespace domain = "http://xquerrail.com/domain" at "../../domain.xqy";

import module namespace js = "http://xquerrail.com/helper/javascript" at "../../helpers/javascript-helper.xqy";

declare variable $response as map:map external;

response:initialize($response),
let $node := response:body()
let $model :=  domain:get-domain-model($node/@type)
let $result := for $n in $node/*[local-name(.) eq $model/@name]
return 
   model:to-json($model,$n)
return
 if($model) then 
    <x>{js:object((       
        js:keyvalue("type",$node/@type cast as xs:string),
        js:keyvalue("elapsed",fn:string($node/@elapsed)),
        js:keyvalue("processing",xdmp:elapsed-time()),
        js:keyvalue("currentpage",$node/currentpage cast as xs:integer),
        js:keyvalue("pagesize",$node/pagesize cast as xs:integer),
        js:keyvalue("totalpages",$node/totalpages cast as xs:integer),
        js:keyvalue("totalrecords",$node/totalrecords cast as xs:integer),
        js:entry($node/@type,js:a(
        $result
        ))
     ))}</x>/*
 else ()