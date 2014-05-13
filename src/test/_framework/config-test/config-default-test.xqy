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

declare variable $CONFIG := ();

declare %test:setup function setup() as empty-sequence()
{
  ()
};

declare %test:before-each function before-test() {
  xdmp:set($CONFIG, app:bootstrap($TEST-APPLICATION))
};

(:declare %test:after-each function after-test() {
};
:)
declare %test:case function test-anonymous-user() as item()*
{
  assert:equal(config:anonymous-user($CONFIG), "xquerrail2-framework-user")
};

declare %test:case function test-anonymous-user-by-application() as item()*
{
  let $application := config:default-application()
  return
  assert:empty(config:anonymous-user($CONFIG, $application))
};

declare %test:case function test-application-directory() as item()*
{
  let $application := config:default-application()
  let $_ := xdmp:log(("config:application-directory", config:application-directory($application)))
  return
  assert:equal(config:application-directory($application), "/test/_framework/test-config/test-app")
};

declare %test:case function test-application-namespace() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:application-namespace($application), "http://xquerrail.com/test-app")
};

declare %test:case function test-application-script-directory() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:application-script-directory($application), "resources/js/")
};

declare %test:case function test-application-stylesheet-directory() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:application-stylesheet-directory($application), "resources/css/")
};

declare %test:case function test-attribute-prefix() as item()*
{
  assert:equal(config:attribute-prefix(), "@")
};

declare %test:case function test-base-view-directory() as item()*
{
  assert:equal(config:base-view-directory(), "/main/_framework/base/views")
};

declare %test:case function test-cache-location() as item()*
{
  assert:equal(config:cache-location($CONFIG), "database")
};

declare %test:case function test-controller-base-path() as item()*
{
  assert:equal(config:controller-base-path(), "/controller/")
};

declare %test:case function test-controller-extension() as item()*
{
  assert:empty(config:controller-extension())
};

declare %test:case function test-controller-suffix() as item()*
{
  assert:equal(config:controller-suffix(), "-controller")
};

declare %test:case function test-default-action() as item()*
{
  assert:equal(config:default-action(), "index")
};

declare %test:case function test-default-application() as item()*
{
  assert:equal(config:default-application(), "test-app")
};

declare %test:case function test-default-controller() as item()*
{
  assert:equal(config:default-controller(), "default")
};

declare %test:case function test-default-engine() as item()*
{
  assert:equal(config:default-engine(), "engine.html")
};

declare %test:case function test-default-format() as item()*
{
  assert:equal(config:default-format(), "html")
};

declare %test:case function test-default-template() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:default-template($application), "main")
};

declare %test:case function test-error-handler() as item()*
{
  assert:equal(config:error-handler(), config:resolve-framework-path("error.xqy"))
};

declare %test:case function test-framework-path() as item()*
{
  assert:equal(config:framework-path(), "/main/_framework")
};

declare %test:case function test-get-application() as item()*
{
  let $name := config:default-application()
  let $application := config:get-application($name)
  return
  (
    assert:not-empty($application),
    assert:equal(xs:string($application/@name), $name)
  )
};

declare %test:case function test-get-applications() as item()*
{
  let $applications := config:get-applications()
  return
  (
    assert:not-empty($applications),
    assert:equal(fn:count($applications), 1)
  )
};

declare %test:case function test-get-base-model-location() as item()*
{
  assert:equal(config:get-base-model-location("dummy-model"), "/main/_framework/base/base-model.xqy")
};

declare %test:case function test-get-base-path() as item()*
{
  assert:equal(config:get-base-path(), xs:string($TEST-APPLICATION/config:base))
};

declare %test:case function test-get-config-path() as item()*
{
  assert:equal(config:get-config-path(), xs:string($TEST-APPLICATION/config:config))
};

declare %test:case function test-get-dispatcher() as item()*
{
  assert:true(fn:ends-with(config:get-dispatcher(), "/dispatcher.web.xqy"))
};

(:declare %test:case function test-get-domain() as item()*
{
  let $_ := app:bootstrap($TEST-APPLICATION)
  return
  assert:equal(config:get-domain(), "/dispatcher.web.xqy")
};
:)
declare %test:case function test-resource-directory() as item()*
{
  assert:equal(config:resource-directory(), "/resources/")
};

declare %test:case function test-model-suffix() as item()*
{
  assert:equal(config:model-suffix(), "-model")
};



