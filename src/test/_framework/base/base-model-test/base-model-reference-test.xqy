xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-reference-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $instance1 := 
<model1 xmlns="http://marklogic.com/model/model1">
  <id>model1-id</id>
  <name>model1-name</name>
</model1>
;

declare variable $instance2 := 
<model2 xmlns="http://marklogic.com/model/model2">
  <id>model2-id</id>
  <name>model2-name</name>
</model2>
;

declare variable $CONFIG := ();

declare %test:setup function setup() {
  let $_ := xdmp:set($CONFIG, app:bootstrap($TEST-APPLICATION))
  let $model1 := domain:get-model("model1")
  let $_ := model:create($model1, $instance1, $TEST-COLLECTION)
  return
    ()
};

declare %test:teardown function teardown() {
  xdmp:invoke-function(
    function() {
      xdmp:collection-delete($TEST-COLLECTION)
      , xdmp:commit() 
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
    </options>
  )
};

declare %test:before-each function before-test() {
  xdmp:set($CONFIG, app:bootstrap($TEST-APPLICATION))
};

declare %test:case function model1-model2-exist-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  return (
    assert:not-empty($model1),
    assert:not-empty($model2)
  )
};

declare %test:case function model-reference-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model1-instance := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $itentity-map := map:new((map:entry(domain:get-model-identity-field-name($model1), $identity-value)))
  let $reference := model:reference("model1", $model1, $itentity-map)
  return (
    assert:not-empty($reference)
  )
};

declare %test:case function get-model-references-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model2, "model1")
  return (
    assert:not-empty($reference-field),
    assert:not-empty(model:get-model-references($reference-field, $identity-value))
  )
};

declare %test:case function build-reference-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
(:  let $itentity-map := map:new((map:entry(domain:get-model-identity-field-name($model1), $identity-value))):)
  let $reference-field := domain:get-model-field($model2, "model1")
  let $model1-reference := model:get-model-references($reference-field, $identity-value)
  (:model:reference($model1, $itentity-map):)
(:  let $_ := xdmp:log(("$model2", $model2)):)
(:  let $_ := xdmp:log(("$identity-value", $identity-value)):)
(:  let $_ := xdmp:log(("domain:get-model-fields", domain:get-model-fields:)
(:  let $model2-instance := model:find($model2, map:new((map:entry("id", "model2-id")))):)
  let $map := map:new((
      map:entry("id", "model2-id"),
      map:entry("name", "model2-name"),
      map:entry("model1", $model1-reference)
    ))
(:  let $_ := xdmp:log(("$map", $map)):)
  let $model2-instance := model:create(
    $model2, 
    $map, 
    $TEST-COLLECTION)
(:  let $_ := xdmp:log(("$model2-instance", $model2-instance)):)
(:  let $_ := xdmp:log(("model:reference", model:reference($model1, $itentity-map))):)
(:  let $_ := xdmp:log(("model:get($model1, $identity-value)", model:get($model1, map:new((map:entry("uuid", $identity-value)))))):)
  return assert:not-empty($model2-instance) 
};

declare %test:case function build-reference-different-name-test() {
  let $reference-field-name := "dummyModel"
  let $model1 := domain:get-model("model1")
  let $model3 := domain:get-model("model3")
  let $model1-instance := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model3, $reference-field-name)
  let $model1-reference := model:get-model-references($reference-field, $identity-value)
  return assert:equal(fn:local-name($model1-reference), $reference-field-name) 
};
