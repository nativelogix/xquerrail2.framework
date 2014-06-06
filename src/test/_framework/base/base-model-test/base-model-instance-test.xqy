xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup" at "../../../../test/_framework/setup.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-reference-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $INSTANCE1 := 
<model1 xmlns="http://marklogic.com/model/model1">
  <id>model1-id</id>
  <name>model1-name</name>
</model1>
;

declare variable $CONFIG := ();

declare %test:setup function setup() {
  let $_ := xdmp:set($CONFIG, app:bootstrap($TEST-APPLICATION))
  let $model1 := domain:get-model("model1")
  let $_ := model:create($model1, $INSTANCE1, $TEST-COLLECTION)
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

declare %test:ignore function model-instance-map-by-key-label-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model5 := domain:get-model("model5")
  let $instance5 := map:new((
    map:entry("id", "model5-id"),
    map:entry("name", "model5-name"),
    map:entry("model1", xs:string($INSTANCE1/*:id))
  ))
  let $_ := xdmp:log(("$instance5", $instance5))
  let $instance5 := setup:eval(
    function() {
      model:new($model5, $instance5)
    }
  )
  let $_ := xdmp:log(("$instance5", $instance5))
  return (
    assert:not-empty($instance5/*:model1)
  )
};

declare %test:ignore function model-instance-xml-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model5 := domain:get-model("model5")
  let $instance1 := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity1 := xs:string(domain:get-field-value(domain:get-model-identity-field($model1), $instance1))
  let $instance5 :=
    <model5 xmlns="http://marklogic.com/model/model5">
      <id>model5-id</id>
      <name>model5-name</name>
      <model1>{$identity1}</model1>
    </model5>
  let $_ := xdmp:log(("$instance5", $instance5))
  let $instance5 := setup:eval(
    function() {
      model:new($model5, $instance5)
    }
  )
  let $_ := xdmp:log(("$instance5", $instance5))
  return (
    assert:not-empty($instance5/*:model1)
  )
};

declare %test:ignore function model-instance-json-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model5 := domain:get-model("model5")
  let $instance1 := model:find($model1, map:new((map:entry("id", "model1-id"))))
  let $identity1 := xs:string(domain:get-field-value(domain:get-model-identity-field($model1), $instance1))
  let $instance5 := xdmp:from-json('{propertyGroup:["' || $identity1 || '"]}')
(:    <model5 xmlns="http://marklogic.com/model/model5">
      <id>model5-id</id>
      <name>model5-name</name>
      <model1>{$identity1}</model1>
    </model5>
:)  let $_ := xdmp:log(("$instance5", $instance5))
  let $instance5 := setup:eval(
    function() {
      model:new($model5, $instance5)
    }
  )
  let $_ := xdmp:log(("$instance5", $instance5))
  return (
    assert:not-empty($instance5/*:model1)
  )
};
