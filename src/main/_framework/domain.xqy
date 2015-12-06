xquery version "1.0-ml";
(:~
 : Controls all interaction with an application domain.  The domain provides annotations and
 : definitions for dynamic features built into XQuerrail.
 : @version 2.0
 :)
module namespace domain = "http://xquerrail.com/domain";

import module namespace cache = "http://xquerrail.com/cache" at "cache.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace module-loader = "http://xquerrail.com/module" at "module.xqy";

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
  let $modules-map := module-loader:get-modules-map("http://xquerrail.com/domain/", "/domain")
  for $namespace in map:keys($modules-map)
  return
    element module {
      attribute type {"domain"},
      attribute namespace { $namespace },
      attribute location { map:get($modules-map, $namespace) }
    }
};

declare function domain:domain-function(
  $name as xs:string,
  $arity as xs:integer
) as xdmp:function {
  let $key := fn:concat($name,"#",$arity)
  return
  if (map:contains($FUNCTIONS-CACHE, $key)) then
    map:get($FUNCTIONS-CACHE, $key)
  else
    let $function :=
      module-loader:load-function-module(
        domain:get-default-application(),
        "domain",
        $name,
        $arity,
        (),
        ()
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
};

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
  domain:domain-function("cast-value", 2)($field, $value)
};

(:~
 : Returns the cts scalar type for all types.  The default is "string"
:)
declare function domain:get-field-scalar-type(
  $field as element()
) {
  domain:domain-function("get-field-scalar-type", 1)($field)
};

(:~
 : Returns if the value is castable to the given value based on the field/@type
 : @param $field Domain element (element|attribute|container)
 :)
declare function domain:castable-value(
  $field as element(),
  $value as item()?
) {
  domain:domain-function("castable-value", 2)($field, $value)
};

declare function domain:resolve-cts-type(
  $type as xs:string
) {
  domain:domain-function("resolve-cts-type", 1)($type)
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
  domain:domain-function("get-model-cache", 2)($application, $model-name)
};

(:~
 : Sets the cache for a domain model
 :)
declare function domain:set-model-cache(
  $application,
  $model-name,
  $model as element(domain:model)?
) {
  domain:domain-function("set-model-cache", 3)($application, $model-name, $model)
};

(:~
 : Sets a cache for quick lookup on domain model field paths
 :)
declare function domain:set-field-cache(
  $key as xs:string,
  $func as function(*)
) {
  domain:domain-function("set-field-cache", 2)($key, $func)
};

(:~
 : Gets the value of an identity cache from the map
 : @private
 :)
declare function domain:get-identity-cache(
  $key as xs:string
) {
  domain:domain-function("get-identity-cache", 1)($key)
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
  domain:domain-function("set-identity-cache", 2)($key, $value)
};

(:~
 : Returns a cache key unique to a field
 :)
declare function domain:get-field-cache-key(
  $field,
  $prefix as xs:string
) {
  domain:domain-function("get-field-cache-key", 2)($field, $prefix)
};

declare function domain:get-function-cache-key(
  $field as item(),
  $type as xs:string
) as xs:string {
  domain:domain-function("get-function-cache-key", 2)($field, $type)
};

(:~
 : Returns the cache for a given value function
:)
declare function domain:undefined-field-function-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  domain:domain-function("undefined-field-function-cache", 2)($field, $type)
};

(:~
 : Returns the cache for a given value function
:)
declare function domain:exists-field-function-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  domain:domain-function("exists-field-function-cache", 2)($field, $type)
};

(:~
 : Sets the function in the value cache
 :)
declare function domain:set-field-function-cache(
  $field as element(),
  $type as xs:string,
  $funct as function(*)?
) {
  domain:domain-function("set-field-function-cache", 3)($field, $type, $funct)
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function domain:get-field-function-cache(
  $field as element(),
  $type as xs:string
) as function(*)? {
  domain:domain-function("get-field-function-cache", 2)($field, $type)
};


(:~
 : Returns the cache for a given value function
:)
declare function domain:exists-field-value-cache(
  $field as element(),
  $type as xs:string
) as xs:boolean {
  domain:domain-function("exists-field-value-cache", 2)($field, $type)
};

(:~
 : Sets the function in the value cache
 :)
declare function domain:set-field-value-cache(
  $field as element(),
  $type as xs:string,
  $value as item()*
) {
  domain:domain-function("set-field-value-cache", 3)($field, $type, $value)
};

(:~
 : Gets the function for the xxx-path from the cache
:)
declare function domain:get-field-value-cache(
  $field as element(),
  $type as xs:string
) as item() {
  domain:domain-function("get-field-value-cache", 2)($field, $type)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field-name(
  $model as element(domain:model)
) as xs:string {
  domain:domain-function("get-model-identity-field-name", 1)($model)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-identity-field(
  $model as element(domain:model)
) {
  domain:domain-function("get-model-identity-field", 1)($model)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keylabel-field(
  $model as element(domain:model)
) {
  domain:domain-function("get-model-keylabel-field", 1)($model)
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
  domain:domain-function("get-model-identity-query", 2)($model, $value)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-key-field(
  $model as element(domain:model)
) {
  domain:domain-function("get-model-key-field", 1)($model)
};

(:~
 : Returns the field that is the identity key for a given model.
 : @param $model - The model to extract the given identity field
 :)
declare function domain:get-model-keyLabel-field(
  $model as element(domain:model)
) {
  domain:domain-function("get-model-keyLabel-field", 1)($model)
};

declare function domain:get-field-prefix(
  $field as element()
) as xs:string? {
  domain:domain-function("get-field-prefix", 1)($field)
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
  domain:domain-function("get-model-field", 3)($model, $name, $include-container)
};

(:~
 : Returns model fields with unique constraints
 : @param $model - The model that returns all the unique constraint fields
 :)
declare function domain:get-model-unique-constraint-fields(
  $model as element(domain:model)
) {
  domain:domain-function("get-model-unique-constraint-fields", 1)($model)
};

(:~
 : Resolves a domain type to xsi:type
 : @param $model - The model to extract the given identity field
 :)
declare function domain:resolve-datatype(
  $field as element()
) {
  domain:domain-function("resolve-datatype", 1)($field)
};

(:~
 : Resolves the field to its xs:Type equivalent
 : @return - String representing the schema
 :)
declare function domain:resolve-ctstype(
  $field as element()
) {
  domain:domain-function("resolve-ctstype", 1)($field)
};

(:~
 : Returns the default application domain content-namespace-uri
 : @return the content-namespace for the default application
 :)
declare function domain:get-content-namespace-uri(
) as xs:string {
  domain:domain-function("get-content-namespace-uri", 0)()
};

(:~
 : Returns the content-namespace value for a given application
 : @param $application - name of the application
 : @return - The namespace URI of the given application
 :)
declare function domain:get-content-namespace-uri(
  $application as xs:string
) as xs:string {
  domain:domain-function("get-content-namespace-uri", 1)($application)
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
  domain:domain-function("get-controller", 2)($application, $controller-name)
};
(:~
 : Returns the actions associated with the controller. The function assumes the controller lives in the default application.
 : @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-actions(
  $controller-name as xs:string
) {
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
) {
  domain:domain-function("get-controller-actions", 2)($application, $controller-name)
};

(:~
 :  Returns the name of the model associated with a controller.
 :  @param $application - Name of the application
 :  @param $controller-name - Name of the controller
 :)
declare function domain:get-controller-model(
  $controller-name as xs:string
) as element(domain:model)? {
  domain:domain-function("get-controller-model", 1)($controller-name)
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
  domain:domain-function("get-controller-model", 2)($application, $controller-name)
};

(:~
 : Gets the name of the controller associated with a model
 : @param $model-name - name of the model
 : @return The name of the controller
 :)
declare function domain:get-model-controller-name(
  $model-name as xs:string?
) as xs:string* {
  domain:domain-function("get-model-controller-name", 1)($model-name)
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
  domain:domain-function("get-model-controller-name", 2)($application, $model-name)
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
  domain:domain-function("get-domain-model", 3)($application, $model-names, $extension)
};

declare %private function domain:find-model-by-name(
  $domain as element(domain:domain),
  $name as xs:string?
) as element(domain:model)? {
  domain:domain-function("find-model-by-name", 2)($domain, $name)
};

declare function domain:compile-model(
  $application as xs:string,
  $model as element(domain:model)
) as element(domain:model) {
  domain:domain-function("compile-model", 2)($application, $model)
};

declare function domain:navigation(
  $field as element()
) as element(domain:navigation)? {
  domain:domain-function("navigation", 1)($field)
};

declare function domain:validators(
  $model as element(domain:model)
) as element(domain:validator)* {
  domain:domain-function("validators", 1)($model)
};

(:~
  Build model permission
:)
declare function domain:build-model-permission(
  $model as element(domain:model)
) as element(domain:permission)? {
  domain:domain-function("build-model-permission", 1)($model)
};

(:~
  navigation from model, abstract or domain are merged in this order
:)
declare function domain:build-model-navigation(
  $field as element()
) as element(domain:navigation)* {
  domain:domain-function("build-model-navigation", 1)($field)
};

(:~
  Set navigation, permission for all model elements (if not defined will inherit from parent else default is false)
:)
declare function domain:set-model-field-defaults(
  $field as item()
) as item() {
  domain:domain-function("set-model-field-defaults", 1)($field)
};

declare function domain:set-model-field-attributes(
  $field as item()
) as item() {
  domain:domain-function("set-model-field-attributes", 1)($field)
};

declare function domain:set-field-attributes(
  $field as element()
) as attribute()* {
  domain:domain-function("set-field-attributes", 1)($field)
};

declare function domain:model-validation-enabled(
  $model as element(domain:model)
) as xs:boolean {
  domain:domain-function("model-validation-enabled", 1)($model)
};

(:~
 : Returns a list of all defined controllers for a given application domain
 : @param $application - application domain name
 :)
declare function domain:get-controllers(
  $application as xs:string
) as element(domain:controller)* {
  (:domain:domain-function("get-controllers", 1)($application):)
  config:get-domain($application)/domain:controller
};

(:~
 : Returns the default application domain defined in the config.xml
 :)
declare function domain:get-default-application(
) as xs:string {
  (:domain:domain-function("get-default-application", 0)():)
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
  domain:domain-function("get-default-namespace", 1)($application)
};

(:~
 : Returns all content and declare-namespace in application-domain
 : @param $application - Name of the application
 : @return sequence of element(namespace).
 :)
declare function domain:get-domain-namespaces(
  $application as xs:string
) as element(namespace) {
  domain:domain-function("get-domain-namespaces", 1)($application)
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
  domain:domain-function("model-selector", 2)($application, $class)
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
  domain:domain-function("model-fields", 2)($application, $model-name)
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
  domain:domain-function("get-field-name-key", 1)($field)
};

declare function domain:hash(
  $field as node()
) {
  domain:domain-function("hash", 1)($field)
};

(:~
 :  Returns a unique identity key that can used as a unique identifier for the field.
 :  @param $context - is any domain:model field such as (domain:element|domain:attribute|domain:container)
 :  @return The unique identifier representing the field
 :)
declare function domain:get-field-id(
  $field as node()
) {
  domain:domain-function("get-field-id", 1)($field)
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
  domain:domain-function("get-field-namespace", 1)($field)
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
  domain:domain-function("get-field-param-value", 4)($field, $params, $relative, $cast)
};

declare function domain:get-field-param-match-key(
  $field as element(),
  $params as map:map
) {
  domain:domain-function("get-field-param-match-key", 2)($field, $params)
};

declare function domain:get-field-param-langString-value(
  $field as element(),
  $params as map:map
) as rdf:langString? {
  domain:domain-function("get-field-param-langString-value", 2)($field, $params)
};

declare function domain:get-field-param-triple-value(
  $field as element(),
  $params as map:map
) as element(sem:triple)? {
  domain:domain-function("get-field-param-triple-value", 2)($field, $params)
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
  domain:domain-function("get-field-reference", 2)($field, $current-node)
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
  domain:domain-function("get-field-reference-model", 1)($field)
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
  domain:domain-function("get-field-xpath", 2)($field, $relative)
};

(:~
 : Returns the xpath expression for a given field by its id/name key
 : The xpath expression is relative to the root of the parent element
 : @param $field - instance of a field
 :)
declare function domain:get-field-absolute-xpath(
  $field as element()
) {
  domain:domain-function("get-field-absolute-xpath", 1)($field)
};

declare function domain:get-field-qname(
  $field as element()
) {
  domain:domain-function("get-field-qname", 1)($field)
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
  domain:domain-function("build-value-map", 2)($doc, $retain)
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
  domain:domain-function("recurse", 3)($node, $map, $retain)
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
  domain:domain-function("get-model-controller", 3)($application, $model-name, $checked)
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
  domain:domain-function("get-optionlist", 2)($application, $listname)
};

(:~
 : Returns an optionlist associated with a field definitions inList attribute.
 : @param $field  Field instance (domain:element|domain:attribute)
 : @return optionlist specified by field.
 :)
declare function domain:get-field-optionlist(
  $field
) {
  domain:domain-function("get-field-optionlist", 1)($field)
};
(:~
 : Gets an application element specified by the application name
 : @param $application Name of the application
 :)
declare function domain:get-application(
  $application as xs:string
) {
  domain:domain-function("get-application", 1)($application)
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
  domain:domain-function("get-model-reference-key", 1)($model)
};
(:~
 : Gets a list of domain models that reference a given model.
 : @param $model - The domain model instance.
 : @return a sequence of domain:model elements
 :)
declare function domain:get-model-references(
  $model as element(domain:model)
) {
  domain:domain-function("get-model-references", 1)($model)
};

declare function domain:get-models-reference-query(
  $model as element(domain:model),
  $instance as item()
) as cts:or-query {
  domain:domain-function("get-models-reference-query", 2)($model, $instance)
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
  domain:domain-function("is-model-referenced", 2)($model, $instance)
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
  domain:domain-function("get-model-reference-uris", 2)($model, $instance)
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
  domain:domain-function("get-model-reference-query", 3)($reference-model, $reference-key, $reference-value)
};

(:~
 : Returns the default collation for the given field. The function walks up the ancestor tree to find the collation in the following order:
 : $field/@collation->$field/model/@collation->$domain/domain:default-collation.
 : @param $field - the field to find the collation by.
 :)
declare function domain:get-field-collation(
  $field as element()
) as xs:string {
  domain:domain-function("get-field-collation", 1)($field)
};

(:~
 : Returns the list of fields that are part of the uniqueKey constraint as defined by the $model/@uniqueKey attribute.
 : @param $model - Model that defines the unique constraint.
 :)
declare function domain:get-model-uniqueKey-constraint-fields(
  $model as element(domain:model)
) {
  domain:domain-function("get-model-uniqueKey-constraint-fields", 1)($model)
};

(:~
 : Returns a unique constraint query
 :)
declare function domain:get-model-uniqueKey-constraint-query(
  $model as element(domain:model),
  $params as item(),
  $mode as xs:string
) {
  domain:domain-function("get-model-uniqueKey-constraint-query", 3)($model, $params, $mode)
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
  domain:domain-function("get-model-unique-constraint-query", 3)($model, $params, $mode)
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
  domain:domain-function("get-model-search-expression", 3)($model, $query, $options)
};

(:~
 : Returns a cts query that returns a cts:query which matches a node against its value.
:)
declare function domain:get-identity-query(
  $model as element(domain:model),
  $params as item()
) {
  domain:domain-function("get-identity-query", 2)($model, $params)
};

declare function domain:get-keylabel-query(
  $model as element(domain:model),
  $params as item()
) {
  domain:domain-function("get-keylabel-query", 2)($model, $params)
};

(:~
 : Returns the base query for a given model
 : @param $model  name of the model for the given base-query
 :)
declare function domain:get-base-query(
  $model as element(domain:model)
) {
  domain:domain-function("get-base-query", 1)($model)
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
  domain:domain-function("get-model-estimate-expression", 3)($model, $query, $options)
};

(:~
 : Creates a root term query that can be used in combination to specify the root.
:)
declare function domain:model-root-query(
  $model as element(domain:model)
) {
  domain:domain-function("model-root-query", 1)($model)
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
  domain:domain-function("get-field-query", 3)($field, $value, $options)
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
  domain:domain-function("get-field-tuple-reference", 2)($field, $add-options)
};

(:~
 : Return as list of all prefixes and their respective namespaces
:)
declare function domain:declared-namespaces(
  $model as element()
) as xs:string* {
  domain:domain-function("declared-namespaces", 1)($model)
};

declare function domain:declared-namespaces-map(
  $model as element()
) {
  domain:domain-function("declared-namespaces-map", 1)($model)
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
  domain:domain-function("invoke-events", 4)($model, $events, $updated-values, $old-values)
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
  domain:domain-function("fire-before-event", 4)($model, $event-name, $updated-values, $old-values)
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
  domain:domain-function("fire-after-event", 4)($model, $event-name, $updated-values, $old-values)
};

declare function domain:get-field-json-name(
  $field as element()
) as xs:string {
  domain:domain-function("get-field-json-name", 1)($field)
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
  domain:domain-function("get-field-jsonpath", 3)($field, $include-root, $base-path)
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
  domain:domain-function("get-field-value", 3)($field, $value, $relative)
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
  domain:domain-function("get-field-value-node", 3)($field, $value, $relative)
};

declare function domain:field-value-exists(
  $field as element(),
  $value as item()*
) as xs:boolean {
  domain:domain-function("field-value-exists", 2)($field, $value)
};

declare function domain:field-param-exists(
  $field as element(),
  $params as map:map
) as xs:boolean {
  domain:domain-function("field-param-exists", 2)($field, $params)
};

declare function domain:field-json-exists(
  $field as element(),
  $values as item()?
) as xs:boolean {
  domain:domain-function("field-json-exists", 2)($field, $values)
};

declare function domain:field-xml-exists(
  $field as element(),
  $value as item()*
) as xs:boolean {
  domain:domain-function("field-xml-exists", 2)($field, $value)
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
  domain:domain-function("get-field-json-value", 3)($field, $values, $relative)
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
  domain:domain-function("get-field-xml-value", 3)($field, $value, $relative)
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
  domain:domain-function("get-base-type", 2)($field, $safe)
};

(:~
 : Returns true if the field is multivalue or occurrence allows for more than 1 value.
 :)
declare function domain:field-is-multivalue(
  $field
) {
  domain:domain-function("field-is-multivalue", 1)($field)
};

(:~
 : Returns the passed in value type and its expecting source values
:)
declare function domain:get-value-type(
  $type as item()?
) {
  domain:domain-function("get-value-type", 1)($type)
};
(:~
 : Returns the value of collections given any object type
 :)
declare function domain:get-field-value-collections(
  $value
) {
  domain:domain-function("get-field-value-collections", 1)($value)
};

(:~
 : Returns the key for a given parameter by its name
 :)
declare function domain:get-param-keys(
  $params as item()
) {
  domain:domain-function("get-param-keys", 1)($params)
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
  domain:domain-function("get-param-value", 3)($params, $key, $default)
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
  domain:domain-function("model-exists", 2)($application, $model-name)
};

(:~
 : Returns whether the module exists or not.
 :)
declare function domain:module-exists(
  $module-location as xs:string
) as xs:boolean {
  domain:domain-function("module-exists", 1)($module-location)
};

declare function domain:get-function-key(
  $module-namespace as xs:string,
  $module-location as xs:string,
  $function-name as xs:string,
  $function-arity as xs:integer
) as element() {
  domain:domain-function("get-function-key", 4)($module-namespace, $module-location, $function-name, $function-arity)
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
  domain:domain-function("get-module-function", 6)($application, $module-type, $module-namespace, $module-location, $function-name, $function-arity)
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
  domain:domain-function("get-model-module-function", 4)($application, $model-name, $action, $function-arity)
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
  domain:domain-function("get-model-base-function", 2)($action, $function-arity)
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
  domain:domain-function("get-model-function", 5)($application, $model-name, $action, $function-arity, $fatal)
};

declare function domain:get-model-extension-function(
  $action as xs:string,
  $function-arity as xs:integer?
) as xdmp:function? {
  domain:domain-function("get-model-extension-function", 2)($action, $function-arity)
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
  domain:domain-function("get-models", 2)($application, $include-abstract)
};

(:~
 : Returns all in scope permissions associated with a model.
 : @param $model for a given permission set
:)
declare function domain:get-permissions(
  $model as element(domain:model)
) {
  domain:domain-function("get-permissions", 1)($model)
};

(:~
 : Returns all models that have been descended(@extends) from the given model.
:)
declare function domain:get-descendant-models(
  $parent as element(domain:model)
) {
  domain:domain-function("get-descendant-models", 1)($parent)
};

(:~
 : Returns the query for descendant(@extends) models.
 : @param $model - Model which is the extension model
 :)
declare function domain:get-descendant-model-query(
  $parent as element(domain:model)
) {
  domain:domain-function("get-descendant-model-query", 1)($parent)
};

(:~
 : returns the default language associated with langString field.
 :)
declare function domain:get-default-language(
  $field as element()
) {
  domain:domain-function("get-default-language", 1)($field)
};

(:~
 : Returns the languages associated with a given domain field whose type is langString
 :)
declare function domain:get-field-languages(
  $field as element()
) {
  domain:domain-function("get-field-languages", 1)($field)
};

(:~
 : Returns the default sort field for a given model
 : @param $model - Model instance
 :)
declare function domain:get-model-sort-field(
  $model as element(domain:model)
) as element()* {
  domain:domain-function("get-model-sort-field", 1)($model)
};

declare function domain:get-parent-field-attribute(
  $field as element(domain:attribute)
) as element() {
  domain:domain-function("get-parent-field-attribute", 1)($field)
};

declare function domain:get-model-name-from-instance(
  $instance as element()
) as xs:string? {
  domain:domain-function("get-model-name-from-instance", 1)($instance)
};

declare function domain:get-model-from-instance(
  $instance as element()
) as element(domain:model)? {
  domain:domain-function("get-model-from-instance", 1)($instance)
};

declare function domain:find-field-in-model(
  $model as element(domain:model),
  $key as xs:string
) as element()* {
  domain:domain-function("find-field-in-model", 3)($model, $key, ())
};

declare function domain:build-field-xpath-from-model(
  $model as element(domain:model),
  $fields as element()*
) as xs:string* {
  domain:domain-function("build-field-xpath-from-model", 2)($model, $fields)
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
  domain:domain-function("find-field-from-path-model", 3)($model, $key, $accumulator)
};

declare function domain:generate-schema(
  $model as element(domain:model)
) as element()* {
  domain:domain-function("generate-schema", 1)($model)
};

