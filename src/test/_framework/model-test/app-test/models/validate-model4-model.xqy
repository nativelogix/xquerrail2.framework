xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/app-test/models/validate-model4";

import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare function model:model() {
  domain:get-model("validate-model4")
};

declare function model:base-model-validator(
  $model as element(domain:model),
  $params as item()*,
  $mode as xs:string
) as element(validationError)* {
  let $age-value := domain:get-field-value(domain:get-model-field($model, "age"), $params)
  return
    if (fn:data($age-value) > 20) then
      ()
    else
      <validationError>
        <element>age</element>
        <type>base-model-validator</type>
        <typeValue>{fn:data($age-value)}</typeValue>
        <error>age must be greater than 20</error>
      </validationError>
};

declare function model:model-validator(
  $model as element(domain:model),
  $params as item()*,
  $mode as xs:string
) as element(validationError)* {
  let $last-name-value := domain:get-field-value(domain:get-model-field($model, "lastName"), $params)
  return
    if ($last-name-value eq "doe") then
      ()
    else
      <validationError>
        <element>lastName</element>
        <type>model-validator</type>
        <typeValue>{fn:data($last-name-value)}</typeValue>
        <error>lastName must be doe</error>
      </validationError>
};
