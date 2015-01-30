xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace model1 = "http://marklogic.com/model/model1";
declare namespace app-test = "http://marklogic.com/app-test";

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

declare %test:setup function setup() {
  let $_ := setup:setup($TEST-APPLICATION)
  let $_ := setup:create-instances("model1", $INSTANCES1, $TEST-COLLECTION)
  let $_ := setup:create-instances("model7", $INSTANCES7, $TEST-COLLECTION)
  let $_ := setup:create-instances("model11", $INSTANCES11, $TEST-COLLECTION)
  let $_ := setup:create-instances("model15", $INSTANCES15, $TEST-COLLECTION)
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
  let $instances := model:list($model,
    map:new((
      map:entry("sidx", "count"),
      map:entry("sord", "descending")
    ))
  )
  return (
    assert:not-empty($instances),
    assert:equal($instances/app-test:model15[1]/app-test:groups/app-test:group/@seq, $INSTANCES15[3]/app-test:groups/app-test:group/@seq),
    assert:equal($instances/app-test:model15[3]/app-test:groups/app-test:group/@seq, $INSTANCES15[1]/app-test:groups/app-test:group/@seq),
    assert:equal(xs:integer($instances/totalrecords), 3)
  )
};

