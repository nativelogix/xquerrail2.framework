xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace model1 = "http://marklogic.com/model/model1";
declare namespace app-test = "http://xquerrail.com/app-test";

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

declare variable $INSTANCES15 := (
  <model15 xmlns="http://xquerrail.com/app-test">
    <groups>
      <group seq="seq1" count="1"/>
    </groups>
  </model15>
  ,
  <model15 xmlns="http://xquerrail.com/app-test">
    <groups>
      <group seq="seq2" count="2"/>
    </groups>
  </model15>
  ,
  <model15 xmlns="http://xquerrail.com/app-test">
    <groups>
      <group seq="seq3" count="3"/>
    </groups>
  </model15>
);

declare variable $INSTANCES25 := (
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>john1</name>
    <firstName>john</firstName>
    <lastName>doe</lastName>
  </model25>
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>john2</name>
    <firstName>john</firstName>
    <lastName>smith</lastName>
  </model25>
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>john3</name>
    <firstName>john</firstName>
    <lastName>woo</lastName>
  </model25>
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>jim1</name>
    <firstName>jim</firstName>
    <lastName>doe</lastName>
  </model25>
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>jim2</name>
    <firstName>jim</firstName>
    <lastName>smith</lastName>
  </model25>
);

declare variable $INSTANCES26 := (
  <model26 xmlns="http://xquerrail.com/app-test">
    <name>ABC</name>
  </model26>
  ,
  <model26 xmlns="http://xquerrail.com/app-test">
    <name>aabc</name>
  </model26>
  ,
  <model26 xmlns="http://xquerrail.com/app-test">
    <name>'aaabc'</name>
  </model26>
  ,
  <model26 xmlns="http://xquerrail.com/app-test">
    <name>"zzz"</name>
  </model26>
  ,
  <model26 xmlns="http://xquerrail.com/app-test">
    <name>ZZZa</name>
  </model26>
);

declare %test:setup function setup() {
  let $_ := setup:setup($TEST-APPLICATION)
  let $_ := setup:create-instances("model1", $INSTANCES1, $TEST-COLLECTION)
  let $_ := setup:create-instances("model7", $INSTANCES7, $TEST-COLLECTION)
  let $_ := setup:create-instances("model11", $INSTANCES11, $TEST-COLLECTION)
  let $_ := setup:create-instances("model15", $INSTANCES15, $TEST-COLLECTION)
  let $_ := setup:create-instances("model25", $INSTANCES25, $TEST-COLLECTION)
  let $_ := setup:create-instances("model26", $INSTANCES26, $TEST-COLLECTION)
  return
    ()
};

declare %test:teardown function teardown() {
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

declare %test:case function model-list-sorting-ascending-test() as item()*
{
  let $model := domain:get-model("model1")
  let $instances := model:list($model,
    map:new((
      map:entry("sidx", "id"),
      map:entry("sord", "ascending")
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal($instances/model1:model1[1]/model1:id, $INSTANCES1[1]/model1:id),
    assert:equal($instances/model1:model1[3]/model1:id, $INSTANCES1[3]/model1:id),
    assert:equal(xs:integer($instances/totalrecords), 3)
  )
};

declare %test:case function model-list-sorting-descending-test() as item()*
{
  let $model := domain:get-model("model1")
  let $instances := model:list($model,
    map:new((
      map:entry("sidx", "id"),
      map:entry("sord", "descending")
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal($instances/model1:model1[1]/model1:id, $INSTANCES1[3]/model1:id),
    assert:equal($instances/model1:model1[3]/model1:id, $INSTANCES1[1]/model1:id),
    assert:equal(xs:integer($instances/totalrecords), 3)
  )
};

declare %test:case function model-list-total-pages-test() as item()*
{
  let $model := domain:get-model("model1")
  let $instances := model:list($model,
    map:new()
  )
  return (
    assert:not-empty($instances),
    assert:equal(xs:integer($instances/totalpages), 1)
  )
};

declare %test:case function model-list-total-pages-with-page-size-test() as item()*
{
  let $page-size := 2
  let $model := domain:get-model("model1")
  let $instances := model:list($model,
    map:new((
      map:entry("rows", $page-size)
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal(xs:integer($instances/totalpages), 2)
  )
};

declare %test:case function model-list-page-size-test() as item()*
{
  let $page-size := 2
  let $model := domain:get-model("model1")
  let $instances := model:list($model,
    map:new((
      map:entry("rows", $page-size)
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal(fn:count($instances/model1:model1), $page-size),
    assert:equal(xs:integer($instances/currentpage), 1),
    assert:equal(xs:integer($instances/pagesize), $page-size)
  )
};

declare %test:case function model-list-pagination-test() as item()*
{
  let $page-size := 2
  let $current-page := 2
  let $model := domain:get-model("model1")
  let $instances := model:list($model,
    map:new((
      map:entry("rows", $page-size),
      map:entry("page", $current-page)
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal(fn:count($instances/model1:model1), 1),
    assert:equal(xs:integer($instances/currentpage), $current-page),
    assert:equal(xs:integer($instances/pagesize), $page-size)
  )
};

declare %test:case function model-list-pagination-with-start-test() as item()*
{
  let $page-size := 2
  let $start-item := 2
  let $current-page := 1
  let $model := domain:get-model("model1")
  let $instances := model:list($model,
    map:new((
      map:entry("rows", $page-size),
      map:entry("page", $current-page),
      map:entry("start", $start-item)
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal(fn:count($instances/model1:model1), 2),
    assert:equal(xs:integer($instances/currentpage), $current-page),
    assert:equal(xs:integer($instances/pagesize), $page-size)
  )
};

declare %test:case function model-list-sorting-ascending-in-container-test() as item()*
{
  let $model := domain:get-model("model15")
  let $instances := model:list($model,
    map:new((
      map:entry("sidx", "count"),
      map:entry("sord", "ascending")
    ))
  )
    let $instance := model:new(
    $model,
    <model15 xmlns="http://xquerrail.com/app-test">
      <id>model-new-model15-id</id>
      <groups>
        <group>model15-group-1</group>
        <group seq="seq1" count="2">model15-group-2</group>
      </groups>
    </model15>
  )

  (:let $_ := xdmp:log(("$instance", $instance, "$instance2", $instance2)):)
  return (
    assert:not-empty($instances),
    assert:equal($instances/app-test:model15[1]/app-test:groups/app-test:group/@seq, $INSTANCES15[1]/app-test:groups/app-test:group/@seq),
    assert:equal($instances/app-test:model15[3]/app-test:groups/app-test:group/@seq, $INSTANCES15[3]/app-test:groups/app-test:group/@seq),
    assert:equal(xs:integer($instances/totalrecords), 3)
  )
};



declare %test:case function model-list-sorting-descending-in-container-test() as item()*
{
  let $model := domain:get-model("model15")
  let $list := model:list($model,
    map:new((
      map:entry("sidx", "count"),
      map:entry("sord", "descending")
    ))
  )
  return (
    assert:not-empty($list),
    assert:equal($list/app-test:model15[1]/app-test:groups/app-test:group/@seq, $INSTANCES15[3]/app-test:groups/app-test:group/@seq),
    assert:equal($list/app-test:model15[3]/app-test:groups/app-test:group/@seq, $INSTANCES15[1]/app-test:groups/app-test:group/@seq),
    assert:equal(fn:count($list/app-test:model15), 3),
    assert:equal(xs:integer($list/totalrecords), 3)
  )
};

declare %test:case function model-sorting-from-model-with-minus-order-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      map:new(),
      (),
      ()
  )
  return (
    assert:equal(fn:string($sorting/field/@name), "id"),
    assert:equal(fn:string($sorting/field/@order), "descending")
  )
};

declare %test:case function model-sorting-from-model-test() as item()*
{
  let $model := domain:get-model("model23")
  let $sorting :=
    model:sorting(
      $model,
      map:new(),
      (),
      ()
  )
  return (
    assert:equal(fn:string($sorting/field/@name), "description"),
    assert:equal(fn:string($sorting/field/@order), "ascending")
  )
};

declare %test:case function model-sorting-from-model-multi-test() as item()*
{
  let $model := domain:get-model("model24")
  let $sorting :=
    model:sorting(
      $model,
      map:new(),
      (),
      ()
  )
  return (
    assert:equal(fn:string($sorting/field[1]/@name), "id"),
    assert:equal(fn:string($sorting/field[1]/@order), "ascending"),
    assert:equal(fn:string($sorting/field[2]/@name), "name"),
    assert:equal(fn:string($sorting/field[2]/@order), "descending")
  )
};

declare %test:case function model-sorting-from-map-parameter-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      map:new((
        map:entry("sortName", "AA"),
        map:entry("sortOrder", "ascending")
      )),
      "sortName",
      "sortOrder"
  )
  return (
    assert:equal(fn:string($sorting/field/@name), "AA"),
    assert:equal(fn:string($sorting/field/@order), "ascending")
  )
};

declare %test:case function model-sorting-from-json-parameter-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      xdmp:from-json('{"sortName": "BB", "sortOrder": "descending"}'),
      "sortName",
      "sortOrder"
  )
  return (
    assert:equal(fn:string($sorting/field/@name), "BB"),
    assert:equal(fn:string($sorting/field/@order), "descending")
  )
};

declare %test:case function model-sorting-from-xml-parameter-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      <params>
        <sortName>CC</sortName>
        <sortOrder>descending</sortOrder>
      </params>,
      "sortName",
      "sortOrder"
  )
  return (
    assert:equal(fn:string($sorting/field/@name), "CC"),
    assert:equal(fn:string($sorting/field/@order), "descending")
  )
};

declare %test:case function model-sorting-from-map-parameter-multi-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      map:entry(
        "fields",
        (
          map:new((
            map:entry("sortName", "field1"),
            map:entry("sortOrder", "ascending")
          )),
          map:new((
            map:entry("sortName", "field2"),
            map:entry("sortOrder", "descending")
          ))
        )
      ),
      "fields.sortName",
      "fields.sortOrder"
  )
  return (
    assert:equal(fn:string($sorting/field[1]/@name), "field1"),
    assert:equal(fn:string($sorting/field[1]/@order), "ascending"),
    assert:equal(fn:string($sorting/field[2]/@name), "field2"),
    assert:equal(fn:string($sorting/field[2]/@order), "descending")
  )
};

declare %test:case function model-sorting-from-json-parameter-multi-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      xdmp:from-json('{"fields": [{"sortName": "field1", "sortOrder": "ascending"}, {"sortName": "field2", "sortOrder": "descending"}]}'),
      "fields.sortName",
      "fields.sortOrder"
  )
  return (
    assert:equal(fn:string($sorting/field[1]/@name), "field1"),
    assert:equal(fn:string($sorting/field[1]/@order), "ascending"),
    assert:equal(fn:string($sorting/field[2]/@name), "field2"),
    assert:equal(fn:string($sorting/field[2]/@order), "descending")
  )
};

declare %test:case function model-sorting-from-xml-parameter-multi-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      <fields>
        <field>
          <sortName>field1</sortName>
          <sortOrder>ascending</sortOrder>
        </field>
        <field>
          <sortName>field2</sortName>
          <sortOrder>descending</sortOrder>
        </field>
      </fields>,
      "field.sortName",
      "field.sortOrder"
  )
  return (
    assert:equal(fn:string($sorting/field[1]/@name), "field1", "$sorting/field[1]/@name must equal to 'field1'"),
    assert:equal(fn:string($sorting/field[1]/@order), "ascending", "$sorting/field[1]/@order must equal to 'ascending'"),
    assert:equal(fn:string($sorting/field[2]/@name), "field2", "$sorting/field[2]/@name must equal to 'field2'"),
    assert:equal(fn:string($sorting/field[2]/@order), "descending", "$sorting/field[2]/@order must equal to 'descending'")
  )
};

declare %test:case function model-sorting-from-json-parameter-no-param-name-test() as item()*
{
  let $model := domain:get-model("model22")
  let $sorting :=
    model:sorting(
      $model,
      xdmp:from-json('{"sidx": "field1", "sord": "ascending"}'),
      (),
      ()
  )
  return (
    assert:equal(fn:string($sorting/field[1]/@name), "field1"),
    assert:equal(fn:string($sorting/field[1]/@order), "ascending")
  )
};

declare %test:case function model-sorted-list-from-model-test() as item()*
{
  let $model := domain:get-model("model25")
  let $params := map:new((
    map:entry("debug", fn:true())
  ))
  let $list := model:list($model, $params)
  let $sorted-list :=
    for $instance in $list/app-test:model25
    order by $instance/app-test:firstName ascending, $instance/app-test:lastName descending
    return $instance
  let $valid :=
    for $instance at $pos in $sorted-list
    return
      if ($instance eq $list/app-test:model25[$pos]) then
        ()
      else
        fn:false()
  return (
    assert:not-empty($list),
    assert:empty($valid)
  )
};

declare %test:case function model-sorted-list-from-params-test() as item()*
{
  let $model := domain:get-model("model25")
  let $params := map:new((
    map:entry("debug", fn:true()),
    map:entry(
      "field",
      (
        map:new((
          map:entry("name", "lastName"),
          map:entry("order", "ascending")
        )),
        map:new((
          map:entry("name", "firstName"),
          map:entry("order", "descending")
        ))
      )
    )
  ))
  let $list := model:list($model, $params)
  let $sorted-list :=
    for $instance in $list/app-test:model25
    order by $instance/app-test:lastName ascending, $instance/app-test:firstName descending
    return $instance
  let $valid :=
    for $instance at $pos in $sorted-list
    return
      if ($instance eq $list/app-test:model25[$pos]) then
        ()
      else
        fn:false()
  return (
    assert:not-empty($list),
    assert:empty($valid)
  )
};

declare %test:case function model-sorted-list-custom-model-collation-test() as item()*
{
  let $model := domain:get-model("model26")
  let $params := map:new((
    map:entry(
      "field",
      (
        map:new((
          map:entry("name", "name"),
          map:entry("order", "ascending")
        ))
      )
    )
  ))
  let $list := model:list($model, $params)
  let $sorted-list :=
    for $instance in $list/app-test:model26
    order by $instance/app-test:name ascending collation "http://marklogic.com/collation/en/S1/T00BB/AS"
    return $instance
  let $valid :=
    for $instance at $pos in $sorted-list
    return
      if ($instance eq $list/app-test:model26[$pos]) then
        ()
      else
        fn:false()
  return (
    assert:not-empty($list),
    assert:empty($valid)
  )
};

