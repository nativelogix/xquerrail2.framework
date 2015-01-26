xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare %test:case function response-header-case-insensitive-from-initialize-test() as item()*
{
  let $header-name := "Dummy"
  let $header-value := "value1"
  let $response := map:new((
    map:entry(fn:concat($response:HEADER, fn:lower-case($header-name)), $header-value)
  ))
  let $_ := response:initialize($response)
  return (
    assert:equal(response:response-header($header-name), $header-value),
    assert:equal(response:response-header(fn:lower-case($header-name)), $header-value),
    assert:equal(response:response-header(fn:upper-case($header-name)), $header-value)
  )
};

declare %test:case function response-header-case-insensitive-test() as item()*
{
  let $header-name := "Dummy"
  let $header-value := "value1"
  let $_ := response:initialize(map:new())
  let $_ := response:add-header(fn:upper-case($header-name), $header-value)
  return (
    assert:equal(response:response-header($header-name), $header-value),
    assert:equal(response:response-header(fn:lower-case($header-name)), $header-value),
    assert:equal(response:response-header(fn:upper-case($header-name)), $header-value)
  )
};
