(:~
 :
 : Provides access to config and supports retrieving resources from configuration entries
 : and general features for accessing resources and values from config.xml
 : @version 2.0
 :)
xquery version "1.0-ml";

module namespace config = "http://xquerrail.com/config";

import module namespace response = "http://xquerrail.com/response" at "response.xqy";

import module namespace request  = "http://xquerrail.com/request" at "request.xqy";

import module namespace cache = "http://xquerrail.com/cache" at "cache.xqy";

import module namespace application = "http://xquerrail.com/application" at "application.xqy";

declare namespace domain = "http://xquerrail.com/domain";

declare namespace routing = "http://xquerrail.com/routing";

declare option xdmp:mapping "false";

(:~
 : Defines the default base path for engines
 :)
declare variable $DEFAULT-ENGINE-PATH      := fn:concat(config:framework-path(), "/engines");
(:~
 : Defines the default base path for all interceptors
 :)
declare variable $DEFAULT-INTERCEPTOR-PATH := fn:concat(config:framework-path(), "/interceptors");
(:~
 : Defines the default base path for all dispatches
 :)
declare variable $DEFAULT-DISPATCHER-PATH  := fn:concat(config:framework-path(), "/dispatchers");
(:~
 : Defines the base implementation path for controllers,models and views
 :)
declare variable $DEFAULT-BASE-PATH        := fn:concat(config:framework-path(), "/base");
(:~
 : Defines the default location of views used in dynamic view functions
 :)
declare variable $DEFAULT-VIEWS-PATH       := fn:concat($DEFAULT-BASE-PATH,"/views");
(:~
 : Defines the default location of templates in dynamic ui functions
 :)
declare variable $DEFAULT-TEMPLATE-PATH    := fn:concat($DEFAULT-BASE-PATH,"/templates");
(:~
 : Defines the Default Controller Resources
 :)
declare variable $DEFAULT-CONTROLLER-RESOURCE  := fn:concat($DEFAULT-BASE-PATH,"/base-controller.xqy");
(:~
 : Defines the Default Model Resource
 :)
declare variable $DEFAULT-MODEL-RESOURCE       := fn:concat($DEFAULT-BASE-PATH,"/base-model.xqy");
(:~
 : Defines the db cache prefix when loading domains into the database
~:)
declare variable $DBRESOURCE-PREFIX := "http://xquerrail.com/";

(:~
 : Defines the default anonymous-user configuration
 :)
declare variable $DEFAULT-ANONYMOUS-USER   := "anonymous-user";
(:~
 : Defines the default routing module configuration
 :)
declare variable $DEFAULT-ROUTING-MODULE   := fn:concat(config:framework-path(), "/routing.xqy");

(:Error Codes:)
declare variable $ERROR-RESOURCE-CONFIGURATION := xs:QName("ERROR-RESOURCE-CONFIGURATION");
declare variable $ERROR-ROUTING-CONFIGURATION  := xs:QName("ERROR-ROUTING-CONFIGURATION");
declare variable $ERROR-DOMAIN-CONFIGURATION   := xs:QName("ERROR-DOMAIN-CONFIGURATION");

(:Cache Keys:)
declare variable $BASE-PATH-CACHE-KEY := "__base-path__";
declare variable $CONFIG-PATH-CACHE-KEY := "__config-path__";
(:declare variable $CONFIG-CACHE-KEY := "http://xquerrail.com/cache/config" ;:)
declare variable $DOMAIN-CACHE-KEY := "http://xquerrail.com/cache/domains/" ;
declare variable $DOMAIN-CACHE-TS := "application-domains:timestamp::";
declare variable $CACHE-COLLECTION := "cache:domain";

declare variable $CACHE-PERMISSIONS := (
    xdmp:permission("xquerrail","read"),
    xdmp:permission("xquerrail","update"),
    xdmp:permission("xquerrail","insert"),
    xdmp:permission("xquerrail","execute")
);

declare function config:version() as xs:string {
  "${ version }"
};

declare function config:last-commit() as xs:string {
  "${ lastcommit }"
};

declare function config:get-config() as element(config:config)? {
  cache:get-config-cache($cache:SERVER-FIELD-CACHE-LOCATION)
};

declare function config:get-base-path() as xs:string? {
  cache:get-cache($cache:SERVER-FIELD-CACHE-LOCATION, $BASE-PATH-CACHE-KEY)
};

declare function config:set-base-path($base-path as xs:string) as empty-sequence() {
  let $_ := cache:set-cache($cache:SERVER-FIELD-CACHE-LOCATION, $BASE-PATH-CACHE-KEY, $base-path)
  return ()
};

declare function config:get-config-path() as xs:string? {
  cache:get-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY)
};

declare function config:set-config-path($config-path as xs:string) as empty-sequence() {
  let $_ := cache:set-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY, $config-path)
  return ()
};

(:~
 : Defines the default base path framework
 :)
declare function config:framework-path() as xs:string {
  fn:concat(config:get-base-path(), "/_framework")
};

(:Removes All Cache Keys:)
declare function config:clear-cache() {
  let $config := config:get-config()
  return
  if (fn:exists($config)) then (
    for $application in config:get-applications()
      return cache:remove-domain-cache(config:cache-location($config), xs:string($application/@name), config:anonymous-user($config))
  )
  else
    ()
  ,
  cache:remove-config-cache($cache:SERVER-FIELD-CACHE-LOCATION),
  cache:remove-cache($cache:SERVER-FIELD-CACHE-LOCATION, $BASE-PATH-CACHE-KEY),
  cache:remove-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY)
};

(:~
 : Initializes the application domains and caches them in the application server.
 : When using a cluster please ensure you change configuration to cache from database
 :)
declare function config:refresh-app-cache() {
  let $_ := (
    application:reset(),
    application:bootstrap()
  )
  return
    for $application in config:get-applications()
      return config:get-domain(xs:string($application/@name))
};

declare function config:cache-location($config as element(config:config)) as xs:string {
  ($config/config:cache-location/@value,"database")[1]
};

(:~
 : Returns a list of applications from the config.xml.
 : Try to resolve the application path using @uri
 :)
declare function config:get-applications() {
  for $application in config:get-config()/config:application
    return config:resolve-application($application)
};

declare function config:resolve-application (
  $application as element(config:application)
) as element(config:application) {
  let $uri := $application/@uri
  return
  element config:application {
    attribute name { $application/@name },
    attribute uri { $uri },
    attribute namespace { $application/@namespace },
    $application/* ! (if(./@resource or ./@value) then (
      element { fn:QName("http://xquerrail.com/config", fn:local-name(.)) } {
        if (./@resource) then
          attribute resource { config:resolve-path($uri, ./@resource) }
        else ()
        ,
        if (./@value) then
          attribute value { config:resolve-path($uri, ./@value) }
        else ()
      }
    ) else .)
  }

};

(:~
 : Function Returns a resource based on
 : how the application server is configured.
 : If the modules are in the filesystem. then it is invoked from the filesystem.  If the modules are in a modules database then it evals the call to the modules database using the uri
 : @param $uri - The URI specifying the resource.  The resource is managed from the filesystem then the file is invoked as an xml file.
 :)
declare function config:get-resource($uri as xs:string) {
    if(xdmp:modules-database() = 0 )
    then xdmp:unquote(
            xdmp:binary-decode(
                xdmp:external-binary(fn:concat(xdmp:modules-root(),$uri)),"utf8")
         )/element()
    else
      xdmp:eval("fn:doc('" || $uri || "')/element()",
      (),
      <options xmlns="xdmp:eval">
         <database>{xdmp:modules-database()}</database>
      </options>
      )
};

(:~
 : Retrieves the config value from a database.  This is different than accessing
 : a resource from the modules database
 : @param $uri - The uri to load from the database
 :)
declare function config:get-dbresource($uri as xs:string) {
   fn:doc($uri)
};

(:~
 : Returns a configuration value of the given resource.
 : @param $node - The node must have at least the @resource or @dbresource or @value to resolve the resource.
 :                If not present throws INVALID_CONFIGURATION_VALUE  exception.
 :)
declare function config:get-config-value($node as element()?) {
   if($node/@dbresource)
   then config:get-dbresource(fn:data($node/@dbresource))
   else if($node/@resource)
        then config:get-resource(fn:data($node))
    else if($node/@value)
        then fn:data($node/@value)
   else if(fn:not(fn:exists($node)))
        then ()
   else fn:error(xs:QName("INVALID_CONFIGURATION_VALUE"),
        "A configuration value must be an attribute whose name is @resource,@dbresource,@value",$node)
};

(:~
 : Returns the default application defined in the config or application config
 : The default application is "application"
 :)
 declare function config:default-application() as xs:string
 {
  let $applications := config:get-applications()
  return
    if(fn:count($applications) = 1)
    then $applications/@name/fn:normalize-space(.)
    else (config:get-config()/config:default-application/@value/fn:string(),
     "application"
    )[1]
 };
(:~
 : Returns the default controller for entire application usually default
 : This reads the configuration in the following order:
 : config:get-config()/config:application/config:default-controller
 :)
declare function config:default-controller() as xs:string
{
  (
    config:get-config()/config:default-controller/@value,
    "default"
  )[1]
};

(:~
 : Returns the default template assigned to the application. This reads the configuration in the following order:
 : config:get-config()/config:application/config:default-template/@value resource
 : config:get-config()/config:default-template/@value
 :)
declare function config:default-template($application-name) as xs:string {
  (
    config:get-application($application-name)/config:default-template/@value/fn:string(),
    config:get-config()/config:default-template/@value/fn:string(),
    "main"
  )[1]
};

(:~
 : Returns the default action specifed by the <config:default-action/> configuration element.
 The default action is used to determine any actions that does not pass an action.
 : Reads config:get-config()/config:default-action
:)
declare function config:default-action() as xs:string
{
  (
    xs:string(config:get-config()/config:default-action/@value),
    "index"
  )[1]
};

(:~
 : Returns the default format. The default format specifies that any
 :  URI that does not explicitly define its format will use this value.
 :)
declare function config:default-format() as xs:string
{
  (
    xs:string(config:get-config()/config:default-format/@value),
    "html"
  )[1]
};

(:~
 : Returns the default dispatcher for entire framework. By default the only dispatcher defined is the
  /_framework/displatcher/dispatcher.web.xqy. But if a custom dispatcher is implemented then the configuration will use that value.
 :)
declare function config:get-dispatcher() as xs:string
{
  (
    config:get-config()/config:dispatcher/@resource,
    fn:concat($DEFAULT-DISPATCHER-PATH, "/dispatcher.web.xqy")
  )[1]
};

(:~
 : Returns the application configuration for a given application by name
 : @param $application-name - The name of the application specified by the @name parameter
 :)
declare function config:get-application($application-name as xs:string) as element(config:application)
{
  let $application := config:get-applications()[@name eq $application-name]
  return
    if($application)
    then $application
    else fn:error(xs:QName("INVALID-APPLICATION"),"Application with '" || $application-name || "' does not-exist",$application-name)
};


(:~
 : Returns the resource directory for framework defined in /_config/config.xml
 : $the value is specifed as
 : config:get-config()/config:resource-directory
 : "/resources/"
 :)
declare function config:resource-directory() as xs:string
{
   if(fn:not(config:get-config()/config:resource-directory))
   then "/resources/"
   else fn:data(config:get-config()/config:resource-directory/@resource)
};

(:~
 : Returns the base-model location as defined in the config.xml
 : @param $model-name - Returns the location of the model if defined in the calling application.
 :)
declare function config:get-base-model-location($model-name as xs:string) {
  let $model-suffix := config:model-suffix()
  let $path := fn:concat("/model/", $model-name, $model-suffix, ".xqy")
  return
    if(xdmp:uri-is-file($path))
    then $path
    else fn:concat(config:framework-path(), "/base/base", $model-suffix, ".xqy")
};

declare function config:default-view-directory() {
   fn:concat(config:framework-path(), "/base/views")
};
(:~
 : Returns the base-view-directory defined in the configuration
 : The following order is defined for reading this value.
    config:get-config()/config:base-view-directory
    "/_framework/base/views"
 : th
 :)
declare function config:base-view-directory() as xs:string {
  let $dir :=  xs:string(config:get-config()/config:base-view-directory/@value)
  return
    if ($dir) then $dir else config:default-view-directory()
};

(:~
 : Get the current application directory defined by the /application/@uri attribute
 : @param $application - If the passed value is a string then it will lookup the application by name then return the uri.
 : else if the `$application` is an instance of domain:appliation then reads the @uri attribute.
 :)
declare function config:application-directory($application) as xs:string
{
  if($application instance of element(config:application)) then xs:string($application/@uri)
  else xs:string(config:get-application($application)/@uri)
};
(:~
 : Get the current application namespace defined by config:get-config()set-domain-cache/config:application/@namespace
 : @param $application - If the passed value is a string then it will lookup the application by name then return the @namespace.
 : else if the `$application` is an instance of domain:appliation then reads the @namespace attribute.
 :)
declare function config:application-namespace($application) as xs:string
{
   if($application instance of element(config:application))
   then xs:string($application/@namespace)
   else xs:string(config:get-application($application)/@namespace)
};
(:~
 : Get the current application script directory defined by the config:application/config:script-directory
 : If not present then the config:resource-directory is returned
 : @param $application - string name or instance of the <config:application/> element
 :)
declare function config:application-script-directory($application)
{
  (
    xs:string(config:get-application($application)/config:script-directory/@value),
    config:resource-directory()
  )[1]
};

(:~
 : Get the current application stylesheet directory defined by the config:application/config:stylesheet-directory
  : If not present then the config:resource-directory is returned config:resource-directory
 : @param $application - string name or instance of the <config:application/> element
 :)
declare function config:application-stylesheet-directory($application)
{
  (
    xs:string(config:get-application($application)/config:stylesheet-directory/@value),
    config:resource-directory()
  )[1]
};


(:~
 : Gets the default anonymous user defined by the default application.
 : IF not present then returns the config:get-config()/config:anonymous-user/@value
 :)
declare function config:anonymous-user($config as element(config:config)) as xs:string
{
  (
    config:anonymous-user($config, config:default-application()),
    xs:string($config/config:anonymous-user/@value),
    $DEFAULT-ANONYMOUS-USER
  )[1]
};

(:~
 : Gets the default anonymous user defined by the application
 : TODO: Not implemented.
 :)
declare function config:anonymous-user($config as element(config:config), $application-name as xs:string)
{
  xs:string(config:get-application($application-name)/config:anonymous-user/@value)
};


(:~
 :  Get the domain for a given application. The domain is cached to optimize performance
 :  and if changed may need to be initialized to reflect the latest values
 :  @param $application-name - Name of the application to get the domain.
 :)
declare function config:get-domain($application-name as xs:string) as element(domain:domain)?
{
  let $config := config:get-config()
  let $domain := cache:get-domain-cache(config:cache-location($config), $application-name, config:anonymous-user($config))
  let $domain :=
    typeswitch ($domain)
      case element(domain:domain)
        return $domain
      case document-node()
        return $domain/domain:domain
      default
        return fn:error(xs:QName("NO-DOMAIN-FOUND"))
  return 
    if ($domain) then $domain
    else fn:error(xs:QName("NO-DOMAIN-FOUND"))
};

declare function config:get-domain() as element(domain:domain)? {
   config:get-domain(config:default-application())
};

(:~
 : Registers a dynamic domain for inclusion in application domain
~:)
declare function config:register-domain($domain as element(domain:domain)) {
  fn:error(xs:QName("NOT-IMPLEMENTED"))
(:  let $application-name := $domain/domain:name
  let $_ := if($application-name) then () else fn:error(xs:QName("DOMAIN-MISSING-NAME"),"Domain must have a name")
  let $cache-key := fn:concat($DOMAIN-CACHE-KEY,$application-name)
  return (
    cache:set-cache($cache-key,config:_load-domain($domain)),
    $domain
  )
:)};

declare function config:resolve-path($base as xs:string, $path as xs:string?) as xs:string? {
  if ($path) then
    if (fn:starts-with($path, "/")) then
      $path
    else
      fn:concat($base, "/", $path)
  else
    ()
};

declare function config:resolve-framework-path($path as xs:string?) as xs:string? {
  config:resolve-path(config:framework-path(), $path)
};

declare function config:resolve-config-path($path as xs:string?) as xs:string? {
  config:resolve-path(config:get-config-path(), $path)
};

(:~
 : Returns the routes configuration file defined by config:get-config()/config:routes-config
 :)
declare function config:get-routes()
{
  config:get-resource((
    config:resolve-config-path(config:get-config()/config:routes-config/@resource),
    config:resolve-config-path("routes.xml")
  )[1])
};

(:~
 : Returns the routes module file defined by config:get-config()/config:routes-module
 :)
declare function config:get-route-module() {
   (
    config:get-config()/config:routes-module/@resource,
    "routing.xqy"
   )[1]
};

(:~
 : Returns the engine for processing requests satisfying the response:format()
 : If no format matching an engine is found then the config:get-config()/config:default-engine/@value is returned
 :)
declare function config:get-engine($response as map:map)
{
   let $_ := response:initialize($response)
   return
     if(response:format() eq "html")
     then "engine.html"
     else if(response:format() eq "xml")
     then "engine.xml"
     else if(response:format() eq "json")
     then "engine.json"
     else config:default-engine()(:fn:string(config:get-config()/config:default-engine/@value):)
};

(:~
 : Returns the default engine from the configuration at
 : config:get-config()/config:default-engine/@value
 : or "engine.html"
 :)
declare function config:default-engine() as xs:string
{
  (
    xs:string(config:get-config()/config:default-engine/@value),
    "engine.html"
  )[1]
};

(:~
 : Returns the Error Handler location from the configuration at
 : config:get-config()/config:error-handler/@resource,
 : config:get-config()/config:error-handler/@dbresource
 : "/_framework/error.xqy"
 :)
declare function config:error-handler() as xs:string
{
  (
    xs:string(config:get-config()/config:error-handler/@resource),
    xs:string(config:get-config()/config:error-handler/@dbresource),
    config:resolve-framework-path("error.xqy")
  )[1]
};

(:~
 : Returns the list of all interceptors defined in the configuration
 :)
declare function config:get-interceptors()
{
  config:get-interceptors(())
};


(:~
 : Returns all interceptors that match the interceptor event.  The event will correspond the attributes
 : @param $value - The event to math values are: before-request|after-request|before-response|after-response
 :)
declare function config:get-interceptors(
  $value as xs:string?
){
  (: TODO: use except :)
  let $interceptors :=
    for $interceptor in config:get-config()/config:interceptors/config:interceptor
    return
      element config:interceptor {
        attribute name { $interceptor/@name },
        attribute before-request { $interceptor/@before-request },
        attribute after-request { $interceptor/@after-request },
        attribute before-response { $interceptor/@before-response },
        attribute after-response { $interceptor/@after-response },
        attribute resource { config:resolve-config-path($interceptor/@resource) }
      }
  return
    switch($value)
      case "before-request" return $interceptors[@before-request eq "true"]
      case "after-request" return $interceptors[@after-request eq "true"]
      case "before-response" return $interceptors[@before-response eq "true"]
      case "after-response" return $interceptors[@after-response eq "true"]
      case "all" return $interceptors
      default return ()

};
(:~
 : Returns the default interceptor configuration.  If none is configured will map to the default
 :)
declare function config:interceptor-config() as xs:string?
{
   (
    config:resolve-config-path(config:get-config()/config:interceptor-config/@value/fn:data(.)),
    config:resolve-config-path("interceptor.xml")
   )[1]

};
(:~
 : The resource handler is responsible for accepting resource requests and performing specific actions
 : against the content like compression or other things to augment the resource
 :)
declare function config:resource-handler() {
  if (config:get-config()/config:resource-handler) then (
    if (config:get-config()/config:resource-handler/@resource) then 
      config:get-config()/config:resource-handler
    else
      <resource-handler resource="{config:resolve-framework-path("handlers/resource.handler.xqy")}"/>
  )[1]
  else
    ()
  
};

(:~
 :  Defines the default controller suffix as defined by config:get-config()/config:controller-suffix
 :)
declare function config:controller-suffix() as xs:string {
  (
    xs:string(config:get-config()/config:controller-suffix),
    "-controller"
  )[1]
};

(:~
 :  Defines the default model suffix as defined by config:get-config()/config:model-suffix
 :)
declare function config:model-suffix() as xs:string {
  (
    xs:string(config:get-config()/config:model-suffix),
    "-model"
  )[1]
};

declare function config:property(
  $name as xs:string
) {
  config:property($name,())
};
(:~
 : Returns a property defined in the config:get-config()/config:properties/config:property.
 : The value can be specified by either resource/value or text() attribute
 : @param $name - name of the resource property to return
 :)
declare function config:property(
  $name as xs:string,
  $default as xs:string?
  )  as xs:string?{
      let $value := config:get-config()/config:properties/config:property[@name = $name]/(@resource|@value|text())[1]
      return
      if($value instance of attribute())
      then fn:data($value)
      else if($default) then $default
      else fn:error(xs:QName("INVALID-PROPERTY"),"Missing Property Configuration")
};
(:~
 : Returns the configurations for any controller extension
~:)
declare function config:controller-extension() {
   config:get-config()/config:controller-extension
};
(:~
 : Returns default path for the controller.
 :)
declare function config:controller-base-path()  as xs:string
{
   (
   xs:string(config:get-config()/config:controller-base-path/@value),
    "/controller/")[1]
};
(:~
 : Returns the default identity scheme for all applications
 :)
 declare function config:identity-scheme() as xs:string {
    (
     xs:string(config:get-config()/config:default-identity-scheme/@value),
    "uuid"
    )[1]
 };
 declare function config:attribute-prefix() as xs:string {
     (
     xs:string(config:get-config()/config:attribute-prefix/@value),
    "@"
    )[1]
 };
 
(:~
 : Sets default global validation model for application.
 : To enable at application enable at <application><validation>true</validation></application>
~:)
declare function config:validate-mode()  as xs:boolean{
    xs:boolean((
        config:get-config()/config:validate,
        fn:true()
    )[1])
};
(:~
 : Returns the validation mode 
~:)
declare function config:application-validate-mode($application-name) as xs:boolean {
   (
    config:get-application($application-name)/config:validate! xs:boolean(.),
    config:validate-mode()
   )[1]
};