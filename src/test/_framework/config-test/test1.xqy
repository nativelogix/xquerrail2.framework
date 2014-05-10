
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../main/_framework/config.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/config-test/_config</config>
</application>
;

declare %test:setup function setup() as empty-sequence()
{
  let $_ := app:bootstrap($TEST-APPLICATION)
  return (xdmp:log(("base-path", config:get-base-path(), "config-path", config:get-config-path())))
};

declare %test:case function test-anonymous-user-by-application() as item()*
{
  let $config := app:bootstrap($TEST-APPLICATION)
  let $application := config:default-application()
  return
  assert:equal(config:anonymous-user($config, $application), ())
};
