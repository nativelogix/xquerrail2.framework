xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace domain  = "http://xquerrail.com/domain"      at "/main/_framework/domain.xqy";
import module namespace model   = "http://xquerrail.com/model/base"  at "/main/_framework/base/base-model.xqy";

import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

 (:validate-model:)
declare variable $TEST-DIRECTORY := "/test/model/validation/";

declare variable $TEST-COLLECTION := "base-model-validation-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/model-test/_config</config>
</application>
;

declare variable $TEST-MODEL := domain:get-model("validate-model");
declare variable $TEST-MODEL2 := domain:get-model("validate-model2");
declare variable $TEST-MODEL3 := domain:get-model("validate-model3");
declare variable $TEST-MODEL4 := domain:get-model("validate-model4");

declare variable $TEST-NO-VIOLATIONS :=
  <validate-model xmlns="http://xquerrail.com/app-test" id="test-no-violations" condition="Fulfill all constraints">
    <requiredString>inefay</requiredString>
    <plusInteger>66</plusInteger>
    <optionalOption>grande</optionalOption>
    <defaultValue>Provided</defaultValue>
  </validate-model>;

declare variable $INSTANCES := (
  <validate-model xmlns="http://xquerrail.com/app-test" id="unique-constraint-test" condition="Fulfill all constraints">
    <requiredString>QQQQay</requiredString>
    <plusInteger>66</plusInteger>
    <optionalOption>grande</optionalOption>
    <defaultValue>Provided</defaultValue>
  </validate-model>
);

declare variable $INSTANCE2S := (
  <validate-model2 xmlns="http://xquerrail.com/app-test" id="uniqueKey-constraint1-test">
    <firstName>gary</firstName>
    <lastName>doe</lastName>
  </validate-model2>
);

declare %private function check-violations( $instance as item()*, $checks as element()* ) {
(
    assert:equal( fn:count($instance), 1, "A single object returned"),
    assert:equal( fn:local-name($instance), "validationErrors", "Which is a validationErrors instance"),
    (: now we know $instance is a single validationErrors, so we can check the validationError nodes within :)
    for $check in $checks[@check]
        let $field := fn:local-name($check)
        let $type := $check/@check/fn:string()
        return
            assert:not-empty( $instance/*:validationError[*:element eq $field and fn:matches(*:type, $type)], "Indicating "||$field||" fails "||$type||" validation" ),
    let $count := fn:count($checks[@check])
    return
        assert:equal( fn:count($instance/*:validationError), $count, "Expected count ("||$count||") of validation errors")
)
};

declare %test:setup function setup() as empty-sequence()
{
  let $_ := setup:setup($TEST-APPLICATION)
  let $_ := setup:create-instances("validate-model", $INSTANCES, $TEST-COLLECTION)
  let $_ := setup:create-instances("validate-model2", $INSTANCE2S, $TEST-COLLECTION)
  return ()
};

declare %test:teardown function teardown() {
  xdmp:invoke-function(
    function() {
      xdmp:collection-delete($TEST-COLLECTION)
      , xdmp:commit()
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
    </options>
  )
};

declare %private function model-create(
  $identity
) as element() {
  model-create($TEST-MODEL, $identity)
};

declare %private function model-create(
  $model,
  $identity
) as element() {
  model:create($model, $identity, $TEST-COLLECTION)
};

declare %private function get-validation-errors(
  $error as element(error:error)
) as element (validationErrors) {
  model:validation-errors($error)
};

declare %private function get-validation-error(
  $validation-errors as element(validationErrors),
  $field-name as xs:string*,
  $validation-type as xs:string*
) as element (validationError)* {
  $validation-errors/validationError[element = $field-name and type = $validation-type]
};

declare %test:case function test:violate-no-constraints()
{
  let $instance := model-create($TEST-NO-VIOLATIONS)
  return (
    assert:not-empty($instance),
    assert:equal( fn:count($instance), 1, "A single object returned"),
    assert:equal( fn:local-name($instance), "validate-model", "Which is a validate-model instance"),
    assert:not-equal( fn:local-name($instance), "validationErrors", "And not a validationErrors"),
    $instance
  )
};

declare %test:case function test:validation-unique-constraint-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "QQQQay"),
        map:entry("plusInteger", 10),
        map:entry("optionalOption", "grande")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "requiredString", "unique")),
    assert:equal(get-validation-error($validation-errors, "requiredString", "unique")/error/fn:string(), "Instance is not unique.Field:requiredString Value: QQQQay")
  )
};

declare %test:case function test:validation-uniqueKey-constraint-test()
{
  let $validation-errors := try {
    model-create(
      $TEST-MODEL2,
      map:new((
        map:entry("firstName", "gary"),
        map:entry("lastName", "doe")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "firstName lastName", "uniqueKey")),
    assert:equal(get-validation-error($validation-errors, "firstName lastName", "uniqueKey")/error/fn:string(), "Instance is not unique. Keys:" || fn:string-join(("firstName","lastName"),", "))
  )
};

declare %test:case function test:validation-uniqueKey-constraint-passed-test()
{
  let $instance :=
    model-create(
      $TEST-MODEL2,
      map:new((
        map:entry("firstName", "gary1"),
        map:entry("lastName", "doe")
      ))
    )
  return (
    assert:not-empty($instance)
  )
};

declare %test:case function test:validation-required-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("plusInteger", 11)
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:equal(xs:string($validation-errors/validationError/type), "required")
  )
};

declare %test:case function test:validation-min-length-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "aaaa"),
        map:entry("plusInteger", 11)
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "requiredString", "minLength"))
  )
};

declare %test:case function test:validation-max-length-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "aaaaaAAAAAaaaaa"),
        map:entry("plusInteger", 11)
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "requiredString", "maxLength"))
  )
};

declare %test:case function test:validation-min-value-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "inefay"),
        map:entry("plusInteger", -1)
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "plusInteger", "minValue"))
  )
};

declare %test:case function test:validation-max-value-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "inefay"),
        map:entry("plusInteger", 999)
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "plusInteger", "maxValue"))
  )
};

declare %test:case function test:validation-in-list-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "inefay"),
        map:entry("plusInteger", 10),
        map:entry("optionalOption", "dummy")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "optionalOption", "inList"))
  )
};

declare %test:case function test:validation-pattern-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "qwerty"),
        map:entry("plusInteger", 10),
        map:entry("optionalOption", "grande")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "requiredString", "pattern"))
  )
};

declare %test:case function test:validation-occurence-exactly-one-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "inefay"),
        map:entry("plusInteger", 10),
        map:entry("optionalOption", "grande"),
        map:entry("defaultValue", ("small", "grande"))
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "defaultValue", "occurrence")),
    assert:equal(get-validation-error($validation-errors, "defaultValue", "occurrence")/error/fn:string(), "The value of defaultValue must contain exactly one item.")
  )
};

declare %test:case function test:validation-occurence-plus-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "inefay"),
        map:entry("optionalOption", "grande")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "plusInteger", "occurrence")),
    assert:equal(get-validation-error($validation-errors, "plusInteger", "occurrence")/error/fn:string(), "The value of plusInteger must contain at least one item.")
  )
};

declare %test:case function test:validation-error-count-test()
{
  let $validation-errors := try {
    model-create(
      map:new((
        map:entry("requiredString", "1aZ"),
        map:entry("plusInteger", 10),
        map:entry("optionalOption", "grande")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:equal(fn:count(get-validation-error($validation-errors, "requiredString", ("minLength", "pattern"))), 2, "Must have 2 validationError for requiredString field."),
    assert:equal(fn:count($validation-errors/validationError), 2, "Must have 2 validationError")
  )
};

declare %test:case function test:custom-validator-test()
{
  let $validation-errors := try {
    model-create(
      $TEST-MODEL2,
      map:new((
        map:entry("firstName", "gary"),
        map:entry("lastName", "doe2"),
        map:entry("birthDate", "2011-09-09")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "birthDate", "custom-validator")),
    assert:equal(get-validation-error($validation-errors, "birthDate", "custom-validator")/error/fn:string(), "Custom validator only valid when value is 2000-01-01.")
  )
};

declare %test:case function test:custom-model-validator-test()
{
  let $validation-errors := try {
    model-create(
      $TEST-MODEL3,
      map:new((
        map:entry("firstName", "gary1"),
        map:entry("lastName", "doe2")
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    assert:not-empty(get-validation-error($validation-errors, "firstName lastName", "model-validator")),
    assert:equal(get-validation-error($validation-errors, "firstName lastName", "model-validator")/error/fn:string(), "firstName must be gary or lastName must be doe")
  )
};

declare %test:case function test:custom-model-validators-inheritence-test()
{
  let $validation-errors := try {
    model-create(
      $TEST-MODEL4,
      map:new((
        map:entry("firstName", "gary1"),
        map:entry("lastName", "doe2"),
        map:entry("age", 19)
      ))
    )
  } catch ($ex) { get-validation-errors($ex) }
  return (
    assert:not-empty($validation-errors),
    (: Domain custom validator :)
    assert:not-empty(get-validation-error($validation-errors, "firstName", "domain-model-validator")),
    assert:equal(get-validation-error($validation-errors, "firstName", "domain-model-validator")/error/fn:string(), "firstName must be JOHN"),
    (: Abstract custom validator :)
    assert:not-empty(get-validation-error($validation-errors, "age", "base-model-validator")),
    assert:equal(get-validation-error($validation-errors, "age", "base-model-validator")/error/fn:string(), "age must be greater than 20"),
    (: Modle custom validator :)
    assert:not-empty(get-validation-error($validation-errors, "lastName", "model-validator")),
    assert:equal(get-validation-error($validation-errors, "lastName", "model-validator")/error/fn:string(), "lastName must be doe")
  )
};

declare %test:case function test:custom-model-validators-inheritence-passed-test()
{
  let $instance :=
    model-create(
      $TEST-MODEL4,
      map:new((
        map:entry("firstName", "JOHN"),
        map:entry("lastName", "doe"),
        map:entry("age", 78)
      ))
    )
  return (
    assert:not-empty($instance)
  )
};
