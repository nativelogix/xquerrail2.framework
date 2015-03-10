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
(:~
 : Base Edit Template used for rendering output
 :)
declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace domain = "http://xquerrail.com/domain" at "../../domain.xqy";
import module namespace form = "http://xquerrail.com/helper/form" at "../../helpers/form-helper.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";

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
