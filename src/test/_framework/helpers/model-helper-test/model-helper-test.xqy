xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "/test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace model-helper = "http://xquerrail.com/helper/model" at "/main/_framework/helpers/model-helper.xqy";

declare namespace json-options = "json:options";
declare namespace model1 = "http://marklogic.com/model/model1";
declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "model-helper-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/helpers/model-helper-test/_config</config>
</application>
;

declare variable $INSTANCES1 := (
<model1 xmlns="http://marklogic.com/model/model1">
  <id>model1-id-for-reference</id>
  <name>model1-name-for-reference</name>
</model1>
);

declare %test:setup function setup() as empty-sequence()
{
  let $_ := setup:setup($TEST-APPLICATION)
  let $model1 := domain:get-model("model1")
  let $_ :=
    for $instance in $INSTANCES1
    return
    setup:invoke(
      function() {
        model:create($model1, $instance, $TEST-COLLECTION)
      }
    )
  return ()
};

declare %test:teardown function teardown() as empty-sequence()
{
  xdmp:invoke-function(
    function() {
      xdmp:collection-delete($TEST-COLLECTION),
      xdmp:commit()
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
    </options>
  )
};

declare %private function model1-field-value($instance, $name) {
  domain:get-field-value(domain:get-model-field(domain:get-model("model1"), $name), $instance)
};

declare %test:case function no-option-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $instance := model:new($model1, map:new((map:entry("id", "model1-id"))))
  let $instance-to-json := model-helper:build-json($model1, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:empty(map:get($instance-to-json, $model1/@name)),
    assert:equal(model1-field-value($instance, "uuid"), model1-field-value($instance-to-json, "uuid")),
    assert:equal(model1-field-value($instance, "name"), model1-field-value($instance-to-json, "name")),
    assert:equal(model1-field-value($instance, "description"), model1-field-value($instance-to-json, "description")),
    assert:equal(model1-field-value($instance, "tags"), model1-field-value($instance-to-json, "tags"))
  )
};

declare %test:case function include-root-true-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $instance := model:new($model1, map:new((map:entry("id", "model1-id"))))
  let $instance-to-json := model-helper:build-json($model1, $instance, fn:true())
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:not-empty(map:get($instance-to-json, $model1/@name))
  )
};

declare %test:case function option-empty-string-true-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $instance := model:new($model1, map:new((map:entry("id", "model1-id"))))
  let $options := <json-options:options><json-options:empty-string>true</json-options:empty-string></json-options:options>
  let $instance-to-json := model-helper:build-json($model1, $instance, fn:false(), $options)
  return (
    assert:not-empty($instance),
    assert:not-empty(map:get($instance-to-json, "description"))
  )
};

declare %test:case function no-option-empty-string-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $instance := model:new($model1, map:new((map:entry("id", "model1-id"))))
  let $options := <json-options:options/>
  let $instance-to-json := model-helper:build-json($model1, $instance, fn:false(), $options)
  return (
    assert:not-empty($instance),
    assert:empty(map:get($instance-to-json, "description"))
  )
};

declare %test:case function option-strip-container-true-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $instance :=
    model:new(
      $model1,
      map:new((
        map:entry("id", "model1-id"),
        map:entry("keywords.keyword", ("keyword1", "keyword2"))
      ))
    )
  let $options := <json-options:options><json-options:strip-container>true</json-options:strip-container></json-options:options>
  let $instance-to-json := model-helper:build-json($model1, $instance, fn:false(), $options)
  return (
    assert:not-empty($instance),
    assert:empty(map:get($instance-to-json, "keywords")),
    assert:equal(json:array-values(map:get($instance-to-json, "keyword")), ("keyword1", "keyword2"))
  )
};

declare %test:case function no-option-strip-container-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $instance :=
    model:new(
      $model1,
      map:new((
        map:entry("id", "model1-id"),
        map:entry("keywords.keyword", ("keyword1", "keyword2"))
      ))
    )
  let $options := <json-options:options/>
  let $instance-to-json := model-helper:build-json($model1, $instance, fn:false(), $options)
  return (
    assert:not-empty($instance),
    assert:equal(json:array-values(map:get(map:get($instance-to-json, "keywords"), "keyword")), ("keyword1", "keyword2")),
    assert:empty(map:get($instance-to-json, "keyword"))
  )
};

declare %test:case function option-flatten-reference-true-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $instance :=
    model:new(
      $model2,
      map:new((
        map:entry("id", "model2-id"),
        map:entry("model1", $INSTANCES1[1]/model1:id)
      ))
    )
  let $options := <json-options:options><json-options:flatten-reference>true</json-options:flatten-reference></json-options:options>
  let $instance-to-json := model-helper:build-json($model2, $instance, fn:false(), $options)
  return (
    assert:not-empty($instance),
    assert:equal(map:get($instance-to-json, "model1"), xs:string($INSTANCES1[1]/model1:id))
  )
};

declare %test:case function no-option-flatten-reference-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $instance :=
    model:new(
      $model2,
      map:new((
        map:entry("id", "model2-id"),
        map:entry("model1", $INSTANCES1[1]/model1:id)
      ))
    )
  let $options := <json-options:options/>
  let $instance-to-json := model-helper:build-json($model2, $instance, fn:false(), $options)
  return (
    assert:not-empty($instance),
    assert:equal(map:get(map:get($instance-to-json, "model1"), "text"), xs:string($INSTANCES1[1]/model1:id))
  )
};

declare %test:case function integer-value-string-field-model-helper-build-json-test() {
  let $model1 := domain:get-model("model1")
  let $instance :=
    model:new(
      $model1,
      map:new((
        map:entry("id", "model1-id"),
        map:entry("description", "2000"),
        map:entry("date", xs:date("2015-12-10")),
        map:entry("number", 999),
        map:entry("flag", fn:false())
      ))
    )
  let $instance-to-json := model-helper:build-json($model1, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:equal(map:get($instance-to-json, "description"), "2000", "description must be equal to 2000"),
    assert:equal(map:get($instance-to-json, "number"), 999, "number must be equal to 999"),
    assert:equal(map:get($instance-to-json, "flag"), fn:false(), "description must be false")
  )
};

declare %test:case function custom-json-name-helper-build-json-test() {
  let $model3 := domain:get-model("model3")
  let $instance :=
    model:new(
      $model3,
      map:new((
        map:entry("id", "model3-id"),
        map:entry("name", "john doe"),
        map:entry("MyDescription", "dummy-description"),
        map:entry("first-name", "john"),
        map:entry("last-name", "Doe")
      ))
    )
  let $instance-to-json := model-helper:build-json($model3, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:equal(map:get($instance-to-json, "name"), "john doe", "name must be equal to john doe"),
    assert:equal(map:get($instance-to-json, "description"), "dummy-description", "description must be equal to dummy-description"),
    assert:equal(map:get($instance-to-json, "firstName"), "john", "firstName must be equal to john"),
    assert:equal(map:get($instance-to-json, "lastName"), "Doe", "lastName must be Doe")
  )
};

declare %test:case function model-nested-abtract-model-helper-build-json-test() {
  let $model4 := domain:get-model("model4")
  let $model5 := domain:get-model("model5")
  let $model4-id :=setup:random("model4-id")
  let $model5-name-1 :=setup:random("model5-name")
  let $model5-name-2 :=setup:random("model5-name")
  let $instance :=
    model:new(
      $model4,
      map:new((
        map:entry("id", $model4-id),
        map:entry("name", "dummy-model4-name"),
        map:entry(
          "model5List.model5",
          (
            model:new(
              $model5,
              map:entry("name", $model5-name-1)
            ),
            model:new(
              $model5,
              map:entry("name", $model5-name-2)
            )
          )
        )
      ))
    )
  let $instance-to-json := model-helper:build-json($model4, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:equal(map:get($instance-to-json, "id"), $model4-id, "id must be equal to " || $model4-id),
    assert:equal(map:get(map:get(map:get($instance-to-json, "model5List"), "model5")[1], "name"), $model5-name-1, "model5[1].name must be equal to " || $model5-name-1),
    assert:equal(map:get(map:get(map:get($instance-to-json, "model5List"), "model5")[2], "name"), $model5-name-2, "model5[2].name must be equal to " || $model5-name-2)
  )
};

declare %test:case function custom-get-field-json-name-helper-build-json-test() {
  let $model6 := domain:get-model("model6")
  let $model6-id := setup:random("model6-id")
  let $map-instance :=
    map:new((
      map:entry("id", $model6-id),
      map:entry("name", "John Doe"),
      map:entry("first-name", "John"),
      map:entry("last-name", "Doe")
    ))
  let $instance :=
    model:new(
      $model6,
      $map-instance
    )
  let $instance-to-json := model-helper:build-json($model6, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:equal(map:get($instance-to-json, "id"), $model6-id, "id must be equal to " || $model6-id),
    assert:equal(map:get($instance-to-json, "firstName"), map:get($map-instance, "first-name"), "firstName must be equal to $map-instance.first-name"),
    assert:equal(map:get($instance-to-json, "lastName"), map:get($map-instance, "last-name"), "firstName must be equal to $map-instance.last-name")
  )
};

declare %test:case function custom-json-options-from-model-helper-build-json-test() {
  let $model7 := domain:get-model("model7")
  let $model7-id := setup:random("model7-id")
  let $map-instance :=
    map:new((
      map:entry("id", $model7-id),
      map:entry("first-name", "John"),
      map:entry("last-name", "Doe")
    ))
  let $instance :=
    model:new(
      $model7,
      $map-instance
    )
  let $instance-to-json := model-helper:build-json($model7, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:equal(map:get($instance-to-json, "id"), $model7-id, "id must be equal to " || $model7-id),
    assert:equal(map:get($instance-to-json, config:attribute-prefix() || "name"), "", config:attribute-prefix() || "name must be equal to empty string"),
    assert:equal(map:get($instance-to-json, "last-name"), map:get($map-instance, "last-name"), "firstName must be equal to $map-instance.last-name")
  )
};

declare %test:case function custom-to-json-function-from-model-helper-build-json-test() {
  let $model8 := domain:get-model("model8")
  let $model8-id := setup:random("model8-id")
  let $map-instance :=
    map:new((
      map:entry("id", $model8-id),
      map:entry("last-name", "Doe")
    ))
  let $instance :=
    model:new(
      $model8,
      $map-instance
    )
  let $instance-to-json := model-helper:build-json($model8, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance-to-json),
    assert:equal(map:get($instance-to-json, "first-name"), "dummy-first-name", "firstName must be equal to dummy-first-name")
  )
};

declare %test:case function schema-element-no-value-model-helper-build-json-test() {
  let $model := domain:get-model("model9")
  let $instance :=
    model:new(
      $model,
      map:new((
        map:entry("id", "model9-id"),
        map:entry("name", "model9-name")
      ))
    )
  let $instance-to-json := model-helper:build-json($model, $instance)
  return (
    assert:not-empty($instance),
    assert:empty(map:get($instance-to-json, "html"))
  )
};

declare %test:case function schema-element-with-namespace-model-helper-build-json-test() {
  let $model := domain:get-model("model9")
  let $instance :=
    model:new(
      $model,
      map:new((
        map:entry("id", "model9-id"),
        map:entry("name", "model9-name"),
        map:entry("html", <h1 xmlns="http://www.w3.org/1999/xhtml">title</h1>)
      ))
    )
  let $instance-to-json := model-helper:build-json($model, $instance)
  return (
    assert:not-empty($instance),
    assert:equal(map:get($instance-to-json, "html"), '<h1 xmlns="http://www.w3.org/1999/xhtml">title</h1>')
  )
};

declare %test:case function schema-element-no-namespace-model-helper-build-json-test() {
  let $model := domain:get-model("model9")
  let $instance :=
    model:new(
      $model,
      map:new((
        map:entry("id", "model9-id"),
        map:entry("name", "model9-name"),
        map:entry("html", <h1>title</h1>)
      ))
    )
  let $instance-to-json := model-helper:build-json($model, $instance)
  return (
    assert:not-empty($instance),
    assert:equal(map:get($instance-to-json, "html"), "<h1>title</h1>")
  )
};

