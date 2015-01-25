xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-instance-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $CONFIG := ();

declare %test:setup function setup() {
  setup:setup($TEST-APPLICATION)
  (:,:)
  (:(app:reset(), app:bootstrap($TEST-APPLICATION))[0]:)
};

declare %test:teardown function teardown() {
  setup:teardown($TEST-COLLECTION)
};

(:declare %test:before-each function before-test() {
  (app:reset(), app:bootstrap($TEST-APPLICATION))
};
:)
declare %test:case function model-xml-instance-test() as item()*
{
  let $model8 := domain:get-model("model8")
  let $instance8 :=
  element app-test:model8 {
    attribute id {"model8-id"},
    element app-test:abstract {
      attribute score {99},
      attribute flag2 {fn:true()},
      element app-test:flag {fn:true()},
      element app-test:name {"abstract-1"}
    }
  }

let $instance8 := setup:invoke(
    function() {
      model:new($model8, $instance8)
    }
  )
  return (
    assert:not-empty($instance8/*:abstract),
    assert:equal(xs:string($instance8/*:abstract/*:name), "abstract-1", "abstract/name should be abstract-1"),
    assert:equal(xs:integer($instance8/*:abstract/@score), 99, "abstract@score should be 99"),
    assert:equal(xs:boolean($instance8/*:abstract/@flag2), fn:true(), "abstract@flag2 should be true"),
    assert:equal(xs:boolean($instance8/*:abstract/*:flag), fn:true(), "abstract/flag should be true")
  )
};

declare %test:case function model-map-instance-test() as item()*
{
  let $model8 := domain:get-model("model8")
  let $abstract1 := domain:get-model("abstract1")
  let $instance8 := map:new((
    map:entry("id", "model8-id"),
    map:entry(
      "abstract",
      map:new((
        map:entry("score", 99),
        map:entry("name", "abstract-1"),
        map:entry("flag", fn:true()),
        map:entry("flag2", fn:true())
      ))
    )
  ))
  let $instance8 := setup:invoke(
    function() {
      model:new($model8, $instance8)
    }
  )
  return (
    assert:not-empty($instance8/*:abstract),
    assert:equal(xs:string($instance8/*:abstract/*:name), "abstract-1", "abstract/name should be abstract-1"),
    assert:equal(xs:integer($instance8/*:abstract/@score), 99, "abstract@score should be 99"),
    assert:equal(xs:boolean($instance8/*:abstract/@flag2), fn:true(), "abstract@flag2 should be true"),
    assert:equal(xs:boolean($instance8/*:abstract/*:flag), fn:true(), "abstract/flag should be true")
  )
};

declare %test:case function model-map-instance-with-binary-test() as item()*
{
  let $model18 := domain:get-model("model18")
  let $image-model := domain:get-model("image")
  let $id := "model18-id-" || xdmp:random()
  let $instance18 := map:new((
    map:entry("id", $id),
    map:entry("name", "model18-name"),
    map:entry(
      "image1",
      map:new((
        map:entry("contentType", "image/gif"),
        map:entry("content", binary{ xs:hexBinary("DEADBEEF") })
      ))
    )
  ))
  let $instance18 := setup:invoke(
    function() {
      model:create($model18, $instance18)
    }
  )
  return (
    assert:not-empty($instance18/*:image1),
    assert:equal(xs:string($instance18/*:image1/*:contentType), "image/gif", "image1/contentType should be image/gif"),
    assert:not-empty($instance18/*:image1/*:content, "image1/content should not be empty"),
    assert:equal(xs:string($instance18/*:image1/*:content/@type), "binary", "image1/content/@type should be binary"),
    assert:true(fn:starts-with(xs:string($instance18/*:image1/*:content), "/test/binary/contents/"), "image1/content should be starts with /test/binary/contents/")
  )
};
