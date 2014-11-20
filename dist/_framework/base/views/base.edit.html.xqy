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

import module namespace form     = "http://xquerrail.com/helper/form" at "../../helpers/form-helper.xqy";

import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";

import module namespace domain   = "http://xquerrail.com/domain" at "../../domain.xqy";

declare option xdmp:output "indent-untyped=yes";

declare variable $response as map:map external;

let $init := response:initialize($response)
let $domain-model := response:model()
let $id-field := fn:data(response:body()//*[fn:local-name(.) eq domain:get-model-identity-field-name($domain-model)])
let $form-mode := form:mode("edit") 
let $labels := ("Update","Cancel")
let $actions :=   
    <div class="btn-toolbar form-actions">
        <div class="btn-group">
             <button type="submit" id="save-button" class="btn btn-primary"><b class="icon-ok-sign icon-white"></b> Save</button>
              <button type="button" id="delete-button" class="btn btn-default" onclick="return deleteForm('form_{response:controller()}','{response:controller()}_table');">
              <b class="icon-remove"></b>  Delete
              </button>
              <button type="button" id="cancel-button" class="btn btn-default  " href="#" onclick="window.location.href='/{response:controller()}';">
              <b class="icon-hand-left"></b> Cancel</button>
        </div>
    </div>
return
<div class="box">
  <div class="box-header">
      <h3 class="title"> {$labels[1]}&nbsp;<?title?></h3>
  </div>   
  <div class="box-content">
     <form id="form_{response:controller()}" name="form_{response:controller()}"  class="fill-up form-horizontal" method="post"
                 action="/{response:controller()}/save.html">
       {if($domain-model//domain:element[@type = ("binary","file") or domain:ui/@type eq "fileupload"])
         then attribute enctype{"multipart/form-data"}
         else ()
        }        
        {$actions}
        <div class="row-fluid"> 
            <div class="span8">{form:build-form($domain-model,$response)} <div class="clearfix"></div>
            </div>
           </div>
           <div class="form-actions"> 
                <button type="submit" id="save-button" class="btn btn-primary" href="#"><b class="icon-ok-sign icon-white"></b> Save</button> 
            </div>
       </form>
   </div>
   <script type="text/javascript"> 
    {form:context($response)}
    </script>
</div>
