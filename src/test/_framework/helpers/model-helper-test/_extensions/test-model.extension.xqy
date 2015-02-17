xquery version "1.0-ml";
module namespace model = "http://xquerrail.com/model/extension";

import module namespace base = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-doc-2007-01.xqy";

declare option xdmp:mapping "false";

declare function model:get-field-json-name(
  $field as element()
) as xs:string? {
  let $model := $field/ancestor-or-self::domain:model
  return
    if ($model/@name eq "model6") then
      let $name := fn:string($field/@name)
      let $json-name :=
        fn:string-join(
          (fn:tokenize($name,'-')[1],
          for $word in fn:tokenize($name,'-')[fn:position() > 1]
          return functx:capitalize-first($word))
        ,'')
      return $json-name
    else
      ()
};
