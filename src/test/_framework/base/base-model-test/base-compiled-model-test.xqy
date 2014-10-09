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
  let $_ := (app:reset(), app:bootstrap($TEST-APPLICATION))
  return
    ()
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

declare %test:before-each function before-test() {
  app:bootstrap($TEST-APPLICATION)
};

declare %test:case function model1-navigation-test() as item()*
{
  let $model1 := domain:get-model("model1")
  let $listable := domain:navigation-field($model1, "listable")
  let $removable := domain:navigation-field($model1, "removable")
  let $searchable := domain:navigation-field($model1, "searchable")
  let $page-size := domain:navigation-field($model1, "pageSize")
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
  let $listable := domain:navigation-field($model2, "listable")
  let $showable := domain:navigation-field($model2, "showable")
  let $searchable := domain:navigation-field($model2, "searchable")
  let $removable := domain:navigation-field($model2, "removable")
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
  let $listable := domain:navigation-field($model3, "listable")
  let $showable := domain:navigation-field($model3, "showable")
  let $searchable := domain:navigation-field($model3, "searchable")
  let $removable := domain:navigation-field($model3, "removable")
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
  let $listable := domain:navigation-field($model4, "listable")
  let $showable := domain:navigation-field($model4, "showable")
  let $removable := domain:navigation-field($model4, "removable")
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
  let $listable := domain:navigation-field($field-name, "listable")
  let $removable := domain:navigation-field($field-name, "removable")
  let $searchable := domain:navigation-field($field-name, "searchable")
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
  let $listable := domain:navigation-field($score-field, "listable")
  let $removable := domain:navigation-field($score-field, "removable")
  let $searchable := domain:navigation-field($score-field, "searchable")
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
  let $listable := domain:navigation-field($versions-field, "listable")
  let $removable := domain:navigation-field($versions-field, "removable")
  let $searchable := domain:navigation-field($versions-field, "searchable")
  let $showable := domain:navigation-field($versions-field, "showable")
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
  let $listable := domain:navigation-field($version-field, "listable")
  let $removable := domain:navigation-field($version-field, "removable")
  let $searchable := domain:navigation-field($version-field, "searchable")
  let $showable := domain:navigation-field($version-field, "showable")
  let $editable := domain:navigation-field($version-field, "editable")
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
  let $child-facetable := domain:navigation-field($child-field, "facetable")
  let $child-id-field := domain:get-model-field($model11, "childId")
  let $child-id-facetable := domain:navigation-field($child-id-field, "facetable")
  return (
    assert:not-empty($model11),
    assert:equal($child-facetable, fn:true(), "child@facetable must be true"),
    assert:empty($child-id-facetable, "childId@facetable must be false")
  )
};

