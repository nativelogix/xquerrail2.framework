xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "/test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "model-extension-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/model-test/_config</config>
</application>
;

declare variable $instance1 :=
<model1 xmlns="http://marklogic.com/model/model1">
  <id>model1-id</id>
  <name>model1-name</name>
</model1>
;

declare %test:setup function setup() as empty-sequence()
{
  setup:setup($TEST-APPLICATION),
  setup:create-instances("model1", $instance1, $TEST-COLLECTION)
};

declare %test:teardown function teardown() as empty-sequence()
{
  setup:teardown($TEST-COLLECTION)
};

declare %test:case function config-model-extension-test() as item()*
{
  assert:equal(config:model-extension()/@resource/fn:string(), "/test/_framework/model-test/_extensions/test-model.extension.xqy")
};

declare %test:case function build-model-extension-reference-test() {
  let $_ := setup:lock-for-update()
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model2, "model1")
  let $model1-reference := model:get-model-references($reference-field, $identity-value)
  let $map := map:new((
      map:entry("id", "model2-id"),
      map:entry("name", "model2-name"),
      map:entry("model1", $model1-reference)
    ))
  let $model2-instance := model:create(
    $model2,
    $map,
    $TEST-COLLECTION)
  return (
    assert:not-empty($model2-instance),
    assert:equal(domain:get-field-value($reference-field, $model2-instance)/@reference-test/fn:data(), "model1")
  )
};

declare %test:case function build-function-model-reference-test() {
  let $_ := setup:lock-for-update()
  let $model1 := domain:get-model("model1")
  let $model3 := domain:get-model("model3")
  let $model1-instance := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model3, "model1")
  let $model1-reference := model:get-model-references($reference-field, $identity-value)
  let $map := map:new((
      map:entry("id", "model3-id"),
      map:entry("name", "model3-name"),
      map:entry("model1", $model1-reference)
    ))
  let $model3-instance := model:create(
    $model3,
    $map,
    $TEST-COLLECTION)
  return (
    assert:not-empty($model3-instance),
    assert:equal(domain:get-field-value($reference-field, $model3-instance)/@reference-test/fn:data(), "model1")
  )
};

