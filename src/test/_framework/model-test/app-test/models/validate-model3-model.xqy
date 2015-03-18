xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/app-test/models/validate-model3";

import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare function model:model() {
  domain:get-model("validate-model3")
};

declare function model:model-validator(
  $model as element(domain:model),
  $params as item()*,
  $mode as xs:string
) as element(validationError)* {
  let $first-name-value := domain:get-field-value(domain:get-model-field($model, "firstName"), $params)
  let $last-name-value := domain:get-field-value(domain:get-model-field($model, "lastName"), $params)
  return
    if ($first-name-value = "gary" or $last-name-value = "doe") then
      ()
    else
      <validationError>
        <element>firstName lastName</element>
        <type>model-validator</type>
        <typeValue>{fn:data($first-name-value)} {fn:data($last-name-value)}</typeValue>
        <error>firstName must be gary or lastName must be doe</error>
      </validationError>
};
