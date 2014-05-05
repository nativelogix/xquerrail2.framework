xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace domain  = "http://xquerrail.com/domain"      at "/_framework/domain.xqy";
import module namespace model   = "http://xquerrail.com/model/base"  at "/_framework/base/base-model.xqy";

declare namespace metadata = "http://marklogic.com/metadata";

declare option xdmp:mapping "false";

declare variable $TEST-DIRECTORY := "/test/program/";

declare variable $TEST-EXPORTABLE-MODEL := 
  <model name="program" persistence="directory" label="Program" key="id" keyLabel="id" xmlns="http://xquerrail.com/domain">
    <directory>{$TEST-DIRECTORY}</directory>
    <attribute name="id" identity="true" type="identity" label="Id">
      <navigation searchable="true"></navigation>
    </attribute>
    <element name="field1" type="string" label="Field #1">
      <navigation exportable="true" searchable="true" facetable="false" metadata="true" searchType="range"></navigation>
    </element> 
    <element name="field2" type="string" label="Field #2">
      <navigation exportable="false" searchable="true" facetable="false" metadata="true" searchType="range"></navigation>
    </element> 
    <element name="field3" type="string" label="Field #3">
      <navigation exportable="true" searchable="true" facetable="false" metadata="true" searchType="range"></navigation>
    </element> 
  </model>
;
declare variable $TEST-DOCUMENTS :=
(
  map:new((
    map:entry("field1", "oscar"),
    map:entry("field2", "best actor"),
    map:entry("field3", "GARY")
  )),
  map:new((
    map:entry("field1", "oscar"),
    map:entry("field2", "best actor"),
    map:entry("field3", "gary")
  ))
);

declare %private function create-items() as empty-sequence() {
  let $_ := for $doc in $TEST-DOCUMENTS
    return model:create($TEST-EXPORTABLE-MODEL, $doc)
  return ()
};

declare %test:setup function setup() as empty-sequence()
{
  (
    xdmp:log("*** SETUP ***"),
    create-items()
  )
};

declare %test:teardown function teardown() as empty-sequence()
{
  (
    xdmp:log("*** TEARDOWN ***"),
    xdmp:directory-delete($TEST-DIRECTORY)
   )
};

declare %test:ignore function test-export-all-fields() as item()*
{
  let $params := map:new()
  let $table := model:export($TEST-EXPORTABLE-MODEL, $params)
  return 
  (
    assert:not-empty($table),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/header/metadata:program[1]/metadata:field2)),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:field3)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/body/metadata:program[1]/metadata:field2)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:field3)),
    assert:equal(fn:count($table/body/metadata:program), fn:count($TEST-DOCUMENTS))
  )
};

declare %test:ignore function test-export-with-fields-filter() as item()*
{
  let $params := map:new()
  let $table := model:export($TEST-EXPORTABLE-MODEL, $params, ("field1"))
  
  return 
  (
    assert:not-empty($table),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/header/metadata:program[1]/metadata:field2)),
    assert:false(fn:exists($table/header/metadata:program[1]/metadata:field3)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/body/metadata:program[1]/metadata:field2)),
    assert:false(fn:exists($table/body/metadata:program[1]/metadata:field3)),
    assert:equal(fn:count($table/body/metadata:program), fn:count($TEST-DOCUMENTS))
  )
};

declare %test:ignore function test-export-with-convert-attributes-true() as item()*
{
  let $params := map:new((
    map:entry("_convert-attributes", "true")
  ))
  let $table := model:export($TEST-EXPORTABLE-MODEL, $params)
  
  return 
  (
    assert:not-empty($table),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:id)),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/header/metadata:program[1]/metadata:field2)),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:field3)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:id)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/body/metadata:program[1]/metadata:field2)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:field3)),
    assert:equal(fn:count($table/body/metadata:program), fn:count($TEST-DOCUMENTS))
  )
};

declare %test:ignore function test-export-with-convert-attributes-false() as item()*
{
  let $params := map:new((
    map:entry("_convert-attributes", "false")
  ))
  let $table := model:export($TEST-EXPORTABLE-MODEL, $params)
  
  return 
  (
    assert:not-empty($table),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:id)),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/header/metadata:program[1]/metadata:field2)),
    assert:true(fn:exists($table/header/metadata:program[1]/metadata:field3)),
    assert:true(fn:exists($table/body/metadata:program[1]/@id)),
    assert:false(fn:exists($table/body/metadata:program[1]/metadata:id)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:field1)),
    assert:false(fn:exists($table/body/metadata:program[1]/metadata:field2)),
    assert:true(fn:exists($table/body/metadata:program[1]/metadata:field3)),
    assert:equal(fn:count($table/body/metadata:program), fn:count($TEST-DOCUMENTS))
  )
};
