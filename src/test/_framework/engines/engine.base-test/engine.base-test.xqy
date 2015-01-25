
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
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
