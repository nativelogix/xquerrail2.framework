xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace context = "http://xquerrail.com/context" at "../../../../main/_framework/context.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace model1 = "http://marklogic.com/model/model1";
declare namespace model5 = "http://marklogic.com/model/model5";
declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-crud-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $INSTANCE1 := (
<model1 xmlns="http://marklogic.com/model/model1">
  <id>crud-model1-id</id>
  <name>crud-model1-name</name>
</model1>
);

declare variable $INSTANCE2 :=
<model2 xmlns="http://marklogic.com/model/model2">
  <id>model2-id</id>
  <name>model2-name</name>
</model2>
;

declare variable $INSTANCES4 := (
  <model4 xmlns="http://marklogic.com/model/model4">
    <id>crud-model4-id-delete</id>
    <name>crud-model4-name-delete</name>
  </model4>
  ,
  <model4 xmlns="http://marklogic.com/model/model4">
    <id>partial-update-model4-id</id>
    <name>partial-update-model4-name</name>
  </model4>
  ,
  <model4 xmlns="http://marklogic.com/model/model4">
    <id>partial-update-empty-field-map-model4-id</id>
    <name>partial-update-empty-field-model4-name</name>
  </model4>
  ,
  <model4 xmlns="http://marklogic.com/model/model4">
    <id>partial-update-empty-field-xml-model4-id</id>
    <name>partial-update-empty-field-model4-name</name>
  </model4>
  ,
  <model4 xmlns="http://marklogic.com/model/model4">
    <id>partial-update-empty-field-json-model4-id</id>
    <name>partial-update-empty-field-model4-name</name>
  </model4>
)
;

declare variable $INSTANCES5 := (
<model5 xmlns="http://marklogic.com/model/model5">
  <id>model5-id-1</id>
  <name>model5-name-1</name>
</model5>
,
<model5 xmlns="http://marklogic.com/model/model5">
  <id>model5-id-2</id>
  <name>model5-name-2</name>
</model5>
);

declare variable $INSTANCES6 := (
<model6 xmlns="http://xquerrail.com/app-test" id="partial-update-empty-attribute-xml-model6-id" score="1">
  <name>model6-name-1</name>
</model6>
,
<model6 xmlns="http://xquerrail.com/app-test" id="partial-update-empty-attribute-map-model6-id" score="2">
  <name>model6-name-2</name>
</model6>
,
<model6 xmlns="http://xquerrail.com/app-test" id="partial-update-empty-attribute-json-model6-id" score="3">
  <name>model6-name-3</name>
</model6>
);

declare variable $INSTANCE11 :=
<model11 xmlns="http://xquerrail.com/app-test">
  <id>model11-id</id>
  <abstract name="model11-abstract-name" />
  <child childId="child-id-model11" />
</model11>
;

declare variable $INSTANCES15 := (
<model15 xmlns="http://xquerrail.com/app-test">
  <id>partial-update-empty-array-xml-model15-id</id>
  <groups>
    <group>model15-group-1</group>
  </groups>
</model15>
,
<model15 xmlns="http://xquerrail.com/app-test">
  <id>partial-update-empty-array-map-model15-id</id>
  <groups>
    <group>model15-group-1</group>
  </groups>
</model15>
,
<model15 xmlns="http://xquerrail.com/app-test">
  <id>partial-update-empty-array-json-model15-id</id>
  <groups>
    <group>model15-group-1</group>
  </groups>
</model15>
);

declare variable $INSTANCES19 := (
<model19 xmlns="http://xquerrail.com/app-test">
  <name>model19-name-append</name>
  <abstractList>
    <abstract name="model19-abstract-name-append" />
  </abstractList>
</model19>
,
<model19 xmlns="http://xquerrail.com/app-test">
  <name>model19-name-prepend</name>
  <abstractList>
    <abstract name="model19-abstract-name-prepend" />
  </abstractList>
</model19>
);

declare variable $CHILD-INSTANCES := (
<child-model xmlns="http://xquerrail.com/app-test">
  <name>child-model-1</name>
  <parent>parent-model-1</parent>
</child-model>
,
<child-model xmlns="http://xquerrail.com/app-test">
  <name>child-model-2</name>
  <parent>parent-model-1</parent>
  <parent>parent-model-2</parent>
</child-model>
,
<child-model xmlns="http://xquerrail.com/app-test">
  <name>child-model-3</name>
  <parent>parent-model-2</parent>
  <parent>parent-model-3</parent>
</child-model>
);

declare variable $PARENT-INSTANCES := (
<parent-model xmlns="http://xquerrail.com/app-test">
  <name>parent-model-1</name>
</parent-model>
,
<parent-model xmlns="http://xquerrail.com/app-test">
  <name>parent-model-2</name>
</parent-model>
,
<parent-model xmlns="http://xquerrail.com/app-test">
  <name>parent-model-3</name>
</parent-model>
);

declare variable $INSTANCES23 := (
<model23 xmlns="http://xquerrail.com/app-test">
  <name>model23-name-with-default</name>
</model23>
,
<model23 xmlns="http://xquerrail.com/app-test" description="no-default">
  <name>model23-name-no-default</name>
  <comment>no-default</comment>
</model23>
,
<model23 xmlns="http://xquerrail.com/app-test">
  <name>model23-name-default-attribute</name>
  <comment>no-default</comment>
</model23>
);

declare variable $CONFIG := ();

declare %test:setup function setup() {
  let $_ := setup:setup($TEST-APPLICATION)
  let $model1 := domain:get-model("model1")
  let $_ := setup:invoke(
      function() {
        model:create($model1, $INSTANCE1, $TEST-COLLECTION)
      }
    )
  let $_ := setup:create-instances("model4", $INSTANCES4, $TEST-COLLECTION)
  let $model5 := domain:get-model("model5")
  let $_ := for $instance in $INSTANCES5 return (
    setup:invoke(
      function() {
        model:create($model5, $instance, $TEST-COLLECTION)
      }
    )
  )
  let $model6 := domain:get-model("model6")
  let $_ := for $instance in $INSTANCES6 return (
    setup:invoke(
      function() {
        model:create($model6, $instance, $TEST-COLLECTION)
      }
    )
  )
  let $model15 := domain:get-model("model15")
  let $_ := for $instance in $INSTANCES15 return (
    setup:invoke(
      function() {
        model:create($model15, $instance, $TEST-COLLECTION)
      }
    )
  )
  let $model19 := domain:get-model("model19")
  let $_ := for $instance in $INSTANCES19 return (
    setup:invoke(
      function() {
        model:create($model19, $instance, $TEST-COLLECTION)
      }
    )
  )
  let $model23 := domain:get-model("model23")
  let $_ := for $instance in $INSTANCES23 return (
    setup:invoke(
      function() {
        model:create($model23, $instance, $TEST-COLLECTION)
      }
    )
  )
  let $parent-model := domain:get-model("parent-model")
  let $_ := for $instance in $PARENT-INSTANCES return (
    setup:invoke(
      function() {
        model:create($parent-model, $instance, $TEST-COLLECTION)
      }
    )
  )
  let $child-model := domain:get-model("child-model")
  let $_ := for $instance in $CHILD-INSTANCES return (
    setup:invoke(
      function() {
        model:create($child-model, $instance, $TEST-COLLECTION)
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

declare %test:case function model-get-from-key-label-test() as item()*
{
  let $key-label := $INSTANCES5[1]/model5:id/fn:string()
  let $model5 := domain:get-model("model5")
  let $instance := model:get($model5, $key-label)
  return (
    assert:not-empty($instance)
  )
};

declare %test:case function model-get-from-uri-test() as item()*
{
  let $key-label := $INSTANCES5[1]/model5:id/fn:string()
  let $model5 := domain:get-model("model5")
  let $instance := model:get($model5, $key-label)
  let $instance := model:get($model5, map:entry("uri", xdmp:node-uri($instance)))
  return (
    assert:not-empty($instance)
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
  let $instance4 :=
  <model4 xmlns="http://marklogic.com/model/model4">
    <id>model4-id</id>
    <name>model4-name</name>
  </model4>

  let $instance4 := model:new(
    $model4,
    $instance4
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model4, "id"), $instance4)
  let $value-name := domain:get-field-value(domain:get-model-field($model4, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:equal("model4-id", xs:string($value-id)),
    assert:equal("model4-name", xs:string($value-name))
  )
};

declare %test:case function model-directory-element-attribute-new-test() as item()*
{
  let $model11 := domain:get-model("model11")
  let $instance11 := model:new(
    $model11,
    $INSTANCE11
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model11, "id"), $instance11)
  let $value-child-id := domain:get-field-value(domain:get-model-field($model11, "childId"), $instance11)
  let $abstract-value := domain:get-field-value(domain:get-model-field($model11, "abstract"), $instance11)
  let $abstract-name-value := domain:get-field-value(domain:get-model-field(domain:get-model("abstract2"), "name"), $abstract-value)
  return (
    assert:not-empty($instance11),
    assert:equal("model11-id", xs:string($value-id)),
    assert:equal("child-id-model11", xs:string($value-child-id)),
    assert:equal("model11-abstract-name", xs:string($abstract-name-value))
  )
};

declare %test:case function model-document-new-keep-identity-test() as item()*
{
  let $random := setup:random()
  let $model1 := domain:get-model("model1")
  let $instance1 := model:new(
    $model1,
    map:new((
      map:entry("uuid", $random),
      map:entry("id", "id-" || $random),
      map:entry("name", "name-" || $random)
    ))
  )
  let $identity-value := xs:string(domain:get-field-value(domain:get-model-identity-field($model1), $instance1))
  return (
    assert:not-empty($instance1),
    assert:equal($identity-value, $random, "uuid must be equal to " || $random)
  )
};

declare %test:case function model-document-new-create-keep-identity-test() as item()*
{
  let $random := setup:random()
  let $model1 := domain:get-model("model1")
  let $new-instance1 := model:new(
    $model1,
    map:new((
      map:entry("id", "id-" || $random),
      map:entry("name", "name-" || $random)
    ))
  )
  let $identity-value := xs:string(domain:get-field-value(domain:get-model-identity-field($model1), $new-instance1))

  let $instance1 := setup:eval(
    function() {
      model:create(
        $model1,
        $new-instance1,
        $TEST-COLLECTION
      )
    }
  )

  return (
    assert:not-empty($instance1),
    assert:equal($identity-value, xs:string(domain:get-field-value(domain:get-model-identity-field($model1), $instance1)))
  )
};

(: Require element range index for keyLabel :)
declare %test:case function model-directory-create-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $instance4 :=
  <model4 xmlns="http://marklogic.com/model/model4">
    <id>model4-id</id>
    <name>model4-name</name>
  </model4>
  let $instance4 := setup:eval(
    function() {
      model:create(
        $model4,
        $instance4,
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
  let $update1 := setup:eval(
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

declare %test:case function model-directory-partial-update-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $instance4 := model:find(
    $model4,
    map:entry("id", "partial-update-model4-id")
  )
  let $name := setup:random("model4-name")
  let $instance4 := setup:eval(
    function() {
      model:update(
        $model4,
        map:new((
          map:entry("id", "partial-update-model4-id"),
          map:entry("name", $name)
        )),
        (),
        fn:true()
      )
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model4, "id"), $instance4)
  let $value-name := domain:get-field-value(domain:get-model-field($model4, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:equal($name, $value-name, "name must equal " || $name)
  )
};

declare %test:case function model-partial-update-map-empty-field-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $instance4 := setup:eval(
    function() {
      model:update(
        $model4,
        map:new((
          map:entry("id", "partial-update-empty-field-map-model4-id"),
          map:entry("name", "")
        )),
        (),
        fn:true()
      )
    }
  )
  let $value-name := domain:get-field-value(domain:get-model-field($model4, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:empty($value-name, "name must be empty")
  )
};

declare %test:case function model-partial-update-xml-empty-field-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $instance4 := setup:eval(
    function() {
      model:update(
        $model4,
        <model4 xmlns="http://marklogic.com/model/model4">
          <id>partial-update-empty-field-xml-model4-id</id>
          <name></name>
        </model4>,
        (),
        fn:true()
      )
    }
  )
  let $value-name := domain:get-field-value(domain:get-model-field($model4, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:empty($value-name, "name must be empty")
  )
};

declare %test:case function model-partial-update-json-empty-field-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $instance4 := setup:eval(
    function() {
      model:update(
        $model4,
        xdmp:from-json('{"id": "partial-update-empty-field-json-model4-id", "name": ""}'),
        (),
        fn:true()
      )
    }
  )
  let $value-name := domain:get-field-value(domain:get-model-field($model4, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:empty($value-name, "name must be empty")
  )
};

declare %test:case function model-partial-update-map-empty-attribute-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := setup:eval(
    function() {
      model:update(
        $model6,
        map:new((
          map:entry("id", "partial-update-empty-attribute-map-model6-id"),
          map:entry("score", "")
        )),
        (),
        fn:true()
      )
    }
  )
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:equal(xs:string($value-score), "", "score must be empty string")
  )
};

declare %test:case function model-partial-update-xml-empty-attribute-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := setup:eval(
    function() {
      model:update(
        $model6,
        <model6 xmlns="http://xquerrail.com/app-test" id="partial-update-empty-attribute-xml-model6-id" score="">
        </model6>,
        (),
        fn:true()
      )
    }
  )
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:equal(xs:string($value-score), "", "score must be empty string")
  )
};

declare %test:case function model-partial-update-json-empty-attribute-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := setup:eval(
    function() {
      model:update(
        $model6,
        xdmp:from-json('{"' || config:attribute-prefix() || 'id": "partial-update-empty-attribute-json-model6-id", "' || config:attribute-prefix() || 'score": ""}'),
        (),
        fn:true()
      )
    }
  )
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:equal(xs:string($value-score), "", "score must be empty string")
  )
};

(:declare %test:case function model-partial-update-map-empty-array-test() as item()*
{
  let $model10 := domain:get-model("model10")
  let $instance4 := setup:eval(
    function() {
      model:update(
        $model10,
        map:new((
          map:entry("id", "partial-update-empty-array-map-model10-id"),
          map:entry("name", "")
        )),
        (),
        fn:true()
      )
    }
  )
  let $value-name := domain:get-field-value(domain:get-model-field($model10, "name"), $instance4)
  return (
    assert:not-empty($instance4),
    assert:empty($value-name, "name must be empty")
  )
};
:)
declare %test:case function model-partial-update-xml-empty-array-test() as item()*
{
  let $model15 := domain:get-model("model15")
  let $instance15 := setup:eval(
    function() {
      model:update(
        $model15,
        <model15 xmlns="http://xquerrail.com/app-test">
          <id>partial-update-empty-array-xml-model15-id</id>
          <groups><group/></groups>
        </model15>,
        (),
        fn:true()
      )
    }
  )
  let $value-group := domain:get-field-value(domain:get-model-field($model15, "group"), $instance15)
  return (
    assert:not-empty($instance15),
    assert:empty($value-group, "group must be empty")
  )
};

declare %test:case function model-partial-update-json-empty-array-test() as item()*
{
  let $model15 := domain:get-model("model15")
  let $instance15 := setup:eval(
    function() {
      model:update(
        $model15,
        xdmp:from-json('{"id": "partial-update-empty-array-json-model15-id", "groups": {"group": []}}'),
        (),
        fn:true()
      )
    }
  )
  let $value-group := domain:get-field-value(domain:get-model-field($model15, "group"), $instance15)
  return (
    assert:not-empty($instance15),
    assert:empty($value-group, "name must be empty")
  )
};

declare %test:case function model-document-new-different-namespace-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $instance1 := setup:eval(
    function() {
      model:new(
        $model1,
        map:new((
          map:entry("id", "1234"),
          map:entry("name", "name-1")
        ))
      )
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model1, "id"), $instance1)
  let $value-name := domain:get-field-value(domain:get-model-field($model1, "name"), $instance1)
  return (
    assert:not-empty($instance1, "instance1 should not be empty"),
    assert:not-empty($instance1/model1:uuid, "model1:uuid should no be empty"),
    assert:not-empty($instance1/model1:create-user, "model1:create-user should no be empty")
  )
};

declare %test:case function model-document-create-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $instance1 := setup:eval(
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
  let $value-id := domain:get-field-value(domain:get-model-field($model1, "id"), $instance1)
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
  let $instance6 := setup:eval(
    function() {
      model:create(
        $model6,
        <model6 xmlns="http://xquerrail.com/app-test" score="10" id="666666">
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
  let $instance6 := setup:eval(
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

declare %test:case function model-find-by-attribute-test() as item()*
{
  let $id := setup:random()
  let $model6 := domain:get-model("model6")
  let $instance6 := setup:invoke(
    function() {
      model:create(
        $model6,
        map:new((
          map:entry("id", $id),
          map:entry("score", 10),
          map:entry("name", "name-6")
        )),
        $TEST-COLLECTION
      )
    }
  )

  let $instance6 := model:find(
    $model6,
    map:new((
      map:entry("id", $id)
(:      map:entry("name", "name-6"):)
    ))
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model6, "id"), $instance6)
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  let $value-name := domain:get-field-value(domain:get-model-field($model6, "name"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:equal($id, xs:string($value-id)),
    assert:equal(10, xs:integer($value-score)),
    assert:equal("name-6", xs:string($value-name))
  )
};

declare %test:case function model-document-create-from-xml-with-integer-attribute-test() as item()*
{
  let $model7 := domain:get-model("model7")
  let $instance7 := setup:eval(
    function() {
      model:create(
        $model7,
        <model7 xmlns="http://xquerrail.com/app-test" score="10" id="777777">
          <name>name-7</name>
        </model7>
        ,
        $TEST-COLLECTION
      )
    }
  )

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
  let $instance7 := setup:eval(
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

declare %test:case function model-document-create-multiple-reference-instances-test() as item()*
{
  let $version-model := domain:get-model("version")
  let $model10 := domain:get-model("model10")

  let $version1 := model:new(
    $version-model,
    map:new((
      map:entry("version", 1),
      map:entry("action", "new")
    ))
  )

  let $version2 := model:new(
    $version-model,
    map:new((
      map:entry("version", 2),
      map:entry("action", "update")
    ))
  )

  let $instance10 := setup:eval(
    function() {
      model:create(
        $model10,
        map:new((
          map:entry("id", "10101010"),
          map:entry("version", ($version1, $version2))
        )),
        $TEST-COLLECTION
      )
    }
  )

  let $value-id := domain:get-field-value(domain:get-model-field($model10, "id"), $instance10)
  let $value-version := domain:get-field-value(domain:get-model-field($model10, "version"), $instance10)

  return (
    assert:not-empty($instance10),
    assert:equal("10101010", xs:string($value-id)),
    assert:equal(2, fn:count($value-version))
  )
};

declare %test:case function model-document-binary-with-directory-binary-create() as item()*
{
  let $model12 := domain:get-model("model12")
  let $id := "id12-" || xdmp:random()
  let $binary := binary{ xs:hexBinary("DEADBEEF") }
  let $instance12 := setup:invoke(
    function() {
      model:create(
        $model12,
        map:new((
          map:entry("id", $id),
          map:entry("file", $binary)
        )),
        $TEST-COLLECTION
      ),
      xdmp:commit()
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model12, "id"), $instance12)
  let $value-file := domain:get-field-value(domain:get-model-field($model12, "file"), $instance12)
  return (
    assert:not-empty($instance12),
    assert:equal($id, xs:string($value-id)),
    assert:equal( xdmp:binary-decode($binary, "UTF-8"), xdmp:binary-decode(fn:doc(xs:string($value-file)), "UTF-8"))
  )
};

declare %test:case function model-document-binary-with-file-uri-create() as item()*
{
  let $model13 := domain:get-model("model13")
  let $id := "id13-" || xdmp:random()
  let $binary := binary{ xs:hexBinary("DEADBEEF") }
  let $instance13 := setup:invoke(
    function() {
      model:create(
        $model13,
        map:new((
          map:entry("id", $id),
          map:entry("file", $binary)
        )),
        $TEST-COLLECTION
      ),
      xdmp:commit()
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model13, "id"), $instance13)
  let $value-file := domain:get-field-value(domain:get-model-field($model13, "file"), $instance13)
  return (
    assert:not-empty($instance13),
    assert:equal($id, xs:string($value-id)),
    assert:equal( xdmp:binary-decode($binary, "UTF-8"), xdmp:binary-decode(fn:doc(xs:string($value-file)), "UTF-8"))
  )
};

declare %test:case function model-document-binary-with-filename-content-type-create() as item()*
{
  let $model13 := domain:get-model("model13")
  let $id := "id13-" || xdmp:random()
  let $text := "Testing binary Constructor"
  let $filename := "dummy.txt"
  let $content-type := "text/plain"
  let $binary := binary { string-join(string-to-codepoints($text) ! (xdmp:integer-to-hex(.)), "") }
  let $instance13 := setup:invoke(
    function() {
      model:create(
        $model13,
        map:new((
          map:entry("id", $id),
          map:entry("file", $binary),
          map:entry(fn:concat("file", "_filename"), $filename),
          map:entry(fn:concat("file", "_content-type"), $content-type)
        )),
        $TEST-COLLECTION
      ),
      xdmp:commit()
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model13, "id"), $instance13)
  let $value-file := domain:get-field-value(domain:get-model-field($model13, "file"), $instance13)
  return (
    assert:not-empty($instance13),
    assert:equal($id, xs:string($value-id)),
    assert:equal( xdmp:binary-decode($binary, "UTF-8"), xdmp:binary-decode(fn:doc(xs:string($value-file)), "UTF-8")),
    assert:equal( $content-type, xs:string($value-file/@content-type)),
    assert:equal( $filename, xs:string($value-file/@filename))
  )
};

declare %test:case function model-directory-container-multiple-instance-element-with-attributes-new() as item()*
{
  let $model14 := domain:get-model("model14")
  let $group-model := domain:get-model("group")
  let $id := "id14-" || xdmp:random()
  let $group1 := model:new(
    $group-model,
    map:new((
      map:entry("seq", "seq1"),
      map:entry("count", 1),
      map:entry("text", "This is a text")
    ))
  )
  let $group2 := model:new(
    $group-model,
    map:new((
      map:entry("seq", "seq2"),
      map:entry("count", 2),
      map:entry("text", "This is a text")
    ))
  )
  let $instance14 := setup:invoke(
    function() {
      model:create(
        $model14,
        element { xs:QName("app-test:model14") } {
          element { xs:QName("app-test:id") } { $id },
          element { xs:QName("app-test:groups") } {
            (
              $group1, $group2
            )
          }
        },
        $TEST-COLLECTION
      ),
      xdmp:commit()
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model14, "id"), $instance14)
  let $value-group := domain:get-field-value(domain:get-model-field($model14, "group"), $instance14)
  return (
    assert:not-empty($instance14),
    assert:equal($id, xs:string($value-id)),
    assert:equal( fn:count($value-group), 2)
  )
};

declare %test:case function model-directory-container-multiple-element-with-attributes-new() as item()*
{
  let $model15 := domain:get-model("model15")
  let $id := "id15-" || xdmp:random()
  let $instance15 := setup:invoke(
    function() {
      model:create(
        $model15,
        element { xs:QName("app-test:model15") } {
          element { xs:QName("app-test:id") } { $id },
          element { xs:QName("app-test:groups") } {
            element { xs:QName("app-test:group") } {
              attribute seq { "seq1"},
              attribute count { 1 },
              "this is group1"
            },
            element { xs:QName("app-test:group") } {
              attribute seq { "seq2"},
              attribute count { 2 },
              "this is group2"
            }
          }
        },
        $TEST-COLLECTION
      ),
      xdmp:commit()
    }
  )
  let $value-id := domain:get-field-value(domain:get-model-field($model15, "id"), $instance15)
  let $value-group := domain:get-field-value(domain:get-model-field($model15, "group"), $instance15)
  let $value-seq := domain:get-field-value(domain:get-model-field($model15, "seq"), $instance15)
  return (
    assert:not-empty($instance15),
    assert:equal($id, xs:string($value-id)),
    assert:equal( fn:count($value-group), 2),
    assert:equal( fn:count($value-seq), 2),
    assert:equal( $value-seq[1], "seq1"),
    assert:equal( $value-seq[2], "seq2")
  )
};

declare %test:case function get-model-generate-uri-test() as item()*
{
  let $id := "model16-" || xdmp:random()
  let $model16 := domain:get-model("model16")
  let $uri := model:generate-uri(
    $model16/domain:directory,
    $model16,
    map:new((
      map:entry("id", $id),
      map:entry("name", "name-16")
    ))
    )
  return (
    assert:equal($uri, "/test/model16/" || $id)
  )
};

declare %test:case function model-new-xml-attribute-empty-string-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := model:new(
    $model6,
    <model6 id="model6-id" score="" xmlns="http://xquerrail.com/app-test">
      <name>model6-name</name>
    </model6>
  )
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:not-empty($value-score),
    assert:equal("", xs:string($value-score))
  )
};

declare %test:case function model-new-map-attribute-empty-string-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := model:new(
    $model6,
    map:new((
      map:entry("id", "model6-id"),
      map:entry("score", ""),
      map:entry("name", "model6-name")
    ))
  )
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:not-empty($value-score),
    assert:equal("", xs:string($value-score))
  )
};

declare %test:case function model-new-xml-attribute-no-value-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := model:new(
    $model6,
    <model6 id="model6-id" xmlns="http://xquerrail.com/app-test">
      <name>model6-name</name>
    </model6>
  )
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:empty($value-score)
  )
};

declare %test:case function model-new-map-attribute-no-value-test() as item()*
{
  let $model6 := domain:get-model("model6")
  let $instance6 := model:new(
    $model6,
    map:new((
      map:entry("id", "model6-id"),
      map:entry("score", ()),
      map:entry("name", "model6-name")
    ))
  )
  let $value-score := domain:get-field-value(domain:get-model-field($model6, "score"), $instance6)
  return (
    assert:not-empty($instance6),
    assert:empty($value-score, "score field is be empty"),
    assert:empty($instance6/@score, "score attribute is be empty")
  )
};

declare %test:case function model-new-xml-element-occurrence-question-mark-test() as item()*
{
  let $model17 := domain:get-model("model17")
  let $instance17 := model:new(
    $model17,
    <model17 id="model17-id" xmlns="http://xquerrail.com/app-test">
    </model17>
  )
  let $element-question-mark-value := domain:get-field-value(domain:get-model-field($model17, "element-question-mark"), $instance17)
  let $element-plus-value := domain:get-field-value(domain:get-model-field($model17, "element-plus"), $instance17)
  return (
    assert:not-empty($instance17),
    assert:empty($element-question-mark-value),
    assert:empty($instance17/*:element-question-mark, "element-question-mark should not exist"),
    assert:empty($element-plus-value),
    assert:not-empty($instance17/*:element-plus, "element-plus should exist")
  )
};

declare %test:case function model-new-xml-element-occurrence-star-test() as item()*
{
  let $model17 := domain:get-model("model17")
  let $instance17 := model:new(
    $model17,
    <model17 id="model17-id" xmlns="http://xquerrail.com/app-test">
    </model17>
  )
  let $element-plus-value := domain:get-field-value(domain:get-model-field($model17, "element-plus"), $instance17)
  let $element-star-value := domain:get-field-value(domain:get-model-field($model17, "element-star"), $instance17)
  return (
    assert:not-empty($instance17),
    assert:empty($element-plus-value),
    assert:empty($instance17/*:element-star, "element-star should not exist"),
    assert:empty($element-star-value),
    assert:not-empty($instance17/*:element-plus, "element-plus should exist")
  )
};

declare %test:case function model-new-xml-attribute-occurrence-question-mark-test() as item()*
{
  let $model17 := domain:get-model("model17")
  let $instance17 := model:new(
    $model17,
    <model17 id="model17-id" xmlns="http://xquerrail.com/app-test">
    </model17>
  )
  let $attribute-question-mark-value := domain:get-field-value(domain:get-model-field($model17, "attribute-question-mark"), $instance17)
  return (
    assert:not-empty($instance17),
    assert:empty($attribute-question-mark-value, "domain:get-field-value - attribute-question-mark should not exist"),
    assert:empty($instance17/@attribute-question-mark, "attribute-question-mark should not exist")
  )
};

declare %test:case function model-new-xml-attribute-occurrence-star-test() as item()*
{
  let $model17 := domain:get-model("model17")
  let $instance17 := model:new(
    $model17,
    <model17 id="model17-id" xmlns="http://xquerrail.com/app-test">
    </model17>
  )
  let $attribute-star-value := domain:get-field-value(domain:get-model-field($model17, "attribute-star"), $instance17)
  return (
    assert:not-empty($instance17),
    assert:empty($attribute-star-value, "domain:get-field-value - attribute-star should not exist"),
    assert:empty($instance17/@attribute-star, "attribute-star should not exist")
  )
};

declare %test:case function model-new-xml-attribute-occurrence-plus-test() as item()*
{
  let $model17 := domain:get-model("model17")
  let $instance17 := model:new(
    $model17,
    <model17 id="model17-id" xmlns="http://xquerrail.com/app-test">
    </model17>
  )
  let $attribute-plus-value := domain:get-field-value(domain:get-model-field($model17, "attribute-plus"), $instance17)
  return (
    assert:not-empty($instance17),
    assert:not-empty($attribute-plus-value, "domain:get-field-value - attribute-plus should exist"),
    assert:not-empty($instance17/@attribute-plus, "attribute-plus should exist")
  )
};

declare %test:case function model-document-new-custom-user-context-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $user-test := "user-test"
  let $_ := context:user($user-test)
  let $instance1 := model:new(
    $model1,
    map:new((
      map:entry("id", "1234"),
      map:entry("name", "name-1")
    ))
  )
  let $create-user-value := domain:get-field-value(domain:get-model-field($model1, "create-user"), $instance1)
  return (
    assert:not-empty($instance1),
    assert:equal($user-test, xs:string($create-user-value))
  )
};

declare %test:case function model-append-new-item-container-element-with-id-test() as item()*
{
  let $model19 := domain:get-model("model19")
  let $model-abstract2 := domain:get-model("abstract2")
  let $instance19 := model:get($model19, "model19-name-append")
  let $instance19 := model:convert-to-map($model19, $instance19)
  let $new-abstract-value-name := "abstract-" || setup:random()
  let $abstract-value := domain:get-field-value(domain:get-model-field($model19, "abstractList.abstract"), $instance19)
  let $abstract-value-id := domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $abstract-value)
  let $abstract-value-name := domain:get-field-value(domain:get-model-field($model-abstract2, "name"), $abstract-value)
  let $abstract-value := (
    $abstract-value,
    model:new(
      $model-abstract2,
      map:new((
        map:entry("name", $new-abstract-value-name)
      ))
    )
  )
  let $_ := map:put(
    $instance19,
    "abstractList.abstract",
    $abstract-value
  )
  let $instance19 := model:update($model19, $instance19)
  let $new-abstract-value := domain:get-field-value(domain:get-model-field($model19, "abstractList.abstract"), $instance19)
  return (
    assert:not-empty($instance19),
    assert:equal($abstract-value-id, domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $new-abstract-value[1])),
    assert:equal($abstract-value-name, domain:get-field-value(domain:get-model-field($model-abstract2, "name"), $new-abstract-value[1])),
    assert:equal($new-abstract-value-name, domain:get-field-value(domain:get-model-field($model-abstract2, "name"), $new-abstract-value[2])),
    assert:not-equal(
      domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $new-abstract-value[1]),
      domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $new-abstract-value[2])
    ),
    assert:not-equal($abstract-value-name, $new-abstract-value-name)
  )
};

declare %test:case function model-prepend-new-item-container-element-with-id-test() as item()*
{
  let $model19 := domain:get-model("model19")
  let $model-abstract2 := domain:get-model("abstract2")
  let $instance19 := model:get($model19, "model19-name-prepend")
  let $instance19 := model:convert-to-map($model19, $instance19)
  let $new-abstract-value-name := "abstract-" || setup:random()
  let $abstract-value := domain:get-field-value(domain:get-model-field($model19, "abstractList.abstract"), $instance19)
  let $abstract-value-id := domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $abstract-value)
  let $abstract-value-name := domain:get-field-value(domain:get-model-field($model-abstract2, "name"), $abstract-value)
  let $abstract-value := (
    model:new(
      $model-abstract2,
      map:new((
        map:entry("name", $new-abstract-value-name)
      ))
    ),
    $abstract-value
  )
  let $_ := map:put(
    $instance19,
    "abstractList.abstract",
    $abstract-value
  )
  let $instance19 := model:update($model19, $instance19)
  let $new-abstract-value := domain:get-field-value(domain:get-model-field($model19, "abstractList.abstract"), $instance19)
  return (
    assert:not-empty($instance19),
    assert:equal($abstract-value-id, domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $new-abstract-value[2])),
    assert:equal($abstract-value-name, domain:get-field-value(domain:get-model-field($model-abstract2, "name"), $new-abstract-value[2])),
    assert:equal($new-abstract-value-name, domain:get-field-value(domain:get-model-field($model-abstract2, "name"), $new-abstract-value[1])),
    assert:not-equal(
      domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $new-abstract-value[1]),
      domain:get-field-value(domain:get-model-field($model-abstract2, "id"), $new-abstract-value[2])
    ),
    assert:not-equal($abstract-value-name, $new-abstract-value-name)
  )
};

declare %test:case function model-delete-key-label-test() as item()*
{
  let $key := "crud-model4-id-delete"
  let $model4 := domain:get-model("model4")
  let $result := model:delete($model4, $key)
  return (
    assert:not-empty($result, "model:delete should have returned true")
  )
};

declare %test:case function model-delete-cascade-remove-test() as item()*
{
  let $key := "parent-model-1"
  let $child-model := domain:get-model("child-model")
  let $parent-model := domain:get-model("parent-model")
  let $instance := model:get($parent-model, $key)
  let $instance := model:convert-to-map($parent-model, $instance)
  let $_ := map:put($instance, "_cascade", "remove")
  let $before-child-instance := model:find($child-model, map:entry("parent", $key))
  let $result :=
    model:delete($parent-model, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($before-child-instance, "Should find child referencing parent parent-model-1"),
    assert:not-empty($result, "model:delete should have returned true")
  )
};

declare %test:case function model-delete-cascade-detach-test() as item()*
{
  let $key := "parent-model-3"
  let $child-model := domain:get-model("child-model")
  let $parent-model := domain:get-model("parent-model")
  let $instance := model:get($parent-model, $key)
  let $instance := model:convert-to-map($parent-model, $instance)
  let $_ := map:put($instance, "_cascade", "detach")
  let $before-child-instance := model:find($child-model, map:entry("parent", $key))
  let $result := model:delete($parent-model, $instance)
  (:let $child-instance := model:find($child-model, map:entry("parent", $key)):)
  return (
    assert:not-empty($instance),
    assert:not-empty($before-child-instance, "Should find child referencing parent parent-model-1"),
    (:assert:empty($child-instance, "All parents referencing child-model-1 should be deleted."),:)
    (:assert:equal($result, fn:true(), "model:delete should have returned true"):)
    assert:not-empty($result, "model:delete should have returned true")
  )
};

declare %test:case function model-no-delete-cascade-test() as item()*
{
  let $key := "parent-model-2"
  let $child-model := domain:get-model("child-model")
  let $parent-model := domain:get-model("parent-model")
  let $instance := model:get($parent-model, $key)
  let $instance := model:convert-to-map($parent-model, $instance)
  let $before-child-instance := model:find($child-model, map:entry("parent", $key))
  let $result := try {
    model:delete($parent-model, $instance)
  } catch ($ex) { $ex }
  return (
    assert:not-empty($instance),
    assert:not-empty($before-child-instance, "Should find parent referencing child-model-1"),
    assert:error($result, "You are attempting to delete document which is referenced by other documents")
  )
};

declare %test:case function model-new-json-name-attribute-test() as item()*
{
  let $model22 := domain:get-model("model22")
  let $instance22 := model:new(
    $model22,
    xdmp:from-json('{"contentType": "dummy-content-type", "description": "dummy-description"}')
  )
  let $content-type-value := domain:get-field-value(domain:get-model-field($model22, "content-type"), $instance22)
  let $my-description-value := domain:get-field-value(domain:get-model-field($model22, "MyDescription"), $instance22)
  return (
    assert:not-empty($instance22),
    assert:equal("dummy-content-type", xs:string($content-type-value)),
    assert:equal("dummy-description", xs:string($my-description-value))
  )
};

declare %test:case function model-new-map-default-fields-test() as item()*
{
  let $model23 := domain:get-model("model23")
  let $name := setup:random("dummy-name")
  let $instance23 := model:new(
    $model23,
    map:new((
      map:entry("name", $name)
    ))
  )
  let $comment-value := domain:get-field-value(domain:get-model-field($model23, "comment"), $instance23)
  let $description-value := domain:get-field-value(domain:get-model-field($model23, "description"), $instance23)
  return (
    assert:not-empty($instance23),
    assert:equal("default-comment", xs:string($comment-value)),
    assert:equal("default-description", xs:string($description-value))
  )
};

declare %test:case function model-new-json-default-fields-test() as item()*
{
  let $model23 := domain:get-model("model23")
  let $name := setup:random("dummy-name")
  let $instance23 := model:new(
    $model23,
    xdmp:from-json('{"name": "'||$name||'"}')
  )
  let $comment-value := domain:get-field-value(domain:get-model-field($model23, "comment"), $instance23)
  let $description-value := domain:get-field-value(domain:get-model-field($model23, "description"), $instance23)
  return (
    assert:not-empty($instance23),
    assert:equal("default-comment", xs:string($comment-value)),
    assert:equal("default-description", xs:string($description-value))
  )
};

declare %test:case function model-update-default-element-test() as item()*
{
  let $model23 := domain:get-model("model23")
  let $instance23 := model:get($model23, "model23-name-with-default")
  let $comment-value := domain:get-field-value(domain:get-model-field($model23, "comment"), $instance23)
  let $description-value := domain:get-field-value(domain:get-model-field($model23, "description"), $instance23)
  let $instance23-map := model:convert-to-map($model23, $instance23)
  let $_ := map:put($instance23-map, "comment", ())
  let $_ := map:put($instance23-map, "description", "updated-description")
  let $_ := xdmp:log($instance23-map)
  let $update23 := setup:eval(
    function() {
      model:update(
        $model23,
        $instance23-map,
        $TEST-COLLECTION
      )
    }
  )
  let $description-updated-value := domain:get-field-value(domain:get-model-field($model23, "description"), $update23)
  let $comment-updated-value := domain:get-field-value(domain:get-model-field($model23, "comment"), $update23)
  return (
    assert:equal("default-comment", xs:string($comment-value)),
    assert:equal("default-description", xs:string($description-value)),
    assert:equal("updated-description", xs:string($description-updated-value)),
    assert:empty($comment-updated-value)
  )
};

declare %test:case function model-update-default-attribute-test() as item()*
{
  let $model23 := domain:get-model("model23")
  let $instance23 := model:get($model23, "model23-name-default-attribute")
  let $comment-value := domain:get-field-value(domain:get-model-field($model23, "comment"), $instance23)
  let $description-value := domain:get-field-value(domain:get-model-field($model23, "description"), $instance23)
  let $instance23-map := model:convert-to-map($model23, $instance23)
  let $_ := map:put($instance23-map, "comment", "updated-comment")
  let $_ := map:put($instance23-map, "description", ())
  let $_ := xdmp:log($instance23-map)
  let $update23 := setup:eval(
    function() {
      model:update(
        $model23,
        $instance23-map,
        $TEST-COLLECTION
      )
    }
  )
  let $description-updated-value := domain:get-field-value(domain:get-model-field($model23, "description"), $update23)
  let $comment-updated-value := domain:get-field-value(domain:get-model-field($model23, "comment"), $update23)
  return (
    assert:equal("no-default", xs:string($comment-value)),
    assert:equal("default-description", xs:string($description-value)),
    assert:equal("updated-comment", xs:string($comment-updated-value), "updated comment field must equal 'updated-comment'"),
    assert:empty($description-updated-value, "updated description attribute must be empty")
  )
};

declare %test:case function model-create-xml-no-default-test() as item()*
{
  let $model23 := domain:get-model("model23")
  let $instance23 := model:get($model23, "model23-name-no-default")
  let $comment-value := domain:get-field-value(domain:get-model-field($model23, "comment"), $instance23)
  let $description-value := domain:get-field-value(domain:get-model-field($model23, "description"), $instance23)
  return (
    assert:equal("no-default", xs:string($comment-value)),
    assert:equal("no-default", xs:string($description-value))
  )
};

