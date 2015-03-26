xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-reference-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $instances1 :=
(
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-id</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-id-2</id>
    <name>model1-name-2</name>
  </model1>
)
;

declare variable $instance2 :=
<model2 xmlns="http://marklogic.com/model/model2">
  <id>model2-id</id>
  <name>model2-name</name>
</model2>
;

declare variable $CONFIG := ();

declare %test:setup function setup() {
  let $_ := setup:setup($TEST-APPLICATION)
  let $model1 := domain:get-model("model1")
  let $_ := for $instance in $instances1 return (
    setup:invoke(
      function() {
        model:create($model1, $instance, $TEST-COLLECTION)
      }
    )
  )
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

declare %test:case function model1-model2-exist-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  return (
    assert:not-empty($model1),
    assert:not-empty($model2)
  )
};

declare %test:case function model-default-reference-function-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $itentity-map := map:new((map:entry(domain:get-model-identity-field-name($model1), $identity-value)))
  let $reference-field := domain:get-model-field($model2, "model1")
  let $reference := model:reference($reference-field, $model1, $itentity-map)
  return (
    assert:not-empty($reference)
  )
};

declare %test:case function get-model-references-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model2, "model1")
  return (
    assert:not-empty($reference-field),
    assert:not-empty(model:get-model-references($reference-field, $identity-value))
  )
};

declare %test:case function model-new-one-reference-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model2, "model1")
  let $map := map:new((
      map:entry("id", "model2-id"),
      map:entry("name", "model2-name"),
      map:entry("model1", $identity-value)
    ))
  let $model2-instance := model:new(
    $model2,
    $map)
  let $reference-value := domain:get-field-value($reference-field, $model2-instance)
  return (
    assert:not-empty($model2-instance),
    assert:not-empty($reference-value),
    assert:equal(fn:count($reference-value), 1)
  )
};

declare %test:case function model-new-two-reference-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance-1 := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value-1 := xs:string(domain:get-field-value($identity-field, $model1-instance-1))
  let $model1-instance-2 := model:get($model1, "model1-id-2")
  let $identity-value-2 := xs:string(domain:get-field-value($identity-field, $model1-instance-2))
  let $reference-field := domain:get-model-field($model2, "model1")
  let $map := map:new((
      map:entry("id", "model2-id"),
      map:entry("name", "model2-name"),
      map:entry("model1", ($identity-value-1, $identity-value-2))
    ))
  let $model2-instance := model:new(
    $model2,
    $map)
  let $reference-value := domain:get-field-value($reference-field, $model2-instance)
  return (
    assert:not-empty($model2-instance),
    assert:not-empty($reference-value),
    assert:equal(fn:count($reference-value), 2),
    assert:equal(xs:string($reference-value[1]/@ref-id), $identity-value-1),
    assert:equal(xs:string($reference-value[2]/@ref-id), $identity-value-2)
  )
};

declare %test:case function model-update-two-reference-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance-1 := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value-1 := xs:string(domain:get-field-value($identity-field, $model1-instance-1))
  let $model1-instance-2 := model:get($model1, "model1-id-2")
  let $identity-value-2 := xs:string(domain:get-field-value($identity-field, $model1-instance-2))
  let $reference-field := domain:get-model-field($model2, "model1")
  let $map := map:new((
      map:entry("id", "model2-id-" || setup:random()),
      map:entry("name", "model2-name"),
      map:entry("model1", ($identity-value-1, $identity-value-2))
    ))
  let $model2-instance := setup:invoke(
    function() {
      model:create(
        $model2,
        $map
      )
    }
  )
  let $model2-instance-map := model:convert-to-map($model2, $model2-instance)
  let $_ := map:put($model2-instance-map, "model1", map:get($model2-instance-map, "model1")[1])
  let $model2-instance := model:update($model2, $model2-instance-map)
  let $reference-value := domain:get-field-value($reference-field, $model2-instance)
  return (
    assert:not-empty($model2-instance),
    assert:not-empty($reference-value),
    assert:equal(fn:count($reference-value), 1),
    assert:equal(xs:string($reference-value/@ref-id), $identity-value-1)
  )
};

declare %test:case function build-reference-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $model1-instance := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
(:  let $itentity-map := map:new((map:entry(domain:get-model-identity-field-name($model1), $identity-value))):)
  let $reference-field := domain:get-model-field($model2, "model1")
  let $model1-reference := model:get-model-references($reference-field, $identity-value)
  (:model:reference($model1, $itentity-map):)
(:  let $model2-instance := model:find($model2, map:new((map:entry("id", "model2-id")))):)
  let $map := map:new((
      map:entry("id", "model2-id"),
      map:entry("name", "model2-name"),
      map:entry("model1", $model1-reference)
    ))
  let $model2-instance := model:create(
    $model2,
    $map,
    $TEST-COLLECTION)
  return assert:not-empty($model2-instance)
};

declare %test:case function build-reference-different-name-test() {
  let $reference-field-name := "dummyModel"
  let $model1 := domain:get-model("model1")
  let $model3 := domain:get-model("model3")
  let $model1-instance := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model3, $reference-field-name)
  let $model3-instance :=
    model:new(
      $model3,
      <model3 xmlns="http://marklogic.com/model/model3">
        <dummyModel>{$identity-value}</dummyModel>
      </model3>
    )
  let $reference-field := domain:get-model-field($model3, "dummyModel")
  let $model1-key-label-value := domain:get-field-value(domain:get-model-keylabel-field($model1), $model1-instance)
  (:~ TODO: to be fixed ~:)
  let $model1-key-label-value := "model1-id"
  return
  (
    assert:not-empty($model3-instance/*:dummyModel, "model3 should have dummyModel element name"),
    assert:equal(domain:get-field-value(domain:get-model-field($model3, "dummyModel"), $model3-instance)/fn:string(), $model1-key-label-value)
  )
};

declare %test:case function reference-function-test() {
  let $reference-field-name := "dummyModel"
  let $model1 := domain:get-model("model1")
  let $model3 := domain:get-model("model3")
  let $model1-instance := model:get($model1, "model1-id")
  let $identity-field := domain:get-model-identity-field($model1)
  let $identity-value := xs:string(domain:get-field-value($identity-field, $model1-instance))
  let $reference-field := domain:get-model-field($model3, $reference-field-name)
  let $model1-reference := model:get-model-references($reference-field, $identity-value)
  return assert:not-empty($model1-reference, "model1-reference should not be empty")
};

declare %test:case function application-reference-from-map-test() {
  let $model9 := domain:get-model("model9")
  let $model9-instance :=
    model:new(
      $model9,
      map:new((
        map:entry("id", "model9-id"),
        map:entry("type", "country")
      ))
    )
  let $reference-field := domain:get-model-field($model9, "type")
  return
  (
    assert:not-empty($model9-instance/*:type, "model9 should have type element name"),
    assert:equal(domain:get-field-value($reference-field, $model9-instance)/@ref-type/fn:string(), "application"),
    assert:equal(domain:get-field-value($reference-field, $model9-instance)/@ref/fn:string(), "type"),
    assert:equal(domain:get-field-value($reference-field, $model9-instance)/@ref-id/fn:string(), "country")
  )
};

declare %test:case function application-reference-from-xml-test() {
  let $model9 := domain:get-model("model9")
  let $model9-instance :=
    model:new(
      $model9,
      <model9 xmlns="http://xquerrail.com/app-test">
        <id>model9-id</id>
        <type>country</type>
      </model9>
    )
  let $reference-field := domain:get-model-field($model9, "type")
  return
  (
    assert:not-empty($model9-instance/*:type, "model9 should have type element name"),
    assert:equal(domain:get-field-value($reference-field, $model9-instance)/@ref-type/fn:string(), "application"),
    assert:equal(domain:get-field-value($reference-field, $model9-instance)/@ref/fn:string(), "type"),
    assert:equal(domain:get-field-value($reference-field, $model9-instance)/@ref-id/fn:string(), "country")
  )
};

declare %test:case function model-reference-from-nested-xml-test() {
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  let $instance1 :=
    model:new(
      $model1,
      map:new((
        map:entry("id", "model1-id-" || setup:random()),
        map:entry("name", "model1-name")
      ))
    )
  let $instance2 :=
    model:new(
      $model2,
      map:new((
        map:entry("id", "model2-id-" || setup:random()),
        map:entry("name", "model2-name"),
        map:entry("model1", $instance1)
      ))
    )
  let $reference-field := domain:get-model-field($model2, "model1")
  let $reference-value := domain:get-field-value($reference-field, $instance2)
  return
  (
    assert:not-empty($reference-value, "model2/model1 reference must exist"),
    assert:equal($reference-value/@ref-type/fn:string(), "model"),
    assert:equal($reference-value/@ref/fn:string(), "model1"),
    assert:equal($reference-value/@ref-id/fn:string(), domain:get-field-value(domain:get-model-identity-field($model1), $instance1))
  )
};
