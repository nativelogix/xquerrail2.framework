xquery version "1.0-ml";

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form     = "http://xquerrail.com/helper/form" at "/main/_framework/helpers/form-helper.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace domain   = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";

declare option xdmp:mapping "false";
declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

let $init := response:initialize($response)
let $model := response:model()
let $instance := response:body()
let $field := domain:get-model-field($model, response:context())
let $value := domain:get-field-value($field, $instance)
let $label := $field/@label/fn:data()
return
  <div class="form-group">
    <label class="col-md-3 control-label">CUSTOM-TEMPLATE-FOR-MODEL3-NAME</label>
    <div class="col-md-9">
      <input type="text" value="{$value}"/>
    </div>
  </div>
