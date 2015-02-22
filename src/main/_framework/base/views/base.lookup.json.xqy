xquery version "1.0-ml";

import module namespace request = "http://xquerrail.com/request" at "../../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";
import module namespace model-helper = "http://xquerrail.com/helper/model" at "../../helpers/model-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../domain.xqy";
import module namespace js = "http://xquerrail.com/helper/javascript" at "../../helpers/javascript-helper.xqy";

declare variable $response as map:map external;

response:initialize($response),
let $node := response:body()
let $model := domain:get-domain-model($node/@type)
return
  if($model) then
    <x>{
      js:object((
        js:keyvalue("_type",$node/@type cast as xs:string),
        js:entry("lookups", js:array(
        for $n in $node/*:lookup
        return js:object((
          js:keyvalue("key",fn:string($n/*:key)),
          js:keyvalue("label",fn:string($n/*:label))
        ))))
      ))
    }</x>/*
  else
    ()
