xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../main/_framework/config.xqy";
declare namespace domain = "http://xquerrail.com/domain";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/config-test/_config</config>
</application>
;

declare %test:setup function setup() as empty-sequence()
{
  (
    app:reset(),
    app:bootstrap($TEST-APPLICATION)
  )[0]
};

declare %test:teardown function teardown() as empty-sequence()
{
  (
    xdmp:set-server-field("custom-bootstrap-test", ()),
    setup:teardown()
  )[0]
};

declare %test:case function custom-bootstrap-test() as item()*
{
  assert:not-empty(xdmp:get-server-field("custom-bootstrap-test"), "custom-bootstrap-test is not empty")
};

