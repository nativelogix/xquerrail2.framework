(:@GENERATED@:)
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

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form = "http://xquerrail.com/helper/form" at "../../helpers/form-helper.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";
import module namespace model = "http://xquerrail.com/model" at "../../model.xqy";

declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;
let $init := response:initialize($response)
let $form-type := form:mode("readonly")
return
<div id="show-wrapper">
   <div class="inner-page-title">
      <h2>Show {response:controller()}</h2>
   </div>
   <div id="showbox-container">
      <ul>
        <li><a href="#show-form">HTML</a></li>
        <!--
        <li><a href="#show-xml">XML</a></li>
        <li><a href="#show-json">JSON</a></li>
        -->
      </ul>
      <div id="show-form" class="content-box content-box-header">
        <div class="content-box-wrapper">
            <form name="form_{response:controller()}" method="get" action="/{response:controller()}/edit.html">
               <ul>
                 {form:build-form(response:model(),$response)}
               </ul>
            </form>
         </div>
      </div>
      <!--
      <div id="show-xml" class="content-box content-box-header">
         <div class="content-box-wrapper">
         <h2>XML Format</h2>
            <div style="width:400px">
               <pre class="codemirror">{xdmp:quote(response:body())}</pre>
            </div>
         </div>
      </div>
     <div id="show-json" class="content-box content-box-header">
        <div class="content-box-wrapper">   
             <h2>JSON Format</h2>
             <div style="width:400px">
                <pre>{model:to-json(response:model(),response:body())}</pre>
             </div>
         </div>
      </div>
      -->
   </div>
   
   <script type="text/javascript">
      $("#showbox-container").tabs();
   </script>
</div>