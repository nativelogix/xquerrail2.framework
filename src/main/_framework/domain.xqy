xquery version "1.0-ml";
(:~
 : Controls all interaction with an application domain.  The domain provides annotations and
 : definitions for dynamic features built into XQuerrail.
 : @version 2.0
 :)
module namespace domain = "http://xquerrail.com/domain";

import module namespace cache = "http://xquerrail.com/cache" at "cache.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace module = "http://xquerrail.com/module" at "module.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-doc-2007-01.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace qry = "http://marklogic.com/cts/query";

declare option xdmp:mapping "false";

declare variable $FUNCTIONS-CACHE := map:map();
declare variable $FUNCTION-KEYS := "$FUNCTION-KEYS$";
declare variable $UNDEFINED-FUNCTION := "$UNDEFINED-FUNCTION$";
declare variable $DOMAINS-CONTROLLER-NAMESPACE := "http://xquerrail.com/controller/domains";
declare variable $CONTROLLER-EXTENSION-NAMESPACE := "http://xquerrail.com/controller/extension";
declare variable $DOMAIN-EXTENSION-NAMESPACE := "http://xquerrail.com/domain/extension";
declare variable $MODEL-EXTENSION-NAMESPACE := "http://xquerrail.com/model/extension";
declare variable $XQUERRAIL-NAMESPACES := map:new((
  map:entry("config", "http://xquerrail.com/config"),
  map:entry("domain", "http://xquerrail.com/domain")
));

declare %config:module-location function domain:module-location(
) as element(module)* {
  let $modules-map := module:get-modules-map("http://xquerrail.com/domain/", "/domain")
  return (
    element module {
      attribute type {"domain"},
      attribute namespace { "http://xquerrail.com/domain" },
      attribute location { module:normalize-uri((config:framework-path(), "/domain.xqy")) },
      attribute interface { fn:true() }
    },
    for $namespace in map:keys($modules-map)
    return
      element module {
        attribute type {"domain"},
        attribute namespace { $namespace },
        attribute location { map:get($modules-map, $namespace) },
        attribute interface { fn:false() }
      }
  )
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*
) {
  domain:apply-function($name, 1, $argument-1, (), (), (), (), (), (), (), (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*
) {
  domain:apply-function($name, 2, $argument-1, $argument-2, (), (), (), (), (), (), (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*
) {
  domain:apply-function($name, 3, $argument-1, $argument-2, $argument-3, (), (), (), (), (), (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*
) {
  domain:apply-function($name, 4, $argument-1, $argument-2, $argument-3, $argument-4, (), (), (), (), (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*
) {
  domain:apply-function($name, 5, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, (), (), (), (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*
) {
  domain:apply-function($name, 6, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, (), (), (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*
) {
  domain:apply-function($name, 7, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, (), (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*
) {
  domain:apply-function($name, 8, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, (), ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*
) {
  domain:apply-function($name, 9, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, ())
};

declare function domain:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*,
  $argument-10 as item()*
) {
  domain:apply-function($name, 10, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
};

declare function domain:apply-function(
  $name as xs:string,
  $arity as xs:positiveInteger,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*,
  $argument-8 as item()*,
  $argument-9 as item()*,
  $argument-10 as item()*
) {
  module:apply-function-module(
    (),
    "domain",
    $name,
    $arity,
    (),
    (),
    $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10
  )
};

(:declare function domain:domain-function(
  $name as xs:string,
  $arity as xs:integer
) as xdmp:function {
  let $key := fn:concat($name,"#",$arity)
  return
  if (map:contains($FUNCTIONS-CACHE, $key)) then
    map:get($FUNCTIONS-CACHE, $key)
  else
    let $function :=
      module:load-function-module(
        (),
        "domain",
        $name,
        $arity,
        (),
        (),
        fn:false()
        )
    let $function :=
      if (fn:empty($function)) then
        fn:error(xs:QName("LOAD-FUNCTION-MODULE-ERROR"), text{"Function", $name, "from domain module type not found."})
      else
        $function
    return (
      map:put($FUNCTIONS-CACHE, $key, $function),
      $function
    )
};:)

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

declare variable $MODEL-INHERIT-ATTRIBUTES := ('class', 'key', 'keyLabel', 'persistence');

declare variable $MODEL-PERMISSION-ATTRIBUTES := (
  "role", "read", "update", "insert", "execute"
);

declare variable $MODEL-NAVIGATION-ATTRIBUTES := (
  "editable", "exportable", "findable", "importable", "listable", "newable", "removable", "searchable", "securable", "showable", "sortable"
);

declare variable $FIELD-NAVIGATION-ATTRIBUTES := (
  $MODEL-NAVIGATION-ATTRIBUTES, "metadata", "suggestable"
);

(:~
 : Holds a cache of all the domain models
 :)
declare variable $DOMAIN-MODEL-CACHE := cache:domain-model-cache();

(: Generic domain cache:)
declare variable $CACHE := cache:get-server-field-cache-map("domain-cache");

(:Holds a cache of all the identity fields:)
declare variable $DOMAIN-IDENTITY-CACHE := cache:get-server-field-cache-map("domain-identity-cache");

(:~
 : Cache all values
:)
declare variable $FIELD-VALUE-CACHE := cache:get-server-field-cache-map("domain-field-value-cache");

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
declare function domain:cast-value(
  $field as element(),
  $value as item()*
) {
  domain:apply-function("cast-value", $field, $value)
};

(:~
 : Returns the cts scalar type for all types.  The default is "string"
:)
declare function domain:get-field-scalar-type(
  $field as element()
) {
  domain:apply-function("get-field-scalar-type", $field)
};

(:~
 : Returns if the value is castable to the given value based on the field/@type
 : @param $field Domain element (element|attribute|container)
 :)
declare function domain:castable-value(
  $field as element(),
  $value as item()?
) {
  domain:apply-function("castable-value", $field, $value)
};

declare function domain:resolve-cts-type(
  $type as xs:string
) {
  domain:apply-function("resolve-cts-type", $type)
};

(:
 : Clear domain model cache
 :)
declare function domain:clear-model-cache(
) as empty-sequence() {
  map:clear($domain:DOMAIN-MODEL-CACHE)
};

(:~
 : Gets the domain model from the given cache
 :)
declare function domain:get-model-cache(
  $application,
  $model-name
) {
  domain:apply-function("get-model-cache", $application, $model-name)
};

(:~
 : Sets the cache for a domain model
 :)
declare function domain:set-model-cache(
  $application,
  $model-name,
  $model as element(domain:model)?
) {
  domain:apply-function("set-model-cache", $application, $model-name, $model)
};

(:~
 : Sets a cache for quick lookup on domain model field paths
 :)
declare function domain:set-field-cache(
  $key as xs:string,
  $func as function(*)
) {
  domain:apply-function("set-field-cache", $key, $func)
};

(:~
 : Gets the value of an identity cache from the map
 : @private
 :)
declare function domain:get-identity-cache(
  $key as xs:string
) {
  domain:apply-function("get-identity-cache", $key)
};

(:~
 : Sets the cache value of a models identity field for fast resolution
 : @param $key - key string to identify the cache identity
 : @param $value - $value of the cache item
 :)
declare function domain:set-identity-cache(
  $key as xs:string,
  $value as item()*
) as item()* {
  domain:apply-function("set-identity-cache", $key, $value)
};

(:~
 : Returns a cache key unique to a field
 :)
declare function domain:get-field-cache-key(
  $field,
  $prefix as xs:string
) {
  domain:apply-function("get-field-cache-key", $field, $prefix)
};

declare function domain:get-function-cache-key(
  $field as item(),
  $type as xs:string
) as xs:string {
  domain:apply-function("get-function-cache-key", $field, $type)
};

(:~
 : Returns the cache for a given value function
:)
declare function domain:undefined-field-function-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  domain:apply-function("undefined-field-function-cache", $field, $type)
};

(:~
 : Returns the cache for a given value function
:)
declare function domain:exists-field-function-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  domain:apply-function("exists-field-function-cache", $field, $type)
};

(:~
 : Sets the function in the value cache
 :)
declare function domain:set-field-function-cache(
  $field as element(),
  $type as xs:string,
  $funct as function(*)?
) {
  domain:apply-function("set-field-function-cache", $field, $type, $funct)
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function domain:get-field-function-cache(
  $field as element(),
  $type as xs:string
) as function(*)? {
  domain:apply-function("get-field-function-cache", $field, $type)
};


(:~
 : Returns the cache for a given value function
:)
declare function domain:exists-field-value-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  domain:apply-function("exists-field-value-cache", $field, $type)
};

(:~
 : Sets the function in the value cache
 :)
declare function domain:set-field-value-cache(
  $field as element(),
  $type as xs:string,
  $value as item()*
) {
  domain:apply-function("set-field-value-cache", $field, $type, $value)
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function domain:get-field-value-cache(
  $field as element(),
  $type as xs:string
) as item() {
  domain:apply-function("get-field-value-cache", $field, $type)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field-name(
  $model as element(domain:model)
) as xs:string {
  domain:apply-function("get-model-identity-field-name", $model)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-identity-field", $model)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keylabel-field(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-keylabel-field", $model)
};

(:~
 : Returns the identity query for a domain-model
 : @param $model - The domain model for the identity-query
 : @param $value - The value of the domain instance for retrieval
 :)
declare function domain:get-model-identity-query(
  $model as element(domain:model),
  $value as xs:anyAtomicType?
) {
  domain:apply-function("get-model-identity-query", $model, $value)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-key-field(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-key-field", $model)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keyLabel-field(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-keyLabel-field", $model)
};

declare function domain:get-field-prefix(
  $field as element()
) as xs:string? {
  domain:apply-function("get-field-prefix", $field)
};

(:~
 : Returns the field that matches the given field name or key
 : @param $model - The model to extract the given field
 : @param $name  - name or key of the field
 :)
declare function domain:get-model-field(
  $model as element(domain:model),
  $name as xs:string
) {
  domain:get-model-field($model, $name, fn:false())
};

declare function domain:get-model-field(
  $model as element(domain:model),
  $name as xs:string,
  $include-container as xs:boolean
) {
  domain:apply-function("get-model-field", $model, $name, $include-container)
};

(:~
 : Returns model fields with unique constraints
 : @param $model - The model that returns all the unique constraint fields
 :)
declare function domain:get-model-unique-constraint-fields(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-unique-constraint-fields", $model)
};

(:~
 : Resolves a domain type to xsi:type
 : @param $model - The model to extract the given identity field
 :)
declare function domain:resolve-datatype(
  $field as element()
) {
  domain:apply-function("resolve-datatype", $field)
};

(:~
 : Resolves the field to its xs:Type equivalent
 : @return - String representing the schema
 :)
declare function domain:resolve-ctstype(
  $field as element()
) {
  domain:apply-function("resolve-ctstype", $field)
};

(:~
 : Returns the default application domain content-namespace-uri
 : @return the content-namespace for the default application
 :)
declare function domain:get-content-namespace-uri(
) as xs:string {
  domain:apply-function("get-content-namespace-uri", ())
};

(:~
 : Returns the content-namespace value for a given application
 : @param $application - name of the application
 : @return - The namespace URI of the given application
 :)
declare function domain:get-content-namespace-uri(
  $application as xs:string
) as xs:string {
  domain:apply-function("get-content-namespace-uri", $application)
};

(:~
 : Gets the controller definition for a given application by its name
 : @param $application - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller(
  $application as xs:string,
  $controller-name as xs:string
) as element(domain:controller)? {
  domain:apply-function("get-controller", $application, $controller-name)
};
(:~
 : Returns the actions associated with the controller. The function assumes the controller lives in the default application.
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-actions(
  $controller-name as xs:string
) as xs:string* {
  domain:get-controller-actions(config:default-application(), $controller-name)
};

(:~
 : Returns all the available functions for a given controller.
 : @param $application - Name of the application
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-actions(
  $application as xs:string,
  $controller-name as xs:string
) as xs:string* {
  domain:apply-function("get-controller-actions", $application, $controller-name)
};

(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application - Name of the application
 :  @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-model(
  $controller-name as xs:string
) as element(domain:model)? {
  domain:apply-function("get-controller-model", $controller-name)
};

(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application - Name of the application
 :  @param $controller-name - Name of the controller
 :  @return  - returns the model associated with the given controller.
 :)
declare function domain:get-controller-model(
  $application as xs:string,
  $controller-name as xs:string
) as element(domain:model)? {
  domain:apply-function("get-controller-model", $application, $controller-name)
};

(:~
 : Gets the name of the controller associated with a model
 : @param $model-name - name of the model
 : @return The name of the controller
 :)
declare function domain:get-model-controller-name(
  $model-name as xs:string?
) as xs:string* {
  domain:apply-function("get-model-controller-name", $model-name)
};

(:~
 : Gets the name of the controller for a given application and model.
 :  @param $application - Name of the application
 :  @param $model-name - Name of the controller
 :  @return - the name of the controller
 :)
declare function domain:get-model-controller-name(
  $application as xs:string,
  $model-name as xs:string?
) as xs:string* {
  domain:apply-function("get-model-controller-name", $application, $model-name)
};

(:~
 : Returns the model definition by its application and model name
 : @param $application - Name of the application
 : @param $model-name - Name of the model
 : @return  a model definition
  :)
declare function domain:get-model(
  $application as xs:string,
  $model-name as xs:string*
) as element(domain:model)* {
  domain:get-domain-model($application, $model-name)
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
  $model-name as xs:string+
) as element(domain:model)* {
  domain:get-domain-model(config:default-application(), $model-name)
};

declare function domain:get-domain-model(
  $application as xs:string,
  $model-name as xs:string*
) as element(domain:model)* {
  domain:get-domain-model($application, $model-name, fn:true())
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
) as element(domain:model)* {
  domain:apply-function("get-domain-model", $application, $model-names, $extension)
};

declare %private function domain:find-model-by-name(
  $domain as element(domain:domain),
  $name as xs:string?
) as element(domain:model)? {
  domain:apply-function("find-model-by-name", $domain, $name)
};

declare function domain:compile-model(
  $application as xs:string,
  $model as element(domain:model)
) as element(domain:model) {
  domain:apply-function("compile-model", $application, $model)
};

declare function domain:navigation(
  $field as element()
) as element(domain:navigation)? {
  domain:apply-function("navigation", $field)
};

declare function domain:validators(
  $model as element(domain:model)
) as element(domain:validator)* {
  domain:apply-function("validators", $model)
};

(:~
  Build model permission
:)
declare function domain:build-model-permission(
  $model as element(domain:model)
) as element(domain:permission)* {
  domain:apply-function("build-model-permission", $model)
};

(:~
  navigation from model, abstract or domain are merged in this order
:)
declare function domain:build-model-navigation(
  $field as element()
) as element(domain:navigation)* {
  domain:apply-function("build-model-navigation", $field)
};

(:~
  Set navigation, permission for all model elements (if not defined will inherit from parent else default is false)
:)
declare function domain:set-model-field-defaults(
  $field as item()
) as item() {
  domain:apply-function("set-model-field-defaults", $field)
};

declare function domain:set-model-field-attributes(
  $field as item()
) as item() {
  domain:apply-function("set-model-field-attributes", $field)
};

declare function domain:set-field-attributes(
  $field as element()
) as attribute()* {
  domain:apply-function("set-field-attributes", $field)
};

declare function domain:model-validation-enabled(
  $model as element(domain:model)
) as xs:boolean {
  domain:apply-function("model-validation-enabled", $model)
};

(:~
 : Returns a list of all defined controllers for a given application domain
 : @param $application - application domain name
 :)
declare function domain:get-controllers(
  $application as xs:string
) as element(domain:controller)* {
  config:get-domain($application)/domain:controller
};

(:~
 : Returns the default application domain defined in the config.xml
 :)
declare function domain:get-default-application(
) as xs:string {
  config:default-application()
};

(:~
 : Returns the default content namespace for a given application. Convenience wrapper for @see config:default-namespace() function.
 : @param $application - Name of the application
 : @return default content namespace
 :)
declare function domain:get-default-namespace(
  $application as xs:string
) {
  domain:apply-function("get-default-namespace", $application)
};

(:~
 : Returns all content and declare-namespace in application-domain
 : @param $application - Name of the application
 : @return sequence of element(namespace).
 :)
declare function domain:get-domain-namespaces(
  $application as xs:string
) as element(namespace)* {
  domain:apply-function("get-domain-namespaces", $application)
};

(:~
 : Returns a list of domain models given a class selector
 : @param $class - name of a class associated witha given model.
 :)
declare function domain:model-selector(
  $class as xs:string
) as element(domain:model)* {
  domain:model-selector(config:default-application(), $class)
};

(:~
 : Returns a list of models with a given class attribute from a given application.
 : Function is helpful for selecting a list of all models or selecting them by their @class attribute.
 : @param $application - Name of the application
 : @param $class - the selector class it can be space delimitted
 :)
declare function domain:model-selector(
  $application as xs:string,
  $class as xs:string*
) as element(domain:model)* {
  domain:apply-function("model-selector", $application, $class)
};

(:~
 : Returns a list of all the fields defined by the selector.
 :)
declare function domain:model-fields(
  $model-name as xs:string
) as element()*{
  domain:model-fields(config:default-application(), $model-name)
};

(:~
 : Returns the list of fields associated iwth
 :)
declare function domain:model-fields(
  $application as xs:string,
  $model-name as xs:string
) as element()* {
  domain:apply-function("model-fields", $application, $model-name)
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
declare function domain:get-field-name-key(
  $field as node()
) {
  domain:apply-function("get-field-name-key", $field)
};

declare function domain:hash(
  $field as node()
) {
  domain:apply-function("hash", $field)
};

(:~
 :  Returns a unique identity key that can used as a unique identifier for the field.
 :  @param $context - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain:get-field-id(
  $field as node()
) {
  domain:apply-function("get-field-id", $field)
};

(:~
 :  Gets the namespace of the field. Namespace resolution is inherited if not specified by the field in the following order:
 :  field-> model-> domain:content-namespace
 :  @param $field - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain:get-field-namespace(
  $field as element()
) as xs:string? {
  domain:apply-function("get-field-namespace", $field)
};

(:~
 : Retrieves the value of a field based on a parameter key
 : @param $field - The field definition representing the value to return
 : @param $params - A map:map representing the field parameters
:)
declare function domain:get-field-param-value(
  $field as element(),
  $params as map:map
) {
  domain:get-field-param-value($field, $params, fn:false(), fn:true())
};

declare function domain:get-field-param-value(
  $field as element(),
  $params as map:map,
  $relative as xs:boolean,
  $cast as xs:boolean
) {
  domain:apply-function("get-field-param-value", $field, $params, $relative, $cast)
};

declare function domain:get-field-param-match-key(
  $field as element(),
  $params as map:map
) {
  domain:apply-function("get-field-param-match-key", $field, $params)
};

declare function domain:get-field-param-langString-value(
  $field as element(),
  $params as map:map
) as rdf:langString? {
  domain:apply-function("get-field-param-langString-value", $field, $params)
};

declare function domain:get-field-param-triple-value(
  $field as element(),
  $params as map:map
) as element(sem:triple)? {
  domain:apply-function("get-field-param-triple-value", $field, $params)
};

(:~
 : Returns the reference value from a given field from the current context node.
 : @param $field - the model definition
 : @param $current-node - is the instance of the current element to extract the value from
 :)
declare function domain:get-field-reference(
  $field as element(),
  $current-node as node()
) {
  domain:apply-function("get-field-reference", $field, $current-node)
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
  domain:apply-function("get-field-reference-model", $field)
};

(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $field - instance of a field
 :)
declare function domain:get-field-xpath(
  $field as element()
) {
  domain:get-field-xpath($field, fn:false())
};

declare function domain:get-field-xpath(
  $field as element(),
  $relative as xs:boolean
) {
  domain:apply-function("get-field-xpath", $field, $relative)
};

(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $field - instance of a field
 :)
declare function domain:get-field-absolute-xpath(
  $field as element()
) {
  domain:apply-function("get-field-absolute-xpath", $field)
};

declare function domain:get-field-qname(
  $field as element()
) {
  domain:apply-function("get-field-qname", $field)
};

(:~
 : Constructs a map of a domain instance based on a list of retain node names
 : @param $doc - context node instance
 : @param $retain  - a list of nodes to retain from original context
 :)
declare function domain:build-value-map(
  $doc as node()?,
  $retain as xs:string*
) as map:map? {
  domain:apply-function("build-value-map", $doc, $retain)
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
  $retain as xs:string*
) {
  domain:apply-function("recurse", $node, $map, $retain)
};

declare function domain:get-model-by-xpath(
  $path as xs:string
) as xs:string? {
  fn:error(xs:QName("DEPRECATED"), "Function is deprecated")
};

(:~
 : Returns a controller based on the model name
 : @param $model-name  - name of the model
 :)
declare function domain:get-model-controller(
  $model-name as xs:string
) as element(domain:controller)* {
  domain:get-model-controller(config:default-application(), $model-name)
};

declare function domain:get-model-controller(
  $application as  xs:string,
  $model-name as xs:string
) as element(domain:controller)* {
  domain:get-model-controller($application, $model-name, fn:false())
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
  domain:apply-function("get-model-controller", $application, $model-name, $checked)
};

(:~
 : Returns an optionlist from the default domain
 : @param $name  Name of the optionlist
 :)
declare function domain:get-optionlist(
  $name as xs:string
) {
  domain:get-optionlist(domain:get-default-application(), $name)
};

(:~
 :  Returns an optionlist from the application by its name
 : @param $application  Name of the application
 : @param $listname  Name of the optionlist
 :)
declare function domain:get-optionlist(
  $application as xs:string,
  $listname as xs:string
) {
  domain:apply-function("get-optionlist", $application, $listname)
};

(:~
 : Returns an optionlist associated with a field definitions inList attribute.
 : @param $field  Field instance (domain:element|domain:attribute)
 : @return optionlist specified by field.
 :)
declare function domain:get-field-optionlist(
  $field
) {
  domain:apply-function("get-field-optionlist", $field)
};
(:~
 : Gets an application element specified by the application name
 : @param $application Name of the application
 :)
declare function domain:get-application(
  $application as xs:string
) {
  domain:apply-function("get-application", $application)
};
(:~
 : Returns the key that represents the given model
 : the key format is model:{model-name}:reference
 : @param $model - The instance of the domain model
 : @return The reference-key defining the model
 :)
declare function domain:get-model-reference-key(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-reference-key", $model)
};
(:~
 : Gets a list of domain models that reference a given model.
 : @param $model - The domain model instance.
 : @return a sequence of domain:model elements
 :)
declare function domain:get-model-references(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-references", $model)
};

declare function domain:get-models-reference-query(
  $model as element(domain:model),
  $instance as item()
) as cts:or-query {
  domain:apply-function("get-models-reference-query", $model, $instance)
};

(:~
 : Returns true if a model is referenced by its identity
 : @param $model - The model to determine the reference
 : @param $instance -
 :)
declare function domain:is-model-referenced(
  $model as element(domain:model),
  $instance as element()
) as xs:boolean {
  domain:apply-function("is-model-referenced", $model, $instance)
};

(:~
 : Returns true if a model is referenced by its identity
 : @param $model - The model which is the base of the instance reference
 : @instance - The instance for a given model
 :)
declare function domain:get-model-reference-uris(
 $model as element(domain:model),
 $instance as element()
) {
  domain:apply-function("get-model-reference-uris", $model, $instance)
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
) as cts:and-query? {
  domain:apply-function("get-model-reference-query", $reference-model, $reference-key, $reference-value)
};

(:~
 : Returns the default collation for the given field. The function walks up the ancestor tree to find the collation in the following order:
 : $field/@collation->$field/model/@collation->$domain/domain:default-collation.
 : @param $field - the field to find the collation by.
 :)
declare function domain:get-field-collation(
  $field as element()
) as xs:string {
  domain:apply-function("get-field-collation", $field)
};

(:~
 : Returns the list of fields that are part of the uniqueKey constraint as defined by the $model/@uniqueKey attribute.
 : @param $model - Model that defines the unique constraint.
 :)
declare function domain:get-model-uniqueKey-constraint-fields(
  $model as element(domain:model)
) {
  domain:apply-function("get-model-uniqueKey-constraint-fields", $model)
};

(:~
 : Returns a unique constraint query
 :)
declare function domain:get-model-uniqueKey-constraint-query(
  $model as element(domain:model),
  $params as item(),
  $mode as xs:string
) {
  domain:apply-function("get-model-uniqueKey-constraint-query", $model, $params, $mode)
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
  $mode as xs:string
) {
  domain:apply-function("get-model-unique-constraint-query", $model, $params, $mode)
};

(:~
 : Constructs a search expression based on a give model
 :)
declare function domain:get-model-search-expression(
  $model as element(domain:model),
  $query as cts:query?
) {
  domain:get-model-search-expression($model,$query,())
};

(:~
 : Constructs a search expression based on a givem model
 :)
declare function domain:get-model-search-expression(
  $model as element(domain:model),
  $query as cts:query?,
  $options as xs:string*
) {
  domain:apply-function("get-model-search-expression", $model, $query, $options)
};

(:~
 : Returns a cts query that returns a cts:query which matches a node against its value.
:)
declare function domain:get-identity-query(
  $model as element(domain:model),
  $params as item()
) {
  domain:apply-function("get-identity-query", $model, $params)
};

declare function domain:get-keylabel-query(
  $model as element(domain:model),
  $params as item()
) {
  domain:apply-function("get-keylabel-query", $model, $params)
};

(:~
 : Returns the base query for a given model
 : @param $model  name of the model for the given base-query
 :)
declare function domain:get-base-query(
  $model as element(domain:model)
) {
  domain:apply-function("get-base-query", $model)
};

(:~
 : Constructs a xdmp:estimate expresion for a referenced model
 : @param $model - model definition
 : $query - Additional query to add the estimate expression
 : $options - cts:search options
 :)
declare function domain:get-model-estimate-expression(
  $model as element(domain:model),
  $query as cts:query?,
  $options as xs:string*
) {
  domain:apply-function("get-model-estimate-expression", $model, $query, $options)
};

(:~
 : Creates a root term query that can be used in combination to specify the root.
:)
declare function domain:model-root-query(
  $model as element(domain:model)
) {
  domain:apply-function("model-root-query", $model)
};

declare function domain:get-field-query-operator(
  $field as element(),
  $operator as xs:string?
) as xs:string {
  domain:apply-function("get-field-query-operator", $field, $operator)
};

(:~
 :
:)
declare function domain:get-field-query(
  $field as element(),
  $value as xs:anyAtomicType*
) {
  domain:get-field-query($field, $value, ())
};

(:~
 :
:)
declare function domain:get-field-query(
  $field as element(),
  $value as xs:anyAtomicType*,
  $options as xs:string*
) {
  domain:get-field-query($field, $value, $options, ())
};

declare function domain:get-field-query(
  $field as element(),
  $value as xs:anyAtomicType*,
  $options as xs:string*,
  $operator as xs:string?
) {
  domain:apply-function("get-field-query", $field, $value, $options, $operator)
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
  domain:apply-function("get-field-tuple-reference", $field, $add-options)
};

(:~
 : Return as list of all prefixes and their respective namespaces
:)
declare function domain:declared-namespaces(
  $model as element()
) as xs:string* {
  domain:apply-function("declared-namespaces", $model)
};

declare function domain:declared-namespaces-map(
  $model as element()
) {
  domain:apply-function("declared-namespaces-map", $model)
};

declare function domain:invoke-events(
  $model as element(domain:model),
  $events as element()*,
  $updated-values as item()*
) {
  domain:invoke-events($model, $events, $updated-values, ())
};

declare function domain:invoke-events(
  $model as element(domain:model),
  $events as element()*,
  $updated-values as item()*,
  $old-values as item()*
) {
  domain:apply-function("invoke-events", $model, $events, $updated-values, $old-values)
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
  $updated-values as item()*
) {
  domain:fire-before-event($model, $event-name, $updated-values, ())
};

declare function domain:fire-before-event(
  $model as element(domain:model),
  $event-name as xs:string,
  $updated-values as item()*,
  $old-values as item()*
) {
  domain:apply-function("fire-before-event", $model, $event-name, $updated-values, $old-values)
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
  $updated-values as item()*
) {
  domain:fire-after-event($model, $event-name, $updated-values, ())
};

declare function domain:fire-after-event(
  $model as element(domain:model),
  $event-name as xs:string,
  $updated-values as item()*,
  $old-values as item()*
) {
  domain:apply-function("fire-after-event", $model, $event-name, $updated-values, $old-values)
};

declare function domain:get-field-json-name(
  $field as element()
) as xs:string {
  domain:apply-function("get-field-json-name", $field)
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
  domain:apply-function("get-field-jsonpath", $field, $include-root, $base-path)
};

(:~
 : Gets the value from an object type
:)
declare function domain:get-field-value(
  $field as element(),
  $value as item()*
) as item()* {
  domain:get-field-value($field, $value, fn:false())
};

declare function domain:get-field-value(
  $field as element(),
  $value as item()*,
  $relative as xs:boolean
) as item()* {
  domain:apply-function("get-field-value", $field, $value, $relative)
};

(:~
 : Gets the node from an object type
:)
declare function domain:get-field-value-node(
  $field as element(),
  $value as item()*
) as item()* {
  domain:get-field-value-node($field, $value, fn:false())
};

declare function domain:get-field-value-node(
  $field as element(),
  $value as item()*,
  $relative as xs:boolean
) as item()* {
  domain:apply-function("get-field-value-node", $field, $value, $relative)
};

declare function domain:field-value-exists(
  $field as element(),
  $value as item()*
) as xs:boolean {
  domain:apply-function("field-value-exists", $field, $value)
};

declare function domain:field-param-exists(
  $field as element(),
  $params as map:map
) as xs:boolean {
  domain:apply-function("field-param-exists", $field, $params)
};

declare function domain:field-json-exists(
  $field as element(),
  $values as item()?
) as xs:boolean {
  domain:apply-function("field-json-exists", $field, $values)
};

declare function domain:field-xml-exists(
  $field as element(),
  $value as item()*
) as xs:boolean {
  domain:apply-function("field-xml-exists", $field, $value)
};

(:~
 : Returns the value for a field given a json object
 :)
declare function domain:get-field-json-value(
  $field as element(),
  $values as item()?
) {
  domain:get-field-json-value($field, $values, fn:false())
};

declare function domain:get-field-json-value(
  $field as element(),
  $values as item()?,
  $relative as xs:boolean
) {
  domain:apply-function("get-field-json-value", $field, $values, $relative)
};

(:~
 : Returns the value for a field given a xml using its xpath expression
 :)
declare function domain:get-field-xml-value(
  $field as element(),
  $value as item()*
) {
  domain:get-field-xml-value($field, $value, fn:false())
};

declare function domain:get-field-xml-value(
  $field as element(),
  $value as item()*,
  $relative as xs:boolean
) {
  domain:apply-function("get-field-xml-value", $field, $value, $relative)
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
  domain:apply-function("get-base-type", $field, $safe)
};

(:~
 : Returns true if the field is multivalue or occurrence allows for more than 1 value.
 :)
declare function domain:field-is-multivalue(
  $field
) {
  domain:apply-function("field-is-multivalue", $field)
};

(:~
 : Returns the passed in value type and its expecting source values
:)
declare function domain:get-value-type(
  $type as item()?
) {
  domain:apply-function("get-value-type", $type)
};
(:~
 : Returns the value of collections given any object type
 :)
declare function domain:get-field-value-collections(
  $value
) {
  domain:apply-function("get-field-value-collections", $value)
};

(:~
 : Returns the key for a given parameter by its name
 :)
declare function domain:get-param-keys(
  $params as item()
) {
  domain:apply-function("get-param-keys", $params)
};

(:~
 : Gets a parameter from a map:map or json:object value by its name
:)
declare function domain:get-param-value(
  $params as item(),
  $key as xs:string*
) {
  domain:get-param-value($params, $key, ())
};

declare function domain:get-param-value(
  $params as item(),
  $key as xs:string*,
  $default
) {
  domain:apply-function("get-param-value", $params, $key, $default)
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
  $application as xs:string,
  $model-name as xs:string?
) {
  domain:apply-function("model-exists", $application, $model-name)
};

(:~
 : Returns whether the module exists or not.
 :)
declare function domain:module-exists(
  $module-location as xs:string
) as xs:boolean {
  domain:apply-function("module-exists", $module-location)
};

declare function domain:get-function-key(
  $module-namespace as xs:string,
  $module-location as xs:string,
  $function-name as xs:string,
  $function-arity as xs:integer
) as element() {
  domain:apply-function("get-function-key", $module-namespace, $module-location, $function-name, $function-arity)
};

(:
 : get a module function  (generic)
 : this should be refactored along with the module code in domain.xqy
 : TODO : Add support for model extension registered in module location
 : @author jjl
 :)
declare function domain:get-module-function(
  $application as xs:string?,
  $module-type as xs:string,
  $module-namespace as xs:string?,
  $module-location as xs:string?,
  $function-name as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  domain:apply-function("get-module-function", $application, $module-type, $module-namespace, $module-location, $function-name, $function-arity)
};

(:
 : get a model-module-specific model function
 : @author jjl
 :)
declare function domain:get-model-module-function(
  $application as xs:string?,
  $model-name as xs:string,
  $action as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  domain:apply-function("get-model-module-function", $application, $model-name, $action, $function-arity)
};

 (:
  : This needs to figure in any _extension/model.extension.xqy
  : Perhaps a better name than get-base-model-function would be get-model-default-function
  : Either that or we add get-model-extension-function and put that in the sequence in
  : get-model-function
  :)
declare function domain:get-model-base-function(
  $action as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  domain:apply-function("get-model-base-function", $action, $function-arity)
};

 (:
 : get a model function, either from model-module or base-module
 :)
declare function domain:get-model-function(
  $application as xs:string?,
  $model-name as xs:string,
  $action as xs:string,
  $function-arity as xs:integer?,
  $fatal as xs:boolean?
) as xdmp:function? {
  domain:apply-function("get-model-function", $application, $model-name, $action, $function-arity, $fatal)
};

declare function domain:get-model-extension-function(
  $action as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  domain:apply-function("get-model-extension-function", $action, $function-arity)
};

(:~
 : Returns all models for all domains
:)
declare function domain:get-models(
) as element(domain:model)* {
  domain:get-models(domain:get-default-application(), fn:false())
};

(:~
 : Returns all models for a given application including abstract
 : @param $application - Name of the application
 : @param $include-abstract - Determines if to include abstract models.
 :)
declare function domain:get-models(
  $application as xs:string,
  $include-abstract as xs:boolean
) as element(domain:model)* {
  domain:apply-function("get-models", $application, $include-abstract)
};

(:~
 : Returns all in scope permissions associated with a model.
 : @param $model for a given permission set
:)
declare function domain:get-permissions(
  $model as element(domain:model)
) as element(sec:permission)* {
  domain:apply-function("get-permissions", $model)
};

(:~
 : Returns all models that have been descended(@extends) from the given model.
:)
declare function domain:get-descendant-models(
  $parent as element(domain:model)
) {
  domain:apply-function("get-descendant-models", $parent)
};

(:~
 : Returns the query for descendant(@extends) models.
 : @param $model - Model which is the extension model
 :)
declare function domain:get-descendant-model-query(
  $parent as element(domain:model)
) {
  domain:apply-function("get-descendant-model-query", $parent)
};

(:~
 : returns the default language associated with langString field.
 :)
declare function domain:get-default-language(
  $field as element()
) as xs:string {
  domain:apply-function("get-default-language", $field)
};

(:~
 : Returns the languages associated with a given domain field whose type is langString
 :)
declare function domain:get-field-languages(
  $field as element()
) as xs:string* {
  domain:apply-function("get-field-languages", $field)
};

(:~
 : Returns the default sort field for a given model
 : @param $model - Model instance
 :)
declare function domain:get-model-sort-field(
  $model as element(domain:model)
) as element()* {
  domain:apply-function("get-model-sort-field", $model)
};

declare function domain:get-parent-field-attribute(
  $field as element(domain:attribute)
) as element() {
  domain:apply-function("get-parent-field-attribute", $field)
};

declare function domain:get-model-name-from-instance(
  $instance as element()
) as xs:string? {
  domain:apply-function("get-model-name-from-instance", $instance)
};

declare function domain:get-model-from-instance(
  $instance as element()
) as element(domain:model)? {
  domain:apply-function("get-model-from-instance", $instance)
};

declare function domain:find-field-in-model(
  $model as element(domain:model),
  $key as xs:string
) as element()* {
  domain:apply-function("find-field-in-model", $model, $key, ())
};

declare function domain:build-field-xpath-from-model(
  $model as element(domain:model),
  $fields as element()*
) as xs:string* {
  domain:apply-function("build-field-xpath-from-model", $model, $fields)
};

declare function domain:find-field-from-path-model(
  $model as element(domain:model),
  $key as xs:string
) as element()* {
  domain:find-field-from-path-model($model, $key, ())
};

declare function domain:find-field-from-path-model(
  $model as element(domain:model),
  $key as xs:string,
  $accumulator as element()*
) as element()* {
  domain:apply-function("find-field-from-path-model", $model, $key, $accumulator)
};

declare function domain:generate-schema(
  $model as element(domain:model)
) as element()* {
  domain:generate-schema($model, ())
};

declare function domain:generate-schema(
  $model as element(domain:model),
  $options as map:map?
) as element()* {
  domain:apply-function("generate-schema", $model, $options)
};

declare function domain:generate-json-schema(
  $field as element()
) as json:object? {
  domain:generate-json-schema($field, ())
};

declare function domain:generate-json-schema(
  $field as element(),
  $options as map:map?
) as json:object? {
  domain:apply-function("generate-json-schema", $field, $options)
};

declare function domain:spawn-function(
  $function as function(*),
  $options as item()?
) as item()* {
  domain:apply-function("spawn-function", $function, $options)
};
