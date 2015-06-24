xquery version "1.0-ml";
(:~
: Base Model for MarkLogic 8
: @author Gary Vidal
: @version  1.0
 :)

module namespace model-impl = "http://xquerrail.com/model/base/v8";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

import module namespace context = "http://xquerrail.com/context" at "../context.xqy";

import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";

import module namespace model = "http://xquerrail.com/model/base" at "base-model.xqy";

import module namespace config = "http://xquerrail.com/config" at "../config.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-doc-2007-01.xqy";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace as = "http://www.w3.org/2005/xpath-functions";

declare default collation "http://marklogic.com/collation/codepoint";

(:Options Definition:)
declare option xdmp:mapping "false";

(:~
 : Converts Search Parameters to cts search construct for list;
 :)
declare function model-impl:list-params(
  $model as element(domain:model),
  $params as item()
) {
  let $sf := domain:get-param-value($params,"searchField"),
      $so := domain:get-param-value($params,"searchOper"),
      $sv := domain:get-param-value($params,"searchString"),
      $filters := domain:get-param-value($params,"filters")[1]
  return
    if(fn:exists($sf) and fn:exists($so) and fn:exists($sv) and
      $sf ne "" and $so ne "")
    then
      let $op := $so
      let $field-elem := domain:get-model-field($model, $sf)
      let $field := fn:QName(domain:get-field-namespace($field-elem),$field-elem/@name)
      let $value := domain:get-param-value($params,"searchString")[1]
      return
        model:operator-to-cts($field-elem,$op,$value)
    else if(fn:exists($filters[. ne ""])) then
      let $parsed  := <x>{xdmp:from-json-string($filters)}</x>/*
      let $groupOp := ($parsed/json:entry[@key eq "groupOp"]/json:value,"AND")[1]
      let $rules :=
        for $rule in $parsed//json:entry[@key eq "rules"]/json:value/json:array/json:value/json:object
        let $op :=  $rule/json:entry[@key='op']/json:value
        let $sf :=  $rule/json:entry[@key='field']/json:value
        let $sv :=  $rule/json:entry[@key='data']/json:value
        let $field-elem := domain:get-model-field($model, $sf)
        let $field :=
            fn:QName(domain:get-field-namespace($field-elem),$field-elem/@name)
        return
          if($op and $sf and $sv) then
          model:operator-to-cts($field-elem,$op, $sv)
          else ()
      return
        if($groupOp eq "OR") then
          cts:or-query((
            $rules
          ))
        else
          cts:and-query((
            $rules
          ))
    else ()
};

declare function model-impl:validation-errors(
  $error as element(error:error)
) as element (validationErrors)? {
  if ($error/error:data/error:datum) then
    if (fn:starts-with($error/error:data/error:datum, "map:map(") and fn:ends-with($error/error:data/error:datum, ")")) then
      map:get(xdmp:value($error/error:data/error:datum/text()), "validation-errors")
    else
      xdmp:value(map:get(xdmp:from-json-string($error/error:data/error:datum/text()), "validation-errors"))
  else
    ()
};
