
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace engine = "http://xquerrail.com/engine" at "/main/_framework/engines/engine.base.xqy";
import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/engines/engine.base-test/_config</config>
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

declare %test:case function engine-set-format-content-type-found-test() as item()*
{
  let $request :=
    map:new((
      map:entry("request:content-type", "application/json")
    ))
  let $format := engine:set-format($request)
  return assert:equal($format, "json", "format should be json for content-type application/json")
};

declare %test:case function engine-set-format-content-type-not-found-test() as item()*
{
  let $request :=
    map:new((
      map:entry("request:content-type", "dummy-mime-type")
    ))
  let $format := engine:set-format($request)
  return assert:empty($format, "should not find format for content-type dummy-mime-type")
};

declare %test:case function view-uri-controller-specific-test() as item()*
{
  let $controller := "models1"
  let $action := "action1"
  let $format := "xml"
  let $view-uri := engine:view-uri($controller, $action, $format, fn:true())
  return assert:equal($view-uri, fn:concat(config:application-directory(config:default-application()), "/views/models1/models1.action1.xml.xqy"), "$view-uri must be controller specific.")
};

declare %test:case function view-uri-default-base-application-test() as item()*
{
  let $controller := "models1"
  let $action := "action2"
  let $format := "xml"
  let $view-uri := engine:view-uri($controller, $action, $format, fn:true())
  return assert:equal($view-uri, fn:concat(config:base-view-directory(), "/base.action2.xml.xqy"), "$view-uri must be default application base.")
};

declare %test:case function view-uri-framework-base-test() as item()*
{
  let $controller := "models1"
  let $action := "definition"
  let $format := "json"
  let $view-uri := engine:view-uri($controller, $action, $format, fn:true())
  return assert:equal($view-uri, fn:concat(config:default-view-directory(), "/base.definition.json.xqy"), "$view-uri must be default framework base.")
};
