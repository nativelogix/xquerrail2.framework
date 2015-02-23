xquery version "1.0-ml";

module namespace events = "http://xquerrail.com/app-test/events";

import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare function events:before-create-1(
  $event,
  $context as item()
) {
  let $model := $event/ancestor::domain:model
  let $instance :=
    if (domain:get-value-type($context) eq "xml") then
      model:convert-to-map($model, $context)
    else
      $context
  let $_ := map:put($instance, "firstName", "john")
  return $instance
};

declare function events:before-create-2(
  $event,
  $context as item()
) {
  let $model := $event/ancestor::domain:model
  let $instance :=
    if (domain:get-value-type($context) eq "xml") then
      model:convert-to-map($model, $context)
    else
      $context
  let $_ := map:put($instance, "lastName", "doe")
  return $instance
};

declare function events:validate-constraint(
  $event,
  $context as item()
) {
  let $model := $event/ancestor::domain:model
  let $unique-constraints := domain:get-model-unique-constraint-fields($model)
  let $unique-search := domain:get-model-unique-constraint-query($model, $context, $event/@name)
  return
    if(fn:exists($unique-search)) then
      let $validation-errors :=
      <validationErrors>
      {
        for $v in $unique-constraints
        let $param-value := domain:get-field-value($v,$context)
        let $param-value := if($param-value) then $param-value else $v/@default
        return
        <validationError>
            <type>Unique Constraint</type>
            <error>Instance is not unique.Field:{fn:data($v/@name)} Value:{$param-value}</error>
        </validationError>
      }
      </validationErrors>
      return fn:error(xs:QName("MODEL-VALIDATION-UNIQUE-CONSTRAINT-ERROR"), text{"Unique constraint error for model", $model/@name}, $validation-errors)
    else
      $context
};

