xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "/test/_framework/setup.xqy";
import module namespace js = "http://xquerrail.com/helper/javascript" at "/main/_framework/helpers/javascript-helper.xqy";

declare option xdmp:mapping "false";

declare %test:case function simple-js-object-test() {
  let $object :=
    <x>{
      js:o((
        js:e("string", "string"),
        js:e("boolean", fn:true()),
        js:e("integer", 100),
        js:e("date", js:dt(xs:date("2015-01-23")))
      ))
      }</x>/*
  let $json := xdmp:from-json(xdmp:to-json(json:object($object)))
  return (
    assert:not-empty($object),
    assert:equal(map:get($json, "string"), "string"),
    assert:equal(map:get($json, "boolean"), fn:true()),
    assert:equal(map:get($json, "integer"), 100),
    assert:equal(map:get($json, "date"), js:dt(xs:date("2015-01-23")))
  )
};

declare %test:case function simple-js-array-test() {
  let $array :=
    <x>{
      js:a((
        js:e("string", "string"),
        js:e("boolean", fn:true()),
        js:e("integer", 100),
        js:e("date", js:dt(xs:date("2015-01-23")))
      ))
      }</x>/*
  let $json := xdmp:from-json(xdmp:to-json(json:array($array)))
  return (
    assert:not-empty($array),
    assert:equal(map:get($json[1], "string"), "string"),
    assert:equal(map:get($json[2], "boolean"), fn:true()),
    assert:equal(map:get($json[3], "integer"), 100),
    assert:equal(map:get($json[4], "date"), js:dt(xs:date("2015-01-23")))
  )
};
