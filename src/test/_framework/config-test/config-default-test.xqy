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
  setup:setup($TEST-APPLICATION)
};

declare %test:teardown function teardown() as empty-sequence()
{
  setup:teardown()
};

declare %test:case function test-anonymous-user() as item()*
{
  assert:equal(config:anonymous-user(config:get-config()), "xquerrail2-anonymous-user")
};

declare %test:case function test-anonymous-user-by-application() as item()*
{
  let $application := config:default-application()
  return
  assert:empty(config:anonymous-user(config:get-config(), $application))
};

declare %test:case function application-directory-test() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:application-directory($application), "/test/_framework/config-test/app-test")
};

declare %test:case function application-namespace-test() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:application-namespace($application), "http://xquerrail.com/app-test")
};

declare %test:case function application-script-directory-test() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:application-script-directory($application), "/test/_framework/config-test/app-test/resources/js/")
};

declare %test:case function application-stylesheet-directory-test() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:application-stylesheet-directory($application), "/test/_framework/config-test/app-test/resources/css/")
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
  assert:equal(config:cache-location(config:get-config()), "database")
};

declare %test:case function test-controller-base-path() as item()*
{
  assert:equal(config:controller-base-path(), "/controller/")
};

declare %test:case function test-controller-extension() as item()*
{
  assert:empty(config:controller-extension())
};

declare %test:case function test-model-extension() as item()*
{
  assert:empty(config:model-extension())
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
  assert:equal(config:default-application(), "app-test")
};

declare %test:case function test-default-controller() as item()*
{
  assert:equal(config:default-controller(), "default")
};

declare %test:case function test-default-engine() as item()*
{
  assert:equal(config:default-engine(), $config:DEFAULT-ENGINES-CONFIGURATION/config:engines/config:engine[1])
};

declare %test:case function test-default-format() as item()*
{
  assert:equal(config:default-format(), "html")
};

declare %test:case function test-default-template() as item()*
{
  let $application := config:default-application()
  return
  assert:equal(config:default-template($application), "templates")
};

declare %test:case function test-error-handler() as item()*
{
  assert:equal(config:error-handler(), config:resolve-framework-path("error.xqy"))
};

declare %test:case function test-resource-handler() as item()*
{
  assert:equal(config:resource-handler()/@resource/fn:string(), config:resolve-framework-path("handlers/resource.handler.xqy"))
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

declare %test:case function test-application-templates-path() as item()*
{
  assert:equal(config:application-templates-path(config:default-application()), "/test/_framework/config-test/app-test/templates/")
};

declare %test:case function test-application-views-path() as item()*
{
  assert:equal(config:application-views-path(config:default-application()), "/test/_framework/config-test/app-test/views/")
};

declare %test:case function test-application-controllers-path() as item()*
{
  assert:equal(config:application-controllers-path(config:default-application()), "/test/_framework/config-test/app-test/controllers/")
};

declare %test:case function test-application-models-path() as item()*
{
  assert:equal(config:application-models-path(config:default-application()), "/test/_framework/config-test/app-test/models/")
};

declare %test:case function test-model-location() as item()*
{
  assert:equal(config:model-location(config:default-application(), "model1"), "/test/_framework/config-test/app-test/models/model1-model.xqy")
};

declare %test:case function test-model-uri() as item()*
{
  assert:equal(config:model-uri(config:default-application(), "model1"), fn:concat(config:application-namespace(config:default-application()), "/models/model1"))
};

declare %test:case function test-controller-location() as item()*
{
  assert:equal(config:controller-location(config:default-application(), "model1"), "/test/_framework/config-test/app-test/controllers/model1-controller.xqy")
};

declare %test:case function test-controller-uri() as item()*
{
  assert:equal(config:controller-uri(config:default-application(), "model1"), fn:concat(config:application-namespace(config:default-application()), "/controllers/model1"))
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

declare %test:case function test-get-domain() as item()*
{
  let $domain := config:get-domain()
  return
  (
    assert:not-empty($domain),
    assert:equal($domain/domain:name/fn:string(.), "app-test")
  )
};

declare %test:case function test-resource-directory() as item()*
{
  assert:equal(config:resource-directory(), "/resources/")
};

declare %test:case function test-model-suffix() as item()*
{
  assert:equal(config:model-suffix(), "-model")
};



