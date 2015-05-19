(:
: Copyright 2011 - NativeLogix
:
: Licensed under the Apache License, Version 2.0 (the "License");
: you may not use this file except in compliance with the License.
: You may obtain a copy of the License at
:
: http://www.apache.org/licenses/LICENSE-2.0
:
: Unless required by applicable law or agreed to in writing, software
: distributed under the License is distributed on an "AS IS" BASIS,
: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
: See the License for the specific language governing permissions and
: limitations under the License.
:
:
:
:
:
:)xquery version "1.0-ml";
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
 : Builds a instance of an element based on a domain:model
 : Provides a caching mechanism to optimize speedup of calling builder functions.
 :)
module namespace builder = "http://xquerrail.com/builder";

import module namespace domain  ="http://xquerrail.com/domain" at "domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";

declare namespace as = "http://www.w3.org/2009/xpath-functions/analyze-string";

(:Options Definition:)
declare option xdmp:mapping "false";
declare option xdmp:output "indent-untyped=yes";

declare variable $COLLATION := "http://marklogic.com/collation/codepoint";
declare variable $SIMPLE-TYPES := 
(
    "string"
);
declare variable $builder-cache := map:map();
declare variable $reference-cache := map:map();
declare variable $binary-dependencies := map:map();
declare variable $current-identity := ();


declare function builder:add-builder(
  $model as element(domain:model)
) {
   let $builder := builder:build($model)
   return (
        map:put($builder-cache,$model/@name,$builder),
        $builder
   )
};

declare function builder:builder(
  $model as element(domain:model)
) {
   let $current := map:get($builder-cache, $model/@name)
   return
     if(fn:exists($current)) 
     then $current
     else builder:add-builder($model)
};

declare function builder:builder-exists($model) {
   map:contains($builder-cache, $model/@name)
};
declare function builder:xpath($field) {
fn:substring-after(xdmp:path($field),"/domain:model")
};
declare function builder:build($field as element()) {
    let $namespace := domain:get-field-namespace($field)
    let $occurrence := ($field/@occurrence)
    return
    typeswitch($field)
       case element(domain:model) return 
         fn:string-join(
           ("function($model as element(domain:model), $current as item()*) {&#xA;",
           xdmp:quote(element {fn:QName($namespace,$field/@name)} 
           {
             for $n in $field/(domain:attribute|domain:element|domain:container)
             return
                builder:build($n)
           }),
           "&#xA;}")," ")
     case element(domain:attribute) return
         attribute {fn:QName($namespace,$field/@name)} {(
           "{domain:get-field-value($model",builder:xpath($field), ", $current)}&#xA;"
         )}
     case element(domain:element) return ("{",
         " for $c in ",
           fn:concat("domain:get-field-value($model",builder:xpath($field),", $current)"),
         " return ",
         element{fn:QName($namespace,$field/@name)} {
            "{$c}"
         },
       "}&#xA;")
     (:case element(domain:element) return fn:concat("{base:recursive-build($model",builder:xpath($field),",(),$current)}"):)
     case element(domain:container) return element {fn:QName($namespace,$field/@name)} {
       for $n in $field/(domain:element|domain:attribute|domain:container)
       return
         builder:build($n)
     }
     default return () 
 };

