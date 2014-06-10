xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-crud-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $INSTANCE1 := 
<model1 xmlns="http://marklogic.com/model/model1">
  <id>crud-model1-id</id>
  <name>crud-model1-name</name>
</model1>
;

declare variable $INSTANCE2 := 
<model2 xmlns="http://marklogic.com/model/model2">
  <id>model2-id</id>
  <name>model2-name</name>
</model2>
;

declare variable $INSTANCE4 := 
<model4 xmlns="http://marklogic.com/model/model4">
  <id>model4-id</id>
  <name>model4-name</name>
</model4>
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

declare %test:case function model1-model2-exist-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $model2 := domain:get-model("model2")
  return (
    assert:not-empty($model1),
    assert:not-empty($model2)
  )
};

declare %test:case function model-document-new-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $instance1 := model:new(
    $model1, 
    map:new((
      map:entry("id", "1234"),
      map:entry("name", "name-1")
    ))
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model1, "id"), $instance1)
  let $value-name := domain:get-field-value(domain:get-model-field($model1, "name"), $instance1)
  return (
    assert:not-empty($instance1),
    assert:equal("1234", xs:string($value-id)),
    assert:equal("name-1", xs:string($value-name))
  )
};

declare %test:case function model-directory-new-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $instance4 := model:new(
    $model4,
    $INSTANCE4
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model4, "id"), $instance4)
  let $value-name := domain:get-field-value(domain:get-model-field($model4, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:equal("model4-id", xs:string($value-id)),
    assert:equal("model4-name", xs:string($value-name))
  )
};

(: Require element range index for keyLabel :)
declare %test:ignore function model-directory-create-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $instance4 := eval(
    function() {
      model:create(
        $model4, 
        $INSTANCE4,
        $TEST-COLLECTION
      )
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model4, "id"), $instance4)
  let $value-name := domain:get-field-value(domain:get-model-field($model4, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:equal("model4-id", xs:string($value-id)),
    assert:equal("model4-name", xs:string($value-name))
  )
};

declare %private function eval($fn as function(*)) {
  xdmp:apply($fn)

(:  xdmp:invoke-function(
    function() {
      xdmp:apply($fn)
      ,
      xdmp:commit()
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
      <prevent-deadlocks>true</prevent-deadlocks>
    </options>
  )
:)
};

declare %test:case function model-document-update-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $identity-field := domain:get-model-identity-field($model1)
  let $name-field := domain:get-model-field($model1, "name")
  let $find := model:find(
    $model1, 
    map:new((
      map:entry("id", "crud-model1-id")
    ))
  )
  let $identity-value := xs:string(domain:get-field-value($identity-field, $find))
  let $update1 := eval(
    function() {
      model:update(
        $model1, 
        map:new((
          map:entry("uuid", $identity-value),
          map:entry("name", "new-name")
        )), 
        $TEST-COLLECTION
      )
    }
  )
  let $find := model:find(
    $model1, 
    map:new((
      map:entry("id", "crud-model1-id")
    ))
  )
  return (
    assert:equal(fn:count($find), 1),
    assert:not-empty($update1),
    assert:equal("new-name", xs:string(domain:get-field-value($name-field, $update1)))
  )
};

declare %test:case function model-document-create-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $instance1 := eval(
    function() {
      model:create(
        $model1, 
        map:new((
          map:entry("id", "1234"),
          map:entry("name", "name-1")
        )), 
        $TEST-COLLECTION
      )
    }
  )
(:  let $instance1 := model:create(
    $model1, 
    map:new((
      map:entry("id", "1234"),
      map:entry("name", "name-1")
    )), 
    $TEST-COLLECTION
  )
:)  let $value-id := domain:get-field-value(domain:get-model-field($model1, "id"), $instance1)
  let $value-name := domain:get-field-value(domain:get-model-field($model1, "name"), $instance1)
  return (
    assert:not-empty($instance1),
    assert:equal("1234", xs:string($value-id)),
    assert:equal("name-1", xs:string($value-name))
  )
};

declare %test:case function model-document-create-from-xml-with-attribute-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := eval(
    function() {
      model:create(
        $model6, 
        <model6 xmlns="http://marklogic.com/model/test" score="10" id="666666">
          <name>name-6</name>
        </model6>
        , 
        $TEST-COLLECTION
      )
    }
  )

  let $value-id := domain:get-field-value(domain:get-model-field($model6, "id"), $instance6)
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  let $value-name := domain:get-field-value(domain:get-model-field($model6, "name"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:equal("666666", xs:string($value-id)),
    assert:equal(10, xs:integer($value-score)),
    assert:equal("name-6", xs:string($value-name))
  )
};

declare %test:case function model-document-create-from-map-with-attribute-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := eval(
    function() {
      model:create(
        $model6, 
        map:new((
          map:entry("id", "66666666"),
          map:entry("score", 10),
          map:entry("name", "name-6")
        )), 
        $TEST-COLLECTION
      )
    }
  )

  let $_ := xdmp:log(("$instance6", $instance6))
  let $value-id := domain:get-field-value(domain:get-model-field($model6, "id"), $instance6)
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  let $value-name := domain:get-field-value(domain:get-model-field($model6, "name"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:equal("66666666", xs:string($value-id)),
    assert:equal(10, xs:integer($value-score)),
    assert:equal("name-6", xs:string($value-name))
  )
};

declare %test:case function model-document-create-from-xml-with-integer-attribute-test() as item()*
{
  let $model7 := domain:get-model("model7")
  let $instance7 := eval(
    function() {
      model:create(
        $model7, 
        <model7 xmlns="http://marklogic.com/model/test" score="10" id="777777">
          <name>name-7</name>
        </model7>
        , 
        $TEST-COLLECTION
      )
    }
  )

  let $_ := xdmp:log(("$instance7", $instance7))
  let $value-id := domain:get-field-value(domain:get-model-field($model7, "id"), $instance7)
  let $value-score := domain:get-field-value(domain:get-model-field($model7, "score"), $instance7)
  let $value-name := domain:get-field-value(domain:get-model-field($model7, "name"), $instance7)
  return (
    assert:not-empty($instance7),
    assert:equal("777777", xs:string($value-id)),
    assert:equal(10, xs:integer($value-score)),
    assert:equal("name-7", xs:string($value-name))
  )
};

declare %test:case function model-document-create-from-map-with-integer-attribute-test() as item()*
{
  let $model7 := domain:get-model("model7")
  let $instance7 := eval(
    function() {
      model:create(
        $model7, 
        map:new((
          map:entry("id", "77777777"),
          map:entry("score", 10),
          map:entry("name", "name-7")
        )), 
        $TEST-COLLECTION
      )
    }
  )

  let $_ := xdmp:log(("$instance6", $instance7))
  let $value-id := domain:get-field-value(domain:get-model-field($model7, "id"), $instance7)
  let $value-score := domain:get-field-value(domain:get-model-field($model7, "score"), $instance7)
  let $value-name := domain:get-field-value(domain:get-model-field($model7, "name"), $instance7)
  return (
    assert:not-empty($instance7),
    assert:equal("77777777", xs:string($value-id)),
    assert:equal(10, xs:integer($value-score)),
    assert:equal("name-7", xs:string($value-name))
  )
};

(:declare %test:case function get-model-references-test() as item()*
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
:)
