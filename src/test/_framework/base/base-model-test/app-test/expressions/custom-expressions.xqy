xquery version "1.0-ml";

module namespace expression = "http://xquerrail.com/expression/custom";

import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare function expression:custom-expression(
  $field as element(),
  $params as item()*,
  $value as item()
) {
  fn:concat($field/@model, '-', fn:string($value))
};

declare function expression:link-to(
  $field as element(),
  $params as item()*,
  $value as item()
) {
  let $model := domain:get-model($field/@model)
  return
    if (fn:exists($model) and xs:boolean($model/domain:navigation/@triplable)) then
      let $linked-instance := model:get($model, $value)
      let $uuid := sem:triple-object(sem:triple($linked-instance/sem:triples/sem:triple[@name eq $model:HAS-URI-PREDICATE]))
      return
        if (fn:exists($uuid)) then
          $uuid
        else
          fn:error(xs:QName("LINK-TO-ERROR"), text{"Could not find hasUri triple for", $model/@name, $value})
    else
      fn:error(xs:QName("LINK-TO-ERROR"))
};
