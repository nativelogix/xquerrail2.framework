xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";

import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "model-actions-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/model-test/_config</config>
</application>
;

declare variable $instances := (
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-add</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-replace</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-remove</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-field-not-found</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-operation-not-implemented</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-test-successful</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-test-failed</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-add-multi</id>
    <name>model1-name</name>
  </model1>
);

declare %test:setup function setup() as empty-sequence()
{
  (app:reset(), app:bootstrap($TEST-APPLICATION))[0]
};

declare %test:teardown function teardown() as empty-sequence()
{
  setup:teardown($TEST-COLLECTION)
};

declare %test:case function model-patch-add-operation-test() {
  let $model1 := domain:get-model("model1")
  let $_ := setup:invoke(function(){model:create($model1, $instances[1], $TEST-COLLECTION)})
  let $current-instance := model:get($model1, "model1-patch-add")
  let $updated := map:new((
    map:entry("op", "add"),
    map:entry("path", "description"),
    map:entry("value", "test description")
  ))
  let $instance := model:patch($model1, $current-instance, $updated)
  let $description-field := domain:get-model-field($model1, "description")
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($description-field, $instance), "test description", "field description should have the value 'test description'")
  )
};

declare %test:case function model-patch-replace-operation-test() {
  let $model1 := domain:get-model("model1")
  let $_ := setup:invoke(function(){model:create($model1, $instances[2], $TEST-COLLECTION)})
  let $current-instance := model:get($model1, "model1-patch-replace")
  let $updated := map:new((
    map:entry("op", "replace"),
    map:entry("path", "name"),
    map:entry("value", "12345")
  ))
  let $instance := model:patch($model1, $current-instance, $updated)

  let $name-field := domain:get-model-field($model1, "name")
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($name-field, $instance), "12345")
  )
};

declare %test:case function model-patch-remove-operation-test() {
  let $model1 := domain:get-model("model1")
  let $_ := setup:invoke(function(){model:create($model1, $instances[3], $TEST-COLLECTION)})
  let $current-instance := model:get($model1, "model1-patch-remove")
  let $updated := map:new((
    map:entry("op", "remove"),
    map:entry("path", "name")
  ))
  let $instance := model:patch($model1, $current-instance, $updated)
  let $name-field := domain:get-model-field($model1, "name")
  return (
    assert:not-empty($instance),
    assert:empty(domain:get-field-value($name-field, $instance), "field name should be empty")
  )
};

declare %test:case function model-patch-remove-operation-field-not-found-test() {
  let $model1 := domain:get-model("model1")
  let $actual := try { 
    let $_ := setup:invoke(function(){model:create($model1, $instances[4], $TEST-COLLECTION)})
    let $current-instance := model:get($model1, "model1-patch-field-not-found")
    let $updated := map:new((
      map:entry("op", "remove"),
      map:entry("path", "name2")
    ))
    return model:patch($model1, $current-instance, $updated)
  } catch ($ex) { $ex }
  return (
    assert:error($actual, text{"Could not find field from path", "name2", "in model", $model1/@name})
  )
};

declare %test:case function model-patch-operation-not-implemented-test() {
  let $model1 := domain:get-model("model1")
  let $operation := "dummy"
  let $actual := try { 
    let $_ := setup:invoke(function(){model:create($model1, $instances[5], $TEST-COLLECTION)})
    let $current-instance := model:get($model1, "model1-patch-operation-not-implemented")
    let $updated := map:new((
      map:entry("op", $operation),
      map:entry("path", "name")
    ))
    return model:patch($model1, $current-instance, $updated)
  } catch ($ex) { $ex }
  return (
    assert:error($actual, text{"Operation", $operation, "not implemented"})
  )
};

declare %test:case function model-patch-test-operation-successful-test() {
  let $model1 := domain:get-model("model1")
  let $_ := setup:invoke(function(){model:create($model1, $instances[6], $TEST-COLLECTION)})
  let $current-instance := model:get($model1, "model1-patch-test-successful")
  let $updated := map:new((
    map:entry("op", "test"),
    map:entry("path", "name"),
    map:entry("value", "model1-name")
  ))
  let $instance := model:patch($model1, $current-instance, $updated)
  return (
    assert:not-empty($instance)
  )
};

declare %test:case function model-patch-test-operation-failed-test() {
  let $model1 := domain:get-model("model1")
  let $path := "name"
  let $value := "dummy"
  let $actual := try { 
    let $_ := setup:invoke(function(){model:create($model1, $instances[7], $TEST-COLLECTION)})
    let $current-instance := model:get($model1, "model1-patch-test-failed")
    let $updated := map:new((
      map:entry("op", "test"),
      map:entry("path", $path),
      map:entry("value", $value)
    ))
    return model:patch($model1, $current-instance, $updated)
  } catch ($ex) { $ex }
  return (
    xdmp:log($actual/error:name),
    assert:error($actual, text{"Test failed", "path", $path, "value", $value})
  )
};

declare %test:case function model-patch-add-operation-multi-value-test() {
  let $model1 := domain:get-model("model1")
  let $_ := setup:invoke(function(){model:create($model1, $instances[8], $TEST-COLLECTION)})
  let $current-instance := model:get($model1, "model1-patch-add-multi")
  let $tags-value := ("tag#1", "tag#2")
  let $updated := map:new((
    map:entry("op", "add"),
    map:entry("path", "tags"),
    map:entry("value", $tags-value)
  ))
  let $instance := model:patch($model1, $current-instance, $updated)
  let $tags-field := domain:get-model-field($model1, "tags")
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($tags-field, $instance), $tags-value)
  )
};

