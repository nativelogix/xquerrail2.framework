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

import module namespace model = "http://xquerrail.com/model/base" at "../base/base-model.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";

declare namespace  xq = "http://xquerrail.com/roxy";

declare function xq:apply-xquerrail-changes(
  $model-name as xs:string
) {
  let $model :=
    if (domain:model-exists($model-name)) then
      domain:get-model($model-name)
    else
      fn:error(xs:QName("MODEL-NOT-FOUND"), text{"Cannot found model", $model-name})
  let $model :=
    if ($model/@persistence eq 'directory') then
      $model
    else
      fn:error(xs:QName("PERSISTENCE-NOT-SUPPORTED"), text{"Persistence not supported", $model-name, $model/@persistence})
  let $root-uri := $model/domain:directory
  let $collection := $model/domain:collection
  let $permissions := domain:get-permissions($model)
  return xdmp:directory($root-uri, "infinity")/node() ! (
    xq:update-instance(., $permissions, $collection)
  )
};

declare function xq:update-instance(
  $instance as item(),
  $permissions as element()*,
  $collection as xs:string*
) {
  xdmp:log(text{"About to update", xdmp:node-uri($instance)}, "debug"),
  xdmp:spawn-function(
    function() {
      xdmp:document-insert(
        xdmp:node-uri($instance),
        $instance,
        $permissions,
        $collection
      ),
      xdmp:commit()
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
      <result>false</result>
    </options>
  )
};

declare function xq:refresh-cache(
  $base-url as xs:string
) {
  let $initialize-url := fn:concat($base-url, "/initialize.xqy")
  let $response := xdmp:http-get($initialize-url)
  return xdmp:log($response)
};

