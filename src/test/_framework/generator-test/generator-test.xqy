xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";

import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace setup = "http://xquerrail.com/test/setup" at "/test/_framework/setup.xqy";
import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace context = "http://xquerrail.com/context" at "/main/_framework/context.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

declare namespace model3 = "http://marklogic.com/model/model3";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "generator-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/generator-test/_config</config>
</application>
;

declare variable $MODEL1 := domain:get-model("model1");
declare variable $MODEL2 := domain:get-model("model2");
declare variable $MODEL3 := domain:get-model("model3");

declare variable $INSTANCES2 := (
  map:new((
    map:entry("id", "model2-id-1"),
    map:entry("name", "model2-name-1")
  )),
  map:new((
    map:entry("id", "model2-id-2"),
    map:entry("name", "model2-name-2")
  ))
);

declare %test:setup function setup() as empty-sequence()
{
  setup:setup($TEST-APPLICATION),
  setup:create-instances("model2", $INSTANCES2, $TEST-COLLECTION)
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

(: <element name="anyURI" type="anyURI"/> :)
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

(: <element name="string" type="string"/> :)
declare %test:case function model-new-string-type-test() {
  let $field := domain:get-model-field($MODEL1, "string")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("string", setup:random("string"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $string-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($string-value, "string field value should not be empty"),
    assert:true(($string-value instance of xs:string), "string field should be xs:string")
  )
};

(: <element name="integer" type="integer"/> :)
declare %test:case function model-new-integer-type-test() {
  let $field := domain:get-model-field($MODEL1, "integer")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("integer", 12)
  ))
  let $instance := model:new($MODEL1, $params)
  let $integer-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($integer-value, "integer field value should not be empty"),
    assert:true(($integer-value instance of xs:integer), "integer field should be xs:integer")
  )
};

(: <element name="long" type="long"/> :)
declare %test:case function model-new-long-type-test() {
  let $field := domain:get-model-field($MODEL1, "long")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("long", 9223372036854775807)
  ))
  let $instance := model:new($MODEL1, $params)
  let $long-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($long-value, "long field value should not be empty"),
    assert:true(($long-value instance of xs:long), "long field should be xs:long")
  )
};

(: <element name="decimal" type="decimal"/> :)
declare %test:case function model-new-decimal-type-test() {
  let $field := domain:get-model-field($MODEL1, "decimal")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("decimal", 92.776)
  ))
  let $instance := model:new($MODEL1, $params)
  let $decimal-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($decimal-value, "decimal field value should not be empty"),
    assert:true(($decimal-value instance of xs:decimal), "decimal field should be xs:decimal")
  )
};

(: <element name="double" type="double"/> :)
declare %test:case function model-new-double-type-test() {
  let $field := domain:get-model-field($MODEL1, "double")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("double", 1.5E1)
  ))
  let $instance := model:new($MODEL1, $params)
  let $double-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($double-value, "double field value should not be empty"),
    assert:true(($double-value instance of xs:double), "double field should be xs:double")
  )
};

(: <element name="float" type="float"/> :)
declare %test:case function model-new-float-type-test() {
  let $field := domain:get-model-field($MODEL1, "float")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("float", 1.5E1)
  ))
  let $instance := model:new($MODEL1, $params)
  let $float-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($float-value, "float field value should not be empty"),
    assert:true(($float-value instance of xs:float), "float field should be xs:float")
  )
};

(: <element name="boolean" type="boolean"/> :)
declare %test:case function model-new-boolean-type-test() {
  let $field := domain:get-model-field($MODEL1, "boolean")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("boolean", fn:true())
  ))
  let $instance := model:new($MODEL1, $params)
  let $boolean-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($boolean-value, "boolean field value should not be empty"),
    assert:true(($boolean-value instance of xs:boolean), "boolean field should be xs:boolean")
  )
};

(: <element name="dateTime" type="dateTime"/> :)
declare %test:case function model-new-dateTime-type-test() {
  let $field := domain:get-model-field($MODEL1, "dateTime")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("dateTime", xs:dateTime("2001-10-26T21:32:52"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $dateTime-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($dateTime-value, "dateTime field value should not be empty"),
    assert:true(($dateTime-value instance of xs:dateTime), "dateTime field should be xs:dateTime")
  )
};

(: <element name="date" type="date"/> :)
declare %test:case function model-new-date-type-test() {
  let $field := domain:get-model-field($MODEL1, "date")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("date", xs:date("2001-10-26"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $date-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($date-value, "date field value should not be empty"),
    assert:true(($date-value instance of xs:date), "date field should be xs:date")
  )
};

(: <element name="time" type="time"/> :)
declare %test:case function model-new-time-type-test() {
  let $field := domain:get-model-field($MODEL1, "time")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("time", xs:time("21:32:52"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $time-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($time-value, "time field value should not be empty"),
    assert:true(($time-value instance of xs:time), "time field should be xs:time")
  )
};

(: <element name="duration" type="duration"/> :)
declare %test:case function model-new-duration-type-test() {
  let $field := domain:get-model-field($MODEL1, "duration")
  let $_ := context:user("user-test")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("duration", xs:duration("PT1004199059S"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $duration-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($duration-value, "duration field value should not be empty"),
    assert:true(($duration-value instance of xs:duration), "duration field should be xs:duration")
  )
};

(: <element name="yearMonth" type="yearMonth"/> :)
declare %test:case function model-new-yearMonth-type-test() {
  let $field := domain:get-model-field($MODEL1, "yearMonth")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("yearMonth", xs:gYearMonth("2001-10"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $yearMonth-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($yearMonth-value, "yearMonth field value should not be empty"),
    assert:true(($yearMonth-value instance of xs:gYearMonth), "yearMonth field should be xs:gYearMonth"),
    assert:equal($yearMonth-value, map:get($params, "yearMonth"), "yearMonth field should be the same")
  )
};

(: <element name="monthDay" type="monthDay"/> :)
declare %test:case function model-new-monthDay-type-test() {
  let $field := domain:get-model-field($MODEL1, "monthDay")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("monthDay", xs:gMonthDay("--05-01"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $monthDay-value := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:not-empty($monthDay-value, "monthDay field value should not be empty"),
    assert:true(($monthDay-value instance of xs:gMonthDay), "monthDay field should be xs:gMonthDay"),
    assert:equal($monthDay-value, map:get($params, "monthDay"), "monthDay field should be the same")
  )
};

declare %test:case function model-new-element-with-attribute-test() {
  let $tag-field := domain:get-model-field($MODEL1, "tag")
  let $title-field := domain:get-model-field($MODEL1, "title")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("tag", setup:random("model1-tag")),
    map:entry("title", setup:random("model1-title"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $tag-value := domain:get-field-value($tag-field, $instance)
  let $title-value := domain:get-field-value($title-field, $instance)
  return (
    assert:not-empty($instance),
    assert:equal($tag-value, map:get($params, "tag"), "tag field should be the same"),
    assert:equal($title-value, map:get($params, "title"), "title field should be the same as $context:user()")
  )
};

declare %test:case function model-new-reference-field-test() {
  let $field := domain:get-model-field($MODEL1, "model2")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("model2", map:get($INSTANCES2[1], "id"))
  ))
  let $instance := model:new($MODEL1, $params)
  let $instance2 := model:get($MODEL2, map:get($INSTANCES2[1], "id"))
  return (
    assert:not-empty($instance),
    assert:not-empty($instance2),
    assert:equal(fn:string(domain:get-field-value($field, $instance)/@ref-id), domain:get-field-value(domain:get-model-identity-field($MODEL2), $instance2), "model2 field should have an attribute ref-id"),
    assert:equal(fn:string(domain:get-field-value($field, $instance)), map:get($INSTANCES2[1], "id"), "model2 field should have a text node")
  )
};

declare %test:case function model-new-schema-element-field-test() {
  let $field := domain:get-model-field($MODEL1, "schema-element")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("schema-element", <container>docker</container>)
  ))
  let $instance := model:new($MODEL1, $params)
  return (
    assert:not-empty($instance),
    assert:equal(domain:get-field-value($field, $instance)/node(), map:get($params, "schema-element"), "schema-element field should be the same")
  )
};

declare %test:case function model-new-instance-field-as-xml-test() {
  let $field := domain:get-model-field($MODEL1, "models.model3")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry(
      "models.model3",
      model:new(
        $MODEL3,
        map:new((
          map:entry("id", "model3-id-1"),
          map:entry("name", "model3-name-1")
        ))
      )
    )
  ))
  let $instance := model:new($MODEL1, $params)
  let $instance3 := domain:get-field-value($field, $instance)
  return (
    assert:not-empty($instance),
    assert:equal($instance3/fn:name(), map:get($params, "models.model3")/fn:name(), "models.model3/name() field should the same"),
    assert:equal($instance3/model3:id, map:get($params, "models.model3")/model3:id, "models.model3/model3:id field should the same"),
    assert:equal($instance3/model3:name, map:get($params, "models.model3")/model3:name, "models.model3/model3:name field should the same")
  )
};

declare %test:case function model-new-multi-occurrence-field-test() {
  let $tags-field := domain:get-model-field($MODEL1, "tags")
  let $params := map:new((
    map:entry("name", setup:random("model1-name")),
    map:entry("tags", (setup:random("tag"), setup:random("tag")))
  ))
  let $instance := model:new($MODEL1, $params)
  let $tags-value := domain:get-field-value($tags-field, $instance)
  return (
    assert:not-empty($instance),
    assert:equal($tags-value, map:get($params, "tags"), "tags field should be the same")
  )
};
