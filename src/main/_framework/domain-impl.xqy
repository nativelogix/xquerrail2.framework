xquery version "1.0-ml";
(:~
 : Controls all interaction with an application domain.  The domain provides annotations and
 : definitions for dynamic features built into XQuerrail.
 : @version 2.0
 :)
module namespace domain-impl = "http://xquerrail.com/domain/impl";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "base/base-model.xqy";
import module namespace module-loader = "http://xquerrail.com/module" at "module.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-doc-2007-01.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace qry = "http://marklogic.com/cts/query";

declare option xdmp:mapping "false";

declare variable $FUNCTION-KEYS := "$FUNCTION-KEYS$";
declare variable $UNDEFINED-FUNCTION := "$UNDEFINED-FUNCTION$";

(:~
 : A list of QName's that define in a model
 :)
declare variable $DOMAIN-FIELDS :=
  xdmp:eager(
    for  $fld in ("domain:model","domain:container","domain:element","domain:attribute","domain:triple")
    return xs:QName($fld)
  );

(:~
 : A list of QName's that define model node fields excluding the model
 :)
declare variable $DOMAIN-NODE-FIELDS :=
  xdmp:eager(
    for  $fld in ("domain:container","domain:element","domain:attribute","domain:triple")
    return  xs:QName($fld)
  );

declare variable $COLLATION := "http://marklogic.com/collation/codepoint";

declare variable $COMPLEX-TYPES := (
  (:GeoSpatial:)
  "lat-long", "longitude", "latitude",
  (:Others:)
  "query", "schema-element", "binary", "reference", "langString"
);

declare variable $SIMPLE-TYPES := (
  (:Identity Sequence:)
  "identity", "ID", "id", "sequence",
  (:Users/Timestamps :)
  "create-user","create-timestamp","update-timestamp","update-user",
  (:xs:atomicType    :)
  "anyURI", "string","integer","decimal","double","float","boolean","long",
  (:Durations        :)
  "date","time","dateTime", "duration","yearMonth","monthDay"
);

declare variable $MODEL-INHERIT-ATTRIBUTES := ('class', 'key', 'keyLabel', 'persistence');

declare variable $MODEL-PERMISSION-ATTRIBUTES := (
  "role", "read", "update", "insert", "execute"
);

declare variable $MODEL-NAVIGATION-ATTRIBUTES := (
  "editable", "exportable", "findable", "importable", "listable", "newable", "removable", "searchable", "securable", "showable", "sortable", "triplable"
);

declare variable $FIELD-NAVIGATION-ATTRIBUTES := (
  $MODEL-NAVIGATION-ATTRIBUTES, "metadata", "suggestable"
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
declare function domain-impl:cast-value(
  $field as element(),
  $value as item()*
) {
  if(fn:not(fn:exists($value))) then
    ()
  else
    let $type := $field/@type
    return
      switch($type)
        case "identity"         return $value[fn:string(.) ne ""] cast as xs:string?
        case "id"               return $value[fn:string(.) ne ""] cast as xs:ID?
        case "anyURI"           return $value[fn:string(.) ne ""] cast as xs:anyURI*
        (:case "string"           return $value cast as xs:string*:)
        case "string"           return
          typeswitch ($field)
            case element(domain:attribute)
              return $value cast as xs:string*
            default
              return $value[fn:string(.) ne ""] cast as xs:string*
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
        case "create-user"      return $value[fn:string(.) ne ""] cast as xs:string?
        case "update-user"      return $value[fn:string(.) ne ""] cast as xs:string?
        case "schema-element"   return $value
        case "langString"  return $value
        default return $value
};

(:~
 : Returns the cts scalar type for all types.  The default is "string"
:)
declare function domain-impl:get-field-scalar-type(
  $field as element()
) {
  domain-impl:resolve-cts-type($field/@type)
};

(:~
 : Returns if the value is castable to the given value based on the field/@type
 : @param $field Domain element (element|attribute|container)
 :)
declare function domain-impl:castable-value(
  $field as element(),
  $value as item()?
) {
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

declare function domain-impl:resolve-cts-type(
  $type as xs:string) {
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
declare %private function domain-impl:get-model-cache(
  $application as xs:string,
  $model-name as xs:string+
) {
  map:get($DOMAIN-MODEL-CACHE, fn:concat($application, ":" , fn:string-join($model-name, "")))
};

(:~
 : Sets the cache for a domain model
 :)
declare %private function domain-impl:set-model-cache(
  $application as xs:string,
  $model-name as xs:string+,
  $model as element(domain:model)+
) as element(domain:model)+ {
  map:put($DOMAIN-MODEL-CACHE, fn:concat($application, ":" , fn:string-join($model-name, "")), $model),
  $model
};

(:~
 : Sets a cache for quick lookup on domain model field paths
 :)
declare %private function domain-impl:set-field-cache(
  $key as xs:string,
  $func as function(*)
) {
  map:put($DOMAIN-MODEL-CACHE,$key,$func)
};

(:~
 : Gets the value of an identity cache from the map
 : @private
 :)
declare %private function domain-impl:get-identity-cache(
  $key as xs:string
) {
  let $value := map:get($DOMAIN-IDENTITY-CACHE,$key)
  return
    if($value) then $value else ()
};
(:~
 : Sets the cache value of a models identity field for fast resolution
 : @param $key - key string to identify the cache identity
 : @param $value - $value of the cache item
 :)
declare function domain-impl:set-identity-cache(
  $key as xs:string,
  $value as item()*
) as item()* {
  map:put($DOMAIN-IDENTITY-CACHE, $key, $value),
  $value
};

(:~
 : Returns a cache key unique to a field
 :)
declare function domain-impl:get-field-cache-key(
  $field,
  $prefix as xs:string
) {
  fn:concat(domain-impl:get-field-key($field),"::",$prefix)
};

declare function domain-impl:get-function-cache-key(
  $field as item(),
  $type as xs:string
) as xs:string {
  fn:concat(domain-impl:hash($field),"::",$type)
};

(:~
 : Returns the cache for a given value function
:)
declare function domain-impl:undefined-field-function-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  let $funct := map:get($FUNCTION-CACHE,domain-impl:get-function-cache-key($field,$type))
  return
    if (fn:empty($funct)) then
      fn:false()
    else if($funct instance of xs:string) then
      ($funct = $UNDEFINED-FUNCTION)
    else
      fn:false()
};

(:~
 : Returns the cache for a given value function
:)
declare function domain-impl:exists-field-function-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  map:contains($FUNCTION-CACHE,domain-impl:get-function-cache-key($field,$type))
};

(:~
 : Sets the function in the value cache
 :)
declare function domain-impl:set-field-function-cache(
  $field as element(),
  $type as xs:string,
  $funct as function(*)?
) {
  let $cache-funct :=
    if (fn:empty($funct)) then
      $UNDEFINED-FUNCTION
    else
      $funct
  return (
    map:put($FUNCTION-CACHE,domain-impl:get-function-cache-key($field,$type),$cache-funct),
    $funct
  )
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function domain-impl:get-field-function-cache(
  $field as element(),
  $type as xs:string
) as function(*)? {
  if (domain-impl:undefined-field-function-cache($field, $type)) then
    ()
  else
    map:get($FUNCTION-CACHE,domain-impl:get-function-cache-key($field,$type))
};


(:~
 : Returns the cache for a given value function
:)
declare function domain-impl:exists-field-value-cache(
  $field as element(),
  $type as xs:string
)  as xs:boolean {
    map:contains($VALUE-CACHE,domain-impl:get-field-cache-key($field,$type))
};

(:~
 : Sets the function in the value cache
 :)
declare function domain-impl:set-field-value-cache(
  $field as element(),
  $type as xs:string,
  $value as item()*
) {
   map:put($VALUE-CACHE,domain-impl:get-field-cache-key($field,$type),$value)
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function domain-impl:get-field-value-cache(
  $field as element(),
  $type as xs:string
) as item() {
   map:get($VALUE-CACHE,domain-impl:get-field-cache-key($field,$type))
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain-impl:get-model-identity-field-name(
  $model as element(domain:model)
) as xs:string {
  domain-impl:get-model-identity-field($model)/fn:string(@name)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain-impl:get-model-identity-field(
  $model as element(domain:model)
) {
  let $key := fn:concat($model/@name , ":identity")
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then $cache[1]
    else
    let $id-field := $model//(domain:element|domain:attribute)[fn:node-name(.) = $DOMAIN-NODE-FIELDS][@identity eq "true" or @type =( "identity","id")]
    return domain-impl:set-identity-cache($key,$id-field)[1]
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain-impl:get-model-keylabel-field(
  $model as element(domain:model)
) {
  let $key := fn:concat($model/@name , ":keyLabel")
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then fn:exactly-one($cache)
    else
    let $key-field := $model//(domain:element|domain:attribute)[@name = $model/@keyLabel][1]
    return domain-impl:set-identity-cache($key,$key-field)
};

(:~
 : Returns the identity query for a domain-model
 : @param $domain-model - The domain model for the identity-query
 : @param $value - The value of the domain instance for retrieval
 :)
declare function domain-impl:get-model-identity-query(
  $domain-model as element(domain:model),
  $value as xs:anyAtomicType?
) {
  let $id-field := domain-impl:get-model-identity-field($domain-model)
  let $id-ns    := domain-impl:get-field-namespace($id-field)
  return
    typeswitch($id-field)
      case element(domain:element) return
        cts:element-range-query(
          fn:QName($id-ns,$id-field/@name),
          "=",
          $value,
          ("collation="  || domain-impl:get-field-collation($id-field))
        )
      case element(domain:attribute) return
        let $parent-elem := domain-impl:get-parent-field-attribute($id-field)
        let $parent-ns   := domain-impl:get-field-namespace($parent-elem)
        return
          cts:element-attribute-range-query(
              fn:QName($parent-ns,$parent-elem/@name),
              fn:QName("",$id-field/@name),
              "=",
              $value,
              ("collation="  || domain-impl:get-field-collation($id-field))
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
declare function domain-impl:get-model-key-field(
  $model as element(domain:model)
) {
  let $key := ($model/@name || ":key")
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then $cache
    else
      let $field := $model//(domain:element|domain:attribute)[@name eq $model/@key]
      return domain-impl:set-identity-cache($key,$field)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain-impl:get-model-keyLabel-field(
  $model as element(domain:model)
) {
  let $key := ($model/@name || ":keyLabel")
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then $cache
    else
      let $field := $model//(domain:element|domain:attribute)[fn:node-name(.) = $DOMAIN-NODE-FIELDS][@name eq $model/@keyLabel]
      return domain-impl:set-identity-cache($key,$field)
};

declare function domain-impl:get-field-prefix(
  $field as element()
) as xs:string? {
  if($field/@prefix) then
    $field/@prefix
  else if ($field instance of element(domain:attribute)) then
    ()
  else
    let $key   := fn:concat("namespace-prefix::",fn:generate-id($field))
    let $cache := domain-impl:get-identity-cache($key)
    return
      if($cache) then
        $cache
      else
        let $ns := domain-impl:get-field-namespace($field)
        let $nses := domain:declared-namespaces($field)
        let $pos :=
          if (fn:exists($ns)) then
            fn:index-of($nses,$ns)
          else
            ()
        let $prefix :=
          if (fn:empty($pos)) then
            (:if ($field instance of element(domain:attribute)) then
              ()
            else:)
              fn:error(xs:QName("PREFIX-NOT-DEFINED"), text{"Prefix", $ns, "is not defined in domain"})
          else
            fn:subsequence($nses,$pos -1 ,1)
        (:let $prefix :=:)
          (:if($pos) then:)
            (:fn:subsequence($nses,$pos -1 ,1):)
          (:if ($prefix) then:)
            (:$prefix:)
          (:else:)
            (:fn:error( :)
              (:xs:QName("UNPREFIXED-NAMESPACE"),:)
              (:"Cannot resolve prefix for namespace " || $ns,:)
              (:fn:string($field/ancestor::domain:domain/fn:local-name(.)):)
            (:):)
        return domain-impl:set-identity-cache($key,$prefix)
};
(:~
 : Returns the field that matches the given field name or key
 : @param $model - The model to extract the given field
 : @param $name  - name or key of the field
 :)
(:declare function domain-impl:get-model-field(
  $model as element(domain:model),
  $name as xs:string
) {
  domain-impl:get-model-field($model, $name, fn:false())
};:)

declare function domain-impl:get-model-field(
  $model as element(domain:model),
  $name as xs:string,
  $include-container as xs:boolean
) {
  let $key := ($model/@name || ":field:" || $name || $include-container)
  let $cache := domain-impl:get-identity-cache($key)
  return
    if(fn:exists($cache)) then $cache
    else
      let $value :=
        if ($include-container) then
          $model//(domain:container|domain:element|domain:attribute)[$name eq @name or $name eq @keyId or $name eq @keyName or $name eq @jsonName]
        else
          $model//(domain:element|domain:attribute)[$name eq @name or $name eq @keyId or $name eq @keyName or $name eq @jsonName]
      return domain-impl:set-identity-cache($key,$value)
};

(:~
 : Returns model fields with unique constraints
 : @param $model - The model that returns all the unique constraint fields
 :)
declare function domain-impl:get-model-unique-constraint-fields(
  $model as element(domain:model)
) {
  $model//(domain:element|domain:attribute)[domain:constraint/@unique = "true"]
};

(:~
 : Resolves a domain type to xsi:type
 : @param $model - The model to extract the given identity field
 :)
declare function domain-impl:resolve-datatype(
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
    case element(monthDay) return "xs:gMonthDay" (:"xs:monthDayDuration":)
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
declare function domain-impl:resolve-ctstype(
  $field as element()
) {
  let $data-type := element{$field/@type}{$field}
  return
    typeswitch($data-type)
    case element(id) return "xs:string"
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
    default return fn:error(xs:QName("UNRESOLVED-DATATYPE"),(),$field)
};

(:~
 : Returns the default application domain content-namespace-uri
 : @return the content-namespace for the default application
 :)
declare function domain-impl:get-content-namespace-uri(
) as xs:string {
  domain-impl:get-content-namespace-uri(config:default-application())
};

(:~
 : Returns the content-namespace value for a given application
 : @param $application - name of the application
 : @return - The namespace URI of the given application
 :)
declare function domain-impl:get-content-namespace-uri(
  $application as xs:string
) as xs:string {
  let $key := fn:concat($application, ":namespace-uri")
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then
      $cache
    else
      let $value := fn:data(config:get-domain($application)/domain:content-namespace/@namespace-uri)
      return domain-impl:set-identity-cache($key,$value)
};

(:~
 : Gets the controller definition for a given application by its name
 : @param $application - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain-impl:get-controller(
   $application as xs:string,
   $controller-name as xs:string
) as element(domain:controller)? {
  let $domain := config:get-domain($application)
  return $domain/domain:controller[@name eq $controller-name]
};

(:~
 : Returns all the available functions for a given controller.
 : @param $application - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain-impl:get-controller-actions(
  $application as xs:string,
  $controller-name as xs:string
) {
  let $controller := domain-impl:get-controller($application,$controller-name)
  let $base-uri := config:application-directory($application)
  let $base-ns  := config:application-namespace($application)
  let $controller-ns := config:controller-uri($application, $controller-name)(:fn:concat($base-ns,"/controllers/",$controller-name):)
  let $stmt := fn:concat(
    "import module namespace controller = 'http://xquerrail.com/controller/base' at '../base/base-controller.xqy'; ",
    "&#xA;xdmp:functions()[fn:namespace-uri-from-QName(fn:function-name(.)) = 'http://xquerrail.com/controller/base']"
  )
  let $functions := try {
    xdmp:eval($stmt)
  } catch($ex) {
    fn:error(xs:QName("CONTROLLER-FUNCTIONS-ERROR"), "Error Retrieving functions", $stmt)
  }
  return fn:distinct-values(
    for $func in $functions
    let $name := fn:local-name-from-QName(fn:function-name($func))
    where fn:function-arity($func) = 0
    return $name
  )
};

(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application - Name of the application
 :  @param $controller-name - Name of the controller
 :  @return  - returns the model associated with the given controller.
 :)
declare function domain-impl:get-controller-model(
  $application as xs:string,
  $controller-name as xs:string
) as element(domain:model)? {
  let $domain := config:get-domain($application)
  let $controller := domain-impl:get-controller($application,$controller-name)
  let $model := domain:get-domain-model(fn:data($controller/@model))
  return $model
};

(:~
 : Gets the name of the controller for a given application and model.
 :  @param $application - Name of the application
 :  @param $model-name - Name of the controller
 :  @return - the name of the controller
 :)
declare function domain-impl:get-model-controller-name(
  $application as xs:string,
  $model-name as xs:string?
) as xs:string* {
  let $domain := config:get-domain($application)
  return fn:data($domain/domain:controller[@model = $model-name]/@name)
};

(:~
 : @param $application - Name of the application
 : @param $domain-name - Name of the domain model
 : @param $extension - If true then returns the extension fields, false returns the raw model
 :)
declare function domain-impl:get-domain-model(
  $application as xs:string,
  $model-names as xs:string+,
  $extension as xs:boolean
) as element(domain:model)+ {
  (:if (fn:count($model-names) eq 1) then:)
    let $cached := domain-impl:get-model-cache($application, $model-names)
    return
      if(fn:exists($cached)) then
        $cached
      else
        let $domain := config:get-domain($application)
        let $model := domain-impl:find-model-by-name($domain, $model-names)
        return domain-impl:set-model-cache($application, $model-names, $model)
  (:else
    domain-impl:find-model-by-name(
      config:get-domain($application),
      $model-names
    ):)
  (:let $domain := config:get-domain($application)
  let $models :=
    for $modelName in $model-names
    let $cached := domain-impl:get-model-cache($application, $modelName)
    return
      if($cached) then $cached
      else
        let $model := domain-impl:find-model-by-name($domain, $modelName)
        let $_ := if($model) then () else fn:error(xs:QName("NO-MODEL"),"Missing Model",$modelName)
        let $_ := fn:exactly-one($model)
        return ($model,domain-impl:set-model-cache($application, $modelName, $model))
  return
    if($models) then
      element domain:domain { $domain/namespace::*, $domain/@*, $domain/domain:name, $domain/*[. except $domain/domain:model], $models } / domain:model
    else
      fn:error(xs:QName("NO-DOMAIN-MODEL"), "Model does not exist",$model-names):)
};

declare %private function domain-impl:find-base-model(
  $field as element()
) as element(domain:model)? {
  let $model :=
    if ($field instance of element(domain:model)) then
      $field
    else
      $field/ancestor::domain:model
  return
    domain-impl:find-model-by-name(
      $model/ancestor::domain:domain,
      if ($model/@compiled and fn:exists($model/@domain:extension)) then
        $model/@domain:extension
      else
        $model/@extends
    )
};

declare %private function domain-impl:find-model-by-name(
  $domain as element(domain:domain),
  $name as xs:string*
) as element(domain:model)* {
  if (fn:empty($name)) then ()
  else $domain/domain:model[
    cts:contains(
      .,
      cts:element-attribute-value-query(
        xs:QName("domain:model"),
        xs:QName("name"),
        $name,
        ("exact")
      )
    )
  ]
};

declare %private function domain-impl:is-ns-override(
  $application as xs:string,
  $domain as element(domain:domain),
  $model as element(domain:model)
) as xs:boolean {
  fn:head((
    $model/@override-ns,
    $domain/@override-ns,
    config:get-application($application)/@override-ns,
    fn:false()
  ))
};

declare function domain-impl:build-model-triples-container(
  $model as element(domain:model)
) as element(domain:container)? {
  if (domain:navigation($model)/@triplable eq 'true') then
    let $container := fn:head((
      $model/domain:container[@name eq 'triples' and @namespace eq 'http://marklogic.com/semantics'],
      element domain:container {attribute namespace { "http://marklogic.com/semantics" }, attribute name {"triples"}}
    ))
    return
      element domain:container {
        $container/namespace::*,
        $container/attribute::*,
        element domain:triple {
          attribute name {$model:HAS-URI-PREDICATE},
          attribute autogenerate {fn:true()},
          element domain:subject {
            attribute type {"sem:iri"},
            "{model:triple-identity-value#3}"
          },
          element domain:predicate {
            attribute type {"sem:iri"},
            $model:HAS-URI-PREDICATE
          },
          element domain:object {
            attribute type {"sem:iri"},
            "{model:node-uri#3}"
          }
        },
        element domain:triple {
          attribute name {$model:HAS-TYPE-PREDICATE},
          attribute autogenerate {fn:true()},
          element domain:subject {
            attribute type {"sem:iri"},
            "{model:triple-identity-value#3}"
          },
          element domain:predicate {
            attribute type {"sem:iri"},
            $model:HAS-TYPE-PREDICATE
          },
          element domain:object {
            attribute type {"sem:iri"},
            fn:string($model/@name)
          }
        },
        $container/node()
      }
  else
    $model/domain:container[@name eq 'triples' and @namespace eq 'http://marklogic.com/semantics']
};

(:~
 : Recursively construct an extended domain model
 : @param $model - Model to return, after optionally merging in extension fields
 :)
declare %private function domain-impl:extend-model(
  $application as xs:string,
  $domain as element(domain:domain),
  $model as element(domain:model)
) as element(domain:model) {
  if($model/@extends) then
    let $base-model-name := fn:string($model/@extends)
    let $override-ns := domain-impl:is-ns-override($application, $domain, $model)
    let $base-model := domain-impl:extend-model($application, $domain, domain-impl:find-base-model($model))
    return
      if(fn:not($base-model)) then
        fn:error(xs:QName("NO-EXTENDS-MODEL"),"Missing Extension Base Model", $base-model-name)
      else
        let $base-model-ns := fn:head( ($base-model/@namespace, $base-model/@namespace-uri) )/fn:string()
        let $base-model-ns := if( $base-model-ns ) then $base-model-ns else domain:get-field-namespace($base-model)
        let $model-ns := fn:head( ($model/@namespace, $model/@namespace-uri, $base-model/@namespace, $base-model/@namespace-uri) )/fn:string()
        let $model-ns := if( $model-ns ) then $model-ns else domain:get-field-namespace($model)
        let $model-attr := (
            (: take all specified model attributes :)
            $model/@*[. except ($model/@namespace, $model/@namespace-uri, $model/@prefix)],
            let $prefix := domain:get-field-prefix($model)
            return
              if (fn:exists($prefix)) then
                attribute prefix {$prefix}
              else
                (),
            (: inherit certain attributes if not specified :)
            $base-model/@*[fn:name(.) = $MODEL-INHERIT-ATTRIBUTES][fn:not(fn:name(.) = $model/@*/fn:name(.))]
        )
        let $model-validators := (
          $base-model/domain:validator,
          $domain/domain:validator
        )
        return element { fn:node-name($model) } {
          $model/namespace::*,
          attribute compiled {fn:true()},
          $model-attr,
          attribute namespace { $model-ns },
          attribute domain:extension { fn:string-join( ($base-model-name, $base-model/@extension), ' ' ) },
          for $field in  $base-model/(domain:element|domain:container|domain:attribute|domain:triple|domain:optionlist)
            let $field-name := domain:get-field-qname( $field )
            let $field-ns :=
              typeswitch ($field)
                case element(domain:attribute)
                  return
                    if (fn:string(fn:namespace-uri-from-QName($field-name)) ne "") then
                      fn:namespace-uri-from-QName($field-name)
                    else
                      ()
                default
                  return
                    if ($override-ns) then
                      ($model-ns, fn:namespace-uri-from-QName($field-name)) [1]
                    else
                      fn:head(($base-model-ns, $model-ns, fn:namespace-uri-from-QName($field-name)))
            let $overlap := $model/(domain:element|domain:container|domain:attribute|domain:triple|domain:optionlist)
                            [fn:node-name(.) eq fn:node-name($field)]
                            [domain:get-field-qname(.) eq $field-name]
            return
              if( $overlap ) then
                 if( fn:data($overlap/@override) or fn:data($model/@override) ) then
                  comment { (if(fn:data($overlap/@override)) then "Field" else "Model")||" @override "||$field-name }
                 else
                  fn:error(xs:QName("EXTENDS-MODEL-OVERLAP"),"Extension Model Overlap requires @override", (text{"model", $model/@name, "base", $base-model-name, "field", $field-name}))
              else
                element { fn:node-name($field) } {
                  (: Copy all attributes except namespace or namespace-uri :)
                  $field/@*[. except ($field/@namespace, $field/@namespace-uri)],
                  (: Create a resolved namespace attribute :)
                  if(fn:exists($field-ns)) then attribute namespace { $field-ns } else (),
                  (: If the base field doesn't have a model definition, add one :)
                  if( fn:not( $field/@domain:model ) ) then
                    attribute domain:model { $base-model-name }
                  else (),
                  (: Now copy field children :)
                  $field/node()
                },
          $model-validators,
          $model/node()
        }
  else $model
};

declare function domain-impl:compile-model(
  $application as xs:string,
  $model as element(domain:model)
) as element(domain:model) {
  let $domain := $model/ancestor::domain:domain
  let $model := domain-impl:build-model-triples(domain-impl:sort-model(domain-impl:extend-model($application, $domain, $model)))
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

declare %private function domain-impl:sort-model(
  $model as element(domain:model)
) as element(domain:model) {
  element { fn:node-name($model) } {
    $model/namespace::*,
    $model/@*[. except $model/@extends],
    for $node in $model/*
      order by $node/@sortValue/fn:number()
      return $node
  }
};

declare %private function domain-impl:build-model-triples(
  $model as element(domain:model)
) as element(domain:model) {
  element { fn:node-name($model) } {
    $model/namespace::*,
    $model/attribute::*,
    $model/node()[. except $model/domain:container[@name eq 'triples' and @namespace eq 'http://marklogic.com/semantics']],
    domain-impl:build-model-triples-container($model)
  }
};

declare function domain-impl:navigation(
  $field as element()
) as element(domain:navigation)? {
  $field/domain:navigation
};

declare function domain-impl:validators(
  $model as element(domain:model)
) as element(domain:validator)* {
  $model/domain:validator
};

declare %private function domain-impl:find-profile(
  $field as element(),
  $id as xs:string?,
  $type as xs:string
) as element(domain:profile)* {
  if (fn:empty($id)) then
    ()
  else
    let $domain := $field/ancestor::domain:domain
    return
      if (fn:empty($domain)) then
        xs:QName("DOMAIN-NOT-FOUND")
      else
      (
        $domain/domain:profiles/domain:profile[@id = fn:tokenize($id, " ") and @type eq $type]
      )
};

(:~
  build navigation attribute from model, profile, abstract or domain are merged in this order
  $field can be field model or field navigation
:)
declare %private function domain-impl:build-navigation-attribute(
  $field as element(),
  $attribute-name as xs:string
) as attribute() {
  let $navigation-field :=
    typeswitch ($field)
      case element(domain:navigation)
        return $field
      default
        return $field/domain:navigation
  let $field :=
    typeswitch ($field)
      case element(domain:navigation)
        return $field/parent::node()
      default
        return $field
  let $base-model := domain-impl:find-base-model($field)
  let $profile := domain-impl:find-profile($field, $navigation-field/@profile, "navigation")
  return
    if ($navigation-field/@*[./fn:local-name() eq $attribute-name]) then
      ($navigation-field/@*[./fn:local-name() eq $attribute-name])
    else if (fn:exists($profile) and $profile/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
      ($profile/domain:navigation/@*[./fn:local-name() eq $attribute-name])[1]
    else if (fn:exists($base-model) and $base-model/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
      $base-model/domain:navigation/@*[./fn:local-name() eq $attribute-name]
    else if ($field/ancestor::domain:element/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
      $field/ancestor::domain:element/domain:navigation/@*[./fn:local-name() eq $attribute-name]
    else if ($field/ancestor::domain:container/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
      $field/ancestor::domain:container/domain:navigation/@*[./fn:local-name() eq $attribute-name]
    else if ($field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
      $field/ancestor::domain:model/domain:navigation/@*[./fn:local-name() eq $attribute-name]
    else if ($field/ancestor::domain:domain/domain:navigation/@*[./fn:local-name() eq $attribute-name]) then
      $field/ancestor::domain:domain/domain:navigation/@*[./fn:local-name() eq $attribute-name]
    else
      attribute {$attribute-name} { fn:false() }
};

(:~
  permission from model, profile, abstract or domain are merged in this order
:)
declare %private function domain-impl:build-permission-attribute(
  $model as element(domain:model),
  $attribute-name as xs:string
) as attribute()? {
  let $base-model := domain-impl:find-base-model($model)
  let $profile := domain-impl:find-profile($model, $model/domain:permission/@profile, "permission")
  return
    if ($model/domain:permission/@*[./fn:local-name() eq $attribute-name]) then
      $model/domain:permission/@*[./fn:local-name() eq $attribute-name]
    else if (fn:exists($profile) and $profile/domain:permission/@*[./fn:local-name() eq $attribute-name]) then
      ($profile/domain:permission/@*[./fn:local-name() eq $attribute-name])[1]
    else if (fn:exists($base-model)) then
      domain-impl:build-permission-attribute($base-model, $attribute-name)
    else if ($model/ancestor::domain:domain/domain:permission/@*[./fn:local-name() eq $attribute-name]) then
      $model/ancestor::domain:domain/domain:permission/@*[./fn:local-name() eq $attribute-name]
    else
      ()
};

(:~
  Build model permission
:)
declare function domain-impl:build-model-permission(
  $model as element(domain:model)
) as element(domain:permission)? {
  element domain:permission {
    $MODEL-PERMISSION-ATTRIBUTES ! (
      let $attribute-name := .
      return domain-impl:build-permission-attribute($model, $attribute-name)
    )
  }
};

(:~
  navigation from model, abstract or domain are merged in this order
:)
declare function domain-impl:build-model-navigation(
  $field as element()
) as element(domain:navigation)* {
  if (fn:exists($field/domain:navigation)) then
    $field/domain:navigation ! (
      let $navigation-field := .
      return
        element domain:navigation {
          $MODEL-NAVIGATION-ATTRIBUTES ! (
            let $attribute-name := .
            return domain-impl:build-navigation-attribute($navigation-field, $attribute-name)
          ),
          $navigation-field/@* [. except $navigation-field/@*[fn:index-of($MODEL-NAVIGATION-ATTRIBUTES, ./fn:local-name()) > 0]],
          (
            let $profile := domain-impl:find-profile($field, $navigation-field/@profile, "navigation")
            return (
              $profile/*/@* [. except $profile/node()/@*[fn:index-of(($MODEL-NAVIGATION-ATTRIBUTES, $navigation-field/@*/fn:local-name()), ./fn:local-name()) > 0]][1],
              $profile/*/*
            )
          ),
          $navigation-field/*
        }
    )
  else
    element domain:navigation {
      $MODEL-NAVIGATION-ATTRIBUTES ! (
        let $attribute-name := .
        return domain-impl:build-navigation-attribute($field, $attribute-name)
      ),
      $field/domain:navigation/@* [. except $field/domain:navigation/@*[fn:index-of($MODEL-NAVIGATION-ATTRIBUTES, ./fn:local-name()) > 0]],
      typeswitch($field)
        case element(domain:model) return
        (
          let $profile := domain-impl:find-profile($field, $field/domain:navigation/@profile, "navigation")
          return (
            ($profile/*/@* [. except $profile/*/@*[fn:index-of(($MODEL-NAVIGATION-ATTRIBUTES, $field/domain:navigation/@*/fn:local-name()), ./fn:local-name()) > 0]])[1],
            $profile/*/*
          )
        )
        default return
        (),
      $field/domain:navigation/*
    }
};

(:~
  Set navigation, permission for all model elements (if not defined will inherit from parent else default is false)
:)
declare function domain-impl:set-model-field-defaults(
  $field as item()
) as item() {
  typeswitch($field)
    case element(domain:model) return
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:element | domain:container | domain:attribute | domain:navigation | domain:permission)],
        domain:build-model-navigation($field),
        domain:build-model-permission($field),
        for $f in  $field/(domain:element | domain:container | domain:attribute)
          return domain-impl:set-model-field-defaults($f)
      }
    case element(domain:container) return
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:container | domain:element | domain:attribute | domain:navigation)],
        domain:build-model-navigation($field),
        for $f in  $field/(domain:container | domain:element | domain:attribute)
          return domain-impl:set-model-field-defaults($f)
      }
    case element(domain:element) return
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:attribute | domain:navigation)],
        domain:build-model-navigation($field),
        for $f in  $field/(domain:attribute)
          return domain-impl:set-model-field-defaults($f)
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

declare function domain-impl:set-model-field-attributes(
  $field as item()
) as item() {
  typeswitch($field)
    case element(domain:model) return
      element { fn:node-name($field) } {
        $field/namespace::*,
        $field/@*,
        $field/*[. except $field/(domain:triple| domain:element | domain:container | domain:attribute)],
        for $f in  $field/(domain:triple | domain:element | domain:container | domain:attribute)
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
    case element(domain:triple) return
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

declare function domain-impl:set-field-attributes(
  $field as element()
) as attribute()* {
  (
    $field/@*[. except
    ($field/@keyId,
     $field/@keyName,
     $field/@prefix,
     $field/@namespace,
     $field/@xpath,
     $field/@absXpath,
     $field/@jsonName,
     $field/@jsonPath)],
    attribute keyId { domain-impl:build-field-id($field) },
    attribute keyName { domain-impl:build-field-name-key($field) },
    (
      let $prefix := domain-impl:get-field-prefix($field)
      return
        if (fn:exists($prefix)) then
          attribute prefix {$prefix}
        else
          ()
    ),
    (
      let $namespace := domain-impl:get-field-namespace($field)
      return
        if (fn:exists($namespace)) then
          attribute namespace {$namespace}
        else
          ()
    ),
    attribute xpath {domain:get-field-xpath($field)},
    attribute absXpath {domain:get-field-absolute-xpath($field)},
    attribute jsonName {domain:get-field-json-name($field)},
    attribute jsonPath {domain:get-field-jsonpath($field)}
    )
};

declare function domain-impl:model-validation-enabled(
  $model as element(domain:model)
) as xs:boolean {
  xs:boolean(
    fn:head((
      $model/@validation,
      $model/ancestor::domain:domain/@validation,
      fn:false()
    ))
  )
};

(:~
 : Returns a list of all defined controllers for a given application domain
 : @param $application - application domain name
 :)
declare function domain-impl:get-controllers(
  $application as xs:string
) as element(domain:controller)* {
  config:get-domain($application)/domain:controller
};

(:~
 : Returns the default application domain defined in the config.xml
 :)
(:declare function domain-impl:get-default-application(
) as xs:string {
  config:default-application()
};:)

(:~
 : Returns the default content namespace for a given application. Convenience wrapper for @see config:default-namespace() function.
 : @param $application - Name of the application
 : @return default content namespace
 :)
declare function domain-impl:get-default-namespace(
  $application as xs:string
) as xs:string {
    let $application := config:get-domain($application)
    return
       $application/domain:content-namespace
};

(:~
 : Returns all content and declare-namespace in application-domain
 : @param $application - Name of the application
 : @return sequence of element(namespace).
 :)
declare function domain-impl:get-domain-namespaces(
  $application as xs:string
)  as element(namespace) {
    let $application := config:get-domain($application)
    for $ns in $application/(domain:content-namespace | domain:declare-namespace)
    return
       <namespace prefix="{$ns/@prefix}" namespace="{$ns/(@namespace|@namespace-uri)}"/>
};

(:~
 : Returns a list of models with a given class attribute from a given application.
 : Function is helpful for selecting a list of all models or selecting them by their @class attribute.
 : @param $application - Name of the application
 : @param $class - the selector class it can be space delimitted
 :)
declare function domain-impl:model-selector(
   $application as xs:string,
   $class as xs:string*
) as element(domain:model)*
{
   let $domain := config:get-domain($application)
   return $domain/domain:model[@class = $class ! fn:tokenize(.,"\s+")]
};

(:~
 : Returns a list of all the fields defined by the selector.
 :)
declare function domain-impl:model-fields(
    $model-name as xs:string
)  as element()*{
  domain:model-fields(config:default-application(),$model-name)
};

(:~
 : Returns the list of fields associated iwth
 :)
declare function domain-impl:model-fields(
   $application as xs:string,
   $model-name as xs:string
) as element()*
{
   let $domain := config:get-domain($application)
   return
       domain:get-model($model-name)//(domain:element|domain:attribute)
};
(:~
 : Returns the unique hash of an element suitable for creating a named element.
 :)
declare function domain-impl:get-field-key(
  $node as node()
) {
   domain:get-field-id($node)
};

(:~
 : Returns the name key path defined. The name key is a simplified notation that concatenates all the names - the modelname with .
 : (ex.  <b>Customer.Address.Line1)</b>.  This is useful for creating ID field in an html form.
 : @param $field - Field in a <b>domain:model</b>
 :)
declare function domain-impl:get-field-name-key(
  $field as node()
) {
  if($field/@keyName) then fn:string($field/@keyName) else
  let $key   := fn:concat("field-name-key::",fn:generate-id($field))
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then
      $cache
    else
      let $value := $field/@keyName/fn:string()
      return domain-impl:set-identity-cache($key,$value)
};

declare %private function domain-impl:build-field-name-key(
  $field as node()
) {
  let $ns := domain-impl:get-field-namespace($field)
  let $path :=
  fn:string-join(
    for $item in domain-impl:get-field-node-ancestors($field)
    (:$items:)
    return  fn:concat($item/@name)
    ,"."
  )
  return $path
};

declare function domain-impl:hash($field as node()) {
(:  xdmp:hash64(xdmp:describe($field, (), ())):)
  fn:generate-id($field)
};

(:~
 :  Returns a unique identity key that can used as a unique identifier for the field.
 :  @param $context - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain-impl:get-field-id($field as node()) {
  if($field/@keyId) then fn:string($field/@keyId) else
  let $key   := fn:concat("field-id::",fn:generate-id($field))
  let $cache := domain-impl:get-identity-cache($key)
  return
       if($cache) then $cache
       else
        let $value := $field/@keyId/fn:string()
        return domain-impl:set-identity-cache($key,$value)
};

declare %private function domain-impl:build-field-id($field as node()) {
  (:let $items := $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-FIELDS]:)
  let $ns := domain-impl:get-field-namespace($field)
  let $path :=
     fn:string-join(
         for $item in domain-impl:get-field-ancestors($field)
         return
             fn:concat("{" , $ns, "}", $item/@name)
         ,"/"
     )
  let $path := fn:concat($field/@name,"__", xdmp:md5($path))
  return $path
};

declare function domain-impl:get-field-ancestors(
  $field as node()
) {
  let $key   := fn:concat("field-ancestors::",fn:generate-id($field))
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then
      $cache
    else
      let $fields := $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-FIELDS]
      return domain-impl:set-identity-cache($key, $fields)
};

declare function domain-impl:get-field-node-ancestors(
  $field as node()
) {
  let $key   := fn:concat("field-node-ancestors::",fn:generate-id($field))
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then
      $cache
    else
      let $fields := $field/ancestor-or-self::*[fn:node-name(.) = $DOMAIN-NODE-FIELDS]
      return domain-impl:set-identity-cache($key, $fields)
};

(:~
 :  Gets the namespace of the field. Namespace resolution is inherited if not specified by the field in the following order:
 :  field-> model-> domain-impl:content-namespace
 :  @param $field - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain-impl:get-field-namespace(
  $field as element()
) as xs:string? {
  if($field/@namespace) then
    fn:string($field/@namespace)
  else if ($field instance of element(domain:attribute)) then
    ()
  else
    let $key   := fn:concat("field-namespace::",fn:generate-id($field))
    let $cache := domain-impl:get-identity-cache($key)
    return
    if($cache) then
      $cache
    else
      let $field-namespace := (
        if ($field instance of element(domain:attribute)) then
          (
            if($field/(@namespace-uri|@namespace)) then
              $field/(@namespace-uri|@namespace)/fn:string()
            else
              ()
          )
        else

          if($field/(@namespace-uri|@namespace)) then
            $field/(@namespace-uri|@namespace)/fn:string()
          else if($field/ancestor::domain:model/(@namespace-uri|@namespace)) then
            $field/ancestor::domain:model/(@namespace-uri|@namespace)/fn:string()
          else if($field/ancestor::domain:domain/domain:content-namespace/(@namespace-uri|text())) then
            $field/ancestor::domain:domain/domain:content-namespace/(@namespace-uri|/text())
          (:else (domain-impl:get-content-namespace-uri(),""):)
          else if (domain-impl:get-content-namespace-uri()) then
            domain-impl:get-content-namespace-uri()
          else
            (
              config:application-namespace(config:default-application()),
              ""
            )

      )[1]
      return domain-impl:set-identity-cache($key,$field-namespace)
};

(:~
 : Retrieves the value of a field based on a parameter key
 : @param $field - The field definition representing the value to return
 : @param $params - A map:map representing the field parameters
:)
declare function domain-impl:get-field-param-value(
  $field as element(),
  $params as map:map,
  $relative as xs:boolean,
  $cast as xs:boolean
) {
  let $key := domain:get-field-id($field)
  let $namekey := domain:get-field-name-key($field)
  let $key-value :=
    if (fn:exists($key)) then
      map:get($params,$key)
    else
      ()
  let $namekey-value :=
    if (fn:exists($namekey)) then
      map:get($params,$namekey)
    else
      ()
  let $name-value :=
    if (fn:exists($field/@name)) then
      map:get($params,$field/@name)
    else
      ()
  return
    if ($cast) then
      if($field/@type eq "langString") then
        domain:get-field-param-langString-value($field,$params)
      else
        domain-impl:cast-value(
          $field,
          if(fn:exists($key-value)) then $key-value
          else if(fn:exists($namekey-value)) then $namekey-value else $name-value
        )
    else
      if(fn:exists($key-value)) then $key-value
      else if(fn:exists($namekey-value)) then $namekey-value else $name-value
};

declare function domain-impl:get-field-param-match-key(
  $field as element(),
  $params as map:map
) {
  if(map:contains($params,domain-impl:get-field-name-key($field)))
  then "name-key"
  else if(map:contains($params,domain-impl:get-field-id($field))) then "id"
  else if(map:contains($params,$field/@name)) then "name"
  else () (:No data match key:)
};

declare function domain-impl:get-field-param-langString-value(
  $field as element(),
  $params as map:map
) as rdf:langString? {
  let $matched-key :=
    if(map:contains($params,domain-impl:get-field-name-key($field)))
    then domain-impl:get-field-name-key($field)
    else if(map:contains($params,domain-impl:get-field-id($field))) then domain-impl:get-field-id($field)
    else if(map:contains($params,$field/@name)) then fn:data($field/@name)
    else () (:No data match key:)
  let $lang-value :=
    (map:get($params,fn:concat($matched-key,"@lang")),domain-impl:get-default-language($field))[1]
  return
    if($matched-key) then rdf:langString(map:get($params,$matched-key),$lang-value)
    else ()
};

declare function domain-impl:get-field-param-triple-value(
  $field as element(),
  $params as map:map
) as element(sem:triple)? {
  let $matched-key :=
    if(map:contains($params, domain-impl:get-field-name-key($field)))
    then domain-impl:get-field-name-key($field)
    else if(map:contains($params, domain-impl:get-field-id($field))) then domain-impl:get-field-id($field)
    else if(map:contains($params, $field/@name)) then fn:data($field/@name)
    else () (:No data match key:)
  let $triple-value := map:get($params, $matched-key)
  return
    if ($triple-value instance of map:map) then
      element sem:triple {
        let $attributes := map:get($triple-value, config:attribute-prefix())
        return
          if ($attributes instance of map:map) then
            map:keys($attributes) ! (
              attribute {.} {map:get($attributes, .)}
            )
          else
            ()
        ,
        element sem:subject {
          map:get($triple-value, "subject")
        },
        element sem:predicate {
          map:get($triple-value, "predicate")
        },
        element sem:object {
          map:get($triple-value, "object")
        }
      }
    else if (fn:count($triple-value) eq 3) then
      <x>{
        xdmp:with-namespaces(
          domain:declared-namespaces($field),
          sem:triple($triple-value[1], $triple-value[2], $triple-value[3])
        )
      }</x>/*
    else
      ()
};

(:~
 : Returns the reference value from a given field from the current context node.
 : @param $field - the model definition
 : @param $current-node - is the instance of the current element to extract the value from
 :)
declare function domain-impl:get-field-reference(
  $field as element(),
  $current-node as node()
) {
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
declare function domain-impl:get-field-reference-model(
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
declare function domain-impl:get-field-xpath(
  $field as element(),
  $relative as xs:boolean
) {
  let $xpath :=
    if($field/@xpath) then fn:string($field/@xpath) else
    let $namespaces := domain:declared-namespaces-map($field)
    return
        fn:string-join(
          (
            for $path in domain-impl:get-field-node-ancestors($field)
            return typeswitch($path)
              case element(domain:attribute)
                return fn:concat("/@",$path/@name)
              default
                return fn:concat("/",domain-impl:get-field-prefix($path),":",$path/@name)
            ,
            if ($field/@type eq "query") then
              "/element()"
            else
              ()
          ),
          ""
        )
  return
    if (fn:not($relative)) then
      $xpath
    else
      (
        let $rel-xpath := fn:concat("/", fn:tokenize($xpath, "/")[fn:last()])
        return $rel-xpath
      )
};

(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $field - instance of a field
 :)
declare function domain-impl:get-field-absolute-xpath(
  $field as element()
) {
  if($field/@absXpath) then
    $field/@absXpath
  else
    fn:string-join(
    for $path in domain-impl:get-field-ancestors($field)
    return
     typeswitch($path)
      case element(domain:attribute) return fn:concat("/@",$path/@name)
      default return  fn:concat("/",domain-impl:get-field-prefix($path),":",$path/@name)
    ,"")
};

declare function domain-impl:get-field-qname(
  $field as element()
) {
 typeswitch($field)
   case element(domain:model)       return fn:QName(domain-impl:get-field-namespace($field),$field/@name)
   case element(domain:element)     return fn:QName(domain-impl:get-field-namespace($field),$field/@name)
   case element(domain:attribute)   return fn:QName(domain-impl:get-field-namespace($field),$field/@name)
   case element(domain:container)   return fn:QName(domain-impl:get-field-namespace($field),$field/@name)
   case element(domain:triple)      return xs:QName("sem:triple")
   default return fn:error(xs:QName("QNAME-ERROR"),"Cannot create qname from field",fn:local-name($field))
};

(:~
 : Constructs a map of a domain instance based on a list of retain node names
 : @param $doc - context node instance
 : @param $retain  - a list of nodes to retain from original context
 :)
declare function domain-impl:build-value-map(
  $doc as node()?,
  $retain as xs:string*
) as map:map? {
  let $map := map:map()
  let $results :=  domain-impl:recurse($doc,$map,$retain)
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
declare private function domain-impl:recurse(
  $node as node()?,
  $map as map:map,
  $retain as xs:string*
) {
  let $key := domain-impl:get-field-id($node)
  let $_ :=
    typeswitch ($node)
    case document-node() return domain-impl:recurse($node/node(),$map,$retain)
    case text() return
        if(fn:string-length($node) > 0) then
            let $key := domain-impl:get-field-id($node/..)
            return map:put($map, $key, (map:get($map,$key), $node))
        else ()
    case element() return
         if($node/(element()|attribute()) and fn:not(fn:local-name($node) = $retain))
         then
           for $n in $node/(element()|attribute()| text())
           return domain-impl:recurse($n,$map,$retain)
         else
           let $value := $node/node()
           return map:put($map, $key,(map:get($map,$key),$value))
    case attribute() return
      map:put($map, $key,(map:get($map,$key),fn:data($node)))
    default return ()
 return $map
};

(:@deprecated:)
declare function domain-impl:get-model-by-xpath(
  $path as xs:string
) as xs:string? {
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
     ,
     "/"
    )
  let $xpath := if ($subpath) then fn:concat( "/", $subpath) else ()
  let $key :=
    if($xpath) then
      let $stmt := fn:string(<stmt>$domain{$xpath}</stmt>)
      let $domain-node :=  xdmp:value($stmt)
      return domain-impl:get-field-id($domain-node)
    else ()
  return $key
};

(:~
 : Returns a controller based on the model name
 : @param $model-name  - name of the model
 :)
declare function domain-impl:get-model-controller(
  $model-name as xs:string
) as element(domain:controller)* {
  domain-impl:get-model-controller(config:default-application(), $model-name)
};

declare function domain-impl:get-model-controller(
  $application as  xs:string,
  $model-name as xs:string
) as element(domain:controller)* {
  domain-impl:get-model-controller($application, $model-name, fn:false())
};

(:~
 : Returns a controller based on the model name
 : @param $application - name of the application
 : @param $model-name  - name of the model
 :)
declare function domain-impl:get-model-controller(
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
declare function domain-impl:get-optionlist(
  $name as xs:string
) {
  domain-impl:get-optionlist(domain:get-default-application(),$name)
};

(:~
 :  Returns an optionlist from the application by its name
 : @param $application  Name of the application
 : @param $listname  Name of the optionlist
 :)
declare function domain-impl:get-optionlist(
  $application as xs:string,
  $listname as xs:string
) {
  config:get-domain($application)/domain:optionlist[@name eq $listname]
};

(:~
 : Returns an optionlist associated with a field definitions inList attribute.
 : @param $field  Field instance (domain:element|domain:attribute)
 : @return optionlist specified by field.
 :)
declare function domain-impl:get-field-optionlist(
  $field
) {
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
declare function domain-impl:get-application(
  $application as xs:string
) {
  config:get-application($application)
};

(:~
 : Returns the key that represents the given model
 : the key format is model:{model-name}:reference
 : @param $domain-model - The instance of the domain model
 : @return The reference-key defining the model
 :)
declare function domain-impl:get-model-reference-key(
  $model as element(domain:model)
) {
  fn:concat("model:",$model/@name,":reference")
};

(:~
 : Gets a list of domain models that reference a given model.
 : @param $domain-model - The domain model instance.
 : @return a sequence of domain:model elements
 :)
declare function domain-impl:get-model-references(
  $domain-model as element(domain:model)
) {
  let $domain := config:get-domain($domain-model/ancestor::domain:domain/domain:name[1])
  let $reference-key := domain-impl:get-model-reference-key($domain-model)
  let $reference-models :=
    $domain/domain:model[
      cts:contains(.,
        cts:element-attribute-value-query(
          xs:QName("domain:element"),
          xs:QName("reference"),
          $reference-key)
      )
    ]
  return $reference-models
};

declare function domain-impl:get-models-reference-query(
  $domain-model as element(domain:model),
  $instance as item()
) as cts:or-query {
  let $reference-key    := domain-impl:get-model-reference-key($domain-model)
  let $reference-models := domain-impl:get-model-references($domain-model)
  let $reference-values := (
    domain:get-field-value(domain-impl:get-model-key-field($domain-model),$instance),
    domain:get-field-value(domain-impl:get-model-keyLabel-field($domain-model),$instance)
  )
  return
    cts:or-query((
      for $reference-model in $reference-models
      let $reference-fields := $reference-model//domain:element[@reference = $reference-key]
      return
        domain-impl:get-model-reference-query($reference-model,$reference-key,$reference-values)
    ))
};

(:~
 : Returns true if a model is referenced by its identity
 : @param $domain-model - The model to determine the reference
 : @param $instance -
 :)
declare function domain-impl:is-model-referenced(
  $domain-model as element(domain:model),
  $instance as element()
) as xs:boolean {
     (:let $reference-key    := domain-impl:get-model-reference-key($domain-model)
     let $reference-models := domain-impl:get-model-references($domain-model)
     let $reference-values := (
        domain:get-field-value(domain-impl:get-model-key-field($domain-model),$instance),
        domain:get-field-value(domain-impl:get-model-keyLabel-field($domain-model),$instance)
     )
     let $reference-query :=
       cts:or-query((
        for $reference-model in $reference-models
        let $reference-fields := $reference-model//domain:element[@reference = $reference-key]
        return
          domain-impl:get-model-reference-query($reference-model,$reference-key,$reference-values)
       )):)
  let $reference-query := domain-impl:get-models-reference-query($domain-model, $instance)
  return xdmp:exists(cts:search(fn:collection(),$reference-query))
};

(:~
 : Returns true if a model is referenced by its identity
 : @param $domain-model - The model which is the base of the instance reference
 : @instance - The instance for a given model
 :)
declare function domain-impl:get-model-reference-uris(
  $domain-model as element(domain:model),
  $instance as element()
) {
     (:let $reference-key    := domain-impl:get-model-reference-key($domain-model)
     let $reference-models := domain-impl:get-model-references($domain-model)
     let $reference-values := (
        domain:get-field-value(domain-impl:get-model-key-field($domain-model),$instance),
        domain:get-field-value(domain-impl:get-model-keyLabel-field($domain-model),$instance)
     )
     let $reference-query :=
       cts:or-query((
        for $reference-model in $reference-models
        let $reference-fields := $reference-model//domain:element[@reference = $reference-key]
        return
          domain-impl:get-model-reference-query($reference-model,$reference-key,$reference-values)
       )):)
  let $reference-query := domain-impl:get-models-reference-query($domain-model, $instance)
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
declare function domain-impl:get-model-reference-query(
  $reference-model as element(domain:model),
  $reference-key as xs:string,
  $reference-value as xs:anyAtomicType*
) as cts:and-query? {
  let $referenced-fields := $reference-model//domain:element[@type = "reference" and @reference = $reference-key]
  let $base-constraint := domain:get-base-query($reference-model)
  return
    if (fn:exists($base-constraint)) then
      cts:and-query((
        $base-constraint,
        for $reference-field in $referenced-fields
        let $field-ns := domain-impl:get-field-namespace($reference-field)
        let $field-name := fn:data($reference-field/@name)
        return
          cts:or-query((
            cts:element-attribute-value-query(fn:QName($field-ns,$field-name),xs:QName("ref-id"),$reference-value)
          ))
      ))
    else
      ()
 };

(:~
 : Returns the default collation for the given field. The function walks up the ancestor tree to find the collation in the following order:
 : $field/@collation->$field/model/@collation->$domain/domain:default-collation.
 : @param $field - the field to find the collation by.
 :)
declare function domain-impl:get-field-collation(
  $field as element()
) as xs:string {
  if($field/@collation) then $field/@collation
  else if($field/ancestor::domain:model/@collation) then $field/ancestor::domain:model/@collation
  else if($field/ancestor::domain:domain/domain:default-collation) then $field/ancestor::domain:domain/domain:default-collation
  else fn:error(xs:QName("COLLATION-ERROR"), "No collation defined for domain")
};

(:~
 : Returns the list of fields that are part of the uniqueKey constraint as defined by the $model/@uniqueKey attribute.
 : @param $model - Model that defines the unique constraint.
 :)
declare function domain-impl:get-model-uniqueKey-constraint-fields(
  $model as element(domain:model)
) {
  if($model/@uniqueKey and $model/@uniqueKey ne "") then
    let $fields := fn:tokenize($model/@uniqueKey," ") ! fn:normalize-space(.)
    for $f in $fields
    let $field := $model//(domain:element|domain:attribute)[@name = $f]
    return
      if($field) then
        $field
      else
        fn:error(xs:QName("UNIQUEKEY-FIELD-MISSING"),"The key in a uniqueKey constraint is missing",$f)
  else ()
};

(:~
 : Returns a unique constraint query
 :)
declare function domain-impl:get-model-uniqueKey-constraint-query(
  $model as element(domain:model),
  $params as item(),
  $mode as xs:string
) {
  if(domain-impl:get-model-uniqueKey-constraint-fields($model)) then
   (: It should not include id field value in the query :)
       (:let $id-field := domain-impl:get-model-identity-field($model)
       let $id-field-key := domain-impl:get-field-id($id-field)
       let $id-value := domain:get-field-value($id-field,$params)
       let $id-query :=
          if($mode = ("create","new")) then
               if($id-value) then
                 typeswitch($id-field)
                   case element(domain:element) return
                        cts:element-range-query(fn:QName(domain-impl:get-field-namespace($id-field),$id-field/@name),"=",$id-value,("collation=" || domain-impl:get-field-collation($id-field)))
                   case element(domain:attribute) return
                        cts:element-attribute-range-query(fn:QName(domain-impl:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"=",$id-value,("collation=" || domain-impl:get-field-collation($id-field)))
                   default return ()
                else ()
            else
             typeswitch($id-field)
                  case element(domain:element) return
                    cts:element-range-query(fn:QName(domain-impl:get-field-namespace($id-field),$id-field/@name),"!=",$id-value,("collation="  || domain-impl:get-field-collation($id-field)))
                  case element(domain:attribute) return
                       cts:element-attribute-range-query(fn:QName(domain-impl:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"!=",$id-value,("collation=" || domain-impl:get-field-collation($id-field)))
                  default return ():)
    let $id-query := ()
    let $unique-fields := domain-impl:get-model-uniqueKey-constraint-fields($model)
    let $constraint-query :=
      for $field in $unique-fields
      (:let $field-value := domain:get-field-param-value($field,$params):)
      let $field-value := domain:get-field-value($field,$params)
      let $field-ns := domain-impl:get-field-namespace($field)
      return
        typeswitch($field)
          case element(domain:attribute) return
            let $parent := domain-impl:get-parent-field-attribute($field)
            let $parent-ns := domain-impl:get-field-namespace($parent)
            return cts:element-attribute-value-query(fn:QName($parent-ns,$parent/@name),xs:QName($field/@name),$field-value)
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
    let $search-expression := domain-impl:get-model-search-expression($model,cts:and-query(($id-query,$constraint-query)))
    return xdmp:eval($search-expression)
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
declare function domain-impl:get-model-unique-constraint-query(
  $model as element(domain:model),
  $params as item(),
  $mode as xs:string
) {
  let $unique-fields := domain-impl:get-model-unique-constraint-fields($model)
  return
  if(fn:exists($unique-fields)) then
    (:let $id-field := domain-impl:get-model-identity-field($model)
    let $id-field-key := domain-impl:get-field-id($id-field)
    let $id-value := domain:get-field-value($id-field,$params)
    let $id-query :=
      if($mode = "create") then
        if($id-value) then
          typeswitch($id-field)
            case element(domain:element) return
              cts:element-range-query(fn:QName(domain-impl:get-field-namespace($id-field),$id-field/@name),"=",$id-value,("collation=" || domain-impl:get-field-collation($id-field)))
            case element(domain:attribute) return
              cts:element-attribute-range-query(fn:QName(domain-impl:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"=",$id-value,("collation=" || domain-impl:get-field-collation($id-field)))
            default return ()
        else ()
      else if($id-value) then
        typeswitch($id-field)
          case element(domain:element) return
            cts:element-range-query(fn:QName(domain-impl:get-field-namespace($id-field),$id-field/@name),"!=",$id-value,("collation=" || domain-impl:get-field-collation($id-field)))
          case element(domain:attribute) return
            cts:element-attribute-range-query(fn:QName(domain-impl:get-field-namespace($model),$model/@name),xs:QName($id-field/@name),"!=",$id-value,("collation=" || domain-impl:get-field-collation($id-field)))
          default return ()
      else ():)
    let $id-query := ()
    let $constraint-query :=
      for $field in $unique-fields
      let $field-value := domain:get-field-value($field,$params)
      let $field-ns := domain-impl:get-field-namespace($field)
      return
        typeswitch($field)
          case element(domain:attribute) return
            let $parent := domain-impl:get-parent-field-attribute($field)
            let $parent-ns := domain-impl:get-field-namespace($parent)
            return
              cts:element-attribute-value-query(fn:QName($parent-ns,$parent/@name),xs:QName($field/@name),$field-value)
          case element(domain:element) return
            switch($field/@type)
              case "reference" return
                cts:element-attribute-value-query(fn:QName($field-ns,$field/@name),xs:QName("ref-id"),$field-value)
              default return
                cts:element-value-query(fn:QName($field-ns,$field/@name),$field-value)
          default return ()
    let $search-expression := domain-impl:get-model-search-expression($model,cts:and-query(($id-query,cts:or-query($constraint-query))))
    return xdmp:eval($search-expression)
  else ()
};

(:~
 : Constructs a search expression based on a give model
 :)
declare function domain-impl:get-model-search-expression(
  $domain-model as element(domain:model),
  $query as cts:query?
) {
  domain-impl:get-model-search-expression($domain-model,$query,())
};

(:~
 : Constructs a search expression based on a givem model
 :)
declare function domain-impl:get-model-search-expression(
  $domain-model as element(domain:model),
  $query as cts:query?,
  $options as xs:string*
) {
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
  let $nsExpr := "declare namespace ns0 = '" || domain-impl:get-field-namespace($domain-model) || "'; "
  let $expr :=  $nsExpr || $searchExpr
  return $expr
};

(:~
 : Returns a cts query that returns a cts:query which matches a node against its value.
:)
declare function domain-impl:get-identity-query(
  $model as element(domain:model),
  $params as item()
) {
  let $identity-field := domain-impl:get-model-identity-field($model)
  return
    typeswitch($identity-field)
      case element(domain:attribute) return
        cts:element-attribute-range-query(
          domain-impl:get-field-qname($identity-field/..),
          domain-impl:get-field-qname($identity-field),
          "=",
          domain:get-field-value($identity-field, $params),
          ("collation="  || domain-impl:get-field-collation($identity-field))
        )
      case element(domain:element) return
        cts:element-range-query(
          domain-impl:get-field-qname($identity-field),
          "=",
          domain:get-field-value($identity-field, $params),
          ("collation="  || domain-impl:get-field-collation($identity-field))
        )
      default return fn:error(xs:QName("PERSISTENCE-QUERY-ERROR"),"Identity Error")
};

declare function domain-impl:get-keylabel-query(
  $model as element(domain:model),
  $params as item()
) {
  let $key-field := domain-impl:get-model-keyLabel-field($model)
  return
    typeswitch($key-field)
      case element(domain:attribute) return
        cts:element-attribute-range-query(
          domain-impl:get-field-qname($key-field/..),
          domain-impl:get-field-qname($key-field),
          "=",(
          domain:get-field-value($key-field, $params)
          ),
          ("collation="  || domain-impl:get-field-collation($key-field))
        )
      case element(domain:element) return
        cts:element-range-query(
          domain-impl:get-field-qname($key-field),
          "=",
          domain:get-field-value($key-field, $params),
          ("collation="  || domain-impl:get-field-collation($key-field))
        )
      default return fn:error(xs:QName("PERSISTENCE-QUERY-ERROR"),"KeyLabel Error")
};

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
        xdmp:plan(/*[fn:node-name(.)  eq domain-impl:get-field-qname($model)])//*:key ! cts:term-query(.)
      ))
    case "document"
      return cts:document-query($model/domain:document)
    case "singleton"
      return cts:document-query($model/domain:document)
    case "abstract"
      return  ()
    default return fn:error(xs:QName("BASE-QUERY-ERROR"),"Cannot determine base query on model",$model/@name)
};

(:~
 : Constructs a xdmp:estimate expresion for a referenced model
 : @param $domain-model - model definition
 : $query - Additional query to add the estimate expression
 : $options - cts:search options
 :)
declare function domain-impl:get-model-estimate-expression(
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
  let $nsExpr := "declare namespace ns0 = '" || domain-impl:get-field-namespace($domain-model) || "'; "
  let $expr :=  $nsExpr || $searchExpr
  return $expr
};

(:~
 : Creates a root term query that can be used in combination to specify the root.
:)
declare function domain-impl:model-root-query(
  $model as element(domain:model)
) {
  let $name := $model/@name
  let $ns := domain-impl:get-field-namespace($model)
  let $prefix := domain-impl:get-field-prefix($model)
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
declare function domain-impl:get-field-query(
  $field as element(),
  $value as xs:anyAtomicType*
) {
  let $name := $field/@name
  let $ns := domain-impl:get-field-namespace($field)
  let $index := $field/domain:navigation/@searchType
  return typeswitch($field)
    case element(domain:element) return
      if($index = "range") then
        cts:element-range-query(fn:QName($ns,$name),"=",$value)
      else
        cts:element-value-query(fn:QName($ns,$name), $value)
    case element(domain:attribute) return
      let $parent := $field/..
      let $parent-ns := domain-impl:get-field-namespace($parent)
      let $parent-name := $parent/@name
      return
        if($index = "range") then
          cts:element-attribute-range-query(fn:QName($parent-ns,$parent-name),fn:QName("",$name),"=",$value)
        else
          cts:element-attribute-value-query(fn:QName($parent-ns,$parent-name),fn:QName($ns,$name), $value)
      default return
        fn:error(xs:QName("FIELD-QUERY-ERROR"), "Unable to resolve query for",$field/@name)
};

declare function domain-impl:get-field-tuple-reference(
  $field as element()
) {
  domain-impl:get-field-tuple-reference($field,())
};

(:~
 : Returns a field reference to be used in xxx-value-calls
 :)
declare function domain-impl:get-field-tuple-reference(
  $field as element(),
  $add-options as xs:string*
) {
  let $options := (
    if($field/@type = ("string","reference","identity","id"))
    then "collation=" || domain-impl:get-field-collation($field)
    else if($field/@type = ("integer","decimal","double","float","long","unsignedLong","unsignedInt","int"))
    then "type=" || $field/@type
    else ()
  )
  return typeswitch($field)
    case element(domain:element) return
      cts:element-reference(domain-impl:get-field-qname($field),($options,$add-options))
    case element(domain:attribute) return
      cts:element-attribute-reference(domain-impl:get-field-qname($field),($options,$add-options))
    default return fn:error(xs:QName("NOT-REFERENCABLE"),"Cannot reference type of " || fn:local-name($field),$field)
};

(:~
 : Return as list of all prefixes and their respective namespaces
:)
declare function domain-impl:declared-namespaces(
  $model as element()
) as xs:string* {
  let $key   := fn:concat("declared-namespaces::",fn:generate-id($model))
  let $cache := domain-impl:get-identity-cache($key)
  return
    if($cache) then $cache
    else
    let $value := (
      $model/ancestor::domain:domain/domain:content-namespace ! (./@prefix, ./(@namespace|@namespace-uri)[1]),
      $model/ancestor::domain:domain/domain:declare-namespace ! (./@prefix, ./(@namespace|@namespace-uri)[1]),
      fn:in-scope-prefixes($model)[. ne ""] ! (., fn:namespace-uri-for-prefix(., $model))
    )
    return domain-impl:set-identity-cache($key,$value)
};

declare function domain-impl:declared-namespaces-map(
  $model as element()
) {
  let $nses := domain:declared-namespaces($model)
  let $map := map:map()
  let $_ := (
    $model/../domain:content-namespace ! map:put($map,./@prefix,./(@namespace|@namespace-uri)[1]),
    $model/../domain:declare-namespace ! map:put($map,./@prefix,./(@namespace|@namespace-uri)[1])
  )
  return $map
};

declare function domain-impl:invoke-events(
  $model as element(domain:model),
  $events as element()*,
  $updated-values as item()*
) {
  domain-impl:invoke-events($model, $events, $updated-values, ())
};

declare function domain-impl:invoke-events(
  $model as element(domain:model),
  $events as element()*,
  $updated-values as item()*,
  $old-value as item()*
) {
  if(fn:exists($events)) then
    let $event := fn:head($events)
    let $module-namespace := fn:string($event/@module-namespace)
    let $module-uri := fn:string($event/@module-uri)
    let $function-name := fn:string($event/@function)
    let $function := domain:get-module-function((), "event", $module-namespace, $module-uri, $function-name, 3)
    let $updated-values :=
      if (fn:exists($function)) then
        xdmp:apply($function, $event, $updated-values, $old-value)
      else
        let $function := domain:get-module-function((), "event", $module-namespace, $module-uri, $function-name, 2)
        return xdmp:apply($function, $event, $updated-values)
    (:let $updated-values := xdmp:apply($call, $event, $updated-values):)
    return domain-impl:invoke-events($model, fn:tail($events), $updated-values, $old-value)
  else $updated-values
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
declare function domain-impl:fire-before-event(
  $model as element(domain:model),
  $event-name as xs:string,
  $updated-values as item()*
) {
  domain-impl:fire-before-event($model, $event-name, $updated-values, ())
};

declare function domain-impl:fire-before-event(
  $model as element(domain:model),
  $event-name as xs:string,
  $updated-values as item()*,
  $old-value as item()*
) {
  let $events := $model/domain:event[@name = $event-name and @mode = ("before","wrap")]
  return domain-impl:invoke-events($model, $events, $updated-values, $old-value)
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
declare function domain-impl:fire-after-event(
  $model as element(domain:model),
  $event-name as xs:string,
  $updated-values as item()*
) {
  domain-impl:fire-after-event($model, $event-name, $updated-values, ())
};

declare function domain-impl:fire-after-event(
  $model as element(domain:model),
  $event-name as xs:string,
  $updated-values as item()*,
  $old-value as item()*
) {
  let $events := $model/domain:event[@name = $event-name and @mode = ("after","wrap")]
  return domain-impl:invoke-events($model, $events, $updated-values, $old-value)
};

declare function domain-impl:get-field-json-name(
  $field as element()
) as xs:string {
  if($field/@jsonName) then
    fn:string($field/@jsonName)
  else
    let $get-field-json-name-fn := domain:get-model-extension-function("get-field-json-name", 1)
    let $json-name :=
      if (fn:exists($get-field-json-name-fn)) then
        xdmp:apply($get-field-json-name-fn, $field)
      else
        ()
    return
      if (fn:exists($json-name)) then
        $json-name
      else
        let $name := fn:string($field/@name)
        return
          typeswitch($field)
            case element(domain:attribute)
              return fn:concat(config:attribute-prefix(), $name)
            default
              return $name
};

(:~
 : Gets the json path for a given field definition. The path expression by default is relative to the root of the json type
:)
(:declare function domain-impl:get-field-jsonpath(
  $field as element()
) {
  domain-impl:get-field-jsonpath($field,fn:false(),())
};:)

(:declare function domain-impl:get-field-jsonpath(
  $field as element(),
  $include-root as xs:boolean
) {
  domain-impl:get-field-jsonpath($field,$include-root,())
};:)

(:~
 : Returns the path of field instance from a json object.
 : @param $field - Definition of the field instance (domain:element|domain:attribute|domain:container)
 : @param $include-root - if the root json:object should be returned in path expression
 : @param $base-path - when using nested recursive json structures the base-path to include additional path construct
 :)
declare function domain-impl:get-field-jsonpath(
  $field as element(),
  $include-root as xs:boolean,
  $base-path as xs:string?
) {
  if($field/@jsonPath) then fn:string($field/@jsonPath) else
  (:let $paths := $field/ancestor-or-self::element()[fn:node-name(.) = $DOMAIN-FIELDS]:)
  (:return:)
    fn:string-join((
      $base-path,
      for $path at $pos in domain-impl:get-field-ancestors($field)
      (:$paths:)
      let $json-name := domain-impl:get-field-json-name($field)
      let $key :=
        typeswitch($path)
          case element(domain:attribute)
            return fn:concat(config:attribute-prefix(),fn:data($path/@name))
          default
            return fn:data($path/@name)
      return
        let $is-multi := ("+","*") = $path/@occurrence
        let $base-type := domain:get-base-type($path)
        return
          switch($base-type)
            case "instance" return
              if($is-multi)
              then fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value/json:array/json:value/json:object")
              else fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value/json:object")
            case ("simple") return
              if($is-multi)
              then fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value/json:array/json:value")
              else fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value")
            case ("complex") return
              if($is-multi)
              then fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value/json:array/json:value")
              else fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value")
            case "model" return
              if($include-root) then "/json:object"
              else ""
            case "container" return
              fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value/json:object")
            case "triple" return
              fn:concat("json:entry[@key = ('",$key,"','",$json-name,"')]/json:value/json:object")
            default return fn:error(xs:QName("JSON-PATH-ERROR"),"Unknown Path Type",$base-type)
   ) ,"/")
};

(:~
 : Gets the value from an object type
:)
declare function domain-impl:get-field-value(
  $field as element(),
  $value as item()*,
  $relative as xs:boolean
) as item()* {
  if ($field instance of element(domain:model)) then
    ()
  else
    let $return-value := domain:get-field-value-node($field, $value, $relative)
    return
    domain-impl:cast-value(
      $field,
      if (fn:exists($return-value)) then
        $return-value
      else
        ()
    )
};

(:~
 : Gets the node from an object type
:)
declare function domain-impl:get-field-value-node(
  $field as element(),
  $value as item()*,
  $relative as xs:boolean
) as item()* {
  typeswitch($value)
    case json:object          return domain:get-field-json-value($field,$value,$relative)
    case json:array           return domain:get-field-json-value($field,$value,$relative)
    case element(json:object) return domain:get-field-json-value($field,$value,$relative)
    case element(json:array)  return domain:get-field-json-value($field,$value,$relative)
    case element(map:map)     return domain:get-field-param-value($field,map:map($value),$relative,fn:false())
    case map:map              return domain:get-field-param-value($field,$value,$relative,fn:false())
    case element()            return domain:get-field-xml-value($field,$value,$relative)
    case document-node()      return domain:get-field-xml-value($field,$value/element(),$relative)
    case empty-sequence() return ()
    default return $value
};

declare function domain-impl:field-value-exists(
  $field as element(),
  $value as item()*
) as xs:boolean {
  typeswitch($value)
    case json:object          return domain-impl:field-json-exists($field,$value)
    case json:array           return domain-impl:field-json-exists($field,$value)
    case element(json:object) return domain-impl:field-json-exists($field,$value)
    case element(json:array)  return domain-impl:field-json-exists($field,$value)
    case element(map:map)     return domain-impl:field-param-exists($field,map:map($value))
    case map:map              return domain-impl:field-param-exists($field,$value)
    case element()            return domain-impl:field-xml-exists($field,$value)
    case document-node()      return domain-impl:field-xml-exists($field,$value/element())
    case empty-sequence()     return fn:false()
    default return fn:false()
};

declare function domain-impl:field-param-exists(
  $field as element(),
  $params as map:map
) as xs:boolean {
  let $key := domain-impl:get-field-id($field)
  let $namekey := domain-impl:get-field-name-key($field)
  let $key-value := map:get($params,$key)
  let $namekey-value := map:get($params,$namekey)
  let $name-value := map:get($params,$field/@name)
  return (fn:exists($key-value) or fn:exists($namekey-value) or fn:exists($name-value))
};

declare function domain-impl:field-json-exists(
  $field as element(),
  $values as item()?
) as xs:boolean {
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
    if(domain-impl:exists-field-function-cache($field,"json-exists"))
    then domain-impl:get-field-function-cache($field,"json-exists")($value)
    else
      let $type := domain:get-base-type($field)
      let $path := domain:get-field-jsonpath($field)
      let $path :=
        if (domain-impl:field-is-multivalue($field)) then
          if ($type eq "instance") then
            fn:substring($path, 1, fn:string-length($path) - fn:string-length("/json:value/json:object"))
          else
            fn:substring($path, 1, fn:string-length($path) - fn:string-length("/json:value"))
        else
          $path
      let $func :=
          switch($type)
          case "simple" return xdmp:value(fn:concat("function($value) { fn:exists($value",$path, ")}"))
          default return xdmp:value(fn:concat("function($value) { fn:exists($value", $path,")}"))
      return domain-impl:set-field-function-cache($field,"json-exists",$func)($value)
 };

declare function domain-impl:field-xml-exists(
  $field as element(),
  $value as item()*
) as xs:boolean {
  let $type := domain:get-base-type($field)
  let $path := domain:get-field-xpath($field, fn:false())
  let $expr := fn:concat("$value", $path)
  let $func :=
    switch($type)
      case "simple" return xdmp:with-namespaces(domain:declared-namespaces($field),xdmp:value(fn:concat("function($value){fn:exists(", $expr, ")}")))
      default return xdmp:with-namespaces(domain:declared-namespaces($field),xdmp:value(fn:concat("function($value){fn:exists(", $expr, ")}")))
  return domain-impl:set-field-function-cache($field,"xml-exists",$func)($value)
};

(:~
 : Returns the value for a field given a json object
 :)
declare function domain-impl:get-field-json-value(
  $field as element(),
  $values as item()?,
  $relative as xs:boolean
) {
  let $value :=
    for $v in $values
    return typeswitch($v)
      case json:object return <x>{$v}</x>/*
      case json:array return <x>{$v}</x>/*
      case element(json:object) return $v
      case element(json:array) return json:array-values(json:array($v))
      default return fn:error(xs:QName("UNKNOWN-JSON-OBJECT"),"Type is not json",xdmp:describe($v))
  return
    if(domain-impl:exists-field-function-cache($field,"json")) then
      domain-impl:get-field-function-cache($field,"json")($value)
    else
      let $type := domain:get-base-type($field)
      let $path := domain:get-field-jsonpath($field)
      let $func :=
          switch($type)
          case "simple" return xdmp:value(fn:concat("function($value) { $value",$path, "}"))
          default return xdmp:value(fn:concat("function($value) { $value", $path,"}"))
      return domain-impl:set-field-function-cache($field,"json",$func)($value)
 };

(:~
 : Returns the value for a field given a xml using its xpath expression
 :)
declare function domain-impl:get-field-xml-value(
  $field as element(),
  $value as item()*,
  $relative as xs:boolean
) {
  (:if(domain-impl:exists-field-function-cache($field,"xml")):)
  (:then domain-impl:get-field-function-cache($field,"xml")($value):)
  (:else:)
  let $type := domain:get-base-type($field)
  let $path := domain:get-field-xpath($field, $relative)
  let $expr := fn:concat("$value", $path)
  let $func :=
    switch($type)
      case "simple"
        return xdmp:with-namespaces(domain:declared-namespaces($field),xdmp:value(fn:concat("function($value){", $expr, "}")))
      default
        return xdmp:with-namespaces(domain:declared-namespaces($field),xdmp:value(fn:concat("function($value){", $expr, "}")))
  return domain-impl:set-field-function-cache($field,"xml",$func)($value)
};

(:~
 : Returns the base type of field definition.  The base type of the domain
 :)
declare function domain-impl:get-base-type(
  $field as element(),
  $safe as xs:boolean
) {
  if($field/@type = $SIMPLE-TYPES) then "simple"
  else if($field/@type = $COMPLEX-TYPES) then "complex"
  else if($field instance of element(domain:model)) then "model"
  else if($field instance of element(domain:container)) then "container"
  else if($field instance of element(domain:triple)) then "triple"
  else if(domain:model-exists($field/@type)) then "instance"
  else if($safe) then fn:error(xs:QName("UNKNOWN-BASE-TYPE"),"Unknown Base Type",$field)
  else "unknown"
};

(:~
 : Returns true if the field is multivalue or occurrence allows for more than 1 value.
 :)
declare function domain-impl:field-is-multivalue(
  $field
) as xs:boolean {
  if($field/@occurrence =  ("*","+")) then
    fn:true()
  else if($field/@occurrence castable as xs:integer) then
    $field/@occurrence cast as xs:integer gt 1
  else
    fn:false()
};

(:~
 : Returns the passed in value type and its expecting source values
:)
declare function domain-impl:get-value-type(
  $type as item()?
) {
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
declare function domain-impl:get-field-value-collections(
  $value
) {
  let $value-type := domain-impl:get-value-type($value)
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
declare function domain-impl:get-param-keys(
  $params as item()
) {
  switch(domain-impl:get-value-type($params))
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
declare function domain-impl:get-param-value(
  $params as item(),
  $key as xs:string*
) {
  domain-impl:get-param-value($params, $key, ())
};

declare function domain-impl:get-param-value(
  $params as item(),
  $key as xs:string*,
  $default
) {
  let $type := domain-impl:get-value-type($params[1])
  let $value :=
  switch ($type)
    case "param" return
      if (map:contains($params, $key)) then
        map:get($params, $key)
      else
        ()
    default return
      ()
  return
    if (fn:exists($value)) then
      $value
    else
      let $keys := fn:tokenize($key, "\.")
      let $head := fn:head($keys)
      let $value :=
        switch($type)
          case "json" return
            let $value :=
              if($params instance of json:object) then
                <x>{$params}</x>//json:entry[@key = $head]/json:value
              else
                $params//json:entry[@key = $head]/json:value
            return
              let $value :=
                if ($value/node() instance of element(json:array)) then
                  json:array-values(json:array($value/node()))
                else
                  $value
              return
                if ($value instance of node()*) then
                  if ($value/node() instance of text()*) then
                    $value/fn:data()
                  else
                    $value/node()
                else
                  $value
          case "param"
            return map:get($params,$head)
          case "xml"
            return $params/descendant-or-self::*[fn:local-name(.) = $head]/node()
          default return ()
      return
        if (fn:count($keys) eq 1) then
          if (fn:exists($value)) then
            $value
          else
            $default
        else
          let $value :=
            switch(domain-impl:get-value-type($value[1]))
            case "json"
              return
                if (fn:count($value) eq 1) then
                  $value
                else
                  ()
            case "param"
              return
                if (fn:count($value) eq 1) then
                  $value
                else
                  ()
            case "xml"
              return <x>{$value}</x>
            default
              return ()
          return
            if (fn:exists($value)) then
              domain-impl:get-param-value($value, fn:substring-after($key, fn:concat($head, ".")), $default)
            else
              ()
};
(:~
 :
 :)
declare function domain-impl:model-exists(
  $model-name as xs:string?
) {
  domain:model-exists(config:default-application(),$model-name)
};

(:~
 :
 :)
declare function domain-impl:model-exists(
    $application as xs:string,
    $model-name as xs:string?
) {
   fn:exists(config:get-domain($application)//domain:model[@name = $model-name])
};

(:~
 : Returns whether the module exists or not.
 :)
declare function domain-impl:module-exists(
  $module-location as xs:string
) as xs:boolean {
  module-loader:resource-exists($module-location)
};

declare function domain-impl:get-function-key(
  $module-namespace as xs:string,
  $module-location as xs:string,
  $function-name as xs:string,
  $function-arity as xs:integer
) as element() {
  let $function-keys :=
    if (map:contains($FUNCTION-CACHE, $FUNCTION-KEYS)) then
      map:get($FUNCTION-CACHE, $FUNCTION-KEYS)
    else
      let $function-keys := map:new()
      return (
        map:put($FUNCTION-CACHE, $FUNCTION-KEYS, $function-keys),
        $function-keys
      )
  let $key := fn:concat($module-namespace, $module-location, $function-name, $function-arity)
  return
    if (map:contains($function-keys, $key)) then
      map:get($function-keys, $key)
    else
      let $function-key :=
        element function-key {
          attribute module-namespace {$module-namespace},
          attribute module-location {$module-location},
          attribute function-name {$function-name},
          attribute function-arity {$function-arity}
        }
      return (
        map:put($function-keys, $key, $function-key),
        $function-key
      )

};

(:
 : get a module function  (generic)
 : this should be refactored along with the module code in domain.xqy
 : TODO : Add support for model extension registered in module location
 : @author jjl
 :)
declare function domain-impl:get-module-function(
  $application as xs:string?,
  $module-type as xs:string,
  $module-namespace as xs:string?,
  $module-location as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  module-loader:load-function-module(
    domain:get-default-application(),
    $module-type,
    $function-name,
    $function-arity,
    $module-namespace,
    $module-location
  )
};

(:
 : get a model-module-specific model function
 : @author jjl
 :)
declare function domain-impl:get-model-module-function(
  $application as xs:string?,
  $model-name as xs:string,
  $action as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  let $module-location := config:model-location($application, $model-name)
  let $module-uri := config:model-uri($application, $model-name)
  return domain:get-module-function($application, "model", $module-uri, $module-location, $action, $function-arity)
};

 (:
  : This needs to figure in any _extension/model.extension.xqy
  : Perhaps a better name than get-base-model-function would be get-model-default-function
  : Either that or we add get-model-extension-function and put that in the sequence in
  : get-model-function
  :)
declare function domain-impl:get-model-base-function(
  $action as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  (:let $module-namespace := "http://xquerrail.com/model/base":)
  (:let $module-location  := config:get-base-model-location():)
  (:return:) (:domain-impl:get-module-function( $module-namespace, $module-location, $action, $function-arity ):)
  domain:get-module-function(
    (),
    "base-model",
    (),
    (),
    $action,
    $function-arity
  )
 };

 (:
 : get a model function, either from model-module or base-module
 :)
declare function domain-impl:get-model-function(
  $application as xs:string?,
  $model-name as xs:string,
  $action as xs:string,
  $function-arity as xs:integer?,
  $fatal as xs:boolean?
) as xdmp:function? {
  let $function := domain:get-model-module-function($application, $model-name, $action, $function-arity)
  return
    if (fn:exists($function)) then
      $function
    else
      let $function := domain:get-model-extension-function($action, $function-arity)
      return
        if (fn:exists($function)) then
          $function
        else
          let $function := domain:get-model-base-function($action, $function-arity)
          return
            if (fn:exists($function)) then
              $function
            else
              if($fatal) then
                fn:error(xs:QName("ACTION-NOT-EXISTS"), "The action '" || $action || "' for model '" || $model-name || "' does not exist")
              else
                ()
};

declare function domain-impl:get-model-extension-function(
  $action as xs:string,
  $function-arity as xs:integer?
 ) as xdmp:function? {
  domain:get-module-function(
    (),
    $module-loader:MODEL-EXTENSION-TYPE,
    (),
    (),
    $action,
    $function-arity
  )
};

(:~
 : Returns all models for all domains
:)
declare function domain-impl:get-models (
) as element(domain:model)* {
  domain-impl:get-models(domain:get-default-application(), fn:false())
};

(:~
 : Returns all models for a given application including abstract
 : @param $application - Name of the application
 : @param $include-abstract - Determines if to include abstract models.
 :)
declare function domain-impl:get-models (
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
declare function domain-impl:get-permissions(
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
declare function domain-impl:get-descendant-models(
    $parent as element(domain:model)
 ) {
  config:get-domain($parent/ancestor::domain:domain/domain:name[1])/domain:model[@extends  = $parent/@name]
};

(:~
 : Returns the query for descendant(@extends) models.
 : @param $model - Model which is the extension model
 :)
declare function domain-impl:get-descendant-model-query(
    $parent as element(domain:model)
) {
   domain-impl:get-descendant-models($parent) ! domain:get-base-query(.)
};

(:~
 : returns the default language associated with langString field.
 :)
declare function domain-impl:get-default-language($field) {
  if($field/@defaultLanguage) then $field/@defaultLanguage
  else if($field/ancestor::domain:domain/domain:default-language) then $field/ancestor::domain:domain/domain:default-language
  else "en"
};

(:~
 : Returns the languages associated with a given domain field whose type is langString
 :)
declare function domain-impl:get-field-languages($field as element()) {
   fn:distinct-values((
   $field/ancestor::domain:domain/domain:language,
   fn:tokenize($field/@languages,"\s"),
   "en"))
};

(:~
 : Returns the default sort field for a given model
 : @param $model - Model instance
 :)
declare function domain-impl:get-model-sort-field(
  $model as element(domain:model)
) as element()* {
  $model/domain:navigation/@sortField[. ne ""] ! domain:get-model-field($model, .)
};

declare function domain-impl:get-parent-field-attribute(
  $field as element(domain:attribute)
) as element() {
  let $parent := $field/..
  return
    if ($parent instance of element(domain:model) or $parent instance of element(domain:container) or $parent instance of element(domain:element)) then
      $parent
    else
      fn:error(xs:QName("UNSUPPORTED-PARENT-FIELD-ATTRIBUTE"), text{"Unsupported parent field", $parent/fn:name()})
};

declare function domain-impl:get-model-name-from-instance(
  $instance as element()
) as xs:string? {
  if ($instance/@xsi:type) then
    fn:string($instance/@xsi:type)
  else
    $instance/fn:local-name()
};

declare function domain-impl:get-model-from-instance(
  $instance as element()
) as element(domain:model)? {
  let $model-name := domain-impl:get-model-name-from-instance($instance)
  return
    if (domain:model-exists($model-name)) then
      domain:get-domain-model($model-name)
    else
      ()
};

declare function domain-impl:find-field-in-model(
  $model as element(domain:model),
  $key as xs:string
) as element()* {
  let $cache-key := ($model/@name || ":find-field-in-model:" || $key)
  let $cache := domain-impl:get-identity-cache($cache-key)
  return
    if(fn:exists($cache)) then $cache
    else
      let $value := (
        domain:get-model-field($model, $key),
        for $field in $model//(domain:element)
        where domain:get-base-type($field) = "instance"
        return domain-impl:find-field-in-model(domain:get-model($field/@type), $key)
      )
      return domain-impl:set-identity-cache($cache-key, $value)
};

declare function domain-impl:build-field-xpath-from-model(
  $model as element(domain:model),
  $fields as element()*
) as xs:string* {
  let $cache-key := fn:concat(
    $model/@name,
    ":build-field-xpath-in-model:",
    fn:string-join(for $field in $fields
        return domain-impl:get-field-key($field))
  )
  let $cache := domain-impl:get-identity-cache($cache-key)
  return
    if(fn:exists($cache)) then $cache
    else
      let $value :=
        if (fn:exists(domain:get-model-field($model, domain-impl:get-field-key($fields[1]), fn:true()))) then
          fn:string-join((
            for $f at $index in $fields[fn:not(. instance of element(domain:container))]
            return
              if ($index eq 1) then
                domain-impl:get-field-absolute-xpath($f)
              else
                domain:get-field-xpath($f)
          ),
          "")
        else
          ()
      return domain-impl:set-identity-cache($cache-key, $value)
};

declare function domain-impl:find-field-from-path-model(
  $model as element(domain:model),
  $key as xs:string,
  $accumulator as element()*
) as element()* {
  if (fn:contains($key, "/")) then
    let $path := fn:substring-before($key, "/")
    let $key := fn:substring-after($key, "/")
    let $field := domain:get-model-field($model, $path, fn:true())
    return
      if (fn:exists($field)) then
        if (domain:get-base-type($field) eq "instance") then
          domain-impl:find-field-from-path-model(domain:get-model($field/@type), $key, ($accumulator, $field))
        else if ($field/@type eq "reference") then
          domain-impl:find-field-from-path-model(domain-impl:get-field-reference-model($field), $key, ($accumulator, $field))
        else
          domain-impl:find-field-from-path-model($model, $key, ($accumulator, $field))
      else
        fn:error(xs:QName("FIND-FIELD-ERROR"), text{"Cannot find field", $path, "in model", $model/@name})
  else
    let $field := domain:get-model-field($model, $key)
    return
      if (fn:exists($field)) then
        ($accumulator, $field)
      else
        ()
};

declare function domain-impl:generate-schema(
  $model as element(domain:model)
) as element()* {
  <xs:schema
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    targetNamespace="{domain:get-field-namespace($model)}" xmlns="http://xquerrail.com" elementFormDefault="qualified">
    <xs:element name="{$model/@name}">
      <xs:complexType>
        <xs:sequence>
        {
          for $field in $model/node()
          return domain-impl:generate-schema-field($field)
        }
        </xs:sequence>
      </xs:complexType>
    </xs:element>
  </xs:schema>
};

declare %private function domain-impl:generate-schema-field(
  $field as element()
) as element()? {
  typeswitch ($field)
  case element(domain:element)
  return domain-impl:generate-schema-element($field)
  case element(domain:attribute)
  return domain-impl:generate-schema-attribute($field)
  default
  return ()
};

declare %private function domain-impl:generate-schema-element(
  $field as element(domain:element)
) as element(xs:element) {
  <xs:element>
  {
    attribute name {$field/@name},
    attribute type {'xs:' || domain:get-field-scalar-type($field)},
    domain-impl:generate-schema-occurence-constraints($field)
  }
  </xs:element>
};

declare %private function domain-impl:generate-schema-attribute(
  $field as element(domain:attribute)
) as element(xs:attribute) {
  <xs:attribute>
  {
    attribute name {$field/@name},
    attribute type {'xs:' || domain:get-field-scalar-type($field)},
    domain-impl:generate-schema-occurence-constraints($field)
  }
  </xs:attribute>
};

declare %private function domain-impl:generate-schema-occurence-constraints(
  $field as element()
) as attribute()* {
  if ($field/@name = ($field/ancestor::domain:model/@key, $field/ancestor::domain:model/@keyLabel)) then
  (
    typeswitch($field)
      case element(domain:element) return
      (
        attribute minOccurs {1},
        attribute maxOccurs {1}
      )
      case element(domain:attribute) return
        attribute use {"required"}
      default return
        ()
  )
  else if (fn:exists($field/@occurrence)) then
  (
    typeswitch($field)
      case element(domain:element) return
      (
        attribute minOccurs {
          if ($field/@occurrence = ("?", "*")) then
            0
          else if (fn:data($field/@occurrence) castable as xs:integer) then
            fn:data($field/@occurrence)
          else
            fn:error(xs:QName("GENERATE-SCHEMA-OCCURS-ERROR"), text{"Unsupported occurrence value", $field/@occurrence})
        },
        attribute maxOccurs {
          if ($field/@occurrence eq ("?")) then
            1
          else if ($field/@occurrence eq ("*")) then
            "unbounded"
          else if (fn:data($field/@occurrence) castable as xs:integer) then
            fn:data($field/@occurrence)
          else
            fn:error(xs:QName("GENERATE-SCHEMA-OCCURS-ERROR"), text{"Unsupported occurrence value", $field/@occurrence})
        }
      )
      case element(domain:attribute) return
        attribute use {
          if ($field/@occurrence = "?") then
            "optional"
          else if ($field/@occurrence = "*") then
            fn:error(xs:QName("GENERATE-SCHEMA-OCCURS-ERROR"), text{"Unsupported occurrence value", $field/@occurrence, "for", $field/@name}, $field)
          else
            "required"
        }
      default return
        ()
  )
  else if (xs:boolean($field/domain:constraint/@required)) then
  (
    typeswitch($field)
      case element(domain:element) return
      (
        attribute minOccurs {1},
        attribute maxOccurs {1}
      )
      case element(domain:attribute) return
        attribute use {"required"}
      default return
        ()
  )
  else
  (
    typeswitch($field)
      case element(domain:element) return
      (
        attribute minOccurs {0},
        attribute maxOccurs {1}
      )
      case element(domain:attribute) return
        attribute use {"optional"}
      default return
        ()
  ),
  domain-impl:generate-schema-default($field)
};

declare %private function domain-impl:generate-schema-default(
  $field as element()
) as attribute()? {
  if (fn:exists($field/@default)) then
    typeswitch($field)
      case element(domain:element) return
        $field/@default
      case element(domain:attribute) return
        if (xs:boolean($field/domain:constraint/@required) or fn:data($field/@occurrence) eq 1) then
          fn:error(xs:QName("GENERATE-SCHEMA-DEFAULT-ERROR"), text{"Attribute field", $field/@name,"cannot be required and have default defined"}, $field)
        else
          $field/@default
      default return
        ()
  else
    ()
};
