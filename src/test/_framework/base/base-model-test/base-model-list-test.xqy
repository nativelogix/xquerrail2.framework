xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-list-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $INSTANCES1 := (
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>list-model1-id1</id>
    <name>list-model1-name1</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>list-model1-id2</id>
    <name>list-model1-name2</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>list-model1-id3</id>
    <name>list-model1-name3</name>
  </model1>
);

declare variable $INSTANCES7 := (
  <model7 xmlns="http://xquerrail.com/app-test" id="list-model7-id1">
    <score>10</score>
    <name>list-model7-name1</name>
  </model7>
  ,
  <model7 xmlns="http://xquerrail.com/app-test" id="list-model7-id2">
    <score>11</score>
    <name>list-model7-name2</name>
  </model7>
  ,
  <model7 xmlns="http://xquerrail.com/app-test" id="list-model7-id3">
    <score>12</score>
    <name>list-model7-name3</name>
  </model7>
);

declare variable $INSTANCES11 := (
  <model11 xmlns="http://xquerrail.com/app-test">
    <id>list-model11-id1</id>
    <abstract name="container-model11-id1" />
  </model11>
  ,
  <model11 xmlns="http://xquerrail.com/app-test">
    <id>list-model11-id2</id>
    <abstract name="container-model11-id2" />
  </model11>
  ,
  <model11 xmlns="http://xquerrail.com/app-test">
    <id>list-model11-id3</id>
    <abstract name="container-model11-id3" />
    <child childId="child-model11-id3" />
  </model11>
);

declare variable $CONFIG := ();

declare %private function create-instances($instances as element()*) {
    for $instance in $instances
      let $model := domain:get-model(fn:local-name($instance))
      return xdmp:invoke-function(
        function() {
          xdmp:apply(function() {
            model:create($model, $instance, $TEST-COLLECTION)
          })
          ,
          xdmp:commit()
        },
        <options xmlns="xdmp:eval">
          <transaction-mode>update</transaction-mode>
          <isolation>different-transaction</isolation>
        </options>
      )
};

declare %test:setup function setup() {
  let $_ := (app:reset(), app:bootstrap($TEST-APPLICATION))
  let $model1 := domain:get-model("model1")
  let $_ := create-instances($INSTANCES1)
  let $_ := create-instances($INSTANCES7)
  let $_ := create-instances($INSTANCES11)
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

declare %test:case function model1-exist-test() as item()*
{
  let $model1 := domain:get-model("model1")
  return (
    assert:not-empty($model1)
  )
};

declare %test:case function model-list-totalrecords-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $instances := model:list($model1, map:new())
  return (
    assert:not-empty($instances),
    assert:equal(xs:integer($instances/totalrecords), 3)
  )
};

declare %test:case function model-list-equal-element-test() as item()*
{
  let $model := domain:get-model("model1")
  let $instances := model:list($model, 
    map:new((
      map:entry("searchField", "id"),
      map:entry("searchOper", "eq"),
      map:entry("searchString", "list-model1-id1")
    ))
  )
  let $_ := xdmp:log($instances)
  return (
    assert:not-empty($instances),
    assert:equal(xs:integer($instances/totalrecords), 1)
  )
};

declare %test:case function model-list-equal-model-attribute-test() as item()*
{
  let $model := domain:get-model("model7")
  let $instances := model:list($model, 
    map:new((
      map:entry("searchField", "id"),
      map:entry("searchOper", "eq"),
      map:entry("searchString", "list-model7-id1")
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal(xs:integer($instances/totalrecords), 1)
  )
};

declare %test:case function model-list-equal-element-attribute-test() as item()*
{
  let $model := domain:get-model("model11")
  let $instances := model:list($model, 
    map:new((
      map:entry("searchField", "childId"),
      map:entry("searchOper", "eq"),
      map:entry("searchString", "child-model11-id3")
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal(xs:integer($instances/totalrecords), 1)
  )
};

declare %test:ignore function model-list-equal-abstract-type-attribute-test() as item()*
{
  let $model := domain:get-model("model11")
  let $instances := model:list($model, 
    map:new((
      map:entry("searchField", "abstract.name"),
      map:entry("searchOper", "eq"),
      map:entry("searchString", "container-model11-id1")
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal(xs:integer($instances/totalrecords), 1)
  )
};

(:declare %test:case function model-directory-new-test() as item()*
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
  
  let $instance1 := eval(
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

(\: Require element range index for keyLabel :\)
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

(\:  xdmp:invoke-function(
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
:\)
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
(\:  let $instance1 := model:create(
    $model1, 
    map:new((
      map:entry("id", "1234"),
      map:entry("name", "name-1")
    )), 
    $TEST-COLLECTION
  )
:\)  let $value-id := domain:get-field-value(domain:get-model-field($model1, "id"), $instance1)
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

declare %test:case function model-find-by-attribute-test() as item()*
{
  let $id := setup:random()
  let $model6 := domain:get-model("model6")
  let $instance6 := xdmp:invoke-function(
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
      ,
      xdmp:commit()
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
    </options>
  )

  let $_ := xdmp:log(("$instance6", $instance6))
  let $instance6 := model:find(
    $model6,
    map:new((
      map:entry("id", $id)
(\:      map:entry("name", "name-6"):\)
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

  let $_ := xdmp:log(("$instance7", $instance7))
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
  
  let $instance10 := eval(
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

  let $_ := xdmp:log(("$instance10", $instance10))
  let $value-id := domain:get-field-value(domain:get-model-field($model10, "id"), $instance10)
  let $value-version := domain:get-field-value(domain:get-model-field($model10, "version"), $instance10)
  let $_ := xdmp:log(("$value-version", $value-version))
  return (
    assert:not-empty($instance10),
    assert:equal("10101010", xs:string($value-id)),
    assert:equal(2, fn:count($value-version))
  )
};
:)