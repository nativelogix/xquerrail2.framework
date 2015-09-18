
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "/test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace xdmp-api = "http://xquerrail.com/xdmp/api" at "/main/_framework/lib/xdmp-api.xqy";

declare namespace app-test = "http://xquerrail.com/app-test";

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

declare %test:case function extended-model-two-level-test() as item()* {
  let $model := domain:get-model("floating-abstract-model")
  let $field-id := domain:get-model-field($model, "id")
  let $field-name := domain:get-model-field($model, "name")
  let $field-label := domain:get-model-field($model, "label")
  let $field-caption := domain:get-model-field($model, "caption")
  return (
    assert:not-empty($model),
    assert:not-empty($field-id, "floating-abstract-model model must contains id field"),
    assert:empty($field-id/@prefix, "field id/@prefix should not exist"),
    assert:empty($field-id/@namespace, "field id/@namespace should not exist"),
    assert:not-empty($field-name, "floating-abstract-model model must contains name field"),
    assert:equal(fn:string($field-name/@prefix), "app-test", "field name/@prefix must equal to app-test"),
    assert:equal(fn:string($field-name/@namespace), "http://xquerrail.com/app-test", "field name/@namespace must equal to exist"),
    assert:not-empty($field-label, "floating-abstract-model model must contains label field"),
    assert:not-empty($field-caption, "floating-abstract-model model must contains caption field")
  )
};

declare %test:case function model-inherit-application-namespace-test() as item()* {
  let $model7 := domain:get-model("model7")
  let $author-model := domain:get-model("author")
  return (
    assert:not-empty($author-model),
    assert:equal(fn:string($author-model/@namespace), "http://xquerrail.com/app-test", "author-model/@namespace must equal to 'http://xquerrail.com/app-test'"),
    assert:not-empty($model7),
    assert:empty($model7/@namespace, "model7/@namespace must be empty")
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
  let $json-object := xdmp-api:from-json('{"fruit": "banana"}')
  return
    assert:equal(xs:string(domain:get-param-value($json-object, "fruit")), $value)
};

declare %test:case function get-param-value-json-multi-test() as item()*
{
  let $values := ("banana", "orange")
  let $json-array := xdmp-api:from-json('{"fruits": ["banana", "orange"]}')
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

declare %test:case function get-param-value-map-dotted-notation-test() as item()*
{
  let $citrus := ("lemon", "orange")
  let $berries := ("strawberry", "raspberry", "blueberry")
  let $params := map:new((
    map:entry(
      "fruits",
      map:new((
        map:entry("citrus", $citrus),
        map:entry("berry", $berries)
      ))
    )
  ))
  return (
    assert:equal(domain:get-param-value($params, "fruits.citrus"), $citrus, "'fruits.citrus' must equal " || fn:string-join($citrus, ",")),
    assert:equal(domain:get-param-value($params, "fruits.berry")[2], $berries[2], "'fruits.berry[2]' must equal " || $berries[2]),
    assert:equal(domain:get-param-value($params, "fruits.apple", "pink lady"), "pink lady", "'fruits.apple' must equal 'pink lady'")
  )
};

declare %test:case function get-param-value-map-array-dotted-notation-test() as item()*
{
  let $params := map:new((
    map:entry(
      "sort",
      (
        map:new((
          map:entry("field", "field1"),
          map:entry("order", "descending")
        )),
        map:new((
          map:entry("field", "field2"),
          map:entry("order", "ascending")
        ))
      )
    )
  ))
  let $sort := domain:get-param-value($params, "sort")
  let $field := domain:get-param-value($sort[1], "field")
  return (
    assert:equal($field, "field1","sort.field[1] must equal 'field1")
  )
};

declare %test:case function get-param-value-json-dotted-notation-test() as item()*
{
  let $citrus := ("lemon", "orange")
  let $berries := ("strawberry", "raspberry", "blueberry")
  let $params1 := xdmp-api:from-json('{"fruits": {"citrus": ["lemon", "orange"], "berry": ["strawberry", "raspberry", "blueberry"]}}')
  return (
    assert:equal(domain:get-param-value($params1, "fruits.citrus"), $citrus, "'fruits.citrus' must equal " || fn:string-join($citrus, ",")),
    assert:equal(domain:get-param-value($params1, "fruits.berry")[2], $berries[2], "'fruits.berry[2]' must equal " || $berries[2]),
    assert:equal(domain:get-param-value($params1, "fruits.apple", "pink lady"), "pink lady", "'fruits.apple' must equal 'pink lady'")
  )
};

declare %test:case function get-param-value-json-array-dotted-notation-test() as item()*
{
  let $params2 := xdmp-api:from-json('{"sort": [{"field": "field1", "order": "descending"}, {"field": "field2", "order": "ascending"}]}')
  let $sort := domain:get-param-value($params2, "sort")
  let $field := domain:get-param-value($sort[1], "field")
  return (
    assert:equal($field, "field1","sort.field[1] must equal 'field1")
  )
};

declare %test:case function get-param-value-xml-dotted-notation-test() as item()*
{
  let $citrus := ("lemon", "orange")
  let $berries := ("strawberry", "raspberry", "blueberry")
  let $params1 :=
    <fruits>
    { $citrus ! (<citrus>{.}</citrus>) }
    { $berries ! (<berry>{.}</berry>) }
    </fruits>
  let $params2 :=
  <xml>
    <fruits>
    { $citrus ! (<citrus>{.}</citrus>) }
    { $berries ! (<berry>{.}</berry>) }
    </fruits>
  </xml>
  return (
    assert:equal(domain:get-param-value($params1, "fruits.citrus") ! fn:string(.), $citrus, "'fruits.citrus' must equal " || fn:string-join($citrus, ",")),
    assert:equal(fn:string(domain:get-param-value($params1, "fruits.berry")[2]), $berries[2], "'fruits.berry[2]' must equal " || $berries[2]),
    assert:equal(domain:get-param-value($params1, "fruits.apple", "pink lady"), "pink lady", "'fruits.apple' must equal 'pink lady'"),
    assert:equal(domain:get-param-value($params2, "fruits.citrus") ! fn:string(.), $citrus, "'fruits.citrus' must equal " || fn:string-join($citrus, ",")),
    assert:equal(fn:string(domain:get-param-value($params2, "fruits.berry")[2]), $berries[2], "'fruits.berry[2]' must equal " || $berries[2]),
    assert:equal(domain:get-param-value($params2, "fruits.apple", "pink lady"), "pink lady", "'fruits.apple' must equal 'pink lady'")
  )
};

declare %test:case function field-xml-exists-test() as item()* {
  let $model := domain:get-model("model4")
  let $instance :=
    <model4 id="" xmlns="http://xquerrail.com/app-test">
      <title>Title</title>
      <content/>
    </model4>

  let $id-exists := domain:field-xml-exists(
    domain:get-model-field($model, "id"),
    $instance
  )
  let $content-exists := domain:field-xml-exists(
    domain:get-model-field($model, "content"),
    $instance
  )
  let $title-exists := domain:field-xml-exists(
    domain:get-model-field($model, "title"),
    $instance
  )
  let $type-exists := domain:field-xml-exists(
    domain:get-model-field($model, "type"),
    $instance
  )
  return (
    assert:true($id-exists),
    assert:true($content-exists),
    assert:true($title-exists),
    assert:false($type-exists)
  )
};

declare %test:case function field-json-exists-test() as item()* {
  let $model := domain:get-model("model4")
  let $instance := xdmp-api:from-json('{"@id": "", "title": "Title", "content": null}')
  let $id-exists := domain:field-json-exists(
    domain:get-model-field($model, "id"),
    $instance
  )
  let $content-exists := domain:field-json-exists(
    domain:get-model-field($model, "content"),
    $instance
  )
  let $title-exists := domain:field-json-exists(
    domain:get-model-field($model, "title"),
    $instance
  )
  let $type-exists := domain:field-json-exists(
    domain:get-model-field($model, "type"),
    $instance
  )
  return (
    assert:true($id-exists),
    assert:true($content-exists),
    assert:true($title-exists),
    assert:false($type-exists)
  )
};

declare %test:case function field-param-exists-test() as item()* {
  let $model := domain:get-model("model4")
  let $instance := map:new((
    map:entry("id", ""),
    map:entry("title", "Title"),
    map:entry("content", "")
  ))
  let $id-exists := domain:field-param-exists(
    domain:get-model-field($model, "id"),
    $instance
  )
  let $content-exists := domain:field-param-exists(
    domain:get-model-field($model, "content"),
    $instance
  )
  let $title-exists := domain:field-param-exists(
    domain:get-model-field($model, "title"),
    $instance
  )
  let $type-exists := domain:field-param-exists(
    domain:get-model-field($model, "type"),
    $instance
  )
  return (
    assert:true($id-exists),
    assert:true($content-exists),
    assert:true($title-exists),
    assert:false($type-exists)
  )
};

declare %test:case function find-field-in-model-test() as item()* {
  let $model := domain:get-model("model9")
  let $field := domain:find-field-in-model($model, "model10-name")
  let $model9-nested10-field := domain:get-model-field(domain:get-model("model9"), "nested10")
  let $model10-name-field := domain:get-model-field(domain:get-model("model10"), "model10-name")
  return (
    assert:not-empty($field),
    assert:equal($field, ($model9-nested10-field, $model10-name-field))
  )
};

declare %test:case function build-field-xpath-from-model-test() as item()* {
  let $model := domain:get-model("model8")
  let $model8-nested9-field := domain:get-model-field(domain:get-model("model8"), "nested9")
  let $model9-nested10-field := domain:get-model-field(domain:get-model("model9"), "nested10")
  let $model10-name-field := domain:get-model-field(domain:get-model("model10"), "model10-name")
  let $field-path := (
    $model8-nested9-field,
    $model9-nested10-field,
    $model10-name-field
  )
  let $xpath := domain:build-field-xpath-from-model($model, $field-path)
  let $expected :=
    fn:string-join((
      domain:get-field-absolute-xpath($model8-nested9-field),
      domain:get-field-xpath($model9-nested10-field),
      domain:get-field-xpath($model10-name-field)
    ))
  return (
    assert:not-empty($model10-name-field),
    assert:not-empty($xpath),
    assert:equal($xpath, $expected)
  )
};

declare %test:case function build-field-xpath-from-model-with-container-test() as item()* {
  let $model := domain:get-model("model8")
  let $model8-models9-field := domain:get-model-field(domain:get-model("model8"), "models9", fn:true())
  let $model8-nested9-in-container-field := domain:get-model-field(domain:get-model("model8"), "nested9-in-container")
  let $model9-nested10-field := domain:get-model-field(domain:get-model("model9"), "nested10")
  let $model10-name-field := domain:get-model-field(domain:get-model("model10"), "model10-name")
  let $field-path := (
    $model8-models9-field,
    $model8-nested9-in-container-field,
    $model9-nested10-field,
    $model10-name-field
  )
  let $xpath := domain:build-field-xpath-from-model($model, $field-path)
  let $expected :=
    fn:string-join((
      (:domain:get-field-absolute-xpath($model8-models9-field),:)
      domain:get-field-absolute-xpath($model8-nested9-in-container-field),
      domain:get-field-xpath($model9-nested10-field),
      domain:get-field-xpath($model10-name-field)
    ))
  return (
    assert:not-empty($model10-name-field),
    assert:not-empty($xpath),
    assert:equal($xpath, $expected)
  )
};

declare %test:case function find-field-from-path-model-test() as item()* {
  let $model := domain:get-model("model8")
  let $model10-name-field := domain:find-field-from-path-model($model, "nested9/nested10/model10-name")
  let $expected := (
    domain:get-model-field(domain:get-model("model8"), "nested9"),
    domain:get-model-field(domain:get-model("model9"), "nested10"),
    domain:get-model-field(domain:get-model("model10"), "model10-name")
  )
  return (
    assert:not-empty($model10-name-field),
    assert:equal($model10-name-field, $expected)
  )
};

declare %test:case function find-field-from-path-model-with-container-test() as item()* {
  let $model := domain:get-model("model8")
  let $model10-name-field := domain:find-field-from-path-model($model, "models9/nested9-in-container/nested10/model10-name")
  let $expected := (
    domain:get-model-field(domain:get-model("model8"), "models9", fn:true()),
    domain:get-model-field(domain:get-model("model8"), "nested9-in-container"),
    domain:get-model-field(domain:get-model("model9"), "nested10"),
    domain:get-model-field(domain:get-model("model10"), "model10-name")
  )
  return (
    assert:not-empty($model10-name-field),
    assert:equal($model10-name-field, $expected)
  )
};

declare %test:case function get-field-query-path-test() as item()* {
  let $model := domain:get-model("model1")
  let $field-name := domain:get-model-field($model, "name")
  let $field-query := domain:get-field-query($field-name, "dummy")
  return (
    assert:not-empty($field-query),
    assert:equal(
      $field-query,
      xdmp:with-namespaces(
        domain:declared-namespaces($field-name),
        cts:path-range-query(domain:get-field-absolute-xpath($field-name), "=", "dummy", ("collation=" || domain:get-field-collation($field-name)))
      )
    )
  )
};

declare %test:case function get-field-query-range-test() as item()* {
  let $model := domain:get-model("model2")
  let $field-name := domain:get-model-field($model, "name")
  let $field-query := domain:get-field-query($field-name, "dummy")
  return (
    assert:not-empty($field-query),
    assert:equal(
      $field-query,
      cts:element-range-query(domain:get-field-qname($field-name), "=", "dummy", ("collation=" || domain:get-field-collation($field-name)))
    )
  )
};

declare %test:case function get-field-tuple-reference-path-test() as item()* {
  let $model := domain:get-model("model1")
  let $field-name := domain:get-model-field($model, "name")
  let $field-query := domain:get-field-tuple-reference($field-name)
  return (
    assert:not-empty($field-query),
    assert:equal(
      document{$field-query},
      document{
        xdmp:with-namespaces(
              domain:declared-namespaces($field-name),
              cts:path-reference(domain:get-field-absolute-xpath($field-name), ("collation=" || domain:get-field-collation($field-name)))
            )
      }
    )
  )
};

declare %test:case function get-field-tuple-reference-range-test() as item()* {
  let $model := domain:get-model("model2")
  let $field-name := domain:get-model-field($model, "name")
  let $field-query := domain:get-field-tuple-reference($field-name)
  return (
    assert:not-empty($field-query),
    assert:equal(
      document{$field-query},
      document{
        cts:element-reference(domain:get-field-qname($field-name), ("collation=" || domain:get-field-collation($field-name)))
      }
    )
  )
};
