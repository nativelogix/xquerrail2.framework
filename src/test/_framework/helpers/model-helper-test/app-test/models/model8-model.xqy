xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/app-test/models/model8";

import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace js = "http://xquerrail.com/helper/javascript" at "/main/_framework/helpers/javascript-helper.xqy";
import module namespace model-helper = "http://xquerrail.com/helper/model" at "/main/_framework/helpers/model-helper.xqy";

declare option xdmp:mapping "false";

declare function model:model() {
  domain:get-model("model8")
};

declare function model:json-compact(
  $model as element(domain:model),
  $instance as item()
) {
  js:object((
    for $field in $model/(domain:element|domain:attribute)
    return
      if ($field/@name eq "first-name") then
          js:kv(
            "first-name",
            "dummy-first-name"
          )
      else
        model-helper:build-json($field, $instance)
  ))
};
