xquery version "1.0-ml";
(:~
: Model : Base
: @author Gary Vidal
: @version  1.0
 :)

module namespace model = "http://xquerrail.com/model/base";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

import module namespace context = "http://xquerrail.com/context" at "../context.xqy";

import module namespace cache = "http://xquerrail.com/cache" at "../cache.xqy";

import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";

import module namespace config = "http://xquerrail.com/config" at "../config.xqy";

import module namespace module = "http://xquerrail.com/module" at "../module.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-doc-2007-01.xqy";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace as = "http://www.w3.org/2005/xpath-functions";

declare default collation "http://marklogic.com/collation/codepoint";

(:Options Definition:)
declare option xdmp:mapping "false";

declare variable $HAS-URI-PREDICATE := "hasUri";
declare variable $HAS-TYPE-PREDICATE := "hasType";

declare variable $DEFAULT-PAGE-SIZE := 20;
declare variable $EXPANDO-PATTERN := "\$\((\i\c*(/@?\i\c*)*)\)";

declare %config:module-location function model:module-location(
) as element(module)* {
  let $modules-map := module:get-modules-map("http://xquerrail.com/model/base/", fn:concat("/base/base", config:model-suffix()))
  return (
    element module {
      attribute type {"base-model"},
      attribute namespace { "http://xquerrail.com/model/base" },
      attribute location { module:normalize-uri((config:framework-path(), "/base/base-model.xqy")) },
      attribute interface { fn:true() }
    },
    for $namespace in map:keys($modules-map)
    return
      element module {
        attribute type {"base-model"},
        attribute namespace { $namespace },
        attribute location { map:get($modules-map, $namespace) },
        attribute interface { fn:false() }
      }
  )
};

declare function model:apply-function(
  $name as xs:string
) {
  module:apply-function-module("base-model", $name)
};

declare function model:apply-function(
  $name as xs:string,
  $argument-1 as item()*
) {
  module:apply-function-module("base-model", $name, $argument-1)
};

declare function model:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*
) {
  module:apply-function-module("base-model", $name, $argument-1, $argument-2)
};

declare function model:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*
) {
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3)
};

declare function model:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*
) {
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3, $argument-4)
};

declare function model:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*
) {
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5)
};

declare function model:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*
) {
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6)
};

declare function model:apply-function(
  $name as xs:string,
  $argument-1 as item()*,
  $argument-2 as item()*,
  $argument-3 as item()*,
  $argument-4 as item()*,
  $argument-5 as item()*,
  $argument-6 as item()*,
  $argument-7 as item()*
) {
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7)
};

declare function model:apply-function(
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
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8)
};

declare function model:apply-function(
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
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9)
};

declare function model:apply-function(
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
  module:apply-function-module("base-model", $name, $argument-1, $argument-2, $argument-3, $argument-4, $argument-5, $argument-6, $argument-7, $argument-8, $argument-9, $argument-10)
};

(:declare function model:model-function(
  $name as xs:string,
  $arity as xs:integer
) as xdmp:function {
  let $function :=
    module:load-function-module(
      (),
      "base-model",
      $name,
      $arity,
      (),
      (),
      fn:false()
    )
  return
    if (fn:empty($function)) then
      fn:error(xs:QName("LOAD-FUNCTION-MODULE-ERROR"), text{"Function", $name, "from base-model module type not found."})
    else
      $function
};:)

declare function model:uuid-string(
) as xs:string {
  model:uuid-string(xdmp:random())
};

declare function model:uuid-string(
  $seed as xs:integer?
) as xs:string {
  model:apply-function("uuid-string", $seed)
};

(:~
 : Returns the current-identity field for use when instance does not have an existing identity
 :)
declare function  model:get-identity(
) {
  model:apply-function("get-identity")
};

(:~
 : Generates a UUID based on the SHA1 algorithm.
 : Wallclock will be used to make the UUIDs sortable.
 : Note when calling function the call will reset the current-identity.
 :)
declare function model:generate-uuid(
  $seed as xs:integer?
) as xs:string {
  model:apply-function("generate-uuid", $seed)
};

(:~
 :  Generates a UUID based on randomization function
 :)
declare function model:generate-uuid(
) as xs:string {
  model:apply-function("generate-uuid")
};

(:~
 : Creates an ID for an element using fn:generate-id.   This corresponds to the config:identity-scheme
 :)
declare function model:generate-fnid($instance as item()) {
  model:apply-function("generate-fnid", $instance)
};

(:~
 : Creates a sequential id from a seed that monotonically increases on each call.
 : This is not a performant id pattern as randomly generated one.
~:)
declare function model:generate-sequenceid($seed as xs:integer) {
  model:apply-function("generate-sequenceid", $seed)
};

(:~
 :  Builds an IRI from a string value if the value is curied, then the iri is expanded to its canonical iri
 :  @param $uri - Uri to format. Variables should be in form $(var-name)
 :  @param $model -  Model to use for reference
 :  @param $instance - Instance of asset can be map or instance of element from domain
 :)
declare function model:generate-iri(
  $uri as xs:string?,
  $field as element(),
  $instance as item()
) {
  model:apply-function("generate-iri", $uri, $field, $instance)
};

(:~
 :  Builds a URI with variable placeholders
 :  @param $uri - Uri to format. Variables should be in form $(var-name)
 :  @param $model -  Model to use for reference
 :  @param $instance - Instance of asset can be map or instance of element from domain
 :)
declare function model:generate-uri(
  $uri as xs:string,
  $model as element(domain:model),
  $instance as item()
) {
  model:apply-function("generate-uri", $uri, $model, $instance)
};

declare function model:node-uri(
  $context as element(),
  $current as item()*,
  $updates as item()*
) as xs:string? {
  model:apply-function("node-uri", $context, $current, $updates)
};

(:~
 : Creates a series of collections based on the existing update
 :)
declare function build-collections(
  $collections as xs:string*,
  $model as element(domain:model),
  $instance as item()
) {
  model:apply-function("build-collections", $collections, $model, $instance)
};

(:~
: This function accepts a doc node and converts to an element node and
: returns the first element node of the document
: @param - $doc - the doc
: @return - the root as a node
:)
declare function model:get-root-node(
  $model as element(domain:model),
  $doc as node()
) as node() {
  model:apply-function("get-root-node", $model, $doc)
};

(:~
: This function checks the parameters for an identifier that signifies the instance of a model
: @param - $model - domain model of the content
: @param - $params - parameters of content that pertain to the domain model
: @return a identity or uuid value (repsective) for identifying the model instance
:)
declare function model:get-id-from-params(
  $model as element(domain:model),
  $params as item()*
) as xs:string? {
  model:apply-function("get-id-from-params", $model, $params)
};

(:~
 : Gets only the params for a given model
 : @param - $model - is the model for the given params
 : @param - $params - parameters of content that pertain to the domain model
 : @param - $strict - boolean value on whether to be strict or not
 : @deprecated
 :)
declare function model:get-model-params(
  $model as element(domain:model),
  $params as map:map,
  $strict as xs:boolean
) {
  fn:error(xs:QName("DEPRECATED"), "Function is deprecated")
};

(:~
 :  Creates a new instance of an asset and returns that instance but does not persist in database
 :)
declare function model:new(
  $model as element(domain:model)
) {
  model:new($model, map:map())
};

(:~
 :  Creates a new instance of a model but does not persisted.
 :)
declare function model:new(
  $model as element(domain:model),
  $params as item()
) {
  model:apply-function("new", $model, $params)
};

(:~
 : Creates any binary nodes associated with model instance
 :)
declare function model:create-binary-dependencies(
  $identity as xs:string,
  $instance as element()
) {
  model:create-binary-dependencies($identity, $instance, xdmp:default-permissions(), xdmp:default-collections())
};

(:~
 :  Inserts any binary dependencies created from binary|file type elements
 :)
declare function model:create-binary-dependencies(
  $identity as xs:string,
  $instance as element(),
  $permissions as element(sec:permission)*,
  $collections as xs:string*
) {
  model:apply-function("create-binary-dependencies", $identity, $instance, $permissions, $collections)
};

(:~
 : Caches reference from a created instance so a reference can be formed without a seperate transaction
 :)
declare function model:create-reference-cache(
  $model as element(domain:model),
  $instance
) {
  model:apply-function("create-reference-cache", $model, $instance)
};

(:~
 : Creates a model for a given domain
 : @param - $model - is the model for the given params
 : @param - $params - parameters of content that pertain to the domain model
 : @returns element
 :)
declare function model:create(
  $model as element(domain:model),
  $params as item()
) as element()? {
  model:create($model, $params, xdmp:default-collections())
};

(:~
 : Creates a model for a given domain
 : @param - $model - is the model for the given params
 : @param - $params - parameters of content that pertain to the domain model
 : @returns element
 :)
declare function model:create(
  $model as element(domain:model),
  $params as item(),
  $collections as xs:string*
) as element()? {
  model:create($model, $params, $collections, xdmp:default-permissions())
};

(:~
 : Creates a model for a given domain
 : @param - $model - is the model for the given params
 : @param - $params - parameters of content that pertain to the domain model
 : @returns element
 :)
declare function model:create(
  $model as element(domain:model),
  $params as item()*,
  $collections as xs:string*,
  $permissions as element(sec:permission)*
) as element()? {
  model:apply-function("create", $model, $params, $collections, $permissions)
};

(:~
 : Returns if the passed in _query param will return a model exists
 :)
declare function model:exists(
  $model as element(domain:model),
  $params as item()
) as xs:boolean {
  model:apply-function("exists", $model, $params)
};

(:~
: Retrieves a model document by id
: @param $model the model of the document
: @param $params the values to pull the id from
: @return the document
 :)
declare function model:get(
  $model as element(domain:model),
  $params as item()
) as element()? {
  model:apply-function("get", $model, $params)
};

(:~
: Retrieves a model document by id
: @param $model the model of the document
: @param $params the values to pull the id from
: @return the document
 :)
declare function model:reference-by-keylabel(
  $model as element(domain:model),
  $params as item()
) as element()? {
  model:apply-function("reference-by-keylabel", $model, $params)
};

declare function model:update-partial(
  $model as element(domain:model),
  $params as item()
) {
  model:update-partial($model, $params, xdmp:default-collections())
};
(:~
 : Creates an partial update statement for a given model.
 :)
declare function model:update-partial(
  $model as element(domain:model),
  $params as item(),
  $collections as xs:string*
) {
  model:apply-function("update-partial", $model, $params, $collections)
};

(: %private? :)
declare function model:parse-patch-path(
  $path as xs:string
) {
  model:apply-function("parse-patch-path", $path)
};

declare function model:patch(
  $model as element(domain:model),
  $instance as element(),
  $params as item()*
) {
  model:apply-function("patch", $model, $instance, $params)
};

(:~
 : Overloaded method to support existing controller functions for adding collections
 :)
declare function model:update(
  $model as element(domain:model),
  $params as item()
) {
  model:update($model, $params, xdmp:default-collections())
};

(:~
 : Overloaded method to support existing controller functions for adding collections and partial update
 :)
declare function model:update(
  $model as element(domain:model),
  $params as item(),
  $collections as xs:string*
) {
  model:update($model, $params, $collections, fn:false())
};


(:~
 : Creates an update statement for a given model.
 : @param $model - domain element for the given update
 : @param $params - List of update parameters for a given update, the uuid element must be present in the document
 : @param $collections - Additional collections to add to document
 : @param $partial - if the update should pull the values of the current-node if no params key is present
 :)
declare function model:update(
  $model as element(domain:model),
  $params as item(),
  $collections as xs:string*,
  $partial as xs:boolean
) as element() {
  model:apply-function("update", $model, $params, $collections, $partial)
};

declare function model:create-or-update(
  $model as element(domain:model),
  $params as item()
) {
  model:apply-function("create-or-update", $model, $params)
};

(:~
 :  Returns all namespaces from domain:model and inherited from domain
 :)
declare function model:get-namespaces(
  $model as element(domain:model)
) {
  model:apply-function("get-namespaces", $model)
};

(:~
 :  Function allows for partial updates
 :)
declare function model:recursive-update-partial(
  $context as element(),
  $current as node()?,
  $updates as map:map
) {
  model:apply-function("recursive-update-partial", $context, $current, $updates)
};

(:~
 :  Entry for recursive updates
 :)
declare function model:recursive-create(
  $model as element(domain:model),
  $updates as item()?
) {
  model:recursive-create($model, (), $updates, fn:false())
};

declare function model:recursive-create(
  $model as element(domain:model),
  $current as node()?,
  $updates as item()?,
  $partial as xs:boolean
) {
  model:apply-function("recursive-create", $model, $current, $updates, $partial)
};

(:~
 :
 :)
declare function model:recursive-update(
  $context as node(),
  $current as node(),
  $updates as item()?,
  $partial as xs:boolean
) {
  fn:error(xs:QName("DEPRECATED"),"Function is deprecated. Use model:recursive-create")
};

(:~
 :
 :)
declare function model:recursive-update(
  $context as node(),
  $current as node()?,
  $updates as item()?
) {
  fn:error(xs:QName("DEPRECATED"),"Function is deprecated. Use model:recursive-create")
};

declare function model:recursive-build(
  $context as node(),
  $current as node()?,
  $updates as item()?
) {
  model:recursive-build($context, $current, $updates, fn:false())
};

(:~
 :  Recurses the field structure and builds up a document
 :)
declare function model:recursive-build(
  $context as node(),
  $current as node()?,
  $updates as item()?,
  $partial as xs:boolean
) {
  model:apply-function("recursive-build", $context, $current, $updates, $partial)
};

(:declare function model:add-triples(
  $model as element(domain:model),
  $current as node()?,
  $updates as node()
) {
  model:apply-function("add-triples", $model, $current, $updates)
};:)

declare function model:triple-identity-value(
  $context as element(),
  $current as item(),
  $updates as item()*
) {
  model:apply-function("triple-identity-value", $context, $current, $updates)
};

(:declare function model:build-triples(
  $model as element(domain:model),
  $current as node()?,
  $updates as item()
) as element(sem:triples) {
  model:apply-function("build-triples", $model, $current, $updates)
};:)

declare function model:get-triple-identity(
  $model as element(domain:model),
  $params as item()?
) as xs:string? {
  model:apply-function("get-triple-identity", $model, $params)
};

declare function model:build-element(
  $context as node(),
  $current as node()?,
  $updates as item(),
  $partial as xs:boolean
) {
  model:apply-function("build-element", $context, $current, $updates, $partial)
};

(:~
 : Internal Attribute Builder
~:)
declare function model:build-attribute(
  $context as node(),
  $current as node()?,
  $updates as item(),
  $partial as xs:boolean,
  $relative as xs:boolean
) as attribute()? {
  model:apply-function("build-attribute", $context, $current, $updates, $partial, $relative)
};
(:~
 : Builds a Reference Value by its type
 :)
declare function model:build-reference(
  $context as node(),
  $current as node()?,
  $updates as item()*,
  $partial as xs:boolean
) {
  model:apply-function("build-reference", $context, $current, $updates, $partial)
};

declare function model:build-schema-element(
  $context as node(),
  $current as node()?,
  $updates as item()*,
  $partial as xs:boolean
) as element() {
  model:apply-function("build-schema-element", $context, $current, $updates, $partial)
};

(:~
 : Creates a binary instance
:)
declare function model:build-binary(
  $context as node(),
  $current as node()?,
  $updates as item(),
  $partial as xs:boolean
) {
  model:apply-function("build-binary", $context, $current, $updates, $partial)
};

(:~
 : Builds an instance of an object from a model
 :)
declare function model:build-instance(
  $context as node(),
  $current as node()?,
  $updates as item()?,
  $partial as xs:boolean
) {
  model:apply-function("build-instance", $context, $current, $updates, $partial)
};

declare function model:build-langString(
  $context as node(),
  $current as node()?,
  $updates as item()*,
  $partial as xs:boolean
) {
  model:apply-function("build-langString", $context, $current, $updates, $partial)
};

declare function model:build-triple-subject(
  $field as element(),
  $params as item()*,
  $value as item()
) as element(sem:subject) {
  model:apply-function("build-triple-subject", $field, $params, $value)
};

declare function model:build-triple-predicate(
  $field as element(),
  $params as item()*,
  $value as item()
) as element(sem:predicate) {
  model:apply-function("build-triple-predicate", $field, $params, $value)
};

declare function model:build-triple-object(
  $field as element(),
  $params as item()*,
  $value as item()
) as element(sem:object) {
  model:apply-function("build-triple-object", $field, $params, $value)
};

declare function model:build-triple-graph(
  $field as element(),
  $params as item()*,
  $value as item()
) as element(sem:graph) {
  model:apply-function("build-triple-graph", $field, $params, $value)
};

declare function model:get-model-expression(
  $model as element(domain:model),
  $expression as element(domain:expression),
  $arity as xs:integer
) as xdmp:function? {
  model:apply-function("get-model-expression", $model, $expression, $arity)
};

(:~
 : Creates a triple based on an IRI Pattern
 :)
declare function model:build-triple(
  $context as node(),
  $current as node()?,
  $updates as item()*,
  $partial as xs:boolean
) as element(sem:triple)* {
  model:apply-function("build-triple", $context, $current, $updates, $partial)
};

(:~
 : Deletes the model document
 : @param $model the model of the document and any external binary files
 : @param $params the values to fill into the element
 : @return xs:boolean denoted whether delete occurred
~:)
declare function model:delete(
  $model as element(domain:model),
  $params as item()
) {
  model:apply-function("delete", $model, $params)
};

(:~
 : Deletes any binaries defined by instance
 :)
declare function model:delete-binary-dependencies(
  $model as element(domain:model),
  $current as element()
) as empty-sequence() {
  model:apply-function("delete-binary-dependencies", $model, $current)
};

(:~
 :  Returns the lookup
 :)
declare function model:lookup(
  $model as element(domain:model),
  $params as item()
) as element(lookups)? {
  model:apply-function("lookup", $model, $params)
};

(:~Recursively Removes elements based on @listable = true :)
declare function model:filter-list-result(
  $field as element(),
  $result,
  $params as item()
) {
  model:apply-function("filter-list-result", $field, $result, $params)
};

(:~
: Returns a list of packageType
: @return  element(packageType)*
:)
declare function model:list(
  $model as element(domain:model),
  $params as item()
) as element(list)? {
  model:list($model, $params, ())
};

declare function model:list(
  $model as element(domain:model),
  $params as item(),
  $filter-function as function(*)?
) as element(list)? {
  model:apply-function("list", $model, $params, $filter-function)
};

declare function model:render-list(
  $model as element(domain:model),
  $list as xs:string,
  $params as item()*
) as element() {
  model:render-list($model, $list, $params, ())
};

(: Function responsible to render a list :)
declare function model:render-list(
  $model as element(domain:model),
  $list as xs:string,
  $params as item()*,
  $filter-function as function(*)?
) as element() {
  model:apply-function("render-list", $model, $list, $params, $filter-function)
};

(:~
 : Converts Search Parameters to cts search construct for list;
 :)
declare function model:list-params(
  $model as element(domain:model),
  $params as item()
) {
  model:apply-function("list-params", $model, $params)
};

declare function model:page-size(
  $model as element(domain:model),
  $params,
  $param-name as xs:string?
) as xs:unsignedLong? {
  model:apply-function("page-size", $model, $params, $param-name)
};

declare function model:sort-field(
  $model as element(domain:model),
  $params,
  $param-name as xs:string?
) as xs:string? {
  model:apply-function("sort-field", $model, $params, $param-name)
};

declare function model:sort-order(
  $model as element(domain:model),
  $params,
  $param-name as xs:string?
) as xs:string? {
  model:apply-function("sort-order", $model, $params, $param-name)
};

(: sorting function support dotted notation for $field-param-name and $order-param-name :)
declare function model:sorting(
  $model as element(domain:model),
  $params,
  $field-param-name as xs:string*,
  $order-param-name as xs:string*
) as element(sort)? {
  model:apply-function("sorting", $model, $params, $field-param-name, $order-param-name)
};

(:~
 : Converts a list operator to its cts:* equivalent
 :)
declare function model:operator-to-cts(
  $field as element(),
  $op as xs:string,
  $value as item()?
) {
  model:operator-to-cts($field, $op, $value, fn:false())
};

(:~
 : Converts a list operator to its cts:equivalent
 :)
declare function model:operator-to-cts(
  $field as element(),
  $op as xs:string,
  $value as item()?,
  $ranged as xs:boolean
) {
  model:apply-function("operator-to-cts", $field, $op, $value, $ranged)
};

declare function model:build-search-options(
  $model as element(domain:model)
) as element(search:options) {
  model:build-search-options($model, map:map())
};

(:~
 : Build search options for a given domain model
 : @param $model the model of the content type
 : @return search options for the given model
 :)
declare function model:build-search-options(
  $model as element(domain:model),
  $params as item()
) as element(search:options) {
  model:apply-function("build-search-options", $model, $params)
};

declare function model:build-search-constraints(
  $field as element()
) {
  model:build-search-constraints($field, map:new())
};

declare function model:build-search-constraints(
  $field as element(),
  $params as item()
) {
  model:build-search-constraints($field, $params, ())
};

declare function model:build-search-constraints(
  $field as element(),
  $params as item(),
  $prefix as xs:string*
) {
  model:apply-function("build-search-constraints", $field, $params, $prefix)
};

declare function model:build-search-element(
  $field as element()
) as element()* {
  model:build-search-element($field, ())
};

declare function model:build-search-element(
  $field as element(),
  $name as xs:string?
) as element()* {
  model:apply-function("build-search-element", $field, $name)
};

declare function model:search-sort-state(
  $field as element(),
  $order as xs:string?
) as xs:string {
  model:search-sort-state($field, (), $order)
};

declare function model:search-sort-state(
  $field as element(),
  $prefix as xs:string*,
  $order as xs:string?
) as xs:string {
  model:apply-function("search-sort-state", $field, $prefix, $order)
};

declare function model:build-sort-element(
  $field as element(),
  $name as xs:string*
) as element()* {
  model:apply-function("build-sort-element", $field, $name)
};

declare function model:build-search-query(
  $model as element(domain:model),
  $params as item()
) {
  model:build-search-query($model, $params, ())
};

declare function model:build-search-query(
  $model as element(domain:model),
  $params as item(),
  $output as xs:string?
) {
  model:apply-function("build-search-query", $model, $params, $output)
};

(:~
 : Provide search interface for the model
 : @param $model the model of the content type
 : @param $params the values to fill into the search
 : @return search response element
 :)
declare function model:search(
  $model as element(domain:model),
  $params as item()
) as element(search:response) {
  model:apply-function("search", $model, $params)
};

(:~
 : Provide search:suggest interface for the model
 : @param $model the model of the content type
 : @param $params the values to fill into the search
 : @return search response element
 :)
declare function model:suggest(
  $model as element(domain:model),
  $params as item()
) as xs:string* {
  model:apply-function("suggest", $model, $params)
};

(:~
 :  returns a reference given an id or field value.
 :)
declare function model:get-references(
  $field as element(),
  $params as item()*
) {
  model:apply-function("get-references", $field, $params)
};

declare function model:get-function-cache(
  $function as function(*)?
) {
  model:apply-function("get-function-cache", $function)
};

(:~
 : This function will call the appropriate reference type model to build
 : a relationship between two models types.
 : @param $reference is the reference element that is used to contain the references
 : @param $params the params items to build the relationship
 :)
declare function model:get-model-references(
  $reference as element(domain:element),
  $params as item()*
) as element()* {
  model:apply-function("get-model-references", $reference, $params)
};

(:~
  : Returns a reference to a given controller
 ~:)
declare function model:get-controller-reference(
  $reference as element(domain:element),
  $params as item()
) {
  model:apply-function("get-controller-reference", $reference, $params)
};


 (:~
  : Returns a reference from an optionlist
 ~:)
declare function model:get-optionlist-reference(
  $reference as element(domain:element),
  $params as item()
) {
  model:apply-function("get-optionlist-reference", $reference, $params)
};

(:~~:)
declare function model:get-extension-reference(
  $reference as element(domain:element),
  $params as item()
) {
  model:apply-function("get-extension-reference", $reference, $params)
};

declare function model:set-cache-reference(
  $model as element(domain:model),
  $keys as xs:string*,
  $values as item()*
) {
  model:apply-function("set-cache-reference", $model, $keys, $values)
};

declare function model:get-cache-reference(
  $model as element(domain:model),
  $keys as xs:string
) {
  model:apply-function("get-cache-reference", $model, $keys)
};

declare function model:reference(
  $context as element(),
  $model as element(domain:model),
  $params as item()*
) as element()? {
  model:apply-function("reference", $context, $model, $params)
};

(:~
 : This function will create a reference of an existing element
 : @node-name reference element attribute name
 : @param $ids a sequence of ids for models to be extracted
 : @return a sequence of packageType
 :)
declare function model:instance(
  $context as element(),
  $model as element(domain:model),
  $params as item()*
) {
  model:apply-function("instance", $context, $model, $params)
};

(:~
 :
 :)
declare function model:get-application-reference(
  $field as element(),
  $params as item()*
) {
  model:apply-function("get-application-reference", $field, $params)
};

 (:~
  : Returns the reference from an application
  :)
declare  function model:get-application-reference-values(
  $field
) {
  model:apply-function("get-application-reference-values", $field)
};

(:~
: This is a function that will validate the params with the domain model
: @param domain-model the model to validate against
: @param $params the params to validate
: @return return a set of validation errors if any occur.
 :)
declare function model:validate-params(
  $model as element(domain:model),
  $params as item()*,
  $mode as xs:string
) as empty-sequence() {
  model:apply-function("validate-params", $model, $params, $mode)
};

declare function model:validation-errors(
  $error as element(error:error)
) as element (validationErrors)? {
  model:apply-function("validation-errors", $error)
};

(:~
 :
 :)
declare function model:put(
  $model as element(domain:model),
  $body as item()
) {
  fn:error(xs:QName("DEPRECATED"), "Function is deprecated")
};

(:~
 :
 :)
declare function model:post(
  $model as element(domain:model),
  $body as item()
) {
  fn:error(xs:QName("DEPRECATED"), "Function is deprecated")
};

(:~
 :  Takes a simple xml structure and assigns it to a map
 :  Does not handle nested content models
 :)
declare function model:build-params-map-from-body(
  $model as element(domain:model),
  $body as node()
) as map:map {
  model:apply-function("build-params-map-from-body", $model, $body)
};

declare function model:convert-to-map(
  $model as element(domain:model),
  $current as item()
) as map:map? {
  model:apply-function("convert-to-map", $model, $current)
};

(:~
 :  Builds the value for a given field type.
 :  This ensures that the proper values are set for the given field
 :)
declare function model:build-value(
  $context as element(),
  $value as item()*,
  $current as item()*
) {
  model:apply-function("build-value", $context, $value, $current)
};

(:~
 : Finds any element by a field name.  Important to only pass field names using special syntax
 :  "fieldname==" Equality
 :  "!fieldname=" Not Equality
 :  "fieldname>"  Greater Than (range only)
 :  "fieldname<"  Less Than (range only)
 :  "fieldname>=" Greater Than Equal To (range only)
 :  "fieldname<=" Less Than Equal To
 :  "fieldname.."  Between two values map must have 2 values of type assigned to field
 :  "!fieldname.." Negated between operators
 :  "fieldname*="  Word Wildcard Like Ex
 :  "!name*=" Any word or default
 :  "fieldname"  - performs a value query
 :  "join"
 :)
declare function model:find(
  $model as element(domain:model),
  $params
) {
  model:apply-function("find", $model, $params)
};
(:~
 :  "fieldname==" Equality
 :  "fieldname!=" Not Equality
 :  "fieldname>"  Greater Than (range only)
 :  "fieldname<"  Less Than (range only)
 :  "fieldname>=" Greater Than Equal To (range only)
 :  "fieldname<=" Less Than Equal To
 :  "fieldname.."  Between two values map must have 2 values of type assigned to field
 :  "!fieldname.." Negated between operators
 :  "fieldname*="  Word Wildcard Like Ex
 :  "!name*=" Any word or default
 :  "fieldname"  - performs a value query
 :)
declare function model:find-params(
  $model as element(domain:model),
  $params
) {
  model:apply-function("find-params", $model, $params)
};

declare function partial-update(
  $model as element(domain:model),
  $updates as map:map
) {
  model:apply-function("partial-update", $model, $updates)
};

(:~
 :  Finds particular nodes based on a model and updates the values
 :)
declare function model:find-and-update(
  $model as element(domain:model),
  $params
) {
  model:apply-function("find-and-update", $model, $params)
};

declare function model:export(
  $model as element(domain:model),
  $params as map:map
) as element(results) {
  model:export($model, $params, ())
};

(:~
 : Returns if the passed in _query param will be used as search criteria
 : $params support all model:list-params parameters
 : $fields optional return field list (must be marked as exportable=true)
~:)
declare function model:export(
  $model as element(domain:model),
  $params as map:map,
  $fields as xs:string*
) as element(results) {
  model:apply-function("export", $model, $params, $fields)
};

declare function convert-attributes-to-elements(
  $namespace as xs:string,
  $attributes,
  $convert-attributes
) {
  model:apply-function("convert-attributes-to-elements", $namespace, $attributes, $convert-attributes)
};

declare function serialize-to-flat-xml(
  $namespace as xs:string,
  $model as element(domain:model),
  $current as node()
) {
  model:apply-function("serialize-to-flat-xml", $namespace, $model, $current)
};

declare function convert-flat-xml-to-map(
  $model as element(domain:model),
  $current as node()
) as map:map {
  model:apply-function("convert-flat-xml-to-map", $model, $current)
};

declare function model:import(
  $model as element(domain:model),
  $dataset as element(results)
) as empty-sequence() {
  model:apply-function("import", $model, $dataset)
};

(:~
 : Creates a domain object from its json representation
~:)
declare function model:from-json(
  $model as element(domain:model),
  $update as item()
) {
  model:apply-function("from-json", $model, $update)
};

(:~
 : Creates a new domain instance from a json representation
~:)
declare function model:from-json(
  $model as element(domain:model),
  $update as item(),
  $current as element()?,
  $mode as xs:string
) {
  model:apply-function("from-json", $model, $update, $current, $mode)
};

(:~
 : Deserializes a model instance from a json representation
 :)
declare function model:build-from-json(
  $context as element(),
  $current as element()?,
  $updates as element(),
  $partial as xs:boolean
) {
  model:apply-function("build-from-json", $context, $current, $updates, $partial)
};

(:~
 : Creates a complex element
~:)
declare function build-complex(
  $context as node(),
  $current as node()?,
  $updates as item(),
  $partial as xs:boolean
) {
  model:apply-function("build-complex", $context, $current, $updates, $partial)
};

(:~
 : Creates a simple type as defined by domain:SIMPLE-TYPES
 :)
declare function build-simple(
  $context as node(),
  $current as node()?,
  $updates as item()?,
  $partial as xs:boolean
) {
  model:apply-function("build-simple", $context, $current, $updates, $partial)
};

(:Normalizes the path to ensure // are removed:)
declare function model:normalize-path(
  $path as xs:string
) {
  model:apply-function("normalize-path", $path)
};
