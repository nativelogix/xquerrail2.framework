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
 : Module provides evaluation support to allow the creation 
 : of nodes in a seperate transaction context.
 :)
module namespace eval = "http://xquerrail.com/eval";

import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";
    
declare option xdmp:mapping "false";

(:~
 : Evaluation statements
 :)
declare function eval-create(
    $model as element(domain:model),
    $params as map:map
) {
   eval-create($model,$params,())
};

declare function eval-create(
   $model as element(domain:model),
   $params as map:map,
   $collections as xs:string*   
) {
    let $stmt := '
       import module namespace model = "http://xquerrail.com/model/base"
       at "base/base-model.xqy";
       
       declare option xdmp:mapping "false";
       
       declare variable $call-params as map:map external;
       
       let $model := map:get($call-params,"model")
       let $params := map:get($call-params,"params")
       let $collections := map:get($call-params,"collections")
       return
          model:create($model,$params,$collections)
     '
    let $call-params := map:map()
    let $_ := 
        (
            map:put($call-params,"model",$model),
            map:put($call-params,"params",$params),
            map:put($call-params,"collections",$collections)
        ) 
    return 
      xdmp:eval(
        $stmt,
        (xs:QName("call-params"),$call-params),
        <options xmlns="xdmp:eval">
            <isolation>different-transaction</isolation>
        </options>
     )
};

declare function eval-update(
    $model as element(domain:model),
    $params as map:map
) {
   eval-update($model,$params,(),fn:false()) 
};

declare function eval-update(
    $model as element(domain:model),
    $params as map:map,
    $collections as xs:string*
)
{
    eval-update($model,$params,$collections,fn:false())
};

declare function eval-update(
   $model as element(domain:model),
   $params as map:map,
   $collections as xs:string*,
   $partial as xs:boolean   
) {
    let $stmt := '
       import module namespace model = "http://xquerrail.com/model/base"
       at "base/base-model.xqy";
       
       declare option xdmp:mapping "false";
       
       declare variable $call-params as map:map external;
       let $model := map:get($call-params,"model")
       let $params := map:get($call-params,"params")
       let $collections := map:get($call-params,"collections")
       let $partial := map:get($call-params,"partial")
       return
          model:update($model,$params,$collections,$partial)
     '
    let $cparams := map:map()
    let $_ := 
        (
            map:put($cparams,"model",$model),
            map:put($cparams,"params",$params),
            map:put($cparams,"collections",$collections),
            map:put($cparams,"partial",$partial)
        ) 
    return 
      xdmp:eval(
        $stmt,
        (xs:QName("call-params"),$cparams),
        <options xmlns="xdmp:eval">
            <isolation>different-transaction</isolation>
        </options>
     )
};
