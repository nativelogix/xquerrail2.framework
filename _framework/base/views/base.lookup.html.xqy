xquery version "1.0-ml";
(:~
 : Base Edit Template used for rendering output
 :)
declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form     = "http://xquerrail.com/helper/form" at "/_framework/helpers/form-helper.xqy";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";
import module namespace domain   = "http://xquerrail.com/domain" at "/_framework/domain.xqy";

declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

let $init := response:initialize($response)
return
 <ul>
 {for $lookup in response:body()//lookup
  return <li>{$lookup}</li>
 }
 </ul>