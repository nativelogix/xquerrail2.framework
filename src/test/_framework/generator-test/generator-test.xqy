xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";

import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "../../../test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace context = "http://xquerrail.com/context" at "/main/_framework/context.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "generator-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/generator-test/_config</config>
</application>
;

declare variable $MODEL1 := domain:get-model("model1");

declare variable $instances := (
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-add</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-replace</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-remove</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-field-not-found</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-operation-not-implemented</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-test-successful</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-test-failed</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-add-multi</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-mutliple-operations</id>
    <name>model1-name</name>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-add-with-position</id>
    <name>model1-name</name>
    <tags>tag#1</tags>
    <tags>tag#2</tags>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-replace-with-position</id>
    <name>model1-name</name>
    <tags>tag#1</tags>
    <tags>tag#2</tags>
    <tags>tag#3</tags>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-remove-with-position</id>
    <name>model1-name</name>
    <tags>tag#1</tags>
    <tags>tag#2</tags>
    <tags>tag#3</tags>
  </model1>
  ,
  <model1 xmlns="http://marklogic.com/model/model1">
    <id>model1-patch-test-with-position-successful</id>
    <name>model1-name</name>
    <tags>tag#1</tags>
    <tags>tag#2</tags>
    <tags>tag#3</tags>
  </model1>
);

declare %test:setup function setup() as empty-sequence()
{
  setup:setup($TEST-APPLICATION)
};

declare %test:teardown function teardown() as empty-sequence()
{
  setup:teardown($TEST-COLLECTION)
};

(: TODO domain:get-field-key seems to be deprecated it looks at $model/@keyId :)
declare %test:ignore function model-new-key-field-test() {
  let $key-field := domain:get-field-key($MODEL1)
  let $params := map:new((
    map:entry("uuid", sem:uuid-string()),
    map:entry("name", setup:random("model1-name"))
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($key-field, $instance), map:get($params, "uuid"), "key field should be the same")
  )
};

declare %test:case function model-new-identity-field-test() {
  let $identity-field := domain:get-model-identity-field($MODEL1)
  let $params := map:new((
    map:entry("uuid", sem:uuid-string()),
    map:entry("name", setup:random("model1-name"))
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($identity-field, $instance), map:get($params, "uuid"), "identity field should be the same")
  )
};

declare %test:case function model-new-key-label-field-test() {
  let $key-label-field := domain:get-model-keyLabel-field($MODEL1)
  let $params := map:new((
    map:entry("name", setup:random("model1-name"))
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($key-label-field, $instance), map:get($params, "name"), "field name should be the same")
  )
};

declare %test:ignore function model-new-reference-field-test() {
  let $key-label-field := domain:get-model-keyLabel-field($MODEL1)
  let $params := map:new((
    map:entry("name", setup:random("model1-name"))
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($key-label-field, $instance), map:get($params, "name"), "field name should be the same")
  )
};

declare %test:case function model-new-key-id-field-type-test() {
  let $field := domain:get-model-field($MODEL1, "id")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("id", fn:generate-id(<x>{setup:random("model1-name")}</x>))
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($field, $instance), map:get($params, "id"), "field id should be the same")
  )
};

declare %test:case function model-new-create-timestamp-type-test() {
  let $field := domain:get-model-field($MODEL1, "created")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("id", fn:generate-id(<x>{setup:random("model1-name")}</x>))
  ))
  let $instance := model:new($MODEL1, $params)
  let $created-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($created-value, "create-timestamp field value should not be empty"),
    assert:true(($created-value instance of xs:dateTime), "create-timestamp field should be xs:dateTime")
  )
};

declare %test:case function model-new-update-timestamp-type-test() {
  let $field := domain:get-model-field($MODEL1, "updated")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("id", fn:generate-id(<x>{setup:random("model1-name")}</x>))
  ))
  let $instance := model:new($MODEL1, $params)
  let $updated-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($updated-value, "update-timestamp field value should not be empty"),
    assert:true(($updated-value instance of xs:dateTime), "update-timestamp field should be xs:dateTime")
  )
};

declare %test:case function model-new-create-user-type-test() {
  let $field := domain:get-model-field($MODEL1, "create-user")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("id", fn:generate-id(<x>{setup:random("model1-name")}</x>))
  ))
  let $instance := model:new($MODEL1, $params)
  let $create-user-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:equal($create-user-value, context:user(), "create-user field should be the same as $context:user()")
  )
};

declare %test:case function model-new-update-user-type-test() {
  let $field := domain:get-model-field($MODEL1, "update-user")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("id", fn:generate-id(<x>{setup:random("model1-name")}</x>))
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($field, $instance), context:user(), "update-user field should be the same as $context:user()")
  )
};

declare %test:ignore function model-new-query-type-test() {
  let $field := domain:get-model-field($MODEL1, "update-user")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("id", fn:generate-id(<x>{setup:random("model1-name")}</x>))
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($field, $instance), context:user(), "update-user field should be the same as $context:user()")
  )
};

declare %test:case function model-new-anyURI-type-test() {
  let $field := domain:get-model-field($MODEL1, "anyURI")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("anyURI", "http://xquerrail.com")
  ))
  let $instance := model:new($MODEL1, $params)
  let $anyURI-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($anyURI-value, "anyURI field value should not be empty"),
    assert:true(($anyURI-value instance of xs:anyURI), "anyURI field should be xs:anyURI")
  )
};
