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
let $form-mode := form:mode("new")
let $id-field := domain:get-model-identity-field($domain-model)
let $id-field-value := domain:get-field-value($id-field,response:body())
let $labels := 
    if(response:body()/*:uuid) then      
        ("Update","Save")
    else 
        ("New", "Create") 
return
  <div class="box">
    <h3 class="title"> {$labels[1]}&nbsp;<?title?></h3>
    <div class="box-content">
      <form id="form_{response:controller()}" name="form_{response:controller()}" class="fill-up form-horizontal" method="post" action="/{response:controller()}/save.html">
        {if($domain-model//domain:element[@type = ("binary","file") or domain:ui/@type eq "fileupload"])
          then attribute enctype{"multipart/form-data"}
          else ()
         } 
        <div class="row-fluid"> 
            <div class="span8">{form:build-form($domain-model,$response)}</div>
        </div>
        <div class="form-actions"> 
                <button type="submit" class="btn btn-primary" href="#">{$labels[2]}
                </button>
                <button type="button" class="btn btn-default" href="#" onclick="window.location.href='/{response:controller()}/index.html';return false;">Cancel</button> 
        </div>
      </form>
      <script type="text/javascript"> 
        {form:context($response)}
      </script>
     </div>
  </div>