
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../main/_framework/domain.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/domain-test/_config</config>
</application>
;

declare variable $CONFIG := ();

declare %test:before-each function before-test() {
  xdmp:set($CONFIG, app:bootstrap($TEST-APPLICATION))
};

declare %test:case function get-model-model1-test() as item()*
{
  assert:not-empty(domain:get-model("model1"))
};

declare %test:case function get-model-identity-field-name-test() as item()*
{
  let $model1 := domain:get-model("model1")
  return
  assert:equal(domain:get-model-identity-field-name($model1), "uuid")
};
