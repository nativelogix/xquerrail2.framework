xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/model/extension";

import module namespace base = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";

declare option xdmp:mapping "false";

(:~
 : A modification of model:reference() which as payload rather than
 :  fn:string( field-value( keyLabelField ) )
 : it directly incorporates the key
 : This function will create a sequence of nodes that represent each
 : model for inlining in other references.
 : @param $ids a sequence of ids for models to be extracted
 : @return a sequence of packageType
 :)
declare function model:in-extension-reference-test(
  $context as element(),
  $model as element(domain:model),
  $params as item()*
) as element()? {
  let $name := fn:data($model/@name)
  let $ns := $model/@namespace
  let $qName := fn:QName($ns,$name)
  let $uuid := sem:uuid-string()
  return
    element { $qName } {
      attribute ref-type { "model" },
      attribute ref-uuid { $uuid },
      attribute ref-id   { $uuid },
      attribute ref      { $name },
      attribute reference-test { $name }
    }
};

declare function model:domain-model-validator(
  $model as element(domain:model),
  $params as item()*,
  $mode as xs:string
) as element(validationError)* {
  if ($model/@name = "validate-model4") then
    let $first-name-value := domain:get-field-value(domain:get-model-field($model, "firstName"), $params)
    return
      if ($first-name-value eq "JOHN") then
        ()
      else
        <validationError>
          <element>firstName</element>
          <type>domain-model-validator</type>
          <typeValue>{fn:data($first-name-value)}</typeValue>
          <error>firstName must be JOHN</error>
        </validationError>
  else
    ()
};
