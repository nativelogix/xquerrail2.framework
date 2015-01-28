
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

declare %test:setup function setup() {
  (app:reset(), app:bootstrap($TEST-APPLICATION))[0]
};

declare %test:teardown function teardown() as empty-sequence()
{
  ()
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

declare %test:case function model-inheritance-one-level-test() as item()* {
  let $model4 := domain:get-model("model4")
  let $field := domain:get-model-field($model4, "id")
  return (
    assert:not-empty($model4),
    assert:not-empty($field),
    assert:equal($field/@type/fn:string(), "string", "Field id type must be string"),
    assert:equal(fn:count($field), 1, "Field id must be unique")
  )
};

declare %test:case function model-inheritance-two-level-test() as item()* {
  let $model5 := domain:get-model("model5")
  let $field-id := domain:get-model-field($model5, "id")
  let $field-content := domain:get-model-field($model5, "content")
  return (
    assert:not-empty($model5),
    assert:not-empty($field-id),
    assert:equal($field-id/@type/fn:string(), "string", "Field id type must be string"),
    assert:equal(fn:count($field-id), 1, "Field id must be unique"),
    assert:not-empty($field-content),
    assert:equal($field-content/@type/fn:string(), "schema-element", "Field content type must be schema-element"),
    assert:equal(fn:count($field-content), 1, "Field id must be unique")
  )
};

declare %test:case function model-inheritance-default-value-test() as item()* {
  let $model5 := domain:get-model("model5")
  let $field-type := domain:get-model-field($model5, "type")
  return (
    assert:not-empty($model5),
    assert:not-empty($field-type),
    assert:equal($field-type/@default/fn:string(), "table", "Field Type Default must be table"),
    assert:equal(fn:count($field-type), 1, "Field type must be unique")
  )
};

declare %test:case function model-profiles-navigation-test() as item()* {
  let $model5 := domain:get-model("model5")
  let $navigation := $model5/domain:navigation
  return (
    assert:not-empty($model5, "$model5 should not be empty"),
    assert:not-empty($navigation, "$navigation should not be empty"),
    assert:equal($navigation/@searchable/fn:string(), "true", "navigation/@searchable is true"),
    assert:equal($navigation/@searchType/fn:string(), "value", "navigation/@searchType equal searchType"),
    assert:equal(fn:count($navigation/node()), 6, "navigation should have 6 child nodes")
  )
};

declare %test:case function model-profiles-permission-test() as item()* {
  let $model6 := domain:get-model("model6")
  let $permission := $model6/domain:permission
  return (
    assert:not-empty($model6, "$model6 should not be empty"),
    assert:not-empty($permission, "$permission should not be empty"),
    assert:equal($permission/@role/fn:string(), "anonymous", "$permission/@role equal anonymous"),
    assert:equal($permission/@update/fn:string(), "true", "$permission/@update is true"),
    assert:equal($permission/@insert/fn:string(), "false", "$permission/@insert is false")
  )
};

declare %test:case function abstract-model-profiles-permission-test() as item()* {
  let $abstract1-model := domain:get-model("abstract1")
  let $permission := $abstract1-model/domain:permission
  return (
    assert:not-empty($abstract1-model, "$abstract1-model should not be empty"),
    assert:not-empty($permission, "$permission should not be empty"),
    assert:equal($permission/@role/fn:string(), "anonymous", "$permission/@role equal anonymous"),
    assert:equal($permission/@update/fn:string(), "true", "$permission/@update is true"),
    assert:equal($permission/@insert/fn:string(), "false", "$permission/@insert is false")
  )
};

declare %test:case function model-inheritance-profiles-permission-test() as item()* {
  let $model5 := domain:get-model("model5")
  let $permission := $model5/domain:permission
  return (
    assert:not-empty($model5, "$model5 should not be empty"),
    assert:not-empty($permission, "$permission should not be empty"),
    assert:equal($permission/@role/fn:string(), "anonymous", "$permission/@role equal anonymous"),
    assert:equal($permission/@update/fn:string(), "true", "$permission/@update is true"),
    assert:equal($permission/@insert/fn:string(), "false", "$permission/@insert is false")
  )
};

declare %test:case function model-profiles-multi-navigation-test() as item()* {
  let $model6 := domain:get-model("model6")
  let $navigation := $model6/domain:element[@name = "type"]/domain:navigation
  return (
    assert:not-empty($model6, "$model6 should not be empty"),
    assert:not-empty($navigation, "$navigation should not be empty"),
    assert:equal(fn:count($navigation/*), 9, "fn:count($navigation/*) should be 9"),
    assert:equal($navigation/@facetable/fn:string(), "true", "$navigation/@facetable is true")
  )
};

declare %test:case function model-multi-navigations-with-profile-test() as item()* {
  let $model6 := domain:get-model("model6")
  let $navigation := $model6/domain:element[@name = "description"]/domain:navigation
  return (
    assert:not-empty($model6, "$model6 should not be empty"),
    assert:equal(fn:count($navigation), 2, "description element should have 2 navigation elements"),
    assert:not-empty($navigation[@constraintName = "description-word"], "description element should have a navigation element with @constraintName = description-word"),
    assert:not-empty($navigation[@constraintName = "description-value"], "description element should have a navigation element with @constraintName = description-value"),
    assert:equal($navigation[@constraintName = "description-word"]/@sortable/fn:data(), "true", "navigation element with @constraintName = description-word should have @sortable = true"),
    assert:equal($navigation[@constraintName = "description-value"]/@sortable/fn:data(), "false", "navigation element with @constraintName = description-value should have @sortable = false"),
    assert:equal($navigation[@constraintName = "description-word"]/@searchType/fn:data(), "word", "navigation element with @constraintName = description-word should have @searchType = word"),
    assert:equal($navigation[@constraintName = "description-value"]/@searchType/fn:data(), "value", "navigation element with @constraintName = description-value should have @searchType = value"),
    assert:equal(fn:count($navigation[@constraintName = "description-word"]/*), 6, "navigation element with @constraintName = description-word should have 6 child nodes"),
    assert:equal(fn:count($navigation[@constraintName = "description-value"]/*), 3, "navigation element with @constraintName = description-value should have 6 child nodes")
  )
};

declare %test:case function model-with-attribute-with-namespace-test() as item()* {
  let $model4 := domain:get-model("model4")
  let $attribute1-field-namespace := domain:get-field-namespace($model4/domain:attribute[@name = "attribute1"])
  let $id-field-namespace := domain:get-field-namespace($model4/domain:attribute[@name = "id"])
  return (
    assert:not-empty($model4, "$model4 should not be empty"),
    assert:not-empty($attribute1-field-namespace, "$attribute1-field-namespace should not be empty"),
    assert:equal($attribute1-field-namespace, "http://xquerrail.com/app-test", "$attribute1-field-namespace should be equal to http://xquerrail.com/app-test"),
    assert:empty($id-field-namespace, "$id-field-namespace should be empty")
  )
};

declare %test:case function find-model-by-name-test() as item()*
{
  assert:equal(fn:count(domain:get-model("author")), 1)
};

declare %test:case function get-param-value-map-multi-test() as item()*
{
  let $values := ("banana", "orange")
  return
    assert:equal(domain:get-param-value(map:entry("fruits", $values), "fruits"), $values)
};

declare %test:case function get-param-value-json-key-value-test() as item()*
{
  let $value := "banana"
  let $json-object := xdmp:from-json('{"fruit": "banana"}')
  return
    assert:equal(xs:string(domain:get-param-value($json-object, "fruit")), $value)
};

declare %test:case function get-param-value-json-multi-test() as item()*
{
  let $values := ("banana", "orange")
  let $json-array := xdmp:from-json('{"fruits": ["banana", "orange"]}')
  return
    assert:equal(domain:get-param-value($json-array, "fruits"), $values)
};

declare %test:case function get-param-value-xml-multi-test() as item()*
{
  let $values := ("banana", "orange")
  let $xml :=
    <fruits>
    {$values ! (
      <fruit>{.}</fruit>
    )}
    </fruits>
  return
    assert:equal(domain:get-param-value($xml, "fruit")/fn:string(), $values)
};
