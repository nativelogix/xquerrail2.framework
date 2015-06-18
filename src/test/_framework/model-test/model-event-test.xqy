xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "model-event-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/model-test/_config</config>
</application>
;

declare variable $INSTANCES5 := (
<model5 xmlns="http://xquerrail.com/app-test">
  <id>model5-id-before-update</id>
  <name>model5-name-before-update</name>
  <updated-count>3</updated-count>
</model5>
);

declare variable $INSTANCES6 := (
<model6 xmlns="http://xquerrail.com/app-test">
  <name>model6-name-unique-constraint</name>
  <comment>unique-comment</comment>
</model6>
);

declare %test:setup function setup() as empty-sequence()
{
  setup:setup($TEST-APPLICATION),
  setup:create-instances("model5", $INSTANCES5, $TEST-COLLECTION),
  setup:create-instances("model6", $INSTANCES6, $TEST-COLLECTION)
};

declare %test:teardown function teardown() as empty-sequence()
{
  setup:teardown($TEST-COLLECTION)
};

declare %test:case function build-model-extension-reference-test() {
  let $_ := setup:lock-for-update()
  let $model5 := domain:get-model("model5")
  let $map := map:new((
      map:entry("id", setup:random("model5-id")),
      map:entry("name", "model5-name")
    ))
  let $instance := model:create(
    $model5,
    $map,
    $TEST-COLLECTION
  )
  return (
    assert:not-empty($instance),
    assert:equal(fn:string(domain:get-field-value(domain:get-model-field($model5, "firstName"), $instance)), "john", "$instance.firstName must equal 'john'"),
    assert:equal(fn:string(domain:get-field-value(domain:get-model-field($model5, "lastName"), $instance)), "doe", "$instance.firstName must equal 'doe'")
  )
};

declare %test:case function model-unique-constraint-element-test() as item()*
{
  let $_ := setup:lock-for-update()
  let $model6 := domain:get-model("model6")
  let $instance6 := model:get($model6, "model6-name-unique-constraint")
  let $comment-value := domain:get-field-value(domain:get-model-field($model6, "comment"), $instance6)
  let $instance6-map :=
    map:new((
      map:entry("name", "model6-name-unique-constraint-2"),
      map:entry("comment", fn:string($comment-value))
    ))
  let $actual := try {
    setup:invoke(
      function() {
        model:create(
          $model6,
          $instance6-map,
          $TEST-COLLECTION
        )
      }
    )
  } catch ($ex) { $ex }
  return (
    assert:equal(fn:string($actual/error:name), "MODEL-VALIDATION-UNIQUE-CONSTRAINT-ERROR"),
    assert:error($actual, text{"Unique constraint error for model", $model6/@name})
  )
};

declare %test:case function before-update-event-test() {
  let $_ := setup:lock-for-update()
  let $model5 := domain:get-model("model5")
  let $instance := model:get($model5, "model5-id-before-update")
  let $instance := model:convert-to-map($model5, $instance)
  let $_ := map:put($instance, "name", "gary")
  let $instance := model:update($model5, $instance)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value(domain:get-model-field($model5, "updated-count"), $instance), 4, "$instance.updated-count must equal 4")
  )
};


