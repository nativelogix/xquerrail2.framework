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
  let $_ := xdmp:log(("simple-model-helper-build-json-test", "$instance-to-json", $instance-to-json, xdmp:to-json($instance-to-json)))
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
  let $_ := xdmp:log(("simple-model-helper-build-json-test", "$instance-to-json", $instance-to-json, xdmp:to-json($instance-to-json)))
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
  let $_ := xdmp:log(("empty-string-field-model-helper-build-json-test", "$instance-to-json", $instance-to-json, xdmp:to-json($instance-to-json)))
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
