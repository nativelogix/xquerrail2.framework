xquery version "1.0-ml";

import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace js = "http://xquerrail.com/helper/javascript" at "/main/_framework/helpers/javascript-helper.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare variable $response as map:map external;

response:initialize($response),
let $node := response:body()
let $_ := xdmp:log(("response:body", $node))
return
  if($node) then
    <x>{
      js:object((
        js:keyvalue("response",
          js:object((
            js:entry("record",
              xs:string($node/*:info)
            )
          ))
        )
      ))
    }</x>/*
  else ()
