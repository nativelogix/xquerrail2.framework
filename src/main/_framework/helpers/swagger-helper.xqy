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

module namespace swagger = "http://xquerrail.com/helper/swagger";

import module namespace jsh = "http://xquerrail.com/helper/javascript" at "javascript-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";

declare option xdmp:mapping "false";

declare variable $CACHE-MAP := map:map();
declare variable $SUFFIX-DEFAULT := "#";
declare variable $SUFFIX-PARAM := "suffix";
declare variable $SCHEMA-DEFAULT-VERSION :=  "http://json-schema.org/draft-04/schema#";
declare variable $TYPE-MAP := map:new((
  map:entry("string","string"),
  map:entry("integer","integer"),
  map:entry("decimal","number"),
  map:entry("long","number"),
  map:entry("float","number"),
  map:entry("double","number"),
  map:entry("dateTime","string"),
  map:entry("date","string"),
  map:entry("time","string"),
  map:entry("dayTimeDuration","number"),
  map:entry("yearMonthDuration","number"),
  map:entry("gYear","number"),
  map:entry("gMonth","number"),
  map:entry("create-timestamp","string"),
  map:entry("update-timestamp","string"),
  map:entry("identity","string"),
  map:entry("id","string")
));
declare variable $BUILT-IN-TYPES := (
  jsh:e("triple", jsh:o((
    (:jsh:e("id","triple"),:)
    jsh:e("type","object"),
    jsh:e("properties", jsh:o((
      jsh:e("subject",jsh:o(jsh:e("type","string"))),
      jsh:e("predicate",jsh:o(jsh:e("type","string"))),
      jsh:e("object",jsh:o(jsh:e("type","string")))
    ))),
    jsh:e("required",jsh:a(("subject","predicate","object")))
  )))
);
declare function swagger:get-annotations($field,$options) {
  if(map:get($options,"annotations") = "true")
  then
    jsh:o((
      jsh:e("attributes",jsh:o((
        for $nav in $field/@*
        return
          jsh:e(fn:local-name($nav),fn:data($nav))
      ))),
      jsh:e("navigation",jsh:o((
        for $nav in $field/domain:navigation/@*
        return
          jsh:e(fn:local-name($nav),fn:data($nav))
      ))),
      jsh:e("constraints",jsh:o((
        for $nav in $field/domain:constraint/@*
        return
          jsh:e(fn:local-name($nav),fn:data($nav))
      )))
    ))
  else jsh:o(())
};
declare function swagger:get-field-type($field) {
  let $simple := map:get($TYPE-MAP,$field/@type)
  return
    if($simple)
    then jsh:e("type", $simple)
    else
      if($field/ancestor::domain:domain/domain:model[fn:not(@name eq $field/@type)])
      then jsh:e("type", "string")
      else jsh:e("oneOf",jsh:a(jsh:e("$ref", fn:concat("#/definitions/",$field/@type))))
};
declare function swagger:get-iri($uri,$joiner) {
  if(fn:not(
  	fn:ends-with($uri,"#") or
  	fn:ends-with($uri,":") or
  	fn:ends-with($uri,"/")
  ))
  then fn:concat($uri,$SUFFIX-DEFAULT)
  else $uri
};
declare function swagger:build-json($entity,$params) {
  typeswitch($entity)
  case element(domain:domain) return
      let $appns :=
	  	swagger:get-iri(
	  		$entity/domain:application-namespace/@namespace-uri,
	  		map:get($params,$SUFFIX-PARAM)
	    )
	  return
        jsh:o((
	      jsh:e("$schema",$SCHEMA-DEFAULT-VERSION),
	      jsh:e("id",$appns),
	      jsh:e("type","object"),
	      jsh:e("annotations",jsh:o((
	         jsh:e("compiled",xs:boolean($entity/@compiled)),
	         jsh:e("timestamp",fn:string($entity/@timestamp)),
	         jsh:e("version", jsh:o((
	         	jsh:e("last-commit", $entity/domain:version/@last-commit),
	         	jsh:e("number",$entity/domain:version/@number)
	         ))),
	         jsh:e("contentNamespace", jsh:o((
	         	jsh:e(
	         	  $entity/domain:content-namespace/@prefix,
	              $entity/domain:content-namespace/@namespace-uri
	         )))),
	         jsh:e("declareNamespace", jsh:o(
	         	$entity/domain:declare-namespace !
	         	jsh:o((
	         	jsh:e(
	         	  ./@prefix,
	              ./@namespace-uri
	         ))))),
	         jsh:e("defaultCollation", fn:data($entity/domain:default-collation))
	       ))),
         jsh:e("builtins", jsh:o(($BUILT-IN-TYPES))),
	       (:Generate Models:)
	       jsh:e("definitions", jsh:o((
	       	for $model in $entity/domain:model
		      return
            swagger:build-json($model,$params)
		    ))),
		    jsh:e("properties",	jsh:o(
		        for $model in $entity/domain:model
		        return
            jsh:e($model/@name, jsh:o(jsh:e("$ref",fn:concat($SUFFIX-DEFAULT,"/definitions/",$model/@name))))
		    ))

	    ))
  case element(domain:model) return
    jsh:e($entity/@name, jsh:o((
      jsh:e("id",fn:concat($entity/@name)) ,
      jsh:e("title",fn:data($entity/@label)),
      jsh:e("type","object"),
      jsh:e("required",
      	jsh:a(
      		for $field in $entity/(domain:element|domain:attribute|domain:container)[
      		@required = "true" or
      		@identity = "true" or
      		@occurrence = ("+") or
      		fn:matches(@occurrence,"\d") or
      		./ancestor::domain:model/@key = @name or
      		./ancestor::domain:model/@keyLabel = @name
      		]
        	return $field/@name
        )
      ),
      jsh:e("properties", jsh:o(
        for $field in $entity/(domain:attribute|domain:element|domain:container|domain:triple)
        return swagger:build-json($field,$params)
      )),
      jsh:e("annotations", swagger:get-annotations($entity,$params))
    ))
  )
  (:
    case element(domain:element) return
    case element(domain:attribute) return jsh:e($entity/@name,jsh:o(()))
    case element(domain:container) return jsh:e($entity/@name,jsh:o(()))
  :)
  case element(domain:container) return jsh:e($entity/@name, jsh:o((
  	 jsh:e("id",fn:concat($entity/ancestor::domain:model/@name,".",$entity/@name)),
     jsh:e("title",($entity/@label,$entity/@name)[1]),
     jsh:e("type", "array"),
     jsh:e("items", jsh:o(
     	for $elem in $entity/(domain:attribute|domain:element|domain:container|domain:triple)
     	return  jsh:o(swagger:build-json($elem,$params))
     ))
  )))

  case element(domain:triple) return
     jsh:e($entity/@name, jsh:o((
        jsh:e("$ref", "#/builtins/triple"),
        jsh:e("title",($entity/@label,$entity/@name)[1])
     )))

  case element(domain:optionlist) return jsh:o(())

  case element(domain:enumeration) return jsh:o(())

  default return
	  jsh:e($entity/@name,jsh:o((
	  	  swagger:get-field-type($entity),
	  	  jsh:e("title",$entity/@label),
	  	  jsh:e("properties",jsh:o(
	  	  	for $elem in $entity/(domain:attribute|domain:element|domain:container|domain:triple)
	  	    return jsh:o(swagger:build-json($elem,$params))
	  	  )),
        jsh:e("annotations",swagger:get-annotations($entity,$params))
	  )))
};

declare function swagger:to-json($entity,$params) {
  xdmp:to-json(swagger:build-json($entity,$params)) ! (if (. instance of document-node()) then ./node() else .)
};
