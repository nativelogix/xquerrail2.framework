xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
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
    map:entry("container1.field1", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("field3", "GARY")
  )),
  map:new((
    map:entry("container1.field1", "oscar"),
    map:entry("container1.field2", "best actor"),
    map:entry("field3", "gary")
  ))
);

declare variable $TEST-IMPORT :=
<results>
<header>
  <program>
    <id>Id</id>
    <container1.field1>Field #1</container1.field1>
    <field3>Field #3</field3>
  </program>
</header>
<body>
  <program id="1234567890" xmlns="http://marklogic.com/mdm">
    <container1.field1>noah</container1.field1>
  </program>
</body>
</results>;

declare %test:setup function setup() as empty-sequence()
{
  let $_ := (app:reset(), app:bootstrap($TEST-APPLICATION))
  let $program-model := domain:get-model("program")
  let $_ := for
    $doc in $TEST-DOCUMENTS
    return model:create($program-model, $doc, $TEST-COLLECTION)
  return ()
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
  let $_ := xdmp:log($results/search:result/search:metadata)
  return
  (
    assert:not-empty($results),
    assert:true(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "field1"]), "field1 must exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "field2"]), "field2 should not exist in search response"),
    assert:false(fn:exists($results/search:result/search:metadata[1]/*[fn:local-name(.) = "field3"]), "field3 should not exist in search response"),
    assert:equal(fn:count($results/search:result/search:metadata[1]), 2)
  )
};

