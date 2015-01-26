xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare %test:case function request-header-case-insensitive-test() as item()*
{
  let $header-name := "DummY"
  let $header-value := "value1"
  let $request := map:new((
    map:entry(fn:concat("request:header::", fn:lower-case($header-name)), $header-value)
  ))
  let $_ := request:initialize($request)
  return (
    assert:equal(request:get-header($header-name), $header-value),
    assert:equal(request:get-header(fn:lower-case($header-name)), $header-value),
    assert:equal(request:get-header(fn:upper-case($header-name)), $header-value)
  )
};

