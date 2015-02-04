xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace app = "http://xquerrail.com/application" at "../../../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../../../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../../../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../../../../main/_framework/base/base-model.xqy";
import module namespace setup = "http://xquerrail.com/test/setup";

declare namespace model1 = "http://marklogic.com/model/model1";
declare namespace search = "http://marklogic.com/appservices/search";

declare option xdmp:mapping "false";

declare variable $TEST-COLLECTION := "base-compiled-model-test";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/base/base-model-test/_config</config>
</application>
;

declare %test:setup function setup() {
  (app:reset(), app:bootstrap($TEST-APPLICATION))[0]
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

declare %test:case function model1-navigation-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $listable := domain:navigation($model1)/@listable/fn:data()
  let $removable := domain:navigation($model1)/@removable/fn:data()
  let $searchable := domain:navigation($model1)/@searchable/fn:data()
  let $page-size := domain:navigation($model1)/@pageSize/fn:data()
  let $facet-option := xs:string(domain:navigation($model1)/search:facet-option)
  return (
    assert:not-empty($model1),
    assert:equal($listable, fn:true(), "listable must be true"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($searchable, fn:false(), "searchable must be false"),
    assert:equal($page-size, 20, "pageSize must be 20"),
    assert:equal($facet-option, "frequency-order", "search:facet-option must be frequency-order")
  )
};

declare %test:case function model2-navigation-test() as item()*
{
  let $model2 := domain:get-model("model2")
  let $listable := domain:navigation($model2)/@listable/fn:data()
  let $showable := domain:navigation($model2)/@showable/fn:data()
  let $searchable := domain:navigation($model2)/@searchable/fn:data()
  let $removable := domain:navigation($model2)/@removable/fn:data()
  return (
    assert:not-empty($model2),
    assert:equal($listable, fn:true(), "listable must be true"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($showable, fn:true(), "showable must be true"),
    assert:equal($searchable, fn:false(), "searchabe must be false")
  )
};

declare %test:case function model3-navigation-test() as item()*
{
  let $model3 := domain:get-model("model3")
  let $listable := domain:navigation($model3)/@listable/fn:data()
  let $showable := domain:navigation($model3)/@showable/fn:data()
  let $searchable := domain:navigation($model3)/@searchable/fn:data()
  let $removable := domain:navigation($model3)/@removable/fn:data()
  return (
    assert:not-empty($model3),
    assert:equal($listable, fn:true(), "listable must be true (from application domain)"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($showable, fn:false(), "showable must be false"),
    assert:equal($searchable, fn:false(), "searchabe must be false")
  )
};

declare %test:case function domain-default-model4-navigation-test() as item()*
{
  let $model4 := domain:get-model("model4")
  let $listable := domain:navigation($model4)/@listable/fn:data()
  let $showable := domain:navigation($model4)/@showable/fn:data()
  let $removable := domain:navigation($model4)/@removable/fn:data()
  return (
    assert:not-empty($model4),
    assert:equal($listable, fn:true(), "listable must be true"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($showable, fn:false(), "showable must be true")
  )
};

(:<navigation listable="false" removable="false" searchable="true"></navigation>:)
declare %test:case function model1-element-name-navigation-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $field-name := domain:get-model-field($model1, "name")
  let $listable := domain:navigation($field-name)/@listable/fn:data()
  let $removable := domain:navigation($field-name)/@removable/fn:data()
  let $searchable := domain:navigation($field-name)/@searchable/fn:data()
  return (
    assert:not-empty($model1),
    assert:equal($listable, fn:false(), "listable must be false"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($searchable, fn:true(), "searchabe must be true")
  )
};

(: <navigation listable="false" searchable="true" /> :)
declare %test:case function model7-attribute-score-navigation-test() as item()*
{
  let $model7 := domain:get-model("model7")
  let $score-field := domain:get-model-field($model7, "score")
  let $listable := domain:navigation($score-field)/@listable/fn:data()
  let $removable := domain:navigation($score-field)/@removable/fn:data()
  let $searchable := domain:navigation($score-field)/@searchable/fn:data()
  return (
    assert:not-empty($model7),
    assert:equal($listable, fn:false(), "listable must be false"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($searchable, fn:true(), "searchabe must be true")
  )
};

(: <navigation listable="true" searchable="true" /> :)
declare %test:case function model10-versions-container-navigation-test() as item()*
{
  let $model10 := domain:get-model("model10")
  let $versions-field := $model10/domain:container[@name eq "versions"] (:domain:get-model-field($model10, "versions"):)
  let $listable := domain:navigation($versions-field)/@listable/fn:data()
  let $removable := domain:navigation($versions-field)/@removable/fn:data()
  let $searchable := domain:navigation($versions-field)/@searchable/fn:data()
  let $showable := domain:navigation($versions-field)/@showable/fn:data()
  return (
    assert:not-empty($model10),
    assert:equal($listable, fn:true(), "listable must be true"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($searchable, fn:true(), "searchabe must be true"),
    assert:equal($showable, fn:false(), "showable must be false")
  )
};

(: <navigation listable="false" searchable="true" editable="true" /> :)
declare %test:case function model10-version-element-in-container-navigation-test() as item()*
{
  let $model10 := domain:get-model("model10")
  let $version-field := domain:get-model-field($model10, "version")
  let $listable := domain:navigation($version-field)/@listable/fn:data()
  let $removable := domain:navigation($version-field)/@removable/fn:data()
  let $searchable := domain:navigation($version-field)/@searchable/fn:data()
  let $showable := domain:navigation($version-field)/@showable/fn:data()
  let $editable := domain:navigation($version-field)/@editable/fn:data()
  return (
    assert:not-empty($model10),
    assert:equal($listable, fn:false(), "listable must be false"),
    assert:equal($removable, fn:true(), "removable must be true"),
    assert:equal($searchable, fn:true(), "searchabe must be true"),
    assert:equal($editable, fn:true(), "editable must be true"),
    assert:equal($showable, fn:false(), "showable must be false")
  )
};

declare %test:case function model11-facetable-should-not-inherit-test() as item()*
{
  let $model11 := domain:get-model("model11")
  let $child-field := domain:get-model-field($model11, "child")
  let $child-facetable := domain:navigation($child-field)/@facetable/fn:data()
  let $child-id-field := domain:get-model-field($model11, "childId")
  let $child-id-facetable := domain:navigation($child-id-field)/@facetable/fn:data()
  return (
    assert:not-empty($model11),
    assert:equal($child-facetable, fn:true(), "child@facetable must be true"),
    assert:empty($child-id-facetable, "childId@facetable must be false")
  )
};

declare %test:case function model20-base-with-namespace-no-override-ns-test() as item()*
{
  let $model20 := domain:get-model("model20")
  let $_ := xdmp:log(("$model20", $model20))
  let $uuid-field := domain:get-model-field($model20, "uuid")
  let $name-field := domain:get-model-field($model20, "name")
  return (
    assert:not-empty($model20),
    assert:equal(xs:string($uuid-field/@namespace), "http://marklogic.com/model/base", "uuid@namespace must be 'http://marklogic.com/model/base'"),
    assert:equal(xs:string($name-field/@namespace), "http://marklogic.com/model/model20", "uuid@namespace must be 'http://marklogic.com/model/model20'")
  )
};

declare %test:case function model21-base-with-namespace-with-override-ns-test() as item()*
{
  let $model21 := domain:get-model("model21")
  let $_ := xdmp:log(("$model21", $model21))
  let $uuid-field := domain:get-model-field($model21, "uuid")
  let $name-field := domain:get-model-field($model21, "name")
  return (
    assert:not-empty($model21),
    assert:equal(xs:string($uuid-field/@namespace), "http://marklogic.com/model/model21", "uuid@namespace must be 'http://marklogic.com/model/model21'"),
    assert:equal(xs:string($name-field/@namespace), "http://marklogic.com/model/model21", "uuid@namespace must be 'http://marklogic.com/model/model21'")
  )
};

