xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace domain  = "http://xquerrail.com/domain"      at "/_framework/domain.xqy";
import module namespace model   = "http://xquerrail.com/model/base"  at "/_framework/base/base-model.xqy";

declare namespace metadata = "http://marklogic.com/metadata";

declare option xdmp:mapping "false";

declare variable $TEST-DIRECTORY := "/test/program/";

declare variable $TEST-MODEL := 
  <model name="program" persistence="directory" label="Program" key="id" keyLabel="id" xmlns="http://xquerrail.com/domain">
    <directory>{$TEST-DIRECTORY}</directory>
    <attribute name="id" identity="true" type="identity" label="Id">
      <navigation searchable="true"></navigation>
    </attribute>
    <container name="container1" label="Container #1">
      <element name="field1" type="string" label="Field #1">
        <navigation exportable="true" searchable="true" facetable="false" metadata="true" searchType="range"></navigation>
      </element> 
      <element name="field2" type="string" label="Field #2">
        <navigation exportable="false" searchable="true" facetable="false" metadata="true" searchType="range"></navigation>
      </element> 
    </container>
    <element name="field3" type="string" label="Field #3">
      <navigation exportable="true" searchable="true" facetable="false" metadata="true" searchType="range"></navigation>
    </element> 
  </model>
;
declare variable $TEST-DOCUMENTS :=
(
  map:new((
    map:entry("container1.field1", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("field3", "123456")
  )),
  map:new((
    map:entry("container1.field1", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("field3", "654321")
  ))
);

declare %test:setup function setup() as empty-sequence()
{
  (
    xdmp:log("*** SETUP ***")
  )
};

declare %test:teardown function teardown() as empty-sequence()
{
  (
    xdmp:log("*** TEARDOWN ***")
   )
};

declare %test:case function test-convert-to-map() as item()*
{
  let $doc := model:new($TEST-MODEL, $TEST-DOCUMENTS[1])
  let $_ := xdmp:log($doc)
  let $map := model:convert-to-map($TEST-MODEL, $doc)
  let $_ := xdmp:log($map)
  return 
  (
    assert:true(map:contains($map, "container1.field1")),
    assert:true(map:contains($map, "container1.field2")),
    assert:false(map:contains($map, "field1")),
    assert:true(map:contains($map, "field3")),
    assert:equal(map:count($map), 3)
  )
};

declare %test:case function test-xml-to-map-to-xml() as item()*
{
  let $doc := model:new($TEST-MODEL, $TEST-DOCUMENTS[1])
  let $map := model:convert-to-map($TEST-MODEL, $doc)
  let $doc2 := model:new($TEST-MODEL, $map)
  return 
  (
    assert:not-empty($doc),
    assert:not-empty($doc2),
    assert:equal($doc, $doc2)
  )
};
