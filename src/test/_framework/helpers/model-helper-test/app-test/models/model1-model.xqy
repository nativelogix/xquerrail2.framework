xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/app-test/models/model1";

import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare function model:model() {
  domain:get-model("model1")
};

declare function model:in-model-reference-test(
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
