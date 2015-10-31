xquery version "1.0-ml";
(:~ 

Copyright 2011 - NativeLogix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.




 :)
(:~
 : Controls all interaction with an application domain.  The domain provides annotations and
 : definitions for dynamic features built into XQuerrail.
 : @version 2.0
 :)
module namespace domain-impl = "http://xquerrail.com/domain/v8";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-doc-2007-01.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace qry = "http://marklogic.com/cts/query";

declare option xdmp:mapping "false";

(:~
 : Returns the base query for a given model
 : @param $model  name of the model for the given base-query
 :)
declare function domain-impl:get-base-query(
  $model as element(domain:model)
) {
  switch($model/@persistence)
    case "directory"
      return cts:and-query((
        $model/domain:directory[. ne ""] ! cts:directory-query(.,"infinity"),
        cts:or-query((
          xdmp:plan(/*[fn:node-name(.)  eq domain:get-field-qname($model)])//*:key ! cts:term-query(.)
        ))
      ))
    case "document"
      return cts:document-query($model/domain:document)
    case "singleton"
      return cts:document-query($model/domain:document)
    case "abstract"
      return ()
    default
      return fn:error(xs:QName("BASE-QUERY-ERROR"),"Cannot determine base query on model",$model/@name)
};

(:~
 : Creates a root term query that can be used in combination to specify the root.
:)
declare function domain-impl:model-root-query(
  $model as element(domain:model)
) {
  let $name := $model/@name
  let $ns := domain:get-field-namespace($model)
  let $prefix := domain:get-field-prefix($model)
  return switch($model/@persistence)
    case "directory" return (:cts:or-query(( :)
      xdmp:with-namespaces(domain:declared-namespaces($model),
        xdmp:value(fn:concat("xdmp:plan(/",$prefix,":",$name,")"))/qry:final-plan//qry:key ! cts:term-query(.)
      )
    (:)):)
     case "document" return
       try{
         xdmp:with-namespaces(domain:declared-namespaces($model),
           xdmp:value(
            fn:concat("xdmp:plan(/",$prefix,":",$model/domain:document/@root,
            "/",$prefix,":",$name,")")
            )/qry:final-plan//qry:key ! cts:term-query(.)
        )} catch($ex) {
          fn:error(xs:QName("ROOT-QUERY-ERROR"),fn:concat("xdmp:plan(/",$prefix,":",$model/domain:document/@root,
            "/",$prefix,":",$name,")"))
        }
     default return
        xdmp:with-namespaces(domain:declared-namespaces($model),
            xdmp:value(fn:concat("xdmp:plan(/",$prefix,":",$name,")"))/qry:final-plan//qry:key ! cts:term-query(.)
        )
};
