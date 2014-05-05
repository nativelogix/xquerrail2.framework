xquery version "1.0-ml";
declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace domain = "http://xquerrail.com/domain";

import module namespace form = "http://xquerrail.com/helper/form" at "/_framework/helpers/form-helper.xqy";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";

declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

let $init := response:initialize($response)
let $mode := (response:get-data("form-mode"),"edit")[1]
let $_ := form:mode($mode)
let $domain-model := response:model()
return
    <div class="controls">{
        form:build-form($domain-model,$response)
    }</div>
