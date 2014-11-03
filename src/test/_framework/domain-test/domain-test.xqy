
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../main/_framework/domain.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/domain-test/_config</config>
</application>
;

declare variable $CONFIG := ();

declare %test:teardown function teardown() as empty-sequence()
{
(:  setup:teardown():)
  ()
};

declare %test:before-each function before-test() {
  (app:reset(), app:bootstrap($TEST-APPLICATION))
};

declare %test:case function get-model-model1-test() as item()*
{
  assert:not-empty(domain:get-model("model1"))
};

declare %test:case function get-model-identity-field-name-test() as item()*
{
  let $model1 := domain:get-model("model1")
  return
  assert:equal(domain:get-model-identity-field-name($model1), "uuid")
};

declare %test:case function app-get-setting-test() as item()*
{
  (
    assert:equal(xs:string(app:get-setting("key1")), "value2"),
    assert:equal(fn:count(app:get-setting("key2")/items/item), 2),
    assert:equal(fn:data(app:get-setting("key2")/items/item[1]), 123)
  )
};

declare %test:case function get-model-field-test() as item()* {
  let $model1 := domain:get-model("model1")
  let $field := $model1/domain:element[./@name/fn:string() eq "name"]
  let $_ := xdmp:log(("$model1", $model1, "$field", $field))
  let $field-name := "name"
  let $field-key-id := domain:get-field-id($field)
  let $fiel-key-name := domain:get-field-name-key($field)
  return (
    assert:equal(domain:get-model-field($model1, $field-name), $field),
    assert:equal(domain:get-model-field($model1, $field-key-id), $field),
    assert:equal(domain:get-model-field($model1, $fiel-key-name), $field)
  )
};

declare %test:case function model-element-order-test() as item()* {
  let $model2 := domain:get-model("model2")
  (: model3 has sortValue attributes :)
  let $model3 := domain:get-model("model3")
  let $model2-field-names := $model2/domain:element/@name/fn:string()
  let $model3-field-names := $model3/domain:element/@name/fn:string()

  let $model3-ordered-field-names :=
      for $field in $model3/domain:element
      order by $field/@sortValue/fn:number()
      return $field/@name/fn:string()

  let $same-length := fn:count($model2-field-names) eq fn:count($model3-field-names)
  let $same-values :=
      some $model2-field-name in $model2-field-names
      satisfies
        $model2-field-name = $model3-field-names
  let $order-different :=
      some $model2-field-name in $model2-field-names
      satisfies
        fn:index-of($model2-field-names, $model2-field-name) ne fn:index-of($model3-field-names, $model2-field-name)
  let $order-correct :=
      every $model3-field-name in $model3-field-names
      satisfies
        fn:index-of($model3-field-names, $model3-field-name) eq fn:index-of($model3-ordered-field-names, $model3-field-name)
  return (
    assert:true($same-length, "Models have different field lengths"),
    assert:true($same-values, "Models have different field values"),
    assert:true($order-different, ("Sort value didn't change order. data:" || fn:string-join($model3-field-names,', '))),
    assert:true($order-correct, "Model fields aren't in correct order")
  )
};
