xquery version "1.0-ml";
(:~
 : Model model Application framework model functions
 :)
module namespace model = "http://xquerrail.com/helper/model";

import module namespace js = "http://xquerrail.com/helper/javascript" at "../helpers/javascript-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "../config.xqy";

declare namespace json = "json:options";

declare option xdmp:mapping "false";

(:~
 : Holds a cache of json options per models
 :)
declare variable $JSON-OPTIONS-MODEL-CACHE := map:map();

(:~
 : Sets the function in the value cache
 :)
declare function model:set-options-cache(
  $key as xs:string,
  $value
) {
  (
    map:put($JSON-OPTIONS-MODEL-CACHE,$key,$value),
    $value
  )
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function model:get-options-cache(
  $key as xs:string
) {
   map:get($JSON-OPTIONS-MODEL-CACHE,$key)
};

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

declare function model:field-key(
  $field as element()
) as xs:string {
  domain:get-field-json-name($field)
};

declare function model:build-json(
  $field as element() ,
  $instance as element()
) {
  model:build-json($field,$instance,fn:false())
};

declare function model:build-json(
  $field as element() ,
  $instance as element(),
  $include-root as xs:boolean
) {
  model:build-json($field,$instance,$include-root,model:get-json-options($field/ancestor-or-self::domain:model, ()))
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
        return model:build-json($field,$instance,$include-root,$options)
        ,
        if($field/@reference and $field/@type eq "reference") then
          if($field/@occurrence = ("+","*")) then
            let $value := domain:get-field-value($field,$instance)
            return
              if(fn:empty($value)) then
                js:kv(model:field-key($field),())
              else
                js:kv(model:field-key($field),
                  js:a(
                    for $ref in $field-value
                    return
                      if($options/json:flatten-reference/xs:boolean(.)) then
                        fn:string($ref)
                      else
                        js:kv(
                          model:field-key($field),
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
              js:kv(model:field-key($field),fn:string($field-value))
            else
              js:kv(
                model:field-key($field),
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
              js:kv(model:field-key($field),
                (
                  js:kv("uri", fn:string($field-value)),
                  js:kv("filename", fn:string($field-value/@filename)),
                  js:kv("contentType",fn:string($field-value/@content-type))
                )
              )
            else js:kv(model:field-key($field),"")
        else if($field/@type eq "identity") then
          js:kv(model:field-key($field),fn:string($field-value))
        else if($field/@type eq "schema-element") then
          js:kv(model:field-key($field),$field-value/node() ! xdmp:quote(.))
        else if(domain:model-exists($field/@type)) then
          if($field/@occurrence = ("*","+")) then
            js:kv(model:field-key($field),js:a(
              for $v in $field-value
              return js:o((
                domain:get-model($field/@type) ! model:build-json(.,$v,$include-root,$options)
              ))
            ))
          else
            js:kv(model:field-key($field),
              for $v in $field-value
              return js:o((
                domain:get-model($field/@type) ! model:build-json(.,$v,$include-root,$options)
              ))
            )
        else
          if($field/@occurrence = ("*","+")) then
            js:kv(model:field-key($field), js:a($field-value ! fn:string(.)[. ne ""]))
          else
            js:kv(model:field-key($field), $field-value)
      )
    case element(domain:attribute) return
      let $field-value := model:field-value($field,$instance,$options)
      return
        js:kv(model:field-key($field),$field-value)
    case element(domain:container) return
      if($options/json:strip-container/xs:boolean(.)) then
        for $field in $field/(domain:element|domain:container|domain:attribute)
        return model:build-json($field,$instance,$include-root,$options)
      else
        js:kv(
          model:field-key($field),
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
  model:to-json($model,$instance,fn:false(),())
};

declare function model:to-json(
  $model as element(domain:model),
  $instance as element(),
  $include-root as xs:boolean
) {
  model:to-json($model,$instance,$include-root,())
};

declare function model:to-json(
  $model as element(domain:model),
  $instance as element(),
  $include-root as xs:boolean,
  $options as element(json:options)?
) {
  if($model/@name eq fn:local-name($instance)) then
    model:build-json(
      $model,
      $instance,
      $include-root,
      model:get-json-options($model, $options)
    )
  else
    fn:error(xs:QName("MODEL-INSTANCE-MISMATCH"),
    fn:string(
      <msg>{$instance/fn:local-name(.)} does not have same signature model name:{fn:data($model/@name)}</msg>)
    )
 };

declare %private function model:get-json-options(
  $model as element(domain:model),
  $options as element(json:options)?
) as element(json:options) {
  let $cached-options := model:get-options-cache($model/@name)
  return
    if (fn:exists($cached-options)) then
      $cached-options
    else
      let $cached-options :=
        if (fn:exists($options)) then
          $options
        else
          let $get-options-fn := domain:get-model-function((), $model/@name, "get-json-options", 1, fn:false())
          return
            if (fn:exists($get-options-fn)) then
              xdmp:apply(
                $get-options-fn,
                $model
              )
            else
              <json:options/>
      return model:set-options-cache($model/@name, $cached-options)
};
