(:~
 :
 : Provides access to config and supports retrieving resources from configuration entries
 : and general features for accessing resources and values from config.xml
 : @version 2.0
 :)
xquery version "1.0-ml";

module namespace config = "http://xquerrail.com/config";

import module namespace application = "http://xquerrail.com/application" at "application.xqy";
import module namespace cache = "http://xquerrail.com/cache" at "cache.xqy";
import module namespace xdmp-api = "http://xquerrail.com/xdmp/api" at "lib/xdmp-api.xqy";

declare namespace domain = "http://xquerrail.com/domain";

declare namespace routing = "http://xquerrail.com/routing";

declare option xdmp:mapping "false";

declare variable $USE-MODULES-DB := (xdmp:modules-database() ne 0);

declare variable $CACHE := cache:get-server-field-cache-map("config-cache");

(:~
 : Defines the default base path for engines
 :)
declare variable $DEFAULT-ENGINE-PATH      := fn:concat(config:framework-path(), "/engines");

declare variable $DEFAULT-ENGINES-CONFIGURATION :=
  <config xmlns="http://xquerrail.com/config" xmlns:engine="http://xquerrail.com/engine">
    <engines>
      <engine format="html" namespace="http://xquerrail.com/engine/html" uri="{$DEFAULT-ENGINE-PATH || '/engine.html.xqy'}">
        <mimetypes>
          <mimetype>text/html</mimetype>
        </mimetypes>
      </engine>
      <engine format="json" namespace="http://xquerrail.com/engine/json" uri="{$DEFAULT-ENGINE-PATH || '/engine.json.xqy'}">
        <mimetypes>
          <mimetype>application/json</mimetype>
        </mimetypes>
      </engine>
      <engine format="xml" namespace="http://xquerrail.com/engine/xml" uri="{$DEFAULT-ENGINE-PATH || '/engine.xml.xqy'}">
        <mimetypes>
          <mimetype>text/xml</mimetype>
        </mimetypes>
      </engine>
    </engines>
  </config>
;

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
declare variable $CONFIG-CACHE-KEY := "config";
declare variable $BASE-PATH-CACHE-KEY := "base-path";
declare variable $CONFIG-PATH-CACHE-KEY := "config-path";
(:declare variable $CONFIG-CACHE-KEY := "http://xquerrail.com/cache/config" ;:)
(:declare variable $DOMAIN-CACHE-KEY := "http://xquerrail.com/cache/domains/" ;:)
(:declare variable $DOMAIN-CACHE-TS := "application-domains:timestamp::";:)
declare variable $CACHE-COLLECTION := "cache:domain";

declare function config:version() as xs:string {
  "0.0.13"
};

declare function config:last-commit() as xs:string {
  "0e03db57094a497eae7f1edf98325b4ff8113454"
};

declare function config:get-config() as element(config:config)? {
  (:if (cache:contains-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-CACHE-KEY)) then
    cache:get-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-CACHE-KEY)
  else if (cache:contains-config-cache($cache:DATABASE-CACHE-LOCATION, $CONFIG-CACHE-KEY)) then
    cache:get-config-cache($cache:DATABASE-CACHE-LOCATION, $CONFIG-CACHE-KEY)/node()
  else
    ():)
  cache:get-config((), $CONFIG-CACHE-KEY)
};

declare function config:set-config($config as element(config:config)?) as empty-sequence() {
  (:cache:set-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-CACHE-KEY, $config),
  cache:set-config-cache($cache:DATABASE-CACHE-LOCATION, $CONFIG-CACHE-KEY, $config):)
  cache:set-config($config, $CONFIG-CACHE-KEY, $config)
};

declare function config:get-base-path() as xs:string? {
  (:if (cache:contains-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $BASE-PATH-CACHE-KEY)) then
  (
    xdmp:log(text{"get-base-path from", $cache:SERVER-FIELD-CACHE-LOCATION}),
    cache:get-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $BASE-PATH-CACHE-KEY)
  )
  else if (cache:contains-config-cache($cache:DATABASE-CACHE-LOCATION, $BASE-PATH-CACHE-KEY)) then
    (
    xdmp:log(text{"get-base-path from", $cache:DATABASE-CACHE-LOCATION}),
      cache:get-config-cache($cache:DATABASE-CACHE-LOCATION, $BASE-PATH-CACHE-KEY)/node()
    )
  else
    ():)
  cache:get-config((), $BASE-PATH-CACHE-KEY)
};

declare function config:set-base-path($base-path as xs:string) as empty-sequence() {
  (:cache:set-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $BASE-PATH-CACHE-KEY, $base-path),
  cache:set-config-cache($cache:DATABASE-CACHE-LOCATION, $BASE-PATH-CACHE-KEY, text{$base-path}):)
  cache:set-config((), $BASE-PATH-CACHE-KEY, text{$base-path})
};

declare function config:get-config-path() as xs:string? {
  (:if (cache:contains-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY)) then
    cache:get-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY)
  else if (cache:contains-config-cache($cache:DATABASE-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY)) then
    cache:get-config-cache($cache:DATABASE-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY)/node()
  else
    ():)
  cache:get-config((), $CONFIG-PATH-CACHE-KEY)
};

declare function config:set-config-path($config-path as xs:string) as empty-sequence() {
  (:cache:set-config-cache($cache:SERVER-FIELD-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY, $config-path),
  cache:set-config-cache($cache:DATABASE-CACHE-LOCATION, $CONFIG-PATH-CACHE-KEY, text{$config-path}):)
  cache:set-config((), $CONFIG-PATH-CACHE-KEY, text{$config-path})
};

(:~
 : Defines the default base path framework
 :)
declare function config:framework-path() as xs:string {
  fn:concat(config:get-base-path(), "/_framework")
};

(:~
 : Defines the default base path extensions
 :)
declare function config:extensions-path() as xs:string {
  fn:concat(config:get-base-path(), "/_extensions")
};

(:Removes All Cache Keys:)
declare function config:clear-cache(
  $server-fields-only as xs:boolean
) as empty-sequence() {
  let $config := config:get-config()
  return
  (
    if (fn:exists($config)) then (
      for $application in config:get-applications()
        return cache:clear-domain($config, fn:string($application/@name), $server-fields-only)
    )
    else
      ()
    ,
    cache:clear-config($config, $CONFIG-CACHE-KEY, $server-fields-only),
    cache:clear-config($config, $BASE-PATH-CACHE-KEY, $server-fields-only),
    cache:clear-config($config, $CONFIG-PATH-CACHE-KEY, $server-fields-only),
    cache:remove-server-field-maps(),
    map:clear($CACHE)
  )
};

declare function config:clear-cache(
) as empty-sequence() {
  config:clear-cache(fn:false())
};
(:~
 : Initializes the application domains and caches them in the application server.
 : When using a cluster please ensure you change configuration to cache from database
 :)
declare function config:refresh-app-cache($application as element(config:application)?) {
  let $_ := (
    application:reset(),
    application:bootstrap($application)
  )
  return
    for $application in config:get-applications()
      return config:get-domain(xs:string($application/@name))
};

declare function config:cache-location(
  $config as element(config:config)?
) as xs:string {
  ($config/config:cache-location/@value, $cache:DEFAULT-CACHE-LOCATION)[1]
};

(:~
 : Returns a list of applications from the config.xml.
 : Try to resolve the application path using @uri
 :)
declare function config:get-applications(
) as element(config:application)* {
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
    $application/* ! (if(./@resource) then (
      element { fn:QName("http://xquerrail.com/config", fn:local-name(.)) } {
        if (./@resource) then
          attribute resource { config:resolve-path($uri, ./@resource) }
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
  if(xdmp:modules-database() = 0) then
    let $file-path := fn:concat(xdmp:modules-root(), $uri)
    return
      if (xdmp:filesystem-file-exists($file-path)) then
        xdmp:unquote(
          xdmp:binary-decode(xdmp:external-binary($file-path),"utf8")
         )/element()
      else ()
  else
    xdmp:eval(
      "fn:doc('" || $uri || "')/element()",
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
declare function config:get-dispatcher(
  ) as xs:string {
  let $key := "get-dispatcher"
  return
    if (cache:contains-cache-map($CACHE, $key)) then
      cache:get-cache-map($CACHE, $key)
    else
      cache:set-cache-map(
        $CACHE,
        $key,
        (
          config:get-config()/config:dispatcher/@resource,
          fn:concat($DEFAULT-DISPATCHER-PATH, "/dispatcher.web.xqy")
        )[1]
      )
};

(:~
 : Returns the application configuration for a given application by name
 : @param $application-name - The name of the application specified by the @name parameter
 :)
declare function config:get-application(
  $name as xs:string
) as element(config:application)? {
  config:get-application($name, fn:false())
};

declare function config:get-application(
  $name as xs:string,
  $safe as xs:boolean
) as element(config:application)? {
  let $key := fn:concat("get-application", $name)
  return
    if (cache:contains-cache-map($CACHE, $key)) then
      cache:get-cache-map($CACHE, $key)
    else
      let $application := config:get-applications()[@name eq $name]
      return
        if(fn:exists($application)) then
          cache:set-cache-map($CACHE, $key, $application)
        else
          if (fn:not($safe)) then
            fn:error(xs:QName("INVALID-APPLICATION"),"Application with '" || $name || "' does not-exist", $name)
          else
            ()
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

declare function config:get-base-model-location(
) as xs:string {
  config:get-base-model-location(())
};

(:~
 : Returns the base-model location as defined in the config.xml
 : @param $model-name - Returns the location of the model if defined in the calling application.
 :)
declare function config:get-base-model-location(
  $model-name as xs:string?
) as xs:string {
  let $model-suffix := config:model-suffix()
  let $path := fn:concat("/model/", $model-name, $model-suffix, ".xqy")
  return
    if(xdmp:uri-is-file($path))
    then $path
    else fn:concat(config:framework-path(), "/base/base", $model-suffix, ".xqy")
};

(:~
 : Returns the base-model location as defined in the config.xml
 : @param $model-name - Returns the location of the model if defined in the calling application.
 :)
declare function config:get-base-controller-location(
) as xs:string {
  fn:concat(config:framework-path(), "/base/base-controller.xqy")
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
  let $dir := xs:string(config:get-config()/config:base-view-directory/@value)
  return
    if ($dir) then
      $dir
    else
      fn:concat(config:application-views-path(config:default-application()), "base")
};

(:~
 : Get the current application directory defined by the /application/@uri attribute
 : @param $application - If the passed value is a string then it will lookup the application by name then return the uri.
 : else if the `$application` is an instance of domain:appliation then reads the @uri attribute.
 :)
declare function config:application-directory($application) as xs:string
{
  let $application := if (fn:exists($application)) then $application else config:default-application()
  return
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
  let $application := if (fn:exists($application)) then $application else config:default-application()
  return
   if($application instance of element(config:application)) then xs:string($application/@namespace)
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
    xs:string(config:get-application($application)/config:script-directory/@resource),
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
    xs:string(config:get-application($application)/config:stylesheet-directory/@resource),
    config:resource-directory()
  )[1]
};

declare function config:application-views-path(
  $application-name as xs:string?
) as xs:string {
  fn:concat(config:application-directory($application-name), "/views/")
};

declare function config:application-templates-path(
  $application-name as xs:string?
) as xs:string {
  fn:concat(config:application-directory($application-name), "/templates/")
};

declare function config:application-models-path(
  $application-name as xs:string?
) as xs:string {
  fn:concat(config:application-directory($application-name), "/models/")
};

declare function config:application-controllers-path(
  $application-name as xs:string?
) as xs:string {
  let $path := fn:concat(config:application-directory($application-name), "/controllers/")
  let $old-path := fn:concat(config:application-directory($application-name), "/controller/")
  return
  if(xdmp:modules-database() = 0) then
      if (xdmp:filesystem-file-exists(fn:concat(xdmp:modules-root(), $path))) then
        $path
      else (
        xdmp:log(text{"controllers-path", $path, "does not exist. Please rename controller to controllers"}),
        $old-path
      )
  else
    xdmp:eval(
      "if (fn:exists(xdmp:directory('" || $path || "'))) then
        '" || $path || "'
       else (
        xdmp:log(text{'controllers-path', '" || $path || "', 'does not exist. Please rename controller to controllers'}),
        '" || $old-path || "'
       )",
      (),
      <options xmlns="xdmp:eval">
        <database>{xdmp:modules-database()}</database>
      </options>
    )
};

(:~
 : Gets the default anonymous user defined by the default application.
 : IF not present then returns the config:get-config()/config:anonymous-user/@value
 :)
declare function config:anonymous-user(
  $config as element(config:config)?
) as xs:string? {
  if (fn:exists($config)) then
    (
      config:anonymous-user($config, config:default-application()),
      xs:string($config/config:anonymous-user/@value),
      $DEFAULT-ANONYMOUS-USER
    )[1]
  else
    ()
};

(:~
 : Gets the default anonymous user defined by the application
 : TODO: Not implemented.
 :)
declare function config:anonymous-user(
  $config as element(config:config),
  $application-name as xs:string
) {
  (:xdmp:log((text{"config:anonymous-user", $application-name}, $config)),:)
  xs:string(config:get-application($application-name, fn:true())/config:anonymous-user/@value)
};


(:~
 :  Get the domain for a given application. The domain is cached to optimize performance
 :  and if changed may need to be initialized to reflect the latest values
 :  @param $application-name - Name of the application to get the domain.
 :)
declare function config:get-domain($application-name as xs:string) as element(domain:domain)?
{
  let $config := config:get-config()
  (:let $domain := cache:get-domain-cache(config:cache-location($config), $application-name, config:anonymous-user($config)):)
  let $domain := cache:get-domain($config, $application-name)
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

declare function config:resolve-path($path as xs:string?) as xs:string? {
  config:resolve-path((), $path)
};

declare function config:resolve-path($base as xs:string?, $path as xs:string?) as xs:string? {
  if ($path) then
    if (fn:starts-with($path, "$(framework.path)/")) then
      config:resolve-framework-path(fn:substring-after($path, "$(framework.path)/"))
    else if (fn:starts-with($path, "/")) then
      $path
    else
      fn:concat($base, "/", $path)
  else
    ()
};

declare function config:resolve-framework-path($path as xs:string?) as xs:string? {
  if (fn:starts-with($path, config:framework-path())) then
    $path
  else
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

declare function config:get-engines-configuration(
) as element (config:config) {
  (
    config:get-resource(config:resolve-config-path("engines.xml")),
    $DEFAULT-ENGINES-CONFIGURATION
  )[1]
};

declare function config:get-engines (
) as element(config:engine)* {
  config:get-engines-configuration()/config:engines/config:engine
};

declare function config:get-engine-extensions (
) as element(config:engine)* {
  config:get-engines-configuration()/config:extensions/config:engine
};

(:~
 : Returns the default engine from the configuration - basically the first engine registered
 : TODO: Not sure if this function is still required.
 :)
declare function config:default-engine(
) as element(config:engine) {
  $DEFAULT-ENGINES-CONFIGURATION/config:engines/config:engine[1]
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
declare function config:get-interceptors(
) {
  config:get-interceptors("all")
};


(:~
 : Returns all interceptors that match the interceptor event.  The event will correspond the attributes
 : @param $value - The event to math values are: before-request|after-request|before-response|after-response
 :)
declare function config:get-interceptors(
  $value as xs:string?
) {
  let $key := fn:concat("get-interceptors", $value)
  return
    if (cache:contains-cache-map($CACHE, $key)) then
      cache:get-cache-map($CACHE, $key)
    else
      let $interceptors :=
        for $interceptor in config:get-config()/config:interceptors/config:interceptor
        return element config:interceptor {
          $interceptor/@*[. except $interceptor/@*[fn:local-name(.) eq "resource"]],
          if (fn:exists($interceptor/@resource) and $interceptor/@resource ne "") then
            attribute resource { config:resolve-config-path($interceptor/@resource) }
          else
            ()
        }
      let $interceptors :=
        switch($value)
          case "before-request" return $interceptors[@before-request eq "true"]
          case "after-request" return $interceptors[@after-request eq "true"]
          case "before-response" return $interceptors[@before-response eq "true"]
          case "after-response" return $interceptors[@after-response eq "true"]
          case "all" return $interceptors
          default return ()
      return cache:set-cache-map($CACHE, $key, $interceptors)
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
 : Returns controller location for given application and controller names
~:)
declare function config:controller-location(
  $application-name as xs:string?,
  $controller-name as xs:string
) as xs:string* {
  (
    fn:concat(config:application-controllers-path($application-name), $controller-name, config:controller-suffix(), '.xqy'),
    if (xdmp-api:is-ml-8()) then
      fn:concat(config:application-controllers-path($application-name), $controller-name, config:controller-suffix(), '.sjs')
    else
      ()
  )
};

(:~
 : Returns controller namespace for given application and controller names
~:)
declare function config:controller-uri(
  $application-name as xs:string?,
  $controller-name as xs:string
) as xs:string {
   fn:concat(
    config:application-namespace($application-name),
    if (fn:contains(config:application-controllers-path($application-name), "controllers")) then "/controllers/" else "/controller/",
    $controller-name
  )
};

(:~
 : Returns controller location for given application and controller names
~:)
declare function config:model-location(
  $application-name as xs:string?,
  $model-name as xs:string
) as xs:string {
   fn:concat(config:application-models-path($application-name), $model-name, config:model-suffix(), '.xqy')
};

(:~
 : Returns controller namespace for given application and controller names
~:)
declare function config:model-uri(
  $application-name as xs:string?,
  $model-name as xs:string
) as xs:string {
   fn:concat(
    config:application-namespace($application-name),
    "/models/",
    $model-name
  )
};

declare function config:model-extension-location(
) as xs:string* {
  config:model-extension()/@resource
};

declare function config:domain-extension() {
  config:get-config()/config:domain-extension
};

declare function config:domain-extension-location() {
  config:domain-extension()/@resource
};

(:~
 : Returns the configurations for any controller extension
~:)
declare function config:controller-extension() {
  config:get-config()/config:controller-extension
};

declare function config:controller-extension-location(
) as xs:string* {
  config:controller-extension()/@resource
};

(:~
 : Returns the configurations for any model extension
~:)
declare function config:model-extension() {
  config:get-config()/config:model-extension
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
