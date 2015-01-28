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
 : Model model Application framework model functions
 :)
module namespace model = "http://xquerrail.com/helper/model";

import module namespace js = "http://xquerrail.com/helper/javascript" at "../helpers/javascript-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "../config.xqy";

declare namespace json = "json:options";

declare option xdmp:mapping "false";

declare function model:field-value(
  $field as element(),
  $instance as element(),
  $options as element(json:options)
) {
  let $field-value := domain:get-field-value($field,$instance)
  return
    if ($options/json:empty-string/xs:boolean(.) and $field/@type eq "string" and fn:empty($field-value)) then
      ""
    else
      $field-value
};

declare function model:build-json(
  $field as element() ,
  $instance as element()
) {
  model:build-json($field,$instance,fn:false(),<json:options/>)
};

declare function model:build-json(
  $field as element() ,
  $instance as element(),
  $include-root as xs:boolean
) {
  model:build-json($field,$instance,$include-root,<json:options/>)
};

(:~
  3 options boolean supported:
  - empty-string convert empty string field in "" instead of empty sequence
  - strip-container ignore container
  - flatten-reference reference are converter in single field with key label value
:)
declare function model:build-json(
  $field as element(),
  $instance as element(),
  $include-root as xs:boolean,
  $options as element(json:options)
) {
  typeswitch($field)
    case element(domain:model) return
      let $to-json-function := domain:get-model-function((), $field/@name, "to-json", 2, fn:false())
      return
        if (fn:exists($to-json-function)) then
          xdmp:apply(
            $to-json-function,
            $field,
            $instance
          )
        else
          if ($include-root) then
            js:kv(
              $field/@name,
              js:o((
                for $f in $field/(domain:container|domain:attribute|domain:element)
                return model:build-json($f,$instance,$include-root,$options)
              ))
            )
          else
            js:o((
              for $f in $field/(domain:container|domain:attribute|domain:element)
              return model:build-json($f,$instance,$include-root,$options)
            ))
    case element(domain:element) return
      let $field-value := model:field-value($field,$instance,$options)
      return (
        for $field in $field/(domain:attribute)
        return model:build-json($field,$instance,$include-root,$options),
        if($field/@reference and $field/@type eq "reference") then
          if($field/@occurrence = ("+","*")) then
            let $value := domain:get-field-value($field,$instance)
            return
              if(fn:empty($value)) then
                js:kv($field/@name,())
              else
                js:kv($field/@name,
                  js:a(
                    for $ref in $field-value
                    return
                      if($options/json:flatten-reference/xs:boolean(.)) then
                        fn:string($ref)
                      else
                        js:kv(
                          $field/@name,
                          js:o((
                            js:kv("text", fn:string($ref)),
                            js:kv("id", fn:string($ref/@ref-id)),
                            js:kv("type",fn:string($ref/@ref))
                          ))
                        )
                  )
                )
          else
            if($options/json:flatten-reference/xs:boolean(.)) then
              js:kv($field/@name,fn:string($field-value))
            else
              js:kv(
                $field/@name,
                js:o((
                  js:kv("text", fn:string($field-value)),
                  js:kv("id", fn:string($field-value/@ref-id)),
                  js:kv("type",fn:string($field-value/@ref))
                ))
              )
            else if($field/@type eq "binary") then
              let $value := domain:get-field-value($field,$instance)
              return
                if($value) then
                  js:kv($field/@name,
                    (
                      js:kv("uri", fn:string($field-value)),
                      js:kv("filename", fn:string($field-value/@filename)),
                      js:kv("contentType",fn:string($field-value/@content-type))
                    )
                  )
                else js:kv($field/@name,"")
            else if($field/@type eq "identity") then
              js:kv($field/@name,fn:string($field-value))
            else if($field/@type eq "schema-element") then
              js:kv($field/@name,$field-value/node() ! xdmp:quote(.))
            else if(domain:model-exists($field/@type)) then
              if($field/@occurrence = ("*","+")) then
                js:kv($field/@name,js:a(
                  for $v in $field-value
                  return js:o((
                    domain:get-model($field/@type) ! model:build-json(.,$v,$include-root,$options)
                  ))
                ))
              else
                js:kv($field/@name,
                  for $v in $field-value
                  return js:o((
                    domain:get-model($field/@type) ! model:build-json(.,$v,$include-root,$options)
                  ))
                )
            else
              if($field/@occurrence = ("*","+")) then
                js:kv($field/@name, js:a($field-value ! fn:string(.)[. ne ""]))
              else
                if($field/@type = "string") then
                  js:kv($field/@name,($field-value)[1])
                else if($field/@type = "boolean") then
                  let $field-value := if(fn:string($field-value) eq "true") then fn:true() else fn:false()
                  return js:kv($field/@name, $field-value)
                else js:kv($field/@name, ($field-value,"")[1])
      )
    case element(domain:attribute) return
      let $field-value := model:field-value($field,$instance,$options)
      return
        js:kv(fn:concat(config:attribute-prefix(),$field/@name),$field-value)
    case element(domain:container) return
      if($options/json:strip-container/xs:boolean(.)) then
        for $field in $field/(domain:element|domain:container|domain:attribute)
        return model:build-json($field,$instance,$include-root,$options)
      else
        js:kv(
          $field/@name,
          js:o(
            for $field in $field/(domain:element|domain:container|domain:attribute)
            return model:build-json($field,$instance,$include-root,$options)
          )
        )
    default return ()
};

declare function model:to-json(
  $model as element(domain:model),
  $instance as element()
) {
  model:to-json($model,$instance,fn:false(),<options xmlns="json:options"/>)
};

declare function model:to-json(
  $model as element(domain:model),
  $instance as element(),
  $include-root as xs:boolean
) {
  model:to-json($model,$instance,$include-root,<json:options/>)
};

declare function model:to-json(
  $model as element(domain:model),
  $instance as element(),
  $include-root as xs:boolean,
  $options as element(json:options)
) {
  if($model/@name eq fn:local-name($instance)) then
    model:build-json($model,$instance,$include-root,$options)
  else
    fn:error(xs:QName("MODEL-INSTANCE-MISMATCH"),
    fn:string(
      <msg>{$instance/fn:local-name(.)} does not have same signature model name:{fn:data($model/@name)}</msg>)
    )
 };
