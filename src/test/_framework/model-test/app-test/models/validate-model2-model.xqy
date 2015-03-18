xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/app-test/models/validate-model2";

import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare function model:model() {
  domain:get-model("validate-model2")
};

declare function model:custom-validator(
  $field as element(),
  $params as item()*,
  $mode as xs:string
) as element(validationError)* {
  let $field-name := fn:data($field/@name)
  let $field-value := domain:get-field-value($field,$params)
  return
    if (fn:empty($field-value) or $field-value = "2000-01-01") then
      ()
    else
      <validationError>
        <element>{$field-name}</element>
        <type>custom-validator</type>
        <typeValue>{fn:data($field-value)}</typeValue>
        <error>Custom validator only valid when value is 2000-01-01.</error>
      </validationError>
};
