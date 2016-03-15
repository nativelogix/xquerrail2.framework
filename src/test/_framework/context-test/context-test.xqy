xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace context = "http://xquerrail.com/context" at "/main/_framework/context.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare %test:setup function setup() {
  setup:setup($TEST-APPLICATION)
};

declare %test:case function context-user-test() as item()*
{
  assert:equal(context:user(), xdmp:get-current-user(), "context:user should equal to " || xdmp:get-current-user())
};

declare %test:case function context-database-name-test() as item()*
{
  assert:equal(context:database-name(), xdmp:database-name(xdmp:database()), "context:database-name should equal to " || xdmp:database-name(xdmp:database()))
};

declare %test:case function context-server-test() as item()*
{
  assert:equal(context:server(), xdmp:server(), "context:server should equal to " || xdmp:server())
};

declare %test:case function context-roles-empty-test() as item()*
{
  assert:empty(context:roles(), "context:role should be empty")
};
