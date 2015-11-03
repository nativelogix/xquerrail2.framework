xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace search = "http://marklogic.com/appservices/search";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-search-metadata-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/model-test/_config</config>
</application>
;

declare variable $TEST-DOCUMENTS :=
(
  map:new((
    map:entry("container1.type", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("name", "GARY")
  )),
  map:new((
    map:entry("container1.type", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("name", "gary")
  )),
  map:new((
    map:entry("container1.type", "oscar"),
    map:entry("container1.field2", "worst actor"),
    map:entry("name", "Jim")
  )),
  map:new((
    map:entry("container1.type", "oscar"),
    map:entry("container1.field2", "worst actor"),
    map:entry("name", "john")
  ))
);

declare variable $TEST-IMPORT :=
<results>
<header>
  <program>
    <id>Id</id>
    <container1.type>Field #1</container1.type>
    <name>Field #3</name>
  </program>
</header>
<body>
  <program id="1234567890" xmlns="http://marklogic.com/mdm">
    <container1.type>noah</container1.type>
  </program>
</body>
</results>;

declare %test:setup function setup() as empty-sequence()
{
  setup:setup($TEST-APPLICATION),
  setup:create-instances("program", $TEST-DOCUMENTS, $TEST-COLLECTION)
};

declare %test:teardown function teardown() as empty-sequence()
{
  setup:teardown($TEST-COLLECTION)
};

(: Disabled test as it requires attribute range index to be created :)
declare %test:case function test-search-with-metadata() as item()*
{
  let $program-model := domain:get-model("program")
  let $params := map:new((
    map:entry("query", "gary")
  ))
  let $results := model:search($program-model, $params)
  return
  (
    assert:not-empty($results),
    assert:true(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "type"]), "type must exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "field2"]), "field2 should not exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "name"]), "name should not exist in search response"),
    assert:equal(fn:count($results/search:result/search:metadata[1]), 2)
  )
};

declare %test:case function test-search-with-string-query-grammar-by-name-all-gary() as item()*
{
  let $program-model := domain:get-model("program")
  let $params := map:new((
    map:entry("query", "name:gary OR name:GARY")
  ))
  let $results := model:search($program-model, $params)
  return
  (
    assert:not-empty($results),
    assert:true(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "type"]), "type must exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "field2"]), "field2 should not exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "name"]), "name should not exist in search response"),
    assert:equal(fn:count($results/search:result/search:metadata[1]), 2)
  )
};

declare %test:case function test-search-with-string-query-grammar-by-name-only-gary() as item()*
{
  let $program-model := domain:get-model("program")
  let $params := map:new((
    map:entry("query", "name:gary")
  ))
  let $results := model:search($program-model, $params)
  return
  (
    assert:not-empty($results),
    assert:true(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "type"]), "type must exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "field2"]), "field2 should not exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "name"]), "name should not exist in search response"),
    assert:equal(fn:count($results/search:result/search:metadata[1]), 1)
  )
};

declare %test:case function test-search-with-string-query-grammar-by-type() as item()*
{
  let $program-model := domain:get-model("program")
  let $params := map:new((
    map:entry("query", "container1.type:oscar")
  ))
  let $results := model:search($program-model, $params)
  let $_ := xdmp:log(($program-model,model:build-search-options($program-model, $params)))
  return
  (
    assert:not-empty($results),
    assert:equal(fn:count($results/search:result/search:metadata[1]), 4)
  )
};

declare %private function get-program(
  $id
) as element() {
  model:get(domain:get-model("program"), $id)
};

(: TEST broken in ML8 - It should be fixed in ML8.0-4 :)
declare %test:ignore function test-search-with-string-query-grammar-sorting() as item()*
{
  let $program-model := domain:get-model("program")
  let $params := map:new((
    map:entry("query", "sort:name-asc")
  ))
  let $results := model:search($program-model, $params)
  let $last-id := $results/search:result[fn:last()]/search:metadata/search:attribute-meta[@name eq "id"]/fn:string()
  let $first-id := $results/search:result[1]/search:metadata/search:attribute-meta[@name eq "id"]/fn:string()
  return
  (
    assert:not-empty($results),
    assert:equal(get-program($first-id)/*:name/fn:string(), "gary", "first item name should be gary"),
    assert:equal(get-program($last-id)/*:name/fn:string(), "john", "last item name should be john"),
    assert:equal(fn:count($results/search:result/search:metadata[1]), 4)
  )
};
