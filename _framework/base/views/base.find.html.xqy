xquery version "1.0-ml";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";
declare variable $response as map:map external;

response:initialize($response),
<ul class="nav nav-list">{
  for $f in response:body()//*:find
  return  
     <li>
        <a href="/{response:controller()}/show.html?id={$f/*:key}">{fn:string($f/*:label)}</a>
     </li>
}</ul>
