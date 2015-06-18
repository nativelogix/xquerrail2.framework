xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-suggest-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

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
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>jim3</name>
    <firstName>jim</firstName>
    <lastName>smithA</lastName>
  </model25>
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>jim4</name>
    <firstName>jim</firstName>
    <lastName>smithB</lastName>
  </model25>
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>jim5</name>
    <firstName>jim</firstName>
    <lastName>jsmith5A</lastName>
    <lastName>jsmith5B</lastName>
    <lastName>jsmith5C</lastName>
    <lastName>jsmith5D</lastName>
  </model25>
  ,
  <model25 xmlns="http://xquerrail.com/app-test">
    <name>jim6</name>
    <firstName>jim</firstName>
    <lastName>jsmith6A</lastName>
    <lastName>jsmith6B</lastName>
    <lastName>jsmith6C</lastName>
    <lastName>jsmith6D</lastName>
  </model25>
);

declare %test:setup function setup() {
  let $_ := setup:setup($TEST-APPLICATION)
  let $_ := setup:create-instances("model25", $INSTANCES25, $TEST-COLLECTION)
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

declare %test:case function model-suggest-lastName-test() as item()*
{
  let $model := domain:get-model("model25")
  let $params := map:new((
    map:entry("query", "lastName:sm*")
  ))
  let $suggest := model:suggest($model, $params)
  return (
    assert:not-empty($suggest),
    $suggest ! (
      assert:true(fn:starts-with(., "lastName:sm"), text{.,"start with", "lastName:sm"})
    )
  )
};

declare %test:case function model-suggest-name-test() as item()*
{
  let $model := domain:get-model("model25")
  let $params := map:new((
    map:entry("query", "name:j*")
  ))
  let $suggest := model:suggest($model, $params)
  return (
    assert:not-empty($suggest),
    $suggest ! (
      assert:true(fn:contains(., "john") or fn:contains(., "jim"))
    )
  )
};

declare %test:case function model-suggest-lastName-in-specific-document-test() as item()*
{
  let $model := domain:get-model("model25")
  let $params := map:new((
    map:entry("query", "lastName:jsm*"),
    map:entry("_query", "name:jim6")
  ))
  let $suggest := model:suggest($model, $params)
  return (
    assert:not-empty($suggest),
    $suggest ! (
      assert:true(fn:starts-with(., "lastName:jsmith6"), text{.,"start with", "lastName:jsmith6"}),
      assert:false(fn:starts-with(., "lastName:jsmith5"), text{.,"should not start with", "lastName:jsmith5"})
    )
  )
};

