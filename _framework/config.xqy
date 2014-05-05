(:~ 
 : 
 : Provides access to config and supports retrieving resources from configuration entries 
 : and general features for accessing resources and values from config.xml
 : @version 2.0
 :)
xquery version "1.0-ml";

module namespace config = "http://xquerrail.com/config";

import module namespace response = "http://xquerrail.com/response"
   at "/_framework/response.xqy";
   
import module namespace request  = "http://xquerrail.com/request"
   at "/_framework/request.xqy";

declare namespace domain = "http://xquerrail.com/domain";

declare namespace routing = "http://xquerrail.com/routing";   

declare option xdmp:mapping "false";

(:
 :Make sure this points to a valid location in your modules path
 :)   
declare variable $CONFIG as element(config:config) := 
    if(xdmp:modules-database() = 0) 
    then xdmp:unquote(
            xdmp:binary-decode(
                xdmp:external-binary(fn:concat(
                    xdmp:modules-root(),
                    if(fn:ends-with(xdmp:modules-root(),"/")) then "" else "/", 
                    "_config/config.xml")
                )
            ,"utf8")
         )/element()
    else 
      xdmp:eval("fn:doc('/_config/config.xml')/element()",
      (),
      <options xmlns="xdmp:eval">
         <database>{xdmp:modules-database()}</database>
      </options>
      )
 ;
(:Default Path Values:)
(:~
 : Defines the default base path framework
 :)
declare variable $FRAMEWORK-PATH           := "/_framework";
(:~
 : Defines the default base path for engines
 :)
declare variable $DEFAULT-ENGINE-PATH      := "/_framework/engines";
(:~
 : Defines the default base path for all interceptors
 :)
declare variable $DEFAULT-INTERCEPTOR-PATH := "/_framework/interceptors";
(:~
 : Defines the default base path for all dispatches
 :)
declare variable $DEFAULT-DISPATCHER-PATH  := "/_framework/dispatchers";
(:~
 : Defines the base implementation path for controllers,models and views
 :)
declare variable $DEFAULT-BASE-PATH        := "/_framework/base";
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
declare variable $DEFAULT-ROUTING-MODULE   := "/_framework/routing.xqy";

(:Error Codes:)
declare variable $ERROR-RESOURCE-CONFIGURATION := xs:QName("ERROR-RESOURCE-CONFIGURATION");
declare variable $ERROR-ROUTING-CONFIGURATION  := xs:QName("ERROR-ROUTING-CONFIGURATION");
declare variable $ERROR-DOMAIN-CONFIGURATION   := xs:QName("ERROR-DOMAIN-CONFIGURATION");

(:Cache Keys:)
declare variable $DOMAIN-CACHE-KEY := "http://xquerrail.com/cache/domain/" ;
declare variable $DOMAIN-CACHE-TS := "application-domains:timestamp::";
declare variable $DOMAIN-CACHE-COLLECTION := "cache:domain";

declare variable $DOMAIN-CACHE-PERMISSIONS := (
    xdmp:permission("xquerrail","read"),
    xdmp:permission("xquerrail","update"),
    xdmp:permission("xquerrail","insert"),
    xdmp:permission("xquerrail","execute")
);
(:Removes All Cache Keys:)
declare function config:clear-cache() {
  xdmp:directory-delete($DOMAIN-CACHE-KEY)
};
 
declare function config:get-cache-keys() {
 xdmp:eval(
    'declare variable $DOMAIN-CACHE-KEY as xs:string external;
    function() {cts:uris((),(),cts:directory-query($DOMAIN-CACHE-KEY,"infinity"))}()',(xs:QName("DOMAIN-CACHE-KEY"),$DOMAIN-CACHE-KEY),
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
      <user-id>{xdmp:user(config:anonymous-user())}</user-id>
    </options>
  )
  
};

declare function config:set-cache($key,$value as node()) {
 switch(config:cache-location())
  case "database" return 
           xdmp:eval('
           declare variable $key as xs:string external;
           declare variable $value as node() external;
           declare variable $DOMAIN-CACHE-PERMISSIONS external;
           declare variable $DOMAIN-CACHE-COLLECTION external;
           function() {
               xdmp:document-insert($key,$value,$DOMAIN-CACHE-PERMISSIONS/*,($DOMAIN-CACHE-COLLECTION)),
               xdmp:commit()
           }()',
           (xs:QName("key"),$key,
            xs:QName("value"),$value,
            xs:QName("DOMAIN-CACHE-PERMISSIONS"),<x>{$DOMAIN-CACHE-PERMISSIONS}</x>,
            xs:QName("DOMAIN-CACHE-COLLECTION"),$DOMAIN-CACHE-COLLECTION),
           <options xmlns="xdmp:eval">
             <isolation>different-transaction</isolation>
             <transaction-mode>update</transaction-mode>
             <user-id>{xdmp:user(config:anonymous-user())}</user-id>
           </options>
         )
  default return
      xdmp:set-server-field($key,$value)
};

declare function config:get-cache($key) {
  switch(config:cache-location())
      case "database" return 
              xdmp:eval('
                declare variable $key external;
                function() {
                   fn:doc( $key)
                }',(xs:QName("key"),$key),
                <options xmlns="xdmp:eval">
                  <isolation>different-transaction</isolation>
                  <user-id>{xdmp:user(config:anonymous-user())}</user-id>
                </options>
              )
      default return xdmp:get-server-field($key)
};
(:~
 : Initializes the application domains and caches them in the application server. 
 : When using a cluster please ensure you change configuration to cache from database
 :)
declare function config:refresh-app-cache() {
     for $application in config:get-applications()
     let $cache-key := fn:concat($DOMAIN-CACHE-KEY,$application/@name)
     return  
            let $app-path := config:application-directory(fn:substring-after($cache-key, $DOMAIN-CACHE-KEY))
            let $domain-key := fn:concat($app-path,"/domains/application-domain.xml")
            let $config := config:get-resource(fn:concat($app-path,"/domains/application-domain.xml"))
            let $config := config:_load-domain($config)
            return (
              config:set-cache($cache-key,$config),
              $config
            ) 
     
};
declare function config:cache-location() {
  ($CONFIG/config:cache-location/@value,"database")[1]
};

(:~
 : Returns a list of applications from the config.xml. 
 :)
declare function config:get-applications() {
   $CONFIG/config:application
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
    if(fn:count($CONFIG/config:application) = 1) 
    then $CONFIG/config:application/@name/fn:normalize-space(.) 
    else ($CONFIG/config:default-application/@value/fn:string(),
     "application"
    )[1]
 }; 
(:~
 : Returns the default controller for entire application usually default
 : This reads the configuration in the following order: 
 : $CONFIG/config:application/config:default-controller
 :)
declare function config:default-controller()
{
  fn:string($CONFIG/config:default-controller/@value)
};

(:~
 : Returns the default template assigned to the application. This reads the configuration in the following order:
 : $CONFIG/config:application/config:default-template/@value resource
 : $CONFIG/config:default-template/@value
 :)
declare function config:default-template($application-name) {
  (
   config:get-application($application-name)/config:default-template/@value/fn:string(),
   $CONFIG/config:default-template/@value/fn:string(),
   "main"
   )[1]
};

(:~
 : Returns the default action specifed by the <config:default-action/> configuration element. 
 The default action is used to determine any actions that does not pass an action.
 : Reads $CONFIG/config:default-action
:)
declare function config:default-action()
{
  fn:string($CONFIG/config:default-action/@value)
};

(:~
 : Returns the default format. The default format specifies that any 
 :  URI that does not explicitly define its format will use this value.
 :)
declare function config:default-format()
{
  fn:string($CONFIG/config:default-format/@value)
};

(:~
 : Returns the default dispatcher for entire framework. By default the only dispatcher defined is the 
  /_framework/displatcher/dispatcher.web.xqy. But if a custom dispatcher is implemented then the configuration will use that value.
 :)
declare function config:get-dispatcher()
{
  fn:string($CONFIG/config:dispatcher/@resource)
};

(:~
 : Returns the application configuration for a given application by name
 : @param $application-name - The name of the application specified by the @name parameter
 :)
declare function config:get-application($application-name as xs:string)
{
   let $application := $CONFIG/config:application[@name eq $application-name]
   return
      if($application) 
      then $application 
      else fn:error(xs:QName("INVALID-APPLICATION"),"Application with '" || $application-name || "' does not-exist",$application-name)
};


(:~
 : Returns the resource directory for framework defined in /_config/config.xml
 : $the value is specifed as 
 : $CONFIG/config:resource-directory
 : "/resources/"
 :)
declare function config:resource-directory() as xs:string
{
   if(fn:not($CONFIG/config:resource-directory))
   then "/resources/"
   else fn:data($CONFIG/config:resource-directory/@resource)
}; 

(:~
 : Returns the base-model location as defined in the config.xml
 : @param $model-name - Returns the location of the model if defined in the calling application.
 :)
declare function config:get-base-model-location($model-name as xs:string) {

    let $modelSuffix := fn:data($CONFIG/config:model-suffix/@value)
    let $path := fn:concat("/model/", $model-name, $modelSuffix, ".xqy") 
    return
     if(xdmp:uri-is-file($path))
     then $path
     else fn:concat("/_framework/base/base", $modelSuffix, ".xqy")
};

(:~
 : Returns the base-view-directory defined in the configuration
 : The following order is defined for reading this value.
    $CONFIG/config:base-view-directory
    "/_framework/base/views"
 : th
 :)
declare function config:base-view-directory() {
   let $dir :=  fn:data($CONFIG/config:base-view-directory/@value)
   return 
    if ($dir) then $dir else "/_framework/base/views"
};

(:~
 : Get the current application directory defined by the /application/@uri attribute 
 : @param $application - If the passed value is a string then it will lookup the application by name then return the uri.
 : else if the `$application` is an instance of domain:appliation then reads the @uri attribute.
 :)
declare function config:application-directory($application)
{
   if($application instance of element(config:application))
   then $application/@uri
   else config:get-application($application)/@uri
};
(:~
 : Get the current application namespace defined by $CONFIG/config:application/@namespace
 : @param $application - If the passed value is a string then it will lookup the application by name then return the @namespace.
 : else if the `$application` is an instance of domain:appliation then reads the @namespace attribute.
 :)
declare function config:application-namespace($application)
{
   if($application instance of element(config:application))
   then $application/@uri
   else config:get-application($application)/@namespace
};
(:~
 : Get the current application script directory defined by the config:application/config:script-directory
 : If not present then the config:resource-directory is returned
 : @param $application - string name or instance of the <config:application/> element
 :)
declare function config:application-script-directory($application)
{
   (fn:data(config:get-application($application)/config:script-directory/@value),
    config:resource-directory())[1]
};

(:~
 : Get the current application stylesheet directory defined by the config:application/config:stylesheet-directory
  : If not present then the config:resource-directory is returned config:resource-directory
 : @param $application - string name or instance of the <config:application/> element
 :)
declare function config:application-stylesheet-directory($application)
{
   (
    fn:data(config:get-application($application)/config:stylesheet-directory/@value),
    config:resource-directory()
   )[1]
};


(:~
 : Gets the default anonymous user defined by the default application.
 : IF not present then returns the $CONFIG/config:anonymous-user/@value
 :)
declare function config:anonymous-user()
{
   (
      config:anonymous-user(config:default-application()),
      $CONFIG/config:anonymous-user/@value
    )[1]
};

(:~
 : Gets the default anonymous user defined by the application
 :)
declare function config:anonymous-user($application-name)
{(
   fn:data($CONFIG/config:anonymous-user/@value),
   "anonymous"
)[1]};


(:~
 :  Get the domain for a given application. The domain is cached to optimize performance 
 :  and if changed may need to be initialized to reflect the latest values
 :  @param $application-name - Name of the application to get the domain.
 :)
declare function config:get-domain($application-name)
{
  let $cache-key := fn:concat($DOMAIN-CACHE-KEY,$application-name)
  return 
    switch(config:cache-location())
     case "database" return
         if(fn:doc-available($cache-key))
         then fn:doc($cache-key)/node()
         else 
              let $app-path := config:application-directory($application-name)
              let $domain-key := fn:concat($app-path,"/domains/application-domain.xml")
              let $domain := config:get-resource(fn:concat($app-path,"/domains/application-domain.xml"))
              let $domain := config:_load-domain($domain)
              return (
                config:set-cache($cache-key,$domain),
                $domain
              )
     default return 
            if(xdmp:get-server-field($cache-key)) 
            then xdmp:get-server-field($cache-key)
            else 
              let $app-path := config:application-directory($application-name)
              let $domain-key := fn:concat($app-path,"/domains/application-domain.xml")
              let $domain := config:get-resource(fn:concat($app-path,"/domains/application-domain.xml"))
              let $domain := config:_load-domain($domain)
              return (
                xdmp:set-server-field($cache-key,$domain),
                $domain
              )
};
declare function config:get-domain()  {
   config:get-domain(config:default-application())
};
(:~
 : Registers a dynamic domain for inclusion in application domain
~:)
declare function config:register-domain($domain as element(domain:domain)) {
   let $application-name := $domain/domain:name
   let $_ := if($application-name) then () else fn:error(xs:QName("DOMAIN-MISSING-NAME"),"Domain must have a name")
   let $cache-key := fn:concat($DOMAIN-CACHE-KEY,$application-name)
   return (
      xdmp:set-server-field($cache-key,config:_load-domain($domain)),
      $domain
   )
   
};
(:~
 : Function loads the domain internally and resolves import references
 :)
declare %private function config:_load-domain(
$domain as element(domain:domain)
) {
    let $app-path := config:application-directory($domain/*:name)
    let $imports := 
        for $import in $domain/domain:import
        return
        config:get-resource(fn:concat($app-path,"/domains/",$import/@resource))        
    return 
        element domain {
         namespace domain {"http://xquerrail.com/domain"},
         attribute xmlns {"http://xquerrail.com/domain"},
         $domain/@*,
         $domain/(domain:name|domain:content-namespace|domain:application-namespace|domain:description|domain:author|domain:version|domain:declare-namespace|domain:default-collation),
         ($domain/domain:model,$imports/domain:model),
         ($domain/domain:optionlist,$imports/domain:optionlist),
         ($domain/domain:controller,$imports/domain:controller),
         ($domain/domain:view,$imports/domain:view)
       } 
};

(:~
 : Returns the routes configuration file defined by $CONFIG/config:routes-config
 :)
declare function config:get-routes()
{
  config:get-resource($CONFIG/config:routes-config/@resource) 
};

(:~
 : Returns the routes module file defined by $CONFIG/config:routes-module
 :)
declare function config:get-route-module() {
   $CONFIG/config:routes-module/@resource
};

(:~
 : Returns the engine for processing requests satisfying the response:format()
 : If no format matching an engine is found then the $CONFIG/config:default-engine/@value is returned
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
     else fn:string($CONFIG/config:default-engine/@value)
};


(:~
 : Returns the Error Handler location from the configuration at 
 : $CONFIG/config:error-handler/@resource,
 : $CONFIG/config:error-handler/@dbresource
 : "/_framework/error.xqy"
 :)
declare function config:error-handler()
{ 
  (
    $CONFIG/config:error-handler/@resource,
    $CONFIG/config:error-handler/@dbresource,
    "/_framework/error.xqy"
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
  let $interceptors := $CONFIG/config:interceptors/config:interceptor
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
     $CONFIG/config:interceptor-config/@value/fn:data(.),
     "/_config/interceptor.xml"
   )[1]
   
};
(:~
 : The resource handler is responsible for accepting resource requests and performing specific actions
 : against the content like compression or other things to augment the resource
 :)
declare function config:resource-handler() {
  $CONFIG/config:resource-handler
};
(:~
 :  Defines the default controller suffix as defined by $CONFIG/config:controller-suffix 
 :)
declare function config:controller-suffix() as xs:string {
  $CONFIG/config:controller-suffix
};

declare function config:property(
  $name as xs:string
) {
  config:property($name,())
};
(:~
 : Returns a property defined in the $CONFIG/config:properties/config:property. 
 : The value can be specified by either resource/value or text() attribute
 : @param $name - name of the resource property to return
 :)
declare function config:property(
  $name as xs:string,
  $default as xs:string?
  )  as xs:string?{
      let $value := $CONFIG/config:properties/config:property[@name = $name]/(@resource|@value|text())[1]
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
   $CONFIG/config:controller-extension
};
(:~
 : Returns default path for the controller.
 :)
declare function config:controller-base-path()  as xs:string
{
   (
   $CONFIG/config:controller-base-path/@value,
    "/controller/")[1]
};
(:~
 : Returns the default identity scheme for all applications
 :)
 declare function config:identity-scheme() as xs:string {
    (
     $CONFIG/config:default-identity-scheme/@value,
    "uuid"
    )[1]
 };
 declare function config:attribute-prefix() {
     (
     $CONFIG/config:attribute-prefix/@value,
    "@"
    )[1]   
 };