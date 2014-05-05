xquery version "1.0-ml";
(:~
 : Base Edit Template used for rendering output
 :)
declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace domain = "http://xquerrail.com/domain" at "/_framework/domain.xqy";
import module namespace form = "http://xquerrail.com/helper/form" at "/_framework/helpers/form-helper.xqy";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";

declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

let $init := response:initialize($response)
let $domain-model := response:model()
let $form-mode := form:mode("readonly")
let $id-field := fn:data(response:body()//*[fn:local-name(.) eq domain:get-model-identity-field-name($domain-model)])
return
    <div>
        <div class="content-box">
            <div class="inner-page-title">
                <div class="toolbar"><h2>Details <?title?></h2></div>                
                {form:build-form($domain-model,$response)}
                 <div class="buttons">
                 <button type="button" class="ui-state-default ui-corner-all ui-button" href="#"
                    onclick="window.location.href='/{response:controller()}/index.html';return false;">Back</button> 
                </div>
           </div>
         </div>
    </div>
