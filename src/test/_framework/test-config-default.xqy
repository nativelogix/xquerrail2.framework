xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace config = "http://xquerrail.com/config" at "../../main/_framework/config.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/test-config/_config</config>
</application>
;

declare %test:setup function setup() as empty-sequence()
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return (xdmp:log(("base-path", config:get-base-path(), "config-path", config:get-config-path())))
};


declare %test:case function test-anonymous-user() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $_ := xdmp:log(("test-anonymous-user", "base-path", config:get-base-path(), "config-path", config:get-config-path()))
  return
  assert:equal(config:anonymous-user(), "xquerrail2-framework-user")
};

declare %test:case function test-anonymous-user-by-application() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $application := config:default-application()
  return
  assert:equal(config:anonymous-user($application), "xquerrail2-framework-user")
};

declare %test:case function test-application-directory() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $application := config:default-application()
  let $_ := xdmp:log(("config:application-directory", config:application-directory($application)))
  return
  assert:equal(config:application-directory($application), "/test/_framework/test-config/test-app")
};

declare %test:case function test-application-namespace() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $application := config:default-application()
  return
  assert:equal(config:application-namespace($application), "http://xquerrail.com/test-app")
};

declare %test:case function test-application-script-directory() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $application := config:default-application()
  return
  assert:equal(config:application-script-directory($application), "resources/js/")
};

declare %test:case function test-application-stylesheet-directory() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $application := config:default-application()
  return
  assert:equal(config:application-stylesheet-directory($application), "resources/css/")
};

declare %test:case function test-attribute-prefix() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:attribute-prefix(), "@")
};

declare %test:case function test-base-view-directory() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:base-view-directory(), "/main/_framework/base/views")
};

declare %test:case function test-cache-location() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:cache-location(), "database")
};

declare %test:case function test-controller-base-path() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:controller-base-path(), "/controller/")
};

declare %test:case function test-controller-extension() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:empty(config:controller-extension())
};

declare %test:case function test-controller-suffix() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:controller-suffix(), "-controller")
};

declare %test:case function test-default-action() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:default-action(), "index")
};

declare %test:case function test-default-application() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:default-application(), "test-app")
};

declare %test:case function test-default-controller() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:default-controller(), "default")
};

declare %test:case function test-default-engine() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:default-engine(), "engine.html")
};

declare %test:case function test-default-format() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:default-format(), "html")
};

declare %test:case function test-default-template() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $application := config:default-application()
  return
  assert:equal(config:default-template($application), "main")
};

declare %test:case function test-error-handler() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:error-handler(), config:resolve-framework-path("error.xqy"))
};

declare %test:case function test-framework-path() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:framework-path(), "/main/_framework")
};

declare %test:case function test-get-application() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
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
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  let $applications := config:get-applications()
  return
  (
    assert:not-empty($applications),
    assert:equal(fn:count($applications), 1)
  )
};

declare %test:case function test-get-base-model-location() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
    assert:equal(config:get-base-model-location("dummy-model"), "/main/_framework/base/base-model.xqy")
};

declare %test:case function test-get-base-path() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
    assert:equal(config:get-base-path(), xs:string($TEST-APPLICATION/config:base))
};

declare %test:case function test-get-config-path() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
    assert:equal(config:get-config-path(), xs:string($TEST-APPLICATION/config:config))
};

declare %test:case function test-get-dispatcher() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:true(fn:ends-with(config:get-dispatcher(), "/dispatcher.web.xqy"))
};

(:declare %test:case function test-get-domain() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:get-domain(), "/dispatcher.web.xqy")
};
:)
declare %test:case function test-resource-directory() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:resource-directory(), "/resources/")
};

declare %test:case function test-model-suffix() as item()*
{
  let $_ := config:bootstrap-app($TEST-APPLICATION)
  return
  assert:equal(config:model-suffix(), "-model")
};


