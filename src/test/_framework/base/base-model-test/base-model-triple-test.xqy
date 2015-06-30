xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-triple-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare variable $TRIPLABLES1 := (
<triplable1 xmlns="http://xquerrail.com/app-test">
  <name>triplable2-name-1</name>
</triplable1>
)
;

declare variable $TRIPLABLES2 := (
<triplable2 xmlns="http://xquerrail.com/app-test">
  <name>triplable2-name-1</name>
</triplable2>
)
;

declare %test:setup function setup() {
  setup:setup($TEST-APPLICATION),
  setup:create-instances("triplable1", $TRIPLABLES1, $TEST-COLLECTION),
  setup:create-instances("triplable2", $TRIPLABLES2, $TEST-COLLECTION)
};

declare %test:teardown function teardown() {
  setup:teardown($TEST-COLLECTION)
};

declare %test:case function model-generate-iri-simple-test() as item()*
{
  let $model := domain:get-model("triplable1")
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $uri := "simple"
  let $iri := model:generate-iri($uri, $model, $params)
  return (
    assert:not-empty($iri),
    assert:equal($iri, sem:iri("simple"), "$iri must equal sem:iri('simple')")
  )
};

declare %test:case function model-generate-iri-with-field-value-test() as item()*
{
  let $model := domain:get-model("triplable1")
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $uri := "simple/$(name)"
  let $iri := model:generate-iri($uri, $model, $params)
  return (
    assert:not-empty($iri),
    assert:equal($iri, sem:iri(fn:concat("simple/", map:get($params, "name"))), "$iri must equal sem:iri('simple/$(name)')")
  )
};

declare %test:case function model-generate-iri-with-curie-test() as item()*
{
  let $model := domain:get-model("triplable1")
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $uri := "foaf:simple/$(name)"
  let $iri := model:generate-iri($uri, $model, $params)
  return (
    assert:not-empty($iri),
    assert:equal(
      $iri,
      sem:curie-expand(
        fn:concat("foaf:simple/", map:get($params, "name")),
        map:entry("foaf", "http://xmlns.com/foaf/0.1/")
      ),
      "$iri must equal sem:iri('http://xmlns.com/foaf/0.1/simple/$(name)')"
    )
  )
};

declare %test:case function model-is-triplable-test() as item()*
{
  let $model := domain:get-model("triplable1")
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $instance := model:new($model, $params)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples")
  )
};

declare %test:case function model-has-type-triple-test() as item()*
{
  let $model := domain:get-model("triplable1")
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $instance := model:new($model, $params)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:equal(sem:triple-predicate(sem:triple($instance/sem:triples/sem:triple[2])), "hasType"),
    assert:equal(sem:triple-object(sem:triple($instance/sem:triples/sem:triple[2])), fn:string($model/@name))
  )
};

declare %test:case function model-has-uri-triple-test() as item()*
{
  let $model := domain:get-model("triplable1")
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $instance := model:new($model, $params)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:equal(sem:triple-predicate(sem:triple($instance/sem:triples/sem:triple[1])), "hasUri")
  )
};

declare %test:case function model-is-triplable-keep-uuid-test() as item()*
{
  let $_ := setup:lock-for-update()
  let $model := domain:get-model("triplable1")
  let $instance := model:get($model, fn:data($TRIPLABLES1[1]/app-test:name))
  let $identity-field := domain:get-model-identity-field($model)
  let $params := map:new((
    map:entry($identity-field/@name, domain:get-field-value($identity-field, $instance)),
    map:entry("name", setup:random("updated-triple"))
  ))
  let $updated-instance := model:update($model, $params)
  return (
    assert:not-empty($instance),
    assert:equal(fn:string($instance/sem:triples/sem:triple[sem:predicate eq "hasUri"]/sem:subject), model:get-triple-identity($model, $updated-instance), "triple-identity must be equal")
  )
};

