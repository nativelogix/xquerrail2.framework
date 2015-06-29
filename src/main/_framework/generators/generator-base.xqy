xquery version "1.0-ml";
(:~
 :Generates Expression Code that allows for dynamic functions for mode CRUD operations
 : This performs improvements over iterative generation of domain models
~:)
module namespace generator =  "http://xquerrail.com/generator/base";

import module namespace base = "http://xquerrail.com/model/base" at "../base/base-model.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace cache = "http://xquerrail.com/cache" at "../cache.xqy";
import module namespace config = "http://xquerrail.com/config" at "../config.xqy";

declare option xdmp:mapping "false";

declare variable $GENERATOR-PREFIX := "generator";

declare variable $TAB := "&#9;";
declare variable $NL  := "&#xA;";
declare variable $RB  := "}";
declare variable $LB  := "{";
declare variable $LP  := "(";
declare variable $RP  := ")";

declare variable $FORMAT-IN := ("map","json","xml");
declare variable $FORMAT-OUT := ("map","json","xml");
declare variable $DEFAULT-GENERATOR-PATH := "_generated_";
declare variable $DEFAULT-GENERATOR-SUFFIX := "-generator.xqy";
declare variable $ENABLE-GENERATOR-KEY := "enable-generator";

(:~
 : These functions allow for importing modules dynamically into generators
~:)
declare variable $DEFAULT-IMPORTS :=
  (
   'import module namespace base = "http://xquerrail.com/model/base" at "' || config:resolve-framework-path("base/base-model.xqy") || '";',
   'import module namespace context = "http://xquerrail.com/context" at "' || config:resolve-framework-path("context.xqy") || '";',
   'import module namespace domain = "http://xquerrail.com/domain" at "' || config:resolve-framework-path("domain.xqy") || '";'
  );

(:~
 : Returns the QName of a domain model as an expression
 : The QName is in the format "fn:QName($namespace-uri,$local-name)"
 :)
declare function field-qname-expression(
  $field as element()
) {
   xdmp:describe(domain:get-field-qname($field),(),())
};
(:~
 : Returns an expression that represents the defaultValue assigned to a field
 : if a defaultValue is not present or is equal to empty("") then an empty sequence is returned.
 :)
declare function field-defaultValue(
   $node as element(),
   $options as map:map
) {
 if($node/@default and $node/@default ne "")
 then fn:concat("'",$node/@default,"'")
 else "()"
};

(:~
 : Returns the root xpath expression for use in a cts:search expression
 :)
declare function model-xpath-expression(
  $field as element()
) {
  let $namespaces := domain:declared-namespaces-map($field)
  return
      fn:string-join(
      for $path at $pos in $field/ancestor-or-self::*[fn:node-name(.) = $domain:DOMAIN-FIELDS]
      return
       typeswitch($path)
        case element(domain:attribute) return fn:concat("/@",$path/@name)
        default return (
          if($path instance of element(domain:model) and $path/@persistence = "document")
          then fn:concat("/",domain:get-field-prefix($path),":",$path/domain:document/@root)
          else (),
          fn:concat("/",domain:get-field-prefix($path),":",$path/@name)
        )
      ,"")
};

(:~
 : Constructs a search expression based on a givem model as a reference
 : @param $domain-model - THe domain model to create the search expression
 :)
declare function get-model-search-expression(
    $domain-model as element(domain:model),
    $query as cts:query?,
    $options as xs:string*
) {
  let $pathExpr :=
      switch($domain-model/@persistence)
      case "document" return
         fn:concat("fn:doc('", $domain-model/domain:document/text(),"')",model-xpath-expression($domain-model))
      case "directory" return
         fn:concat("fn:collection()",domain:get-field-absolute-xpath($domain-model))
      default return
         fn:concat("cts:element-query(",xdmp:describe(domain:get-field-qname($domain-model),(),()), "'),cts:and-query(()))")
  let $baseQuery := domain:get-base-query($domain-model)
  return
       "cts:search(" || $pathExpr || "," || xdmp:describe(cts:and-query(($baseQuery,$query)),(),()) || "," || xdmp:describe($options,(),()) || ")"
};
(:~
 : Creates a distinct declaration of namespaces defined in the domain model
 : @param $nodes a list of common namespace definitions.  Type can be of element(application-namespace|content-namespace|declare-namespace)
~:)
declare function namespace-declarations-expression(
   $nodes
) {
   let $map := json:object()
   let $_ := $nodes ! map:put($map,./@prefix,./@namespace-uri)
   for $key in map:keys($map)
   return
      <domain:declare-namespace prefix="{$key}" namespace-uri="{(map:get($map,$key))}"/>
};
(:~
 : Creates a returnType expression for the given model.
~:)
declare function model-returnType-expression(
  $node as element(domain:model),
  $options as map:map
) {
  fn:concat("element(", domain:get-field-prefix($node),":",$node/@name,")")
};

(:~
 : Creates an expression to represent a reference call for a model reference
 :)
declare function model-reference-expression($mode,$persistence,$node, $options) as xs:string {
   let $ref-tokenz := fn:tokenize($node/@reference,":")
   let $model          := $ref-tokenz[2]
   let $funct          := $ref-tokenz[3]
   let $ref-model      := domain:get-model($model)
   let $key            := domain:get-model-key-field($ref-model)
   let $keyLabel       := domain:get-model-keyLabel-field($ref-model)
   let $key-xpath      := domain:get-field-xpath($key)
   let $keyLabel-xpath := domain:get-field-xpath($keyLabel)
   let $ref-query      := domain:get-identity-query($ref-model,map:entry($key/@name,"__PLACEHOLDER__"))
   let $search-expr    := fn:replace(get-model-search-expression($ref-model,$ref-query,()),'"__PLACEHOLDER__"',"\$reference-id")
   return
      <template>
         function() {{
         if(fn:exists($current) or fn:exists($update)) then
         for $reference-id in {field-get-expression("update",$persistence,$node,$options)}
         let $reference := {$search-expr}
         return
           if($reference) then
           element {{ {xdmp:describe(domain:get-field-qname($node))} }} {{
                 attribute ref-type {{ "model" }},
                 attribute ref-id   {{fn:data($reference{$key-xpath})}},
                 attribute ref      {{"{fn:data($ref-model/@name)}"}},
                 text{{fn:data($reference{$keyLabel-xpath})}}
            }}
            else ()
         else ()
         }}()
         </template>

};
(:~
 : Converts a reference into a map defining expression
~:)
declare function parse-reference($node) {
   let $parts := fn:tokenize($node/@reference,":")
   return
     map:new((
       map:entry("type",$parts[1]),
       map:entry("scope",$parts[2]),
       map:entry("function",$parts[3])
     ))
};
(:~
 : Returns a function that returns the reference for an application
 :)
declare function application-reference-expression(
  $node as element(),
  $options as map:map
) as xs:string {
   let $ref := parse-reference($node)
   let $funct := map:get($ref,"function")
   let $scope := map:get($ref,"scope")
   return
     switch(fn:true())
     case $scope eq "model" return "()"
      (:<template>
         function() {{
            let $ref-value := domain:model-{$funct}[@name = {field-get-expression("create","map",$node,$options)}]
            for $ref in $ref-value
            return
               element {{{field-qname-expression($node)}}} {{
                   attribute ref-type {{ "application" }},
                   attribute ref-id   {{$ref/@name}},
                   attribute ref      {{$ref/@name}},
                   text{{$ref/@displayLabel}}
               }}
         }}()
      </template>:)
      default return fn:error(xs:QName("GENERATOR-REFERENCE-ERROR"),"Unable to create reference function for generator")
};

declare function extension-reference-expression($node,$options) {
  ""
};


(:~
 :Returns a reader get expression based on the reader type
 :)
declare function field-get-expression(
  $mode as xs:string,
  $format as xs:string,
  $node as element(),
  $options as map:map
) as xs:string {
  let $variable := if($mode = "update") then "$update" else "$current"
  return
    switch($format)
    case "map"  return fn:concat("map:get(",$variable,",'",domain:get-field-name-key($node),"')")
    case "json" return fn:concat($variable,domain:get-field-jsonpath($node))
    default return     fn:concat($variable,domain:get-field-xpath($node))
};

declare function field-exists-expression(
  $mode as xs:string,
  $format as xs:string,
  $node as element(),
  $options as map:map
) as xs:string {
  let $variable := if($mode = "update") then "$update" else "$current"
  return
    switch($format)
    case "map"  return fn:concat("map:contains(",$variable,",'",domain:get-field-name-key($node),"')")
    case "json" return fn:concat("fn:exists(",$variable,domain:get-field-jsonpath($node),")")
    default return     fn:concat($variable,domain:get-field-xpath($node))
};

(:~
 : Creates an update expression as a recursive compiler
~:)
declare function field-build-expression(
$node as element(),
$options as map:map
) as xs:string {
   let $xs-type := domain:resolve-datatype($node)
   let $is-multi := $node/@occurrence = ("+","*")
   let $default-value := $node/@default[. ne ""]
   let $type-func := fn:concat("type:",$node/@type)
   let $format  := (map:get($options,"format"),"xml")[1]
   let $persistence :=
        if(map:contains($options,"persistence"))
        then map:contains($options,"persistence")
        else fn:data($node/ancestor::domain:model/@persistence)
   let $is-model := domain:get-base-type($node,fn:true()) = ("instance","model")
   return
   fn:normalize-space(
     (:Allow Injector from calling function:)
     if(map:contains($options,$type-func))
     then map:get($options,$type-func)($node,$options)
     else
     fn:normalize-space(
     switch($node/@type)
     case "identity" return
        <template>
        fn:string(if({field-exists-expression("update",$format,$node,$options)})
                then {field-get-expression("update",$format,$node,$options)}
                else if({field-exists-expression("create",$persistence,$node,$options)})
                then {field-get-expression("create",$persistence,$node,$options)}
                else base:generate-uuid())
        </template>
     case "create-timestamp" return
        <template>
            if({field-exists-expression("create",$persistence,$node,$options)})
            then {field-get-expression("create",$persistence,$node,$options)}
            else fn:current-dateTime()</template>
     case "create-user"      return  <template>if({field-exists-expression("create",$persistence,$node,$options)}) then {field-get-expression("create",$persistence,$node,$options)} else context:user()</template>
     case "update-timestamp" return  <template>fn:current-dateTime()</template>
     case "update-user"      return  <template>context:user()</template>
     case "binary"           return  fn:error(xs:QName("UNSUPPORTED-TYPE-EXCEPTION"),"binary type is not currently supported")
     case "sequence"         return
        <template>
        if({field-exists-expression("update",$format,$node,$options)})
        then {field-get-expression("update",$format,$node,$options)}
        else if({field-exists-expression("create",$persistence,$node,$options)})
        then {field-get-expression("create",$persistence,$node,$options) + 1}
        else 1
        </template>
     case "reference" return
       let $ref-type := $node/@reference
       let $ref-parts := fn:tokenize($ref-type,":")
       let $type := $ref-parts[1]
       return
          switch($ref-parts[1])
          case "model"       return  model-reference-expression("update",$format,$node,$options)
          case "application" return  application-reference-expression($node,$options)
          case "extension"   return  extension-reference-expression($node,$options)
          default return fn:error(xs:QName("UNRESOLVED-REFERENCE-EXPRESSION"), "Cannot create reference expression",$ref-parts[1])
     case "schema-element" return
        <template>
            if({field-exists-expression("update",$format,$node,$options)})
            then {field-get-expression("update",$format,$node,$options)}
            else if({field-exists-expression("create",$persistence,$node,$options)})
            then {field-get-expression("create",$persistence,$node,$options)}
            else {field-defaultValue($node,$options)}
        </template>
    case "sequence"         return
        <template>
        if({field-exists-expression("update",$format,$node,$options)})
        then {field-get-expression("update",$format,$node,$options)}
        else if({field-exists-expression("create",$persistence,$node,$options)})
        then {field-get-expression("create",$persistence,$node,$options) + 1}
        else 1
        </template>
        default return
       if($is-model) then
          <template>(
               if({field-exists-expression("update",$format,$node,$options)})
               then {field-get-expression("update",$format,$node,$options)}
               else if({field-exists-expression("create",$persistence,$node,$options)})
               then {field-get-expression("create",$persistence,$node,$options)}
               else {field-defaultValue($node,$options)}
            )
           </template>
       else if($is-multi) then
           <template>{$xs-type}(
               if({field-exists-expression("update",$format,$node,$options)})
               then {field-get-expression("update",$format,$node,$options)}
               else if({field-exists-expression("create",$persistence,$node,$options)})
               then {field-get-expression("create",$persistence,$node,$options)}
               else {field-defaultValue($node,$options)}
            )
           </template>
       else
         <template>(
               if({field-exists-expression("update",$format,$node,$options)})
               then {field-get-expression("update",$format,$node,$options)}
               else if({field-exists-expression("create",$persistence,$node,$options)})
               then {field-get-expression("create",$persistence,$node,$options)}
               else {field-defaultValue($node,$options)}
            )[. ne ""] ! {$xs-type}(.)
        </template>
    ))
};
(:~
 : Abstract generate-build-expression
~:)
declare function generate-build-expression(
  $node as node(),
  $options as map:map
) {
   let $persistence := (map:get($options,"persistence"),"xml")[1]
   return
     switch($persistence)
     case "json" return generate-build-expression-json($node,$options)
     default return generate-build-expression-xml($node,$options)
};

declare function generate-build-expression-json(
  $node as node(),
  $options as map:map
)  as xs:string {
   fn:error(xs:QName("NOT-SUPPORTED-EXCEPTION"),"Not support json persistence now")
};

declare function generate-build-expression-xml(
  $node as node(),
  $options as map:map
) as xs:string {
    switch(fn:node-name($node))
    case xs:QName("domain:content-namespace")
    case xs:QName("domain:application-namespace")
    case xs:QName("domain:declare-namespace") return
       fn:string(<template>declare namespace {fn:data($node/@prefix)} = "{fn:string($node/@namespace-uri)}";</template>)
    case xs:QName("domain:model") return
        let $constructor-type := map:get($options,"build")
        return
          fn:string-join((
             switch($constructor-type)
             case "inline" return fn:concat("function($current,$update)"," as ", model-returnType-expression($node,$options),"{")
             case "library"   return fn:concat("declare function ", $GENERATOR-PREFIX, ":update($current,$update)"," as ", model-returnType-expression($node,$options),"{")
             default return fn:error(xs:QName("UNKNOWN-UPDATE-CONSTRUCTOR"),"Cannot construct function with type",$constructor-type)
             ,
             fn:concat(" element {",xdmp:describe(domain:get-field-qname($node)),"}{"),
             fn:string-join((
                    fn:concat("attribute xsi:type {'",$node/@name,"'}"),
                    $node/(domain:attribute)                ! generate-build-expression(.,$options),
                    $node/(domain:element|domain:container) ! generate-build-expression(.,$options)
                 )[fn:normalize-space(.) ne ""],",&#xA;"),
             "}",
             switch($constructor-type)
             case "inline"    return "}"
             case "library"   return "};"
             default return fn:error(xs:QName("UNKNOWN-UPDATE-CONSTRUCTOR"),"Cannot construct function with type",$constructor-type)
       ),"&#xA;")
    case xs:QName("domain:container") return
        fn:string-join((
            fn:concat("element {", xdmp:describe(domain:get-field-qname($node)), "}"),
           "{(&#xA;",
             fn:string-join((
                $node/domain:attribute ! generate-build-expression(.,$options),
                $node/domain:element   ! generate-build-expression(.,$options)
                )[fn:normalize-space(.) ne ""]
             ,",&#xA;"),
        ")}"
        )," ")
    case xs:QName("domain:attribute")
    case xs:QName("domain:element") return
      let $is-multi := $node/@occurrence = ("+","*")
      let $is-reference := fn:true() = (fn:exists($node/@reference) and $node/@type eq "reference")
      let $is-nullable  := $node/@nullable eq "true" or $node instance of element(domain:attribute) or $node/@occurrence = "?"
      let $is-model := domain:get-base-type($node,fn:true()) = ("instance","model")
      return
      if($is-model) then
        <template>
          {field-build-expression($node,$options)} !
          element {{{field-qname-expression($node)}}} {{
             ./(@*|node())
          }}
        </template>
      else if($is-multi or $is-nullable) then
          fn:string-join((
                  fn:concat(field-build-expression($node,$options)," ! "),
                  fn:concat(fn:local-name($node)," {", xdmp:describe(domain:get-field-qname($node)), "}"),
                  "{(",$NL,
                      fn:string-join((
                         $node/domain:attribute ! generate-build-expression(.,$options),
                         if($is-reference) then "./(@*|node())" else "."
                      ),"," || $NL),
                  "&#9;)}"
          ),$NL)
      else
          fn:string-join((
              fn:concat(fn:local-name($node)," {", xdmp:describe(domain:get-field-qname($node)), "}"),
              "{(",$NL,
                  fn:string-join((
                     $node/domain:attribute ! generate-build-expression(.,$options),
                     field-build-expression($node,$options)
                  ),"," || $NL),
              "&#9;)}"
              )
         )
     default return fn:error(xs:QName("UNKNOWN-ERROR"),"Node Error",xdmp:describe($node))
};
(:~
 : Craetes a module expression based on the output type.
~:)
declare function declare-module-expression(
  $model as element(domain:model),
  $options as map:map
) as xs:string{
    if(map:get($options,"build") = "library")
    then
       <template>
       module namespace generator = '{fn:data($model/ancestor::domain:domain/domain:application-namespace/@namespace-uri)}/generator/{fn:data($model/@name)}';
       </template>
    else if(map:get($options,"build") = "map") then
       <template>
       declare default function namespace '{fn:data($model/ancestor::domain:domain/domain:application-namespace/@namespace-uri)}/generator/{fn:data($model/@name)}';
       </template>
    else ""
};

(:~
 : Generates a Library Module including all namespace and import statements
 : This is used to save modules into application modules directory.
 :)
declare function generate-library-module(
   $model as element(domain:model),
   $options as map:map
) {
    let $functions := map:get($options,"functions")
    let $generated :=
         fn:string-join((
             "xquery version '1.0-ml';",
             declare-module-expression($model,$options),
             $DEFAULT-IMPORTS,
             "(:Namespace Declarations:)",
              namespace-declarations-expression($model/ancestor::domain:domain/(domain:content-namespace|domain:application-namespace|domain:declare-namespace))
              ! generate-build-expression(.,$options),
              if($functions = "build") then generate-build-expression($model,$options) else ()
         ),$NL)
    return
       try{
          xdmp:pretty-print($generated)
       } catch($err) {
         fn:error(xs:QName("COMPILATION-ERROR"),"Unable to compile module",$err)
       }
};

(:~
 : Generates a Library Module including all namespace and import statements
 :)
declare function generate-function-module(
   $model as element(domain:model),
   $options as map:map
) {
    let $functions := map:get($options,"functions")
    let $generated :=
        xdmp:pretty-print(fn:string-join((
             "xquery version '1.0-ml';",
             declare-module-expression($model,$options),
             $DEFAULT-IMPORTS,
             "(:Namespace Declarations:)",
              namespace-declarations-expression($model/ancestor::domain:domain/(domain:content-namespace|domain:application-namespace|domain:declare-namespace)) ! generate-build-expression(.,$options),
              "map:get(
                map:new((",
              fn:string-join((

                 fn:concat("map:entry('build',", generate-build-expression($model,$options),")")
              ),","),
              ")),?)"
         ),$NL))
      return try{
          $generated
       } catch($err) {
         fn:error(xs:QName("COMPILATION-ERROR"),"Unable to compile module",($err,$generated))
       }
};
(:~
 : Returns a main module where the return is a function curry'd as a map:get.
 : This allows the outer function to return the function by its name such as
 : xdmp:invoke("/_generated_/model-hash.xqy")("create")
~:)
declare function generate-main-module(
  $model as element(domain:model),
  $options as map:map
) {
  let $output-directory := map:get($options,"output-directory")
  let $module-expression := generate-function-module($model,$options)
  let $module-persistence :=
    if(xdmp:modules-database() eq 0)
    then "filesystem"
    else "database"
  let $module-root := xdmp:modules-root()
  let $base-uri := fn:concat(
    $module-root,if(fn:ends-with($module-root,"/")) then "" else "/",
    $output-directory,
    "/"
  )
  let $module-uri := fn:concat($base-uri,$model/@name,"-generator.xqy")
  let $save :=
    switch($module-persistence)
    case "filesystem" return (
      if(xdmp:filesystem-file-exists($base-uri))
      then ()
      else
        xdmp:filesystem-directory-create#2(
          $base-uri,
          <options xmlns="xdmp:filesystem-directory-create">
            <create-parents>true</create-parents>
          </options>),
        xdmp:save(
          $module-uri,
          text {$module-expression}
        )
    )
    case "database" return
      xdmp:spawn-function(
        function() {
          xdmp:log(text{"About to save generated module", $module-uri}),
          xdmp:document-insert(
            $module-uri,
            text {$module-expression},
            $cache:CACHE-PERMISSIONS,
            xdmp:default-collections()
          ),
          xdmp:commit()
        },
        <options xmlns="xdmp:eval">
          <database>{xdmp:modules-database()}</database>
          <transaction-mode>update</transaction-mode>
        </options>
      )
     default return fn:error(xs:QName("PERSISTENCE-ERROR"),"Could not resolve module-persistence")
   return $module-uri
};

(:~
 : Clears generator modules previously created
 : using the generator
~:)
declare function reset(
) as empty-sequence() {
  let $_ := cache:remove-domain-cache($cache:SERVER-FIELD-CACHE-LOCATION, $ENABLE-GENERATOR-KEY)
  let $module-persistence :=
    if(xdmp:modules-database() eq 0)
    then "filesystem"
    else "database"
  return
    switch($module-persistence)
    case "filesystem" return ()
    case "database" return ()
    default return ()
};

(:~
 : Implements a keyed generator where the key is a qname representing the model
 : using the generator
~:)
declare function register-generator(
  $key as xs:string,
  $funct-map
) as empty-sequence() {
  (:map:put($GENERATOR-CACHE, $key, $funct-map):)
  cache:set-domain-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key, $funct-map)
};

(:~
 : Returns if the key and mode are present in generator map
~:)
declare function has-generator(
  $key,
  $mode as xs:string
) as xs:boolean {
  if (xs:boolean(cache:get-domain-cache($cache:SERVER-FIELD-CACHE-LOCATION, $ENABLE-GENERATOR-KEY))) then
    let $key-value :=
      if($key instance of element(domain:model))
      then xdmp:key-from-QName(domain:get-field-qname($key))
      else $key
    return
      let $funct-map := cache:get-domain-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key-value)
      return
        if(fn:exists($funct-map) and $funct-map($mode) instance of function(*))
        then fn:true()
        else fn:false()
  else fn:false()
};

(:~
 : Gets a generator either from the cache or as a function passed in by registering the generator.
~:)
declare function get-generator(
  $key as xs:string,
  $mode as xs:string
) {
  if(generator:has-generator($key,$mode))
  then cache:get-domain-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key)($mode)
  else
    let $generator-path :=
      if($key instance of element(domain:model))
      then fn:concat("/","_generated_/",$key/@name,$DEFAULT-GENERATOR-SUFFIX)
      else fn:concat("/","_generated_/",fn:local-name-from-QName(xdmp:QName-from-key($key)),$DEFAULT-GENERATOR-SUFFIX)
    let $generator-exists :=
      if(xdmp:modules-database() eq 0)
      then xdmp:filesystem-file-exists(fn:concat(xdmp:modules-root(),"/",$generator-path))
      else xdmp:invoke-function(
        function() {
          fn:doc-available($generator-path)},
          <options xmlns="xdmp:eval"><database>{xdmp:modules-database()}</database></options>
        )
    let $generator := xdmp:invoke($generator-path)
    return (
      xdmp:log("Invoking Generator Module:" || $generator-path),
      register-generator($key,$generator),
      $generator($mode)
    )
};

