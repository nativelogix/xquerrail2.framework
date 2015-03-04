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
        js:keyvalue("elapsed",fn:string($node/@elapsed)),
        js:keyvalue("processing",xdmp:elapsed-time()),
        js:keyvalue("currentpage",xs:integer($node/currentpage)),
        js:keyvalue("pagesize",xs:integer($node/pagesize)),
        if (fn:exists($node/sort)) then
          js:entry(
            "sort",
            if (fn:count($node/sort/field) = 1) then
              js:object((
                js:keyvalue("field",fn:string($node/sort/field/@name)),
                js:keyvalue("order",fn:string($node/sort/field/@order))
              ))
            else
              js:array((
                for $field in $node/sort/field
                return
                js:object((
                  js:keyvalue("field",fn:string($field/@name)),
                  js:keyvalue("order",fn:string($field/@order))
                ))
              ))
          )
        else
          (),
        js:keyvalue("totalpages",xs:integer($node/totalpages)),
        js:keyvalue("totalrecords",xs:integer($node/totalrecords)),
        engine:render-array($model, $node)
      ))
    }</x>/*
  else
    ()
