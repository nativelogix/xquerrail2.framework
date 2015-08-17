
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "/test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace xdmp-api = "http://xquerrail.com/xdmp/api" at "/main/_framework/lib/xdmp-api.xqy";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/domain-test/_config</config>
</application>
;

declare variable $CONFIG := ();

declare variable $MODEL1 := domain:get-model("model1");
declare variable $MODEL1-SCHEMA := domain:generate-schema($MODEL1);

declare %test:setup function setup() {
  (app:reset(), app:bootstrap($TEST-APPLICATION))[0]
};

declare %test:teardown function teardown() as empty-sequence()
{
  ()
};

declare %test:case function generate-schema-not-empty-test() as item()*
{
  assert:not-empty($MODEL1-SCHEMA)
};

declare %test:case function generate-schema-namespace-test() as item()*
{
  assert:equal(fn:string($MODEL1-SCHEMA/@targetNamespace), fn:string($MODEL1/@namespace), "schema and model have the same namespace")
};

declare %test:case function generate-schema-element-name-test() as item()*
{
  assert:equal(fn:string($MODEL1-SCHEMA/xs:element/@name), fn:string($MODEL1/@name), "schema/xs:element and model have the same name")
};
