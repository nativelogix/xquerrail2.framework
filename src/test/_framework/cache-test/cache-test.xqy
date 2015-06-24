
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace cache = "http://xquerrail.com/cache" at "../../../main/_framework/cache.xqy";

declare option xdmp:mapping "false";

declare variable $ANONYMOUS-USER := "xquerrail2-anonymous-user";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/config-test/_config</config>
</application>
;

declare variable $TEST-VALUE :=
<value>dummy</value>
;

declare variable $TEST-VALUE-2 :=
<value>dummy2</value>
;

declare %test:setup function setup() {
  ()
};

declare %test:teardown function teardown() {
  ()
};

declare %private function _test-cache($type as xs:string, $user as xs:string?) as item()*
{
  let $path := "http://xquerrail.com/test/"
  let $key := $path || "my-key"
  let $key2 := $path || "my-key2"
  let $_ := cache:set-cache($type, $key, $TEST-VALUE, $user)
  let $_ := cache:set-cache($type, $key2, $TEST-VALUE-2, $user)
  let $cache-value := cache:get-cache($type, $key, $user)
  let $keys := cache:get-cache-keys($type, $path, $user)
  let $_ := cache:remove-cache($type, $key, $user)
  let $_ := cache:remove-cache($type, $key2, $user)
  let $cache-value-2 := cache:get-cache($type, $key, $user)
  return
  (
    assert:true($cache-value eq $TEST-VALUE),
    assert:empty($cache-value-2),
    assert:equal(fn:count($keys[. = ($key, $key2)]), 2)
  )
};

declare %test:case function test-server-field-cache() as item()*
{
  _test-cache($cache:SERVER-FIELD-CACHE-LOCATION, ())
};

declare %test:case function test-database-cache() as item()*
{
  _test-cache($cache:DATABASE-CACHE-LOCATION, $ANONYMOUS-USER)
};

declare %test:case function test-application-cache() as item()*
{
  let $key := "my-application-key"
  let $cache-type := $cache:SERVER-FIELD-CACHE-LOCATION
  let $_ := cache:set-application-cache($cache-type, $key, $TEST-VALUE, $ANONYMOUS-USER)
  let $cache-empty := cache:is-application-cache-empty($cache-type, $key, $ANONYMOUS-USER)
  let $cache-value := cache:get-application-cache($cache-type, $key, $ANONYMOUS-USER)
  let $_ := cache:remove-application-cache($cache-type, $key, $ANONYMOUS-USER)
  let $cache-value-2 := cache:get-application-cache($cache-type, $key, $ANONYMOUS-USER)
  return
  (
    assert:true($cache-value eq $TEST-VALUE),
    assert:false($cache-empty, "application cache should not be empty."),
    assert:empty($cache-value-2),
    assert:true(cache:is-application-cache-empty($cache-type, $key, $ANONYMOUS-USER), "application cache must be empty")
  )
};

declare %test:case function test-config-cache() as item()*
{
  let $key := "my-config-key"
  let $_ := cache:set-config-cache((), $key, $TEST-VALUE, $ANONYMOUS-USER)
  let $cache-value := cache:get-config-cache((), $key, $ANONYMOUS-USER)
  let $_ := cache:remove-config-cache((), $key, $ANONYMOUS-USER)
  let $cache-value-2 := cache:get-config-cache((), $key, $ANONYMOUS-USER)
  return
  (
    assert:true($cache-value eq $TEST-VALUE),
    assert:empty($cache-value-2)
  )
};

declare %test:case function test-domain-cache() as item()*
{
  let $key := "my-domain-key"
  let $_ := cache:set-domain-cache((), $key, $TEST-VALUE, $ANONYMOUS-USER)
  let $cache-value := cache:get-domain-cache((), $key, $ANONYMOUS-USER)
  let $_ := cache:remove-domain-cache((), $key, $ANONYMOUS-USER)
  let $cache-value-2 := cache:get-domain-cache((), $key, $ANONYMOUS-USER)
  return
  (
    assert:true($cache-value eq $TEST-VALUE),
    assert:empty($cache-value-2)
  )
};
