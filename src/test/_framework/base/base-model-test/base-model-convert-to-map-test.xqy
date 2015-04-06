xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-convert-to-map-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $INSTANCE1 :=
<model1 xmlns="http://marklogic.com/model/model1">
  <id>convert-to-map-model1-id</id>
  <name>crud-model1-name</name>
</model1>
;

declare variable $INSTANCE10 :=
<model10 id="convert-to-map-model10-id" xmlns="http://xquerrail.com/app-test">
  <versions>
    <version id="n100000">
      <version>1</version>
      <action>new</action>
    </version>
  </versions>
</model10>
;

declare variable $INSTANCE2 := map:new((
  map:entry("id", "xml-to-map-to-xml-model1-id"),
  map:entry("name", "xml-to-map-to-xml-model1-name")
));


declare %test:setup function setup() as empty-sequence()
{
  (app:reset(), app:bootstrap($TEST-APPLICATION))[0]
};

declare %test:teardown function teardown() as empty-sequence()
{
  ()
};

declare %test:case function convert-to-map-simple-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $instance := model:new($model1, $INSTANCE1)
  let $map := model:convert-to-map($model1, $instance)
  return
  (
    assert:true(map:contains($map, "id")),
    assert:true(map:contains($map, "name"))
  )
};

declare %test:case function convert-to-map-with-container-test() as item()*
{
  let $model10 := domain:get-model("model10")
  let $instance := model:new($model10, $INSTANCE10)
  let $map := model:convert-to-map($model10, $instance)
  return
  (
    assert:true(map:contains($map, "id")),
    assert:true(map:contains($map, "versions.version"))
  )
};

declare %test:case function xml-to-map-to-xml-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $doc := model:new($model1, $INSTANCE1)
  let $map := model:convert-to-map($model1, $doc)
  let $doc2 := model:new($model1, $map)
  return
  (
    assert:not-empty($doc),
    assert:not-empty($doc2),
    assert:equal($doc, $doc2)
  )
};

declare %test:case function map-to-xml-to-map-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $doc := model:new($model1, $INSTANCE2)
  let $map := model:convert-to-map($model1, $doc)
  return
  (
    assert:equal(map:get($INSTANCE2, "id"), map:get($map, "id")),
    assert:equal(map:get($INSTANCE2, "name"), map:get($map, "name"))
  )
};
