(:@GENERATED@:)
xquery version "1.0-ml";

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form = "http://xquerrail.com/helper/form" at "/_framework/helpers/form-helper.xqy";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";
import module namespace model = "http://xquerrail.com/model" at "/_framework/model.xqy";

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