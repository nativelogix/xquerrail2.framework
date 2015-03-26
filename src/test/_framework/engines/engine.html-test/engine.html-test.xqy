
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace engine = "http://xquerrail.com/engine" at "../../../../main/_framework/engines/engine.html.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/engines/engine.html-test/_config-ignore-missing-resource-true</config>
</application>
;

declare variable $TEST-APPLICATION-2 :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/engines/engine.html-test/_config-ignore-missing-resource-false</config>
</application>
;

declare %test:teardown function teardown() as empty-sequence()
{
  setup:teardown()
};

declare %test:case function test-ignore-missing-resource-true() as item()*
{
  let $_ := (app:reset(), app:bootstrap($TEST-APPLICATION))
  let $exists := engine:resource-file-exists("/dummy.xqy")
  return
  assert:true($exists)
};

declare %test:case function test-ignore-missing-resource-false() as item()*
{
  let $_ := (app:reset(), app:bootstrap($TEST-APPLICATION-2))
  let $exists := engine:resource-file-exists("/dummy.xqy")
  return
  assert:false($exists)
};

declare %test:case function test-resource-exists-true() as item()*
{
  let $_ := (app:reset(), app:bootstrap($TEST-APPLICATION-2))
  let $exists := engine:resource-file-exists("/test/_framework/engines/engine.html-test/dummy.xqy")
  return
  assert:true($exists)
};

declare %test:case function test-resource-exists-false() as item()*
{
  let $_ := (app:reset(), app:bootstrap($TEST-APPLICATION-2))
  let $exists := engine:resource-file-exists("/test/_framework/engines/engine.html-test/dummy-2.xqy")
  return
  assert:false($exists)
};
