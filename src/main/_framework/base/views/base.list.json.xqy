xquery version "1.0-ml";

import module namespace request = "http://xquerrail.com/request" at "../../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";
import module namespace model-helper = "http://xquerrail.com/helper/model" at "../../helpers/model-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../domain.xqy";
import module namespace js = "http://xquerrail.com/helper/javascript" at "../../helpers/javascript-helper.xqy";
import module namespace engine = "http://xquerrail.com/engine/json" at "../../engines/engine.json.xqy";

declare variable $response as map:map external;

response:initialize($response),
let $node := response:body()
let $model := domain:get-domain-model($node/@type)
return
  if($model) then
    <x>{
      js:object((
        js:keyvalue("elapsed",$node/@elapsed cast as xs:string),
        js:keyvalue("processing",xdmp:elapsed-time()),
        js:keyvalue("currentpage",$node/currentpage cast as xs:integer),
        js:keyvalue("pagesize",$node/pagesize cast as xs:integer),
        if (fn:exists($node/sort/field)) then
          js:entry(
            "sort",
            js:object((
              js:keyvalue("field",$node/sort/field cast as xs:string),
              js:keyvalue("order",$node/sort/order cast as xs:string)
              ))
          )
        else
          (),
        js:keyvalue("totalpages",$node/totalpages cast as xs:integer),
        js:keyvalue("totalrecords",$node/totalrecords cast as xs:integer),
        engine:render-array($model, $node)
      ))
    }</x>/*
  else
    ()
