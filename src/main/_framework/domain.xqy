xquery version "1.0-ml";
(:~
 : Controls all interaction with an application domain.  The domain provides annotations and 
 : definitions for dynamic features built into XQuerrail.  
 : @version 2.0
 :) 
module namespace domain = "http://xquerrail.com/domain";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-doc-2007-01.xqy"; 
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";


declare namespace qry = "http://marklogic.com/cts/query";

declare option xdmp:mapping "false";

(:~
 : A list of QName's that define in a model
 :)   
declare variable $DOMAIN-FIELDS := 
   xdmp:eager(for  $fld in ("domain:model","domain:container","domain:element","domain:attribute") 
   return  xs:QName($fld));

(:~
 : A list of QName's that define model node fields excluding the model
 :)   
declare variable $DOMAIN-NODE-FIELDS := 
   for  $fld in ("domain:container","domain:element","domain:attribute") 
   return  xs:QName($fld);

declare variable $COLLATION := "http://marklogic.com/collation/codepoint";

declare variable $COMPLEX-TYPES := (
  (:GeoSpatial:)        "lat-long", "longitude", "latitude",
  (:Others:)            "query", "schema-element","triple","binary","reference","langString"
);

declare variable $SIMPLE-TYPES := (
  (:Identity Sequence:) "identity", "ID", "id", "sequence",
  (:Users/Timestamps :) "create-user","create-timestamp","update-timestamp","update-user",
  (:xs:atomicType    :) "anyURI", "string","integer","decimal","double","float","boolean","long",
  (:Durations        :) "date","time","dateTime", "duration","yearMonth","monthDay"
);

declare variable $MODEL-NAVIGATION-ATTRIBUTES := (
  "editable", "exportable", "findable", "importable", "listable", "newable", "removable", "searchable", "securable", "showable", "sortable"
);

declare variable $FIELD-NAVIGATION-ATTRIBUTES := (
  $MODEL-NAVIGATION-ATTRIBUTES, (:"facetable",:) "suggestable"
);

(:~
 : Holds a cache of all the domain models
 :)
declare variable $DOMAIN-MODEL-CACHE := map:map();

(:Holds a cache of all the identity fields:)
declare variable $DOMAIN-IDENTITY-CACHE := map:map();

(:~
 : Caches all module functions
 :)
declare variable $FUNCTION-CACHE := map:map() ;

(:~
 : Cache all values
:)
declare variable $VALUE-CACHE := map:map();
(:~
 :Casts the value as a specific type
 :)
declare function domain:cast-value($field as element(),$value as item()*)
{
   if(fn:not(fn:exists($value))) then ()
   else 
   let $type := $field/@type
   return
     switch($type)
        case "identity"         return $value[fn:string(.) ne ""] cast as xs:string?
        case "id"               return $value[fn:string(.) ne ""] cast as xs:ID?
        case "anyURI"           return $value cast as xs:anyURI*
        case "string"           return $value[fn:string(.) ne ""] cast as xs:string*
        case "integer"          return $value[fn:string(.) ne ""] cast as xs:integer*
        case "unsignedInt"      return $value[fn:string(.) ne ""] cast as xs:unsignedInt*
        case "long"             return $value[fn:string(.) ne ""] cast as xs:long*
        case "unsignedLong"     return $value[fn:string(.) ne ""] cast as xs:unsignedLong*
        case "decimal"          return $value[fn:string(.) ne ""] cast as xs:decimal*
        case "double"           return $value[fn:string(.) ne ""] cast as xs:double*
        case "float"            return $value[fn:string(.) ne ""] cast as xs:float*
        case "boolean"          return $value[fn:string(.) ne ""] cast as xs:boolean*
        case "dateTime"         return $value[fn:string(.) ne ""] cast as xs:dateTime*
        case "date"             return $value[fn:string(.) ne ""] cast as xs:date*
        case "time"             return $value[fn:string(.) ne ""] cast as xs:time*
        case "duration"         return $value[fn:string(.) ne ""] cast as xs:duration*
        case "yearMonth"        return $value[fn:string(.) ne ""] cast as xs:gYearMonth*
        case "monthDay"         return $value[fn:string(.) ne ""] cast as xs:gMonthDay*
        (:Custom Types:)
        case "update-timestamp" return $value[fn:string(.) ne ""] cast as xs:dateTime?
        case "create-timestamp" return $value[fn:string(.) ne ""] cast as xs:dateTime?
        case "create-user"      return $value cast as xs:string?
        case "update-user"      return $value cast as xs:string?
        case "schema-element"   return $value
        case "langString"  return $value 
        default return $value
};
(:~
 : Returns if the value is castable to the given value based on the field/@type
 : @param $field Domain element (element|attribute|container)
 :)
declare function domain:castable-value($field as element(),$value as item()?)
{
   let $type := element {fn:QName("",$field/@type)} {""}
   return
     typeswitch($type)
        case element(string)  return $value castable as xs:string?
        case element(integer) return $value castable as xs:integer
        case element(long)    return $value castable as xs:long
        case element(decimal) return $value castable as xs:decimal
        case element(double)  return $value castable as xs:double
        case element(float)   return $value castable as xs:float
        case element(boolean) return $value castable as xs:boolean
        case element(anyURI)  return $value castable as xs:anyURI
        case element(dateTime) return $value castable as xs:dateTime
        case element(date) return $value castable as xs:date
        case element(time) return $value castable as xs:time
        case element(duration) return $value castable as xs:duration
        case element(yearMonth) return $value castable as xs:gYearMonth
        case element(monthDay) return $value castable as xs:gMonthDay
        case element(identity) return $value castable as xs:string
        case element(schema-element) return $value instance of element()
        case element(binary) return $value instance of binary()
        case element(query) return $value castable as cts:query?
        case element(langString) return $value
        default return fn:true()
};
declare function domain:resolve-cts-type($type as xs:string)
{
     switch($type)
        case "string"  return "string"
        case "anyURI"  return "anyURI"
        (:Integer Types:)
        case "boolean" return "int"
        case "integer" return "int"
        case "long"    return "long"
        case "unsignedLong" return "unsignedLong"
        case "unsignedInt" return "unsignedInt"
        case "decimal" return "decimal"
        case "double"  return "double"
        case "float"   return "float"
        (:Durations and Date/Time:)
        case "dateTime" return "dateTime"
        case "date" return "date"
        case "time" return "time"
        case "yearMonth" return "gYearMonth"
        case "monthDay" return "gMonthDay"
        case "dayTimeDuration" return "dayTimeDuration"
        case "yearMonthDuration" return "yearMonthDuration"
        (:Custom Types:)
        case "langString" return "string"
        case "identity" return "string"
        case "id" return "string"
        case "create-user" return "string"
        case "update-user" return "string"
        case "update-timestamp" return "dateTime"
        case "create-timestamp" return "dateTime"
        default return ()
};
(:~
 : Gets the domain model from the given cache
 :)
declare %private function domain:get-model-cache($key) {
   xdmp:log("Reading Caching-" || $key,"debug"),
   map:get($DOMAIN-MODEL-CACHE,$key)
};

(:~
 : Sets the cache for a domain model
 :)
declare %private function domain:set-model-cache($key,$model as element(domain:model)?) {
   xdmp:log("Caching-" || $key,"debug"),
   map:put($DOMAIN-MODEL-CACHE,$key,$model)
};

(:~
 : Sets a cache for quick lookup on domain model field paths
 :)
declare %private function domain:set-field-cache(
    $key as xs:string, 
    $func as function(*)) {
   map:put($DOMAIN-MODEL-CACHE,$key,$func)
};

(:~
 : Gets the value of an identity cache from the map
 : @private
 :)
declare %private function domain:get-identity-cache($key) {
  let $value := map:get($DOMAIN-IDENTITY-CACHE,$key)
  return
    if($value) then $value else ()
};
(:~
 : Sets the cache value of a models identity field for fast resolution
 : @param $key - key string to identify the cache identity
 : @param $value - $value of the cache item
 :)
declare function domain:set-identity-cache($key as xs:string,$value as item()*) {
    map:put($DOMAIN-IDENTITY-CACHE,$key,$value)
};

(:~
 : Returns a cache key unique to a field
 :)
declare function domain:get-field-cache-key($field,$prefix as xs:string) {
   fn:concat(domain:get-field-key($field),"::",$prefix)
};


(:~
 : Returns the cache for a given value function
:)
declare function domain:exists-field-function-cache(
  $field as element(),
  $type as xs:string
)  as xs:boolean {
    map:contains($FUNCTION-CACHE,domain:get-field-cache-key($field,$type))   
};

(:~
 : Sets the function in the value cache
 :) 
declare function domain:set-field-function-cache(
    $field as element(),
    $type as xs:string,
    $funct as function(*)
) {
   map:put($FUNCTION-CACHE,domain:get-field-cache-key($field,$type),$funct)
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function domain:get-field-function-cache(
    $field as element(),
    $type as xs:string
) as function(*)? {
   map:get($FUNCTION-CACHE,domain:get-field-cache-key($field,$type))
};


(:~
 : Returns the cache for a given value function
:)
declare function domain:exists-field-value-cache(
  $field as element(),
  $type as xs:string
)  as xs:boolean {
    map:contains($VALUE-CACHE,domain:get-field-cache-key($field,$type))   
};

(:~
 : Sets the function in the value cache
 :) 
declare function domain:set-field-value-cache(
    $field as element(),
    $type as xs:string,
    $value as item()*
) {
   map:put($VALUE-CACHE,domain:get-field-cache-key($field,$type),$value)
};

(:~
 : Gets the function for the xxx-path from the cache
:)
   declare function domain:get-field-value-cache(
    $field as element(),
    $type as xs:string
) as item() {
   map:get($VALUE-CACHE,domain:get-field-cache-key($field,$type))
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field-name($model as element(domain:model)) as xs:string {
   domain:get-model-identity-field($model)/fn:string(@name)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field($model as element(domain:model)) {
  let $key := fn:concat($model/@name , ":identity")
  let $cache := domain:get-identity-cache($key)
  return
    if($cache) then $cache[1]
    else 
    let $id-field := $model//(domain:element|domain:attribute)[fn:node-name(.) = $DOMAIN-NODE-FIELDS][@identity eq "true" or @type =( "identity","id")]
    return 
     (
     domain:set-identity-cache($key,$id-field),
     $id-field[1]
    )
};
(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keylabel-field($model as element(domain:model)) {
  let $key := fn:concat($model/@name , ":keyLabel")
  let $cache := domain:get-identity-cache($key)
  return
    if($cache) then fn:exactly-one($cache)
    else 
    let $key-field := $model//(domain:element|domain:attribute)[@name = $model/@keyLabel][1]
    return 
     (
     domain:set-identity-cache($key,$key-field),
     $key-field
    )
};
(:~
 : Returns the identity query for a domain-model
 : @param $domain-model - The domain model for the identity-query
 : @param $value - The value of the domain instance for retrieval
 :)
declare function domain:get-model-identity-query(
  $domain-model as element(domain:model),
  $value as xs:anyAtomicType?
) {
  let $id-field := domain:get-model-identity-field($domain-model)
  let $id-ns    := domain:get-field-namespace($id-field)
  return  
    typeswitch($id-field)
      case element(domain:element) return
        cts:element-range-query(
          fn:QName($id-ns,$id-field/@name),
          "=",
          $value,
          ("collation="  || domain:get-field-collation($id-field))
        )
      case element(domain:attribute) return 
        let $parent-elem := $id-field/parent::*[domain:element|domain:model]
        let $parent-ns   := domain:get-field-namespace($parent-elem)
        return  
          cts:element-attribute-range-query(
              fn:QName($parent-ns,$parent-elem/@name),
              fn:QName("",$id-field/@name),
              "=",
              $value,
              ("collation="  || domain:get-field-collation($id-field))
          )
      default return 
        fn:error(
            xs:QName("IDENTITY-QUERY"),
            "Identity Query could not be resolved.",
            fn:data($domain-model/@name)
        )    
      
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-key-field($model as element(domain:model)) {
    let $key := ($model/@name || ":key")
    let $cache := domain:get-identity-cache($key)
    return
        if($cache) then $cache
        else 
            let $field := $model//(domain:element|domain:attribute)[@name eq $model/@key]
            return (
               domain:set-identity-cache($key,$field),
               $field
            )
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keyLabel-field($model as element(domain:model)) {
    let $key := ($model/@name || ":keyLabel")
    let $cache := domain:get-identity-cache($key)
    return
        if($cache) then $cache
        else 
            let $field := $model//(domain:element|domain:attribute)[fn:node-name(.) = $DOMAIN-NODE-FIELDS][@name eq $model/@keyLabel]
            return (
               domain:set-identity-cache($key,$field),
               $field
            )
};
declare function domain:get-field-prefix($field as element()) {
    if($field/@prefix) then $field/@prefix else
    let $key   := fn:concat("namespace-prefix::",fn:generate-id($field))
    let $cache := domain:get-identity-cache($key)
    return
        if($cache) then $cache
        else 
            let $ns := domain:get-field-namespace($field)
            let $nses := domain:declared-namespaces($field)
            let $pos := fn:index-of($nses,$ns)
            let $prefix :=
              if (fn:empty($pos)) then
                fn:error(xs:QName("PREFIX-NOT-DEFINED"), text{"Prefix", $ns, "is not defined in domain"})
              else
                fn:subsequence($nses,$pos -1 ,1)
            let $index-ns := fn:index-of($nses,$ns)
            let $check :=
                if($index-ns) then () 
                else fn:error(xs:QName("UNPREFIXED-NAMESPACE"),"Cannot resolve prefix for namespace " || $ns,
                fn:string($field/ancestor::domain:domain/fn:local-name(.)))
            let $prefix := fn:subsequence($nses,$index-ns -1 ,1)
            return (
               domain:set-identity-cache($key,$prefix),
               $prefix
            )
};
(:~
 : Returns the field that matches the given field name or key
 : @param $model - The model to extract the given field
 : @param $name  - name or key of the field
 :)
declare function domain:get-model-field($model as element(domain:model),$name as xs:string) {
  let $key := ($model/@name || ":field:" || $name)
  let $cache := domain:get-identity-cache($key)
  return
    if(fn:exists($cache)) then $cache
    else 
      let $value := $model//(domain:element|domain:attribute)[$name eq @name or $name eq @keyId or $name eq @keyName]
      return (
        domain:set-identity-cache($key,$value),
        $value
      )
};

(:~
 : Returns model fields with unique constraints
 : @param $model - The model that returns all the unique constraint fields
 :)
declare function domain:get-model-unique-constraint-fields($model as element(domain:model)) {
   $model//(domain:element|domain:attribute)[domain:constraint/@unique = "true"]
};

(:~
 : Resolves a domain type to xsi:type
 : @param $model - The model to extract the given identity field
 :)
declare function domain:resolve-datatype(
    $field as element()
) {
   let $data-type := element{$field/@type}{$field}
   return 
     typeswitch($data-type)
     case element(uuid) return "xs:string"
     case element(identity) return "xs:string"
     case element(id) return "xs:ID"
     case element(create-timestamp) return "xs:dateTime"
     case element(create-user) return "xs:string"
     case element(update-timestamp) return "xs:dateTime"
     case element(update-user) return "xs:string"
     case element(modify-user) return "xs:string"
     case element(binary) return "binary()"
     case element(schema-element) return "schema-element()"
     (:case element(sem:triple) return "sem:triple()" :)
     case element(query) return "cts:query"
     case element(point) return "cts:point"
     case element(string) return "xs:string"
     case element(integer) return "xs:integer"
     case element(int) return "xs:int"
     case element(long) return "xs:long"
     case element(double) return "xs:double"
     case element(decimal) return "xs:decimal"
     case element(float) return "xs:float"
     case element(boolean) return "xs:boolean"
     case element(anyURI) return "xs:anyURI"
     case element(dateTime) return "xs:dateTime"
     case element(date) return "xs:date"
     case element(time) return "xs:time"
     case element(duration) return "xs:duration"
     case element(dayTime) return "xs:dayTimeDuration"
     case element(yearMonth) return "xs:yearMonthDuration"
     case element(monthDay) return "xs:monthDayDuration"
     case element(reference) return "xs:string"
     case element(langString) return "rdf:langString"
     default return 
        if(domain:get-model($field/@type)) then "element()"
        else fn:error(xs:QName("UNRESOLVED-DATATYPE"),$field)
};
(:~
 : Resolves the field to its xs:Type equivalent
 : @return - String representing the schema
 :)
declare function domain:resolve-ctstype(
    $field as element()
) {
   let $data-type := element{$field/@type}{$field}
   return 
     typeswitch($data-type)
     case element(uuid) return "xs:string"
     case element(identity) return "xs:string"
     case element(create-timestamp) return "xs:dateTime"
     case element(create-user) return "xs:string"
     case element(update-timestamp) return "xs:dateTime"
     case element(update-user) return "xs:string"
     case element(modify-user) return "xs:string"
     case element(binary) return "binary()"
     case element(schema-element) return "schema-element()"
     case element(query) return "cts:query"
     case element(point) return "cts:point"
     case element(string) return "xs:string"
     case element(integer) return "xs:integer"
     case element(int) return "xs:int"
     case element(long) return "xs:long"
     case element(double) return "xs:double"
     case element(decimal) return "xs:decimal"
     case element(float) return "xs:float"
     case element(boolean) return "xs:boolean"
     case element(anyURI) return "xs:anyURI"
     case element(dateTime) return "xs:dateTime"
     case element(date) return "xs:date"
     case element(time) return "xs:time"
     case element(duration) return "xs:duration"
     case element(dayTime) return "xs:dayTimeDuration"
     case element(yearMonth) return "xs:yearMonthDuration"
     case element(monthDay) return "xs:monthDayDuration"
     case element(reference) return "xs:string"
     default return fn:error(xs:QName("UNRESOLVED-DATATYPE"),$field)
};

(:~
 : Returns the default application domain content-namespace-uri 
 : @return the content-namespace for the default application
 :)
declare function domain:get-content-namespace-uri(
) as xs:string 
{
  domain:get-content-namespace-uri(config:default-application())
};

(:~
 : Returns the content-namespace value for a given application
 : @param $application-name - name of the application
 : @return - The namespace URI of the given application
 :)
declare function domain:get-content-namespace-uri( 
   $application-name as xs:string
) as xs:string 
{
   let $key := fn:concat($application-name, ":namespace-uri")
   let $cache := domain:get-identity-cache($key)
   return
     if($cache) 
     then $cache
     else 
        let $value := fn:data(config:get-domain($application-name)/domain:content-namespace/@namespace-uri)
        return (
            domain:set-identity-cache($key,$value),
            $value
        )
};

(:~
 : Gets the controller definition for a given application by its name
 : @param $application-name - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller(
   $application-name as xs:string,
   $controller-name as xs:string
) as element(domain:controller)? 
{
    let $domain := config:get-domain($application-name)
    return 
        $domain/domain:controller[@name eq $controller-name]  
};
(:~
 : Returns the actions associated with the controller. The function assumes the controller lives in the default application.
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-actions(
  $controller-name as xs:string
) {
  domain:get-controller-actions(config:default-application(),$controller-name)
};

(:~
 : Returns all the available functions for a given controller. 
 : @param $application-name - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-actions(
  $application-name as xs:string,
  $controller-name as xs:string
) {
    let $controller := domain:get-controller($application-name,$controller-name)
    let $base-uri := config:application-directory($application-name)
    let $base-ns  := config:application-namespace($application-name)
    let $controller-ns := fn:concat($base-ns,"/controller/",$controller-name)
    let $stmt := fn:concat(
        "import module namespace controller = 'http://xquerrail.com/controller/base' at '../base/base-controller.xqy'; ",
        "&#xA;xdmp:functions()[fn:namespace-uri-from-QName(fn:function-name(.)) = 'http://xquerrail.com/controller/base']"
        )
    let $functions := try { 
        xdmp:eval($stmt)
     } catch($ex) {
        fn:error(xs:QName("CONTROLLER-FUNCTIONS-ERROR"),"Error Retrieving functions",
          $stmt)
     }
    return
    fn:distinct-values(for $func in $functions
    let $name := fn:local-name-from-QName(fn:function-name($func))
    where fn:function-arity($func) = 0
    return 
       $name
    )
};
(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application-name - Name of the application
 :  @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-model(
    $controller-name as xs:string
) as element(domain:model)?
{
   domain:get-controller-model(config:default-application(),$controller-name)
};

(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application-name - Name of the application
 :  @param $controller-name - Name of the controller
 :  @return  - returns the model associated with the given controller.
 :)
declare function domain:get-controller-model(
    $application-name as xs:string, 
    $controller-name as xs:string
) as element(domain:model)?
{
     let $domain := config:get-domain($application-name)
     let $controller := domain:get-controller($application-name,$controller-name)
     let $model := domain:get-domain-model(fn:data($controller/@model))
     return 
        $model
};

(:~
 : Gets the name of the controller associated with a model
 : @param $model-name - name of the model
 : @return The name of the controller 
 :)
declare function domain:get-model-controller-name(
    $model-name as xs:string?
 ) as xs:string* {
    domain:get-model-controller(domain:get-default-application(),$model-name)
};
(:~
 : Gets the name of the controller for a given application and model.
 :  @param $application-name - Name of the application
 :  @param $model-name - Name of the controller
 :  @return - the name of the controller
 :)
declare function domain:get-model-controller-name(
    $application as xs:string, 
    $model-name as xs:string?
 ) as xs:string* {
    let $domain := config:get-domain($application)
    return
        fn:data($domain/domain:controller[@model = $model-name]/@name)
};
(:~
 : Returns the model definition by its application and model name
 : @param $application-name - Name of the application
 : @param $model-name - Name of the model
 : @return  a model definition
  :)
declare function domain:get-model(
$application-name as xs:string,
$model-name as xs:string*
) as element(domain:model)* {
   domain:get-domain-model($application-name,$model-name)
};
(:~
 : Returns a model based by its name(s)
 : @param $model-name - list of model names to return 
 :)
declare function domain:get-model(
  $model-name as xs:string+
) as element(domain:model)* {
   domain:get-domain-model($model-name)
};

(:~
 : Returns a domain model from the default domain
 : @deprecated
 : @param - returns a domain model given a
 :)
declare function domain:get-domain-model(
$model-name as xs:string+) {
    domain:get-domain-model(config:default-application(), $model-name,fn:true())
};

declare function domain:get-domain-model(
$application-name as xs:string,
$model-name as xs:string*
) {
    domain:get-domain-model($application-name,$model-name,fn:true())
};
(:~
 : @param $application - Name of the application
 : @param $domain-name - Name of the domain model
 : @param $extension - If true then returns the extension fields, false returns the raw model
 :)
declare function domain:get-domain-model(
    $application as xs:string, 
    $model-names as xs:string+,
    $extension as xs:boolean
) as element(domain:model)+
{
  let $domain := config:get-domain($application)
  let $models := 
     for $modelName in $model-names
     let $cache-key := fn:concat($application, ":" ,$modelName)
     let $cached := domain:get-model-cache($cache-key)
     return
        if($cached) then $cached
        else 
          let $model := $domain/domain:model[cts:contains(.,cts:element-attribute-value-query(xs:QName("domain:model"),xs:QName("name"),$modelName))]
          let $_ := if($model) then () else fn:error(xs:QName("NO-MODEL"),"Missing Model",$modelName)
          let $extends := 
              if($model/@extends) then
                  let $extendedDomain := $domain/domain:model[cts:contains(.,
                    cts:element-attribute-value-query(
                       xs:QName("domain:model"),
                       xs:QName("name"), 
                       $model/@extends))
                ]
                  return
                      if(fn:not($extendedDomain)) then fn:error(xs:QName("NO-EXTENDS-MODEL"),"Missing Extension Model",fn:data($model/@extends))
                      else
                         element { fn:node-name($model) } {
                         $model/namespace::*,
                         $model/@*,
                         for $f in  $extendedDomain/(domain:element | domain:container | domain:attribute| domain:triple|domain:permission|domain:navigation)
                         return 
                            element { fn:node-name($f) } {
                                if($model/(@namespace-uri|@namespace))
                                then $model/(@namespace-uri|@namespace)
                                else if($f/@namespace) 
                                then $f/@namespace
                                else $extendedDomain/@namespace                            
                                , $f/@*[. except $f/@namespace] 
                                , $f/node()
                            }
                        , $model/node()
                     }
            else $model
         return ($extends,domain:set-model-cache($cache-key,$extends))
    return 
        if($models) 
        then element domain:domain { $domain/namespace::*, $domain/@*, $domain/domain:name, $domain/*[. except $domain/domain:model], $models } / domain:model
        else fn:error(xs:QName("NO-DOMAIN-MODEL"), "Model does not exist",$model-names)
};

declare function domain:compile-model(
  $model as element(domain:model)
) {
  let $domain := $model/ancestor::domain:domain
  let $model := 
    if($model/@extends) then
      let $extendedDomain := $domain/domain:model[cts:contains(.,
        cts:element-attribute-value-query(
          xs:QName("domain:model"),
          xs:QName("name"), 
          $model/@extends))
        ]
      return
        if(fn:not($extendedDomain)) then 
          fn:error(xs:QName("NO-EXTENDS-MODEL"),"Missing Extension Model",fn:data($model/@extends))
        else
          element { fn:node-name($model) } {
            $model/namespace::*,
            $model/@*[. except $model/@extends],
            for $f in $extendedDomain/(domain:element | domain:container | domain:attribute| domain:triple | domain:permission | domain:navigation)
            return 
              element { fn:node-name($f) } {
                if($model/(@namespace-uri|@namespace)) then 
                  $model/(@namespace-uri|@namespace)
                else if($f/@namespace) then 
                  $f/@namespace
                else 
                  $extendedDomain/@namespace                            
                , $f/@*[. except $f/@namespace] 
                , $f/node()
              }
            ,
            $model/node()
          }
    else $model
  
  let $model := 
    element domain:domain {
      $domain/*[. except $domain/domain:model[@name = $model/@name]],
      $model
    }/domain:model[@name = $model/@name]
  let $model := 
    element domain:domain {
      $domain/*[. except $domain/domain:model[@name = $model/@name]],
      domain:set-model-field-attributes($model)
    }/domain:model[@name = $model/@name]
  let $model := 
    element domain:domain {
      $domain/*[. except $domain/domain:model[@name = $model/@name]],
      domain:set-model-field-defaults($model)
    }/domain:model[@name = $model/@name]
  return $model
};

declare function domain:navigation(
  $field as element()
) as element(domain:navigation) {
  $field/domain:navigation
};

declare function domain:navigation-field(
  $field as element(),
  $name as xs:string
) {
  domain:navigation($field)/@*[./fn:local-name() eq $name]/fn:data()
};

(:~
  navigation from model, abstract or domain are merged in this order
:)
declare function domain:build-model-navigation(
  $field as element()
) as element(domain:navigation) {
  typeswitch($field)
    case element(domain:model) return 
      element domain:navigation {
        $MODEL-NAVIGATION-ATTRIBUTES ! (
          let $attribute-name := .
          return
            attribute {$attribute-name} {
              if ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name])[fn:last()]
              else if ($field/ancestor::domain:domain/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                $field/ancestor::domain:domain/domain:navigation/@*[./fn:local-name() eq $attribute-name]
              else
                fn:false()
            }
        ),
        $field/domain:navigation/@* [. except $field/domain:navigation/@*[fn:index-of($MODEL-NAVIGATION-ATTRIBUTES, ./fn:local-name()) > 0]],
        $field/domain:navigation/*
      }
    case element(domain:container) return 
      element domain:navigation {
        $FIELD-NAVIGATION-ATTRIBUTES ! (
          let $attribute-name := .
          return
            attribute {$attribute-name} {
              if ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name])[fn:last()]
              else if ($field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                $field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]
              else
                fn:false()
            }
        ),
        $field/domain:navigation/@* [. except $field/domain:navigation/@*[fn:index-of($FIELD-NAVIGATION-ATTRIBUTES, ./fn:local-name()) > 0]],
        $field/domain:navigation/*
      }
    case element(domain:element) return 
      element domain:navigation {
        $FIELD-NAVIGATION-ATTRIBUTES ! (
          let $attribute-name := .
          return
            attribute {$attribute-name} {
              if ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name])[fn:last()]
              else if ($field/ancestor::domain:container/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                $field/ancestor::domain:container/domain:navigation/@*[./fn:local-name() eq $attribute-name]
              else if ($field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                $field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]
              else
                fn:false()
            }
        ),
        $field/domain:navigation/@* [. except $field/domain:navigation/@*[fn:index-of($FIELD-NAVIGATION-ATTRIBUTES, ./fn:local-name()) > 0]],
        $field/domain:navigation/*
      }
    case element(domain:attribute) return 
      element domain:navigation {
        $FIELD-NAVIGATION-ATTRIBUTES ! (
          let $attribute-name := .
          return
            attribute {$attribute-name} {
              if ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                ($field/domain:navigation/@*[./fn:local-name() eq $attribute-name])[fn:last()]
              else if ($field/ancestor::domain:element/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                $field/ancestor::domain:element/domain:navigation/@*[./fn:local-name() eq $attribute-name]
              else if ($field/ancestor::domain:container/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                $field/ancestor::domain:container/domain:navigation/@*[./fn:local-name() eq $attribute-name]
              else if ($field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
                $field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]
              else
                fn:false()
            }
        ),
        $field/domain:navigation/@* [. except $field/domain:navigation/@*[fn:index-of($FIELD-NAVIGATION-ATTRIBUTES, ./fn:local-name()) > 0]],
        $field/domain:navigation/*
      }
    default return ()
};
(:~
  Set navigation attributes for all model elements (if not defined will inherit from parent else default is false)
:)
declare function domain:set-model-field-defaults(
  $field as item()
) as item() {
  typeswitch($field)
    case element(domain:model) return 
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:element | domain:container | domain:attribute | domain:navigation)],
        domain:build-model-navigation($field),
        for $f in  $field/(domain:element | domain:container | domain:attribute)
          return domain:set-model-field-defaults($f)
      }
    case element(domain:container) return
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:element | domain:attribute | domain:navigation)],
        domain:build-model-navigation($field),
        for $f in  $field/(domain:element | domain:attribute)
          return domain:set-model-field-defaults($f)
      }
    case element(domain:element) return
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:attribute | domain:navigation)],
        domain:build-model-navigation($field),
        for $f in  $field/(domain:attribute)
          return domain:set-model-field-defaults($f)
      }
    case element(domain:attribute) return
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:navigation)],
        domain:build-model-navigation($field)
      }
    default return $field
};

declare function domain:set-model-field-attributes(
  $field as item()
) as item() {
  typeswitch($field)
    case element(domain:model) return 
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:element | domain:container | domain:attribute)],
        for $f in  $field/(domain:element | domain:container | domain:attribute)
          return domain:set-model-field-attributes($f)
      }
    case element(domain:container) return
      element { fn:node-name($field) } {
        domain:set-field-attributes($field),
        $field/* ! (domain:set-model-field-attributes(.))
      }
    case element(domain:element) return
      element { fn:node-name($field) } {
        domain:set-field-attributes($field),
        $field/* ! (domain:set-model-field-attributes(.))
      }
    case element(domain:attribute) return
      element { fn:node-name($field) } {
        domain:set-field-attributes($field),
        $field/* ! (domain:set-model-field-attributes(.))
      }
    default return $field
};

declare function domain:set-field-attributes($field as element()) as attribute()* {
  ( 
    $field/@*[. except 
    ($field/@keyId, 
     $field/@keyName,
     $field/@prefix,
     $field/@namespace,
     $field/@xpath,
     $field/@absXpath,
     $field/@jsonPath)],
    attribute keyId { domain:build-field-id($field) },
    attribute keyName { domain:build-field-name-key($field) },
    attribute prefix {domain:get-field-prefix($field)},
    attribute namespace {domain:get-field-namespace($field)},
    attribute xpath {domain:get-field-xpath($field)},
    attribute absXpath {domain:get-field-absolute-xpath($field)},
    attribute jsonPath {domain:get-field-jsonpath($field)}
    )
};

(:~
 : Returns a list of all defined controllers for a given application domain
 : @param $application-name - application domain name
 :)
declare function domain:get-controllers(
   $application-name as xs:string
){
   config:get-domain($application-name)/domain:controller
};

(:~
 : Returns the default application domain defined in the config.xml
 :)
declare function domain:get-default-application(){
    config:default-application()
};

(:~
 : Returns the default content namespace for a given application. Convenience wrapper for @see config:default-namespace() function.
 : @param $application-name - Name of the application 
 : @return default content namespace
 :)
declare function domain:get-default-namespace(
$application-name as xs:string
) {
    let $application := config:get-domain($application-name)
    return 
       $application/domain:content-namespace
};

(:~
 : Returns all content and declare-namespace in application-domain
 : @param $application-name - Name of the application 
 : @return sequence of element(namespace).
 :)
declare function domain:get-domain-namespaces(
  $application-name as xs:string
)  as element(namespace) {
    let $application := config:get-domain($application-name)
    for $ns in $application/(domain:content-namespace | domain:declare-namespace)
    return 
       <namespace prefix="{$ns/@prefix}" namespace="{$ns/(@namespace|@namespace-uri)}"/>
};

(:~
 : Returns a list of models with a given class attribute from a given application.  
 : Function is helpful for selecting a list of all models or selecting them by their @class attribute.
 : @param $application-name - Name of the application
 : @param $class - the selector class it can be space delimitted
 :)
declare function domain:model-selector( 
   $application-name as xs:string,
   $class as xs:string*
) as element(domain:model)*
{ 
   let $domain := config:get-domain($application-name)
   return
       $domain/domain:model[@class = $class ! fn:tokenize(.,"\s+")]
};

(:~
 : Returns a list of domain models given a class selector
 : @param $class - name of a class associated witha given model. 
 :)
declare function domain:model-selector( 
   $class as xs:string
) as element(domain:model)*
{ 
  domain:model-selector(config:default-application(),$class)
};
(:~
 : Returns a list of all the fields defined by the selector.
 :)
declare function domain:model-fields(
    $model-name as xs:string
)  as element()*{
  domain:model-fields(config:default-application(),$model-name)
};

(:~
 : Returns the list of fields associated iwth
 :)
declare function domain:model-fields( 
   $application-name as xs:string,
   $model-name as xs:string
) as element()*
{ 
   let $domain := config:get-domain($application-name)
   return
       domain:get-model($model-name)//(domain:element|domain:attribute)
};
(:~
 : Returns the unique hash of an element suitable for creating a named element.
 :)
declare function domain:get-field-key(
  $node as node()
) {
   domain:get-field-id($node)
};

(:~
 : Returns the name key path defined. The name key is a simplified notation that concatenates all the names - the modelname with .
 : (ex.  <b>Customer.Address.Line1)</b>.  This is useful for creating ID field in an html form.
 : @param $field - Field in a <b>domain:model</b>
 :)
declare function domain:get-field-name-key($field as node()) {
  if($field/@keyName) then fn:string($field/@keyName) else
  let $key   := fn:concat("field-name-key::",fn:generate-id($field))
  let $cache := domain:get-identity-cache($key)
  return
       if($cache) then $cache
       else
        let $value := $field/@keyName/fn:string()
        return (
          domain:set-identity-cache($key,$value),
          $value
       )
};

declare %private function domain:build-field-name-key($field as node()) {
    let $items := $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-NODE-FIELDS]
    let $ns := domain:get-field-namespace($field)
    let $path := 
    fn:string-join(
        for $item in $items
        return  fn:concat($item/@name)
        ,"."
    )
    return $path
};

declare function domain:hash($field as node()) {
(:  xdmp:hash64(xdmp:describe($field, (), ())):)
  fn:generate-id($field)
};

(:~
 :  Returns a unique identity key that can used as a unique identifier for the field.
 :  @param $context - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain:get-field-id($field as node()) {
  if($field/@keyId) then fn:string($field/@keyId) else
  let $key   := fn:concat("field-id::",fn:generate-id($field))
  let $cache := domain:get-identity-cache($key)
  return
       if($cache) then $cache
       else
        let $value := $field/@keyId/fn:string()
        return (
          domain:set-identity-cache($key,$value),
          $value
       )
};

declare %private function domain:build-field-id($field as node()) {
  let $items := $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-FIELDS]
  let $ns := domain:get-field-namespace($field)
  let $path := 
     fn:string-join(
         for $item in $items
         return
             fn:concat("{" , $ns, "}", $item/@name)
         ,"/"    
     )
  let $path := fn:concat($field/@name,"__", xdmp:md5($path))
  return $path
};

(:~
 :  Gets the namespace of the field. Namespace resolution is inherited if not specified by the field in the following order:
 :  field-> model-> domain:content-namespace
 :  @param $field - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain:get-field-namespace(
$field as element()
) as xs:string?
{
    if($field/@namespace) then fn:string($field/@namespace) else
    let $key   := fn:concat("field-namespace::",fn:generate-id($field))
    let $cache := domain:get-identity-cache($key)
    return
    if($cache) then $cache
    else
    let $field-namespace := (
        if($field/(@namespace-uri|@namespace) )
        then $field/(@namespace-uri|@namespace)/fn:string()
        else if($field/ancestor::domain:model/(@namespace-uri|@namespace))
        then $field/ancestor::domain:model/(@namespace-uri|@namespace)/fn:string()
        else if($field/ancestor::domain:domain/domain:content-namespace/(@namespace-uri|text()))
        then $field/ancestor::domain:domain/domain:content-namespace/(@namespace-uri|/text())
        else (domain:get-content-namespace-uri(),"")
    )[1]
    return (
        domain:set-identity-cache($key,$field-namespace),
        $field-namespace
    )
};

(:~
 : Retrieves the value of a field based on a parameter key
 : @param $field - The field definition representing the value to return
 : @param $params - A map:map representing the field parameters
:)
declare function domain:get-field-param-value(
    $field as element(),
    $params as map:map) {
  let $key := domain:get-field-id($field)
  let $name-key := domain:get-field-name-key($field)
  let $key-value := map:get($params,$key)
  let $name-value := map:get($params,$field/@name)
  let $namekey-value := map:get($params,$name-key)
  return
    if($field/@type eq "langString") then  domain:get-field-param-langString-value($field,$params)   
    else 
          domain:cast-value(
                $field, 
                if(fn:exists($key-value)) then $key-value 
                else if(fn:exists($namekey-value)) then $namekey-value else $name-value
           )
};
declare function domain:get-field-param-match-key(
    $field as element(),
    $params as map:map
) {
      if(map:contains($params,domain:get-field-name-key($field)))
      then "name-key"
      else if(map:contains($params,domain:get-field-id($field))) then "id"
      else if(map:contains($params,$field/@name)) then "name"
      else () (:No data match key:)
};
declare function domain:get-field-param-langString-value(
    $field as element(),
    $params as map:map
) {
    let $matched-key :=
      if(map:contains($params,domain:get-field-name-key($field)))
      then  domain:get-field-name-key($field)
      else if(map:contains($params,domain:get-field-id($field))) then domain:get-field-id($field)
      else if(map:contains($params,$field/@name)) then  fn:data($field/@name)
      else () (:No data match key:)
    let $lang-value := 
        (map:get($params,fn:concat($matched-key,"@lang")),domain:get-default-language($field))[1]
    return
       if($matched-key) then rdf:langString(map:get($params,$matched-key),$lang-value)
       else ()
        
};
declare function domain:get-field-param-triple-value(
    $field as element(),
    $params as map:map) {
  let $key := domain:get-field-id($field)
  let $name-key := domain:get-field-name-key($field)
  let $key-value := map:get($params,$key)
  let $name-value := map:get($params,$field/@name)
  let $namekey-value := map:get($params,$name-key)
  return
    if(fn:exists($key-value)) then $key-value 
    else if(fn:exists($namekey-value)) then $namekey-value else $name-value
};

(:~
 : Returns the reference value from a given field from the current context node.
 : @param $field - the model definition
 : @param $current-node - is the instance of the current element to extract the value from
 :)
declare function domain:get-field-reference(
    $field as element(),
    $current-node as node()
 ){
    domain:get-field-value($field,$current-node)/@ref-id
};

(:~
 : Retrieve the reference context associated with a reference field. 
 :   model:{$model-name}:{function}<br/>
 :   application:{scope}:{function}<br/>
 :   optionlist:{application}:{name}<br/>
 :   lib:{library}:{function}<br/>
 : @param $field - Field element (domain:element) 
 :)
declare function domain:get-field-reference-model(
    $field as element()
) {
    let $reference := $field/@reference
    let $tokens    := fn:tokenize($reference,":")
    let $scope     := $tokens[1]
    let $ref       := $tokens[2]
    let $action    := $tokens[3]
    return
        switch($scope)
          case "model" return domain:get-model($ref)
          case "application" return ()
          default return ()
        
};
(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $field - instance of a field
 :)
declare function domain:get-field-xpath(
  $field as element()
) {
    if($field/@xpath) then fn:string($field/@xpath) else 
    let $namespaces := domain:declared-namespaces-map($field)
    return
        fn:string-join(
        for $path in $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-NODE-FIELDS]
        return 
         typeswitch($path)
          case element(domain:attribute) return fn:concat("/@",$path/@name)
          default return  fn:concat("/",domain:get-field-prefix($path),":",$path/@name)
        ,"")
};
(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $field - instance of a field
 :)
declare function domain:get-field-absolute-xpath(
  $field as element()
) {
    if($field/@absXpath) then $field/@absXpath else 
    let $namespaces := domain:declared-namespaces-map($field)
    return
        fn:string-join(
        for $path in $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-FIELDS]
        return 
         typeswitch($path)
          case element(domain:attribute) return fn:concat("/@",$path/@name)
          default return  fn:concat("/",domain:get-field-prefix($path),":",$path/@name)
        ,"")
};
declare function domain:get-field-qname($field as element()) {

   typeswitch($field)
     case element(domain:model)       return fn:QName(domain:get-field-namespace($field),$field/@name)
     case element(domain:element)     return fn:QName(domain:get-field-namespace($field),$field/@name)
     case element(domain:attribute)   return fn:QName("",$field/@name)
     case element(domain:container)   return fn:QName(domain:get-field-namespace($field),$field/@name)
     case element(domain:triple)      return xs:QName("sem:triple")
     default return fn:error(xs:QName("QNAME-ERROR"),"Cannot create qname from field",fn:local-name($field))
 
};

(:~
 : Constructs a map of a domain instance based on a list of retain node names
 : @param $doc - context node instance
 : @param $retain  - a list of nodes to retain from original context
 :)
declare function domain:build-value-map($doc as node()?,$retain as xs:string*) 
as map:map?
{
  let $map := map:map()
  let $results :=  domain:recurse($doc,$map,$retain)
  return
    $results
};

(:~
 : Recursively constructs a map of a domain instance based on a list of retain node names. This allows for building 
 : compositions of existing domains or entirely new domain objects
 : @param $doc - context node instance
 : @param $map  - an existing map to populate with.
 : @param $retain  - a list of nodes to retain from original context
 :)
declare private function domain:recurse(
  $node as node()?,
  $map as map:map, 
  $retain as xs:string*) {
  let $key := domain:get-field-id($node)
  let $_ :=
    typeswitch ($node) 
    case document-node() return domain:recurse($node/node(),$map,$retain)
    case text() return 
        if(fn:string-length($node) > 0) then
            let $key := domain:get-field-id($node/..) 
            return map:put($map, $key, (map:get($map,$key), $node))
        else ()
    case element() return 
         if($node/(element()|attribute()) and fn:not(fn:local-name($node) = $retain)) 
         then 
           for $n in $node/(element()|attribute()| text())
           return domain:recurse($n,$map,$retain)
         else 
           let $value := $node/node()
           return map:put($map, $key,(map:get($map,$key),$value))
    case attribute() return 
      map:put($map, $key,(map:get($map,$key),fn:data($node)))
    default return ()
 return $map
};
(:@deprecated:)
declare function domain:get-model-by-xpath(
    $path as xs:string
) as xs:string?
{

    let $domain := config:get-domain(config:default-application())
    let $subpath :=
    fn:string-join(
        for $item at $pos in fn:tokenize($path, "/")[2 to fn:last()]
        let $item := 
          (: Remove any namespace bindings since we are finding :)
          (: the content in the application domain :)
          if(fn:contains($item, ":"))
          then fn:tokenize($item, ":")[fn:last()]
          else $item
          
        let $item := 
          (: Drop attributes since we are finding it in the domain :)
          if(fn:starts-with($item, "@")) 
          then fn:substring($item, 2)
          else $item
         return 
        fn:concat('*[@name ="', $item, '"]')
     , "/")    
    let $xpath := if ($subpath) then fn:concat( "/", $subpath) else ()
    let $key := 
        if($xpath) then 
            let $stmt := fn:string(<stmt>$domain{$xpath}</stmt>)
            let $domain-node :=  xdmp:value($stmt)
            return domain:get-field-id($domain-node)
        else ()
    
    return $key
};

(:~
 : Returns a controller based on the model name
 : @param $model-name  - name of the model
 :)
declare function domain:get-model-controller($model-name) as element(domain:controller)* {
    domain:get-model-controller(config:default-application(),$model-name)
};

declare function domain:get-model-controller(
    $application as  xs:string,
    $model-name as xs:string
) as element(domain:controller)* {
  domain:get-model-controller($application,$model-name,fn:false())
};
(:~
 : Returns a controller based on the model name
 : @param $application - name of the application
 : @param $model-name  - name of the model
 :)
declare function domain:get-model-controller(
$application as xs:string, 
$model-name as xs:string,
$checked as xs:boolean
) as element(domain:controller)* {
    let $domain := config:get-domain(config:get-application($application)/@name)
    return 
        if($domain) then $domain/domain:controller[@model = $model-name]
        else if($checked) then fn:error(xs:QName("INVALID-DOMAIN"),"Invalid domain", $application)
        else ()
};

(:~
 : Returns an optionlist from the default domain
 : @param $name  Name of the optionlist
 :)
declare function domain:get-optionlist($name) {
    domain:get-optionlist(domain:get-default-application(),$name)
};

(:~
 :  Returns an optionlist from the application by its name
 : @param $application-name  Name of the application
 : @param $listname  Name of the optionlist
 :)
declare function domain:get-optionlist($application-name,$listname) {
    config:get-domain($application-name)/domain:optionlist[@name eq $listname]
};

(:~
 : Returns an optionlist associated with a field definitions inList attribute. 
 : @param $field  Field instance (domain:element|domain:attribute)
 : @return optionlist specified by field.
 :)
declare function domain:get-field-optionlist($field) {
   (
      $field/ancestor::domain:model/domain:optionlist[$field/domain:constraint/@inList = @name],
      $field/ancestor::domain:domain/domain:optionlist[$field/domain:constraint/@inList = @name],
      $field/domain:constraint/@inList
   )[1]
};
(:~
 : Gets an application element specified by the application name
 : @param $application Name of the application
 :)
declare function domain:get-application($application) {
   config:get-application($application)
};
(:~
 : Returns the key that represents the given model
 : the key format is model:{model-name}:reference
 : @param $domain-model - The instance of the domain model
 : @return The reference-key defining the model
 :)
declare function domain:get-model-reference-key(
  $domain-model as element(domain:model)
) {
   fn:concat("model:",$domain-model/@name,":reference")
}; 
(:~
 : Gets a list of domain models that reference a given model.
 : @param $domain-model - The domain model instance.
 : @return a sequence of domain:model elements
 :)
declare function domain:get-model-references(
    $domain-model as element(domain:model)
) {
    let $domain := config:get-domain($domain-model/ancestor::domain:domain/domain:name[1])
    let $reference-key := domain:get-model-reference-key($domain-model)
    let $reference-models := 
        $domain/domain:model
        (:[//cts:element/@reference = $reference-key]:)
        [cts:contains(.,
            cts:element-attribute-value-query(
                xs:QName("domain:element"),
                xs:QName("reference"),
                $reference-key)
        )]
    return
      $reference-models
};

(:~
 : Returns true if a model is referenced by its identity
 : @param $domain-model - The model to determine the reference
 : @param $instance - 
 :)
declare function domain:is-model-referenced(
 $domain-model as element(domain:model),
 $instance as element()
 ) as xs:boolean {
     let $reference-key    := domain:get-model-reference-key($domain-model)
     let $reference-models := domain:get-model-references($domain-model)
     let $reference-values := (
        domain:get-field-value(domain:get-model-key-field($domain-model),$instance),
        domain:get-field-value(domain:get-model-keyLabel-field($domain-model),$instance)
     )
     let $reference-query := 
       cts:or-query((
        for $reference-model in $reference-models
        let $reference-fields := $reference-model//domain:element[@reference = $reference-key]
        return
          domain:get-model-reference-query($reference-model,$reference-key,$reference-values)
       ))
     return 
        xdmp:exists(cts:search(fn:collection(),$reference-query))  
  };
  
(:~
 : Returns true if a model is referenced by its identity
 : @param $domain-model - The model which is the base of the instance reference
 : @instance - The instance for a given model
 :)
declare function domain:get-model-reference-uris(
 $domain-model as element(domain:model),
 $instance as element()
 ) {
     let $reference-key    := domain:get-model-reference-key($domain-model)
     let $reference-models := domain:get-model-references($domain-model)
     let $reference-values := (
        domain:get-field-value(domain:get-model-key-field($domain-model),$instance),
        domain:get-field-value(domain:get-model-keyLabel-field($domain-model),$instance)
     )
     let $reference-query := 
       cts:or-query((
        for $reference-model in $reference-models
        let $reference-fields := $reference-model//domain:element[@reference = $reference-key]
        return
          domain:get-model-reference-query($reference-model,$reference-key,$reference-values)
       ))
     return cts:uris((),(),$reference-query)
};
  
  
(:~
 : Creates a query that determines if a given model instance is referenced by any model instances.
 : The query is built by traversing all models that have a reference field that is referenced by 
 : the given instance value.
 : @param $reference-model - The model that is the base for the reference
 : @param reference-key  - The key to match the reference against the key is model:{model-name}:reference
 : @param reference-value - The value for which the query will match the reference
 :)
declare function domain:get-model-reference-query(
    $reference-model as element(domain:model),
    $reference-key as xs:string,
    $reference-value as xs:anyAtomicType*
 ) {
    let $referenced-fields := $reference-model//domain:element[@type = "reference" and @reference = $reference-key]
    let $base-constraint := domain:get-base-query($reference-model)
    return 
      cts:and-query((
        $base-constraint,
        for $reference-field in $referenced-fields
        let $field-ns := domain:get-field-namespace($reference-field)
        let $field-name := fn:data($reference-field/@name)
        return 
          cts:or-query((
            cts:element-attribute-value-query(fn:QName($field-ns,$field-name),xs:QName("ref-uuid"),$reference-value)
          ))
      ))
 };

(:~
 : Returns the default collation for the given field. The function walks up the ancestor tree to find the collation in the following order:
 : $field/@collation->$field/model/@collation->$domain/domain:default-collation.
 : @param $field - the field to find the collation by.
 :)
declare function domain:get-field-collation($field as element()) as xs:string {
   (:fn:head(($field/@collation,
    $field/ancestor::domain:model/@collation,
    $field/ancestor::domain:domain/domain:default-collation,
   "http://marklogic.com/collation/codepoint"
   )):)
   if($field/@collation) then $field/@collation
   else if($field/ancestor::domain:model/@collation) then $field/ancestor::domain:model/@collation
   else if($field/ancestor::domain:domain/domain:default-collation) then $field/ancestor::domain:domain/domain:default-collation
   else fn:error(xs:QName("COLLATION-ERROR"), "No collation defined for domain")
};

(:~
 : Returns the list of fields that are part of the uniqueKey constraint as defined by the $model/@uniqueKey attribute.
 : @param $model - Model that defines the unique constraint.
 :)
declare function domain:get-model-uniqueKey-constraint-fields($model as element(domain:model)) {
if($model/@uniqueKey and $model/@uniqueKey ne "") 
   then
     let $fields := fn:tokenize($model/@uniqueKey," ") ! fn:normalize-space(.)
     for $f in $fields
     let $field := $model//(domain:element|domain:attribute)[@name = $f]
     return
       if($field) then $field else fn:error(xs:QName("UNIQUEKEY-FIELD-MISSING"),"The key in a uniqueKey constraint is missing",$f)     
   else () 
};
(:~
 : Returns a unique constraint query 
 :)
declare function domain:get-model-uniqueKey-constraint-query(
    $model as element(domain:model),
    $params as item(),
    $mode as xs:string
) {
   if(domain:get-model-uniqueKey-constraint-fields($model)) then 
       let $id-field := domain:get-model-identity-field($model)
       let $id-field-key := domain:get-field-id($id-field)
       let $id-value := domain:get-field-param-value($id-field,$params)
       let $id-query := 
          if($mode = ("create","new")) then
               if($id-value) then 
                 typeswitch($id-field)
                   case element(domain:element) return
                        cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                   case element(domain:attribute) return
                        cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                   default return ()
                else ()
            else 
             typeswitch($id-field)
                  case element(domain:element) return
                    cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"!=",$id-value,("collation="  || domain:get-field-collation($id-field)))
                  case element(domain:attribute) return
                       cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"!=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                  default return ()
     let $unique-fields := domain:get-model-uniqueKey-constraint-fields($model)
     let $constraint-query := 
          for $field in $unique-fields
          let $field-value := domain:get-field-param-value($field,$params)
          let $field-ns := domain:get-field-namespace($field)
          return 
           typeswitch($field)
           case element(domain:attribute) return
              let $parent := $field/parent::domain:element
              let $parent-ns := domain:get-field-namespace($parent)
              return
               cts:element-attribute-value-query(fn:QName($parent-ns,$parent/@name),xs:QName($field/@name),$field-value)
           case element(domain:element) return
              switch($field/@type)
                 case "reference" return 
                   cts:or-query((
                       cts:element-attribute-value-query(fn:QName($field-ns,$field/@name),xs:QName("ref-id"),$field-value),
                       cts:element-value-query(fn:QName($field-ns,$field/@name),$field-value)  
                   ))
                 default return 
                   cts:element-value-query(fn:QName($field-ns,$field/@name),$field-value)
           default return ()                
     let $search-expression := domain:get-model-search-expression($model,cts:and-query(($id-query,$constraint-query)))
     return
        xdmp:eval($search-expression)
   else ()
};
(:~
 : Returns the value of a query matching a unique constraint. A unique constraint at a field level is defined
 : that every value that is considered unique be unique for each field.  For compound unique values 
 : use @see uniqueKey
 : @param $model  - The model to generate the unique constraint
 : @param $params - The map:map of parameters.
 : @param $mode   - The $mode can either be "create" or "update". When in update mode, 
                    removes the document under update to ensure it does not assume it is part of the query.
 :)
declare function domain:get-model-unique-constraint-query(
    $model as element(domain:model),
    $params as item(),
    $mode as xs:string) {
   if(domain:get-model-unique-constraint-fields($model)) then 
     let $id-field := domain:get-model-identity-field($model)
     let $id-field-key := domain:get-field-id($id-field)
     let $id-value := domain:get-field-value($id-field,$params)
     let $id-query := 
        if($mode = "create") then
          if($id-value) then 
              typeswitch($id-field)
                case element(domain:element) return
                  cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                case element(domain:attribute) return
                     cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                default return ()
              else ()
          else if($id-value) then 
              typeswitch($id-field)
                case element(domain:element) return
                  cts:element-range-query(fn:QName(domain:get-field-namespace($id-field),$id-field/@name),"!=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                case element(domain:attribute) return
                     cts:element-attribute-range-query(fn:QName(domain:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"!=",$id-value,("collation=" || domain:get-field-collation($id-field)))
                default return ()
              else ()
     let $unique-fields := domain:get-model-unique-constraint-fields($model)
     let $constraint-query := 
        for $field in $unique-fields
        let $field-value := domain:get-field-value($field,$params)
        let $field-ns := domain:get-field-namespace($field)
        return 
         typeswitch($field)
         case element(domain:attribute) return
            let $parent := $field/parent::domain:element
            let $parent-ns := domain:get-field-namespace($parent)
            return
             cts:element-attribute-value-query(fn:QName($parent-ns,$parent/@name),xs:QName($field/@name),$field-value)
         case element(domain:element) return
            switch($field/@type)
               case "reference" return 
                  cts:element-attribute-value-query(fn:QName($field-ns,$field/@name),xs:QName("ref-id"),$field-value)
               default return 
                 cts:element-value-query(fn:QName($field-ns,$field/@name),$field-value)
         default return ()                
     let $search-expression := domain:get-model-search-expression($model,cts:and-query(($id-query,cts:or-query($constraint-query))))
     return
          xdmp:eval($search-expression)
 else ()
};

(:~
 : Constructs a search expression based on a give model
 :)
declare function domain:get-model-search-expression($domain-model as element(domain:model),$query as cts:query?)
{
 domain:get-model-search-expression($domain-model,$query,())
};

(:~
 : Constructs a search expression based on a givem model
 :)
declare function domain:get-model-search-expression(
    $domain-model as element(domain:model),
    $query as cts:query?,
    $options as xs:string*) {
  let $pathExpr := switch($domain-model/@persistence)
    case "document" return
       "fn:doc('" || $domain-model/domain:document || "')/ns0:" || $domain-model/domain:document/@root || "/ns0:" || $domain-model/@name
    case "directory" return
       "fn:collection()" || "/ns0:" || $domain-model/@name
    default return 
       "cts:element-query(xs:QName('ns0:" || $domain-model/@name || "'),cts:and-query(()))"
  let $baseQuery := domain:get-base-query($domain-model)
  
  let $searchExpr := 
       "cts:search(" || $pathExpr || "," || xdmp:describe(cts:and-query(($baseQuery,$query)),(),()) || "," || xdmp:describe($options,(),()) || ")"
  let $nsExpr := "declare namespace ns0 = '" || domain:get-field-namespace($domain-model) || "'; "
  let $expr :=  $nsExpr || $searchExpr  
  return
         $expr
};
(:~
 : Returns a cts query that returns a cts:query which matches a node against its value.
:)
declare function domain:get-identity-query(
    $model as element(domain:model),
    $params as item()
) {
    let $identity-field := domain:get-model-identity-field($model)
    return 
       typeswitch($identity-field) 
         case element(domain:attribute) return
            cts:element-attribute-range-query(
                domain:get-field-qname($identity-field/..),
                domain:get-field-qname($identity-field),
                "=",
                domain:get-param-value($params,$identity-field/@name),
                ("collation="  || domain:get-field-collation($identity-field))
            )
         case element(domain:element) return
           cts:element-range-query(
              domain:get-field-qname($identity-field),
              "=",
              domain:get-param-value($params,$identity-field/@name),
              ("collation="  || domain:get-field-collation($identity-field))
           )
         default return fn:error(xs:QName("PERSISTENCE-QUERY-ERROR"),"Identity Error")
      
};
declare function domain:get-keylabel-query(
    $model as element(domain:model),
    $params as item()
) {
    let $key-field := domain:get-model-keyLabel-field($model)
        return 
       typeswitch($key-field) 
         case element(domain:attribute) return
            cts:element-attribute-range-query(
                domain:get-field-qname($key-field/..),
                domain:get-field-qname($key-field),
                "=",(
                domain:get-param-value($params,$key-field/@name) ! domain:cast-value($key-field,.)
                ),
                ("collation="  || domain:get-field-collation($key-field))
            )
         case element(domain:element) return
           cts:element-range-query(
              domain:get-field-qname($key-field),
              "=",
              domain:get-param-value($params,$key-field/@name)  ! domain:cast-value($key-field,.),
              ("collation="  || domain:get-field-collation($key-field))
           )
         default return fn:error(xs:QName("PERSISTENCE-QUERY-ERROR"),"KeyLabel Error")
      
};
(:~
 : Returns the base query for a given model
 : @param $model  name of the model for the given base-query
 :)
declare function domain:get-base-query($model) {
     switch($model/@persistence) 
       case "directory" return cts:and-query((
        $model/domain:directory[. ne ""] !cts:directory-query(.,"infinity"),
        xdmp:plan(/*[fn:node-name(.)  eq domain:get-field-qname($model)])//*:key ! cts:term-query(.)
       ))
       case "document" return cts:document-query($model/domain:document)
       case "singleton" return cts:document-query($model/domain:document)
       case "abstract" return  ()
       default return fn:error(xs:QName("BASE-QUERY-ERROR"),"Cannot determine base query on model",$model/@name)
};
(:~
 : Constructs a xdmp:estimate expresion for a referenced model
 : @param $domain-model - model definition
 : $query - Additional query to add the estimate expression
 : $options - cts:search options   
 :)
declare function domain:get-model-estimate-expression(
    $domain-model as element(domain:model),
    $query as cts:query?,
    $options as xs:string*
) {
  let $persistence := fn:data($domain-model/@persistence)
  let $_check := 
     if(fn:not($persistence = ("document","directory","singleton")))
     then fn:error(xs:QName("MODEL-EXPRESSION-ERROR"),"Cannot construct a query when persistence not set",fn:data($domain-model/@persistence))
     else ()     
  let $pathExpr := switch($domain-model/@persistence)
    case "document" return
       "fn:doc('" || $domain-model/domain:document || "')/ns0:" || $domain-model/domain:document/@root || "/ns0:" || $domain-model/@name
    case "directory" return
       "fn:collection()" || "/ns0:" || $domain-model/@name
    case "abstract" return "fn:collection()"
    default return 
       "cts:element-query(xs:QName('ns0:" || $domain-model/@name || "'),cts:and-query(()))"
  let $baseQuery := domain:get-base-query($domain-model)
  let $searchExpr := 
       "xdmp:estimate(cts:search(" || $pathExpr || "," || xdmp:describe(cts:and-query(($baseQuery,$query)),(),()) || "," || xdmp:describe($options,(),()) || "))"
  let $nsExpr := "declare namespace ns0 = '" || domain:get-field-namespace($domain-model) || "'; "
  let $expr :=  $nsExpr || $searchExpr  
  return
      $expr
};
(:~
 : Creates a root term query that can be used in combination to specify the root.
:)
declare function domain:model-root-query($model as element(domain:model)) {
  let $name := $model/@name
  let $ns := domain:get-field-namespace($model)
  let $prefix := domain:get-field-prefix($model)
  return
   switch($model/@persistence)
     case "directory" return 
         xdmp:with-namespaces(domain:declared-namespaces($model),
            xdmp:value(fn:concat("xdmp:plan(/",$prefix,":",$name,")"))/qry:final-plan//qry:key ! cts:term-query(.)
         )
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
(:~
 : 
:)
declare function domain:get-field-query(
$field as element(),
$value as xs:anyAtomicType*) {
    let $name := $field/@name
    let $ns := domain:get-field-namespace($field)
    let $index := $field/domain:navigation/@searchType
    return
       typeswitch($field)
         case element(domain:element) return
           if($index = "range") then 
             cts:element-range-query(fn:QName($ns,$name),"=",$value)
           else cts:element-value-query(fn:QName($ns,$name), $value)
         case element(domain:attribute) return
           let $parent := $field/..
           let $parent-ns := domain:get-field-namespace($parent)
           let $parent-name := $parent/@name
           return 
               if($index = "range") then 
                 cts:element-attribute-range-query(fn:QName($parent-ns,$parent-name),fn:QName("",$name),"=",$value)
               else cts:element-attribute-value-query(fn:QName($parent-ns,$parent-name),fn:QName($ns,$name), $value)
        default return
            fn:error(xs:QName("FIELD-QUERY-ERROR"), "Unable to resolve query for",$field/@name)
};
declare function domain:get-field-tuple-reference(
$field as element()
) {
   domain:get-field-tuple-reference($field,())
};
(:~
 : Returns a field reference to be used in xxx-value-calls
 :)
declare function domain:get-field-tuple-reference( 
   $field as element(),
   $add-options as xs:string*
) {
    let $options := 
        (
          if($field/@type = ("string","reference","identity","id"))
          then "collation=" || domain:get-field-collation($field)
          else if($field/@type = ("integer","decimal","double","float","long","unsignedLong","unsignedInt","int"))
          then "type=" || $field/@type
          else ()   
     )
    return
        typeswitch($field)
            case element(domain:element) return 
                cts:element-reference(domain:get-field-qname($field),($options,$add-options))
            case element(domain:attribute) return
                cts:element-attribute-reference(domain:get-field-qname($field),($options,$add-options))
            default return fn:error(xs:QName("NOT-REFERENCABLE"),"Cannot reference type of " || fn:local-name($field),$field)
};

(:~
 : Return as list of all prefixes and their respective namespaces
:)
declare function domain:declared-namespaces(
  $model as element()
) as xs:string* {
  let $key   := fn:concat("declared-namespaces::",fn:generate-id($model))
  let $cache := domain:get-identity-cache($key)
  return
    if($cache) then $cache
    else
    let $value := (
      $model/ancestor::domain:domain/domain:content-namespace ! (./@prefix, ./(@namespace|@namespace-uri)[1]),
      $model/ancestor::domain:domain/domain:declare-namespace ! (./@prefix, ./(@namespace|@namespace-uri)[1]),
      fn:in-scope-prefixes($model)[. ne ""] ! (., fn:namespace-uri-for-prefix(., $model))
    )
    return (
      domain:set-identity-cache($key,$value),
      $value
    )
};

declare function domain:declared-namespaces-map($model) {
   let $nses := domain:declared-namespaces($model)
   let $map := map:map()
   let $_ := 
     (
     $model/../domain:content-namespace ! map:put($map,./@prefix,./(@namespace|@namespace-uri)[1]),
     $model/../domain:declare-namespace ! map:put($map,./@prefix,./(@namespace|@namespace-uri)[1])     
     )
   return $map
};
(:~
 : Fires an event and returns if event succeeded or failed
 : It is important to note that any event that is fired must return
 : the number of values associated with the given function.
 : Events that break this convention will lead to spurious results
 : @param $model - the model for which the event should fire
 : @param $event-name - The name of the event to fire
 : @param $context - The context for the given event in most cases
 :                   the context is a map:map if it is for before-event
 :)
declare function domain:fire-before-event(
    $model as element(domain:model),
    $event-name as xs:string,
    $context as item()*
) {
   let $event := $model/domain:event[@name = $event-name and @mode= ("before","wrap")]
   return
        if($event) then 
        let $module := $event/@module
        let $module-namespace := $event/@module-namespace
        let $module-uri := $event/@module-uri
        let $function := $event/@function
        let $call := xdmp:function(fn:QName($module-namespace,$function),$module-uri)
        return
          xdmp:apply($call,$event,$context)
        else $context
};

(:~
 : Fires an event and returns if event succeeded or failed.
 : It is important to note that any event that is fired must return
 : the number of values associated with the given function.
 : Events that break this convention will lead to spurious results
 : @param $model - the model for which the event should fire
 : @param $event-name - The name of the event to fire
 : @param $context - The context for the given event in most cases
 :                   the context is an instance of the given model.
 :)
declare function domain:fire-after-event(
    $model as element(domain:model),
    $event-name as xs:string,
    $context as item()*
) {
   let $event := $model/domain:event[@name = $event-name and @mode= ("after","wrap")]
   return
   if($event) then 
     let $module := $event/@module
     let $module-namespace := $event/@module-namespace
     let $module-uri := $event/@module-uri
     let $function := $event/@function
     let $call := xdmp:function(fn:QName($module-namespace,$function),$module-uri)
     return
       xdmp:apply($call,$event,$context)
   else $context
};
(:~
 : Gets the json path for a given field definition. The path expression by default is relative to the root of the json type
:)
declare function domain:get-field-jsonpath(
$field as element()
) {
  domain:get-field-jsonpath($field,fn:false(),())
};

declare function domain:get-field-jsonpath(
$field as element(),
$include-root as xs:boolean
) {
  domain:get-field-jsonpath($field,$include-root,())
};

(:~
 : Returns the path of field instance from a json object.  
 : @param $field - Definition of the field instance (domain:element|domain:attribute|domain:container)
 : @param $include-root - if the root json:object should be returned in path expression
 : @param $base-path - when using nested recursive json structures the base-path to include additional path construct
 :)
declare function domain:get-field-jsonpath(
$field as element(),
$include-root as xs:boolean,
$base-path as xs:string?
) {
   if($field/@jsonPath) then fn:string($field/@jsonPath) else
   let $paths := $field/ancestor-or-self::element()[fn:node-name(.) = $DOMAIN-FIELDS]
   return
     fn:string-join((
          $base-path,
          for $path at $pos in $paths
          let $key := 
             typeswitch($path)
             case element(domain:attribute) return fn:concat(config:attribute-prefix(),fn:data($path/@name))
             default return fn:data($path/@name)
          return
              let $is-multi := ("+","*") = $path/@occurrence
              let $base-type := domain:get-base-type($path)
              return
                switch($base-type)
                    case "instance" return 
                       if($is-multi) 
                       then fn:concat("json:entry[@key = '",$key,"']/json:value/json:array/json:value/json:object")
                       else fn:concat("json:entry[@key = '",$key,"']/json:value/json:object")
                    case ("simple") return 
                       if($is-multi) 
                       then fn:concat("json:entry[@key = '",$key, "']/json:value/json:array/json:value")
                       else fn:concat("json:entry[@key = '",$key, "']/json:value")
                    case ("complex") return 
                      if($is-multi) 
                       then fn:concat("json:entry[@key = '",$key, "']/json:value/json:array/json:value")
                       else fn:concat("json:entry[@key = '",$key, "']/json:value")
                    case "model" return 
                      if($include-root) then "/json:object"
                      else ""
                    case "container" return fn:concat("json:entry[@key = '",$key,"']/json:value/json:object")
                    default return fn:error(xs:QName("JSON-PATH-ERROR"),"Unknown Path Type",$base-type)
     ) ,"/")
};

(:~
 : Gets the value from an object type
:)
declare function domain:get-field-value(
    $field as element(),
    $value as item()*
    ) as item()* {
    if ($field instance of element(domain:model)) then () else
    let $return-value := 
        typeswitch($value)
          case json:object          return domain:get-field-json-value($field,$value)
          case json:array           return domain:get-field-json-value($field,$value)
          case element(json:object) return domain:get-field-json-value($field,$value)
          case element(json:array)  return domain:get-field-json-value($field,$value)
          case element(map:map)     return domain:get-field-param-value($field,map:map($value))
          case map:map              return domain:get-field-param-value($field,$value)
          case element()            return domain:get-field-xml-value($field,$value) 
          case document-node()      return domain:get-field-xml-value($field,$value/element())
          case empty-sequence() return ()
          default return (:fn:error((),"Unknown Value Type",$value):)
          $value
      return domain:cast-value($field,
        if(fn:exists($return-value) )
        then ( $return-value )
        else if($field/@default) then $field/@default
        else ()
      )
};


(:~
 : Returns the value for a field given a json object
 :)
declare function domain:get-field-json-value(
  $field as element(),
  $values as item()?
) {
  let $value := 
      for $v in $values
      return 
       typeswitch($v)
       case json:object return <x>{$v}</x>/*
       case json:array return <x>{$v}</x>/*
       case element(json:object) return $v
       case element(json:array) return json:array-values(json:array($v))
       default return fn:error(xs:QName("UNKNOWN-JSON-OBJECT"),"Type is not json",xdmp:describe($v))
  return
        if(domain:exists-field-function-cache($field,"json"))
        then domain:get-field-function-cache($field,"json")($value)
        else 
          let $type := domain:get-base-type($field)
          let $path := domain:get-field-jsonpath($field)
          let $func := 
              switch($type)
              case "simple" return xdmp:value(fn:concat("function($value) { $value",$path, "}"))
              default return xdmp:value(fn:concat("function($value) { $value", $path,"}"))
          return (
            domain:set-field-function-cache($field,"json",$func),
            $func($value)
          )
 };

(:~
 : Returns the value for a field given a xml using its xpath expression
 :)
declare function domain:get-field-xml-value(
  $field as element(),
  $value as item()*
) {
  if(domain:exists-field-function-cache($field,"xml"))
  then domain:get-field-function-cache($field,"xml")($value)
  else
    let $type := domain:get-base-type($field)
    let $path := domain:get-field-xpath($field)
    let $expr := fn:concat("$value", $path)
    let $_    := xdmp:log(("domain:get-field-xpath",$type,$field,$path),"finest")
    let $func := 
      switch($type)
        case "simple" return xdmp:with-namespaces(domain:declared-namespaces($field),xdmp:value(fn:concat("function($value){", $expr, "}")))
        default return xdmp:with-namespaces(domain:declared-namespaces($field),xdmp:value(fn:concat("function($value){", $expr, "}")))
    return (
       domain:set-field-function-cache($field,"xml",$func),
       $func($value)
    )
};
(:~
 : Returns the base type of field definition.  The base type of the domain 
 :) 
declare function domain:get-base-type(
    $field as element()
) {
  domain:get-base-type($field,fn:true())
};
(:~
 : Returns the base type of field definition.  The base type of the domain 
 :) 
declare function domain:get-base-type(
    $field as element(),
    $safe as xs:boolean
) {
  if($field/@type = $SIMPLE-TYPES) then "simple"
  else if($field/@type = $COMPLEX-TYPES) then "complex"
  else if($field instance of element(domain:model)) then "model"
  else if($field instance of element(domain:container)) then "container"
  else if(domain:model-exists($field/@type)) then "instance"
  else if($safe) then fn:error(xs:QName("UNKNOWN-BASE-TYPE"),"Unknown Base Type",$field)
  else "unknown"
};

(:~
 : Returns true if the field is multivalue or occurrence allows for more than 1 value.
 :)
declare function domain:field-is-multivalue($field) {
    if($field/@occurrence =  ("*","+"))
    then fn:true()
    else if($field/@occurrence castable as xs:integer)
    then $field/@occurrence cast as xs:integer gt 1
    else fn:false()
};

(:~
 : Returns the passed in value type and its expecting source values
:)
declare function domain:get-value-type($type as item()?) {
  typeswitch($type)
    case json:object return "json"
    case json:array return "json"
    case element(json:object) return "json"
    case element(json:array) return "json"
    case element(map:map) return "param"
    case map:map return "param"
    case element() return "xml"
    case xs:string return
      if(fn:matches($type,"^(\{|\[).*(\}\])$")) then "json"
      else "empty"
    default return "empty"
};
(:~
 : Returns the value of collections given any object type
 :)
declare function domain:get-field-value-collections($value) {
  let $value-type := domain:get-value-type($value) 
  return
    switch($value-type)
      case "xml" return $value//_collection
      case "json" return $value//json:entry[@key = "_collection"]//json:value ! fn:data(.)
      case "param" return map:get($value,"_collection")
      default return ()
};

(:~
 : Returns the key for a given parameter by its name
 :)
declare function domain:get-param-keys(
  $params as item()
) {
  switch(domain:get-value-type($params))
    case "json" return 
        if($params instance of json:object)     then <x>{$params}</x>//json:entry/@key 
        else if($params instance of json:array) then json:array-values($params)      
        else $params//json:entry/@key ! fn:string(.)
    case "param" return map:keys($params)
    case "xml" return  $params/fn:local-name
    default return ()
};
(:~
 : Gets a parameter from a map:map or json:object value by its name
:)
declare function domain:get-param-value(
    $params as item(),
    $key as xs:string*
) {
  switch(domain:get-value-type($params))
    case "json" return 
        if($params instance of json:object) 
        then <x>{$params}</x>//json:entry[@key = $key]//json:value/node() 
        else $params//json:entry[@key = $key]//json:value/node()
    case "param" return map:get($params,$key)
    case "xml" return  $params//*[fn:local-name(.) = $key]/node()
    default return ()

};
(:~
 : 
 :)
declare function domain:model-exists(
  $model-name as xs:string?
) {
  domain:model-exists(config:default-application(),$model-name)
};

(:~
 :
 :)
declare function domain:model-exists(
    $application-name as xs:string,
    $model-name as xs:string?
) {
   fn:exists(config:get-domain($application-name)//domain:model[@name = $model-name])
};

(:~
 : Returns whether the module exists or not.
 :)
declare function domain:module-exists(
    $module-location as xs:string
) as xs:boolean {
	if (xdmp:modules-database() ne 0) then
		xdmp:eval(fn:concat('fn:doc-available("', $module-location, '")'), (),
			<options xmlns="xdmp:eval">
				<database>{xdmp:modules-database()}</database>
			</options>
		)
	else
		xdmp:uri-is-file($module-location)
};

(:~
 : Checks that a given module function exists or not
 : $function-arity is optional
 :)
declare function domain:module-function-exists(
$module-namespace as xs:string,
$module-location as xs:string,
$function-name as xs:string,
$function-arity as xs:integer?
) as xs:boolean {
   let $eval := 
      <node>import module namespace func = '{$module-namespace}' at '{$module-location}';
      { if( fn:empty( $function-arity ) )
       then <call>fn:function-available("func:{$function-name}")</call>
       else <call>fn:function-available("func:{$function-name}", {$function-arity})</call>
      }
     </node>
   return      
    try { xdmp:eval( $eval ) }
    catch($ex) {(
       if($ex//error:code = (("XDMP-IMPMODNS","SVC-FILOPN")))
         then xdmp:log(fn:concat("action-not-exist::",$module-location,"({",$module-namespace,"}:",$function-name,"::",$ex//error:format-string),"debug")
         else xdmp:rethrow() 
       ,fn:false()
    )}
};

(:
 : get a module function  (generic)
 : this should be refactored along with the module code in domain.xqy
 : @author jjl
 :)
 declare function domain:get-module-function(
    $module-namespace as xs:string,
    $module-location as xs:string,
    $function-name as xs:string,
    $function-arity as xs:integer?
 ) as xdmp:function? {
    if( domain:module-exists( $module-location ) 
        and domain:module-function-exists( $module-namespace, $module-location, $function-name, $function-arity ) )
    then xdmp:function( fn:QName( $module-namespace, $function-name ), $module-location )
    else ()    
 };

(:
 : get a model-module-specific model function
 : @author jjl
 :)
 declare function domain:get-model-module-function(
    $application-name as xs:string?,
    $model-name as xs:string,
    $action as xs:string
 ) as xdmp:function? {
    let $application := config:get-application( ($application-name, config:default-application())[1] )
    let $module-namespace := fn:concat($application/@namespace,'/model/', $model-name)
    let $module-location  := fn:concat($application/@uri,'/models/', $model-name,'-model.xqy')
    return
        domain:get-module-function( $module-namespace, $module-location, $action, 2 )
 };
 
 (:
  : This needs to figure in any _extension/model.extension.xqy
  : Perhaps a better name than get-base-model-function would be get-model-default-function
  : Either that or we add get-model-extension-function and put that in the sequence in 
  : get-model-function
  :)
 declare function domain:get-model-base-function(
     $action as xs:string
 ) as xdmp:function? {
    let $module-namespace := "http://xquerrail.com/model/base"
    let $module-location  := config:get-base-model-location('')
    return
        domain:get-module-function( $module-namespace, $module-location, $action, 2 )
 };
 
 (:
 : get a model function, either from model-module or base-module
 :
 :)
 declare function domain:get-model-function(
    $application-name as xs:string?,
    $model-name as xs:string,
    $action as xs:string,
    $fatal as xs:boolean?
 ) as xdmp:function? {
    (
        domain:get-model-module-function( $application-name, $model-name, $action ),
        (: domain:get-model-extension-function(..), :)
        domain:get-model-base-function( $action ),
        if( $fatal )
            then fn:error(xs:QName("ACTION-NOT-EXISTS"), "The action '" || $action || "' for model '" || $model-name || "' does not exist")
            else ()
    )[1]
};

(:~
 : Returns all models for all domains
:)
declare function domain:get-models (
) as element(domain:model)* {
   domain:get-models(domain:get-default-application(), fn:false())
};
(:~
 : Returns all models for a given application including abstract
 : @param $application - Name of the application
 : @param $include-abstract - Determines if to include abstract models.
 :)
declare function domain:get-models (
  $application as xs:string,
  $include-abstract as xs:boolean
) as element(domain:model)* {
  if ($include-abstract) then
    config:get-domain($application)/domain:model
  else
    config:get-domain($application)/domain:model[@persistence != 'abstract']
};

(:~
 : Returns all in scope permissions associated with a model.
 : @param $model for a given permission set
:)
declare function domain:get-permissions(
    $model as element(domain:model)
 ) {
  let $permset := (
    $model/domain:permission,
    $model/ancestor::domain:domain/domain:permission
  )
  return
    functx:distinct-deep(
     for $perm in $permset
     return
       (
        if($perm/@read = "true") then xdmp:permission($perm/@role,"read") else (),
        if($perm/@insert = "true") then xdmp:permission($perm/@role,"insert") else (),
        if($perm/@update = "true") then xdmp:permission($perm/@role,"update") else (),
        if($perm/@execute = "true") then xdmp:permission($perm/@role,"execute") else ()
       ))
};
(:~
 : Returns all models that have been descended(@extends) from the given model.
:)
declare function domain:get-descendant-models(
    $parent as element(domain:model)
 ) {
  config:get-domain($parent/ancestor::domain:domain/domain:name[1])/domain:model[@extends  = $parent/@name]
};

(:~
 : Returns the query for descendant(@extends) models.
 : @param $model - Model which is the extension model
 :)
declare function domain:get-descendant-model-query(
    $parent as element(domain:model)
) {
   domain:get-descendant-models($parent) ! domain:get-base-query(.)
};

(:~
 : returns the default language associated with langString field. 
 :)
declare function domain:get-default-language($field) {
  if($field/@defaultLanguage) then $field/@defaultLanguage
  else if($field/ancestor::domain:domain/domain:default-language) then $field/ancestor::domain:domain/domain:default-language
  else "en"
};

(:~
 : Returns the languages associated with a given domain field whose type is langString
 :)
declare function domain:get-field-languages($field as element()) {
   fn:distinct-values((
   $field/ancestor::domain:domain/domain:language,
   fn:tokenize($field/@languages,"\s"),
   "en"))
};
