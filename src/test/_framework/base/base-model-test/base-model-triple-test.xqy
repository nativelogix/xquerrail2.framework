xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace xdmp-api = "http://xquerrail.com/xdmp/api" at "/main/_framework/lib/xdmp-api.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace app-test = "http://xquerrail.com/app-test";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-model-triple-test";

declare variable $TRIPLABLE1-MODEL := domain:get-model("triplable1");
declare variable $TRIPLABLE2-MODEL := domain:get-model("triplable2");
declare variable $TRIPLABLE3-MODEL := domain:get-model("triplable3");
declare variable $TRIPLABLE4-MODEL := domain:get-model("triplable4");
declare variable $TRIPLABLE5-MODEL := domain:get-model("triplable5");

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

declare variable $TRIPLABLES3 := (
<triplable2 xmlns="http://xquerrail.com/app-test">
  <name>triplable3-name-1</name>
</triplable2>
)
;

declare %test:setup function setup() {
  setup:setup($TEST-APPLICATION),
  setup:create-instances("triplable1", $TRIPLABLES1, $TEST-COLLECTION),
  setup:create-instances("triplable2", $TRIPLABLES2, $TEST-COLLECTION),
  setup:create-instances("triplable3", $TRIPLABLES3, $TEST-COLLECTION)
};

declare %test:teardown function teardown() {
  setup:teardown($TEST-COLLECTION)
};

declare %test:case function model-generate-iri-simple-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $uri := "simple"
  let $iri := model:generate-iri($uri, $TRIPLABLE1-MODEL, $params)
  return (
    assert:not-empty($iri),
    assert:equal($iri, sem:iri("simple"), "$iri must equal sem:iri('simple')")
  )
};

declare %test:case function model-generate-iri-with-field-value-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $uri := "simple/$(name)"
  let $iri := model:generate-iri($uri, $TRIPLABLE1-MODEL, $params)
  return (
    assert:not-empty($iri),
    assert:equal($iri, sem:iri(fn:concat("simple/", map:get($params, "name"))), "$iri must equal sem:iri('simple/$(name)')")
  )
};

declare %test:case function model-generate-iri-with-curie-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $uri := "foaf:simple/$(name)"
  let $iri := model:generate-iri($uri, $TRIPLABLE1-MODEL, $params)
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

declare %private function has-triple-element-with-predicate(
  $model as element(domain:model),
  $predicate as xs:string
) {
  assert:not-empty($model/domain:container[@name="triples"], "$model must contain a container[@name eq 'triples']"),
  assert:not-empty($model/domain:container[@name eq "triples"]/domain:triple/domain:predicate[. eq $predicate], "$model must have a triple with predicate value '" || $predicate || "'")
};

declare %test:case function compiled-model-is-triplable-test() as item()*
{
  (
    has-triple-element-with-predicate($TRIPLABLE5-MODEL, "hasUri"),
    has-triple-element-with-predicate($TRIPLABLE5-MODEL, "hasType")
  )
};

declare %test:case function extended-compiled-model-is-triplable-test() as item()*
{
  (
    has-triple-element-with-predicate($TRIPLABLE1-MODEL, "hasUri"),
    has-triple-element-with-predicate($TRIPLABLE1-MODEL, "hasType")
  )
};

declare %test:case function compiled-model-is-triplable-with-triples-container-test() as item()*
{
  (
    has-triple-element-with-predicate($TRIPLABLE4-MODEL, "hasUri"),
    has-triple-element-with-predicate($TRIPLABLE4-MODEL, "hasType"),
    has-triple-element-with-predicate($TRIPLABLE4-MODEL, "foaf:knows")
  )
};

declare %test:case function model-is-triplable-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $instance := model:new($TRIPLABLE1-MODEL, $params)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples")
  )
};

declare %test:case function model-has-type-triple-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple")),
    map:entry("hasType", map:new())
  ))
  let $instance := model:new($TRIPLABLE1-MODEL, $params)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:equal(sem:triple-predicate(sem:triple($instance/sem:triples/sem:triple[2])), "hasType"),
    assert:equal(sem:triple-object(sem:triple($instance/sem:triples/sem:triple[2])), fn:string($TRIPLABLE1-MODEL/@name))
  )
};

declare %test:case function model-has-uri-triple-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $instance := model:new($TRIPLABLE1-MODEL, $params)
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:equal(sem:triple-predicate(sem:triple($instance/sem:triples/sem:triple[1])), "hasUri")
  )
};

declare %test:case function model-is-triplable-keep-uuid-test() as item()*
{
  let $_ := setup:lock-for-update()
  let $instance := model:get($TRIPLABLE1-MODEL, fn:data($TRIPLABLES1[1]/app-test:name))
  let $identity-field := domain:get-model-identity-field($TRIPLABLE1-MODEL)
  let $params := map:new((
    map:entry($identity-field/@name, domain:get-field-value($identity-field, $instance)),
    map:entry("name", setup:random("updated-triple"))
  ))
  let $updated-instance := model:update($TRIPLABLE1-MODEL, $params)
  return (
    assert:not-empty($instance),
    assert:equal(fn:string($instance/sem:triples/sem:triple[sem:predicate eq "hasUri"]/sem:subject), model:get-triple-identity($TRIPLABLE1-MODEL, $updated-instance), "triple-identity must be equal")
  )
};

declare %test:case function domain-get-field-param-triple-value-test() as item()*
{
  let $params := map:new((
    map:entry("friendOfFriend", (sem:uuid-string(), "foaf:knows", sem:iri("richard")))
  ))
  let $triple-value := sem:triple(domain:get-field-param-triple-value($TRIPLABLE2-MODEL/domain:triple[@name eq "friendOfFriend"], $params))
  return (
    assert:not-empty($triple-value),
    assert:equal(sem:triple-subject($triple-value), map:get($params, "friendOfFriend")[1], "Triple subject should be the same"),
    assert:equal(sem:triple-predicate($triple-value), map:get($params, "friendOfFriend")[2], "Triple predicate should be the same"),
    assert:equal(sem:triple-object($triple-value), map:get($params, "friendOfFriend")[3], "Triple object should be the same")
  )
};

declare %test:case function domain-get-field-param-triple-value-from-map-test() as item()*
{
  let $params := map:new((
    map:entry(
      "friendOfFriend",
      map:new((
        map:entry(
          "@",
          map:new((
            map:entry("confidence", 50)
          ))
        ),
        map:entry("subject", sem:iri("subject")),
        map:entry("predicate", "foaf:knows"),
        map:entry("object", "gary")
      ))
    )
  ))
  let $triple-value := domain:get-field-param-triple-value($TRIPLABLE2-MODEL/domain:triple[@name eq "friendOfFriend"], $params)
  return (
    assert:not-empty($triple-value),
    assert:equal(sem:triple-subject(sem:triple($triple-value)), map:get(map:get($params, "friendOfFriend"), "subject"), "Triple subject should be the same"),
    assert:equal(sem:triple-predicate(sem:triple($triple-value)), map:get(map:get($params, "friendOfFriend"), "predicate"), "Triple predicate should be the same"),
    assert:equal(sem:triple-object(sem:triple($triple-value)), map:get(map:get($params, "friendOfFriend"), "object"), "Triple object should be the same"),
    assert:equal(fn:data($triple-value/@confidence), map:get(map:get(map:get($params, "friendOfFriend"), "@"), "confidence"), "triple/@confidence should be the same")
  )
};

declare %test:case function domain-get-field-param-triple-value-from-json-test() as item()*
{
  let $params := xdmp-api:from-json(
    '{
      "friendOfFriend": {
        "@": {"confidence": 50},
        "subject": "subject",
        "predicate": "foaf:knows",
        "object": "gary"
      }
    }'
  )
  let $triple-value := domain:get-field-param-triple-value($TRIPLABLE2-MODEL/domain:triple[@name eq "friendOfFriend"], $params)
  return (
    assert:not-empty($triple-value),
    assert:equal(sem:triple-subject(sem:triple($triple-value)), map:get(map:get($params, "friendOfFriend"), "subject"), "Triple subject should be the same"),
    assert:equal(sem:triple-predicate(sem:triple($triple-value)), map:get(map:get($params, "friendOfFriend"), "predicate"), "Triple predicate should be the same"),
    assert:equal(sem:triple-object(sem:triple($triple-value)), map:get(map:get($params, "friendOfFriend"), "object"), "Triple object should be the same"),
    assert:equal(fn:data($triple-value/@confidence), map:get(map:get(map:get($params, "friendOfFriend"), "@"), "confidence"), "triple/@confidence should be the same")
  )
};

declare %test:case function model-triplable-custom-expression-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple")),
    map:entry("customTriple", "pippo")
  ))
  let $instance := model:new($TRIPLABLE4-MODEL, $params)
  let $triple-value := $instance/sem:triples/sem:triple[@name eq "customTriple"]
  let $has-uri-triple-value := $instance/sem:triples/sem:triple[@name eq "hasUri"]
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:not-empty($triple-value),
    assert:equal(sem:triple-subject(sem:triple($triple-value)), sem:triple-subject(sem:triple($has-uri-triple-value)), "Triple subject should be the same"),
    assert:true(fn:starts-with(sem:triple-object(sem:triple($triple-value)), "triplable3-"), "Triple should start with 'triplable3-'")
  )
};

declare %test:case function model-triplable-manual-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple")),
    map:entry(
      "manualTriple",
      map:new((
        map:entry("predicate", "http://xmlns.com/foaf/0.1/knows/"),
        map:entry("object", "my-object")
      ))
    )
  ))
  let $instance := model:new($TRIPLABLE4-MODEL, $params)
  let $triple-value := $instance/sem:triples/sem:triple[@name eq "manualTriple"]
  let $has-uri-triple-value := $instance/sem:triples/sem:triple[@name eq "hasUri"]
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:not-empty($triple-value),
    assert:equal(sem:triple-subject(sem:triple($triple-value)), sem:triple-subject(sem:triple($has-uri-triple-value)), "Triple subject should be the same"),
    assert:equal(sem:triple-predicate(sem:triple($triple-value)), map:get(map:get($params, "manualTriple"), "predicate"), "Triple predicate should be the same"),
    assert:equal(sem:triple-object(sem:triple($triple-value)), map:get(map:get($params, "manualTriple"), "object"), "Triple object should be the same")
  )
};

declare %test:case function model-triplable-link-to-custom-expression-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple")),
    map:entry("friendOfFriend", fn:string($TRIPLABLES3[1]/app-test:name))
  ))
  let $instance3 := model:get($TRIPLABLE3-MODEL, fn:string($TRIPLABLES3[1]/app-test:name))
  let $uri := model:node-uri($TRIPLABLE3-MODEL, $instance3, ())
  let $instance := model:new($TRIPLABLE4-MODEL, $params)
  let $triple-value := $instance/sem:triples/sem:triple[@name eq "friendOfFriend"]
  let $has-uri-triple-value := $instance/sem:triples/sem:triple[@name eq "hasUri"]
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:not-empty($triple-value),
    assert:equal(sem:triple-subject(sem:triple($triple-value)), sem:triple-subject(sem:triple($has-uri-triple-value)), "Triple subject should be the same"),
    assert:equal(sem:triple-object(sem:triple($triple-value)), $uri, "Triple should start with 'triplable3-'")
  )
};

declare %test:case function model-triple-is-literal-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $instance := model:new($TRIPLABLE4-MODEL, $params)
  let $triple-value := $instance/sem:triples/sem:triple[@name eq "literalTriple"]
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:not-empty($triple-value),
    assert:true(sem:isLiteral(sem:triple-subject(sem:triple($triple-value))), "Triple subject should be a literal"),
    assert:true(sem:isLiteral(sem:triple-predicate(sem:triple($triple-value))), "Triple predicate should be a literal"),
    assert:true(sem:isLiteral(sem:triple-object(sem:triple($triple-value))), "Triple object should be a literal")
  )
};

declare %test:case function model-triple-is-iri-test() as item()*
{
  let $params := map:new((
    map:entry("name", setup:random("triple"))
  ))
  let $instance := model:new($TRIPLABLE4-MODEL, $params)
  let $triple-value := $instance/sem:triples/sem:triple[@name eq "iriTriple"]
  return (
    assert:not-empty($instance),
    assert:not-empty($instance/sem:triples, "$instance must contain sem:triples"),
    assert:not-empty($triple-value),
    assert:true(sem:isIRI(sem:triple-subject(sem:triple($triple-value))), "Triple subject should be an RDF IRI"),
    assert:true(sem:isIRI(sem:triple-predicate(sem:triple($triple-value))), "Triple predicate should be an RDF IRI"),
    assert:true(sem:isIRI(sem:triple-object(sem:triple($triple-value))), "Triple object should be an RDF IRI")
  )
};
