xquery version "1.0-ml";
(:~
 : The controller centralizes request/response and controls access to the server.
 : The controller directs all requests to the rest interface.
 : The controller is used to send all request with the action parameter to the action method name in the REST interface.
 : Reformat the incoming search request parameters as elements.
 : For example, given the rewritten URL:
 : Return the rest function output.
 :
 :)
import module namespace request     = "http://xquerrail.com/request"     at "../request.xqy";
import module namespace response    = "http://xquerrail.com/response"    at "../response.xqy";
import module namespace config      = "http://xquerrail.com/config"      at "../config.xqy";
import module namespace module      = "http://xquerrail.com/module" at "../module.xqy";
import module namespace domain      = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace interceptor = "http://xquerrail.com/interceptor" at "../interceptor.xqy";
import module namespace base        = "http://xquerrail.com/controller/base" at "../base/base-controller.xqy";
import module namespace engine      = "http://xquerrail.com/engine" at "../engines/engine.base.xqy";

declare namespace dispatcher     = "http://xquerrail.com/dispatcher";

declare namespace extension      = "http://xquerrail.com/controller/extension";
declare namespace controller     = "http://xquerrail.com/controller";
declare namespace html           = "http://www.w3.org/1999/xhtml";
declare namespace error          = "http://marklogic.com/xdmp/error";
declare namespace eval           = "xdmp:eval";

(:~ convert error into html page or as simple element :)

declare option xdmp:mapping "false";
declare option xdmp:output "indent=yes";
declare option xdmp:output "method=xml";
declare option xdmp:output "indent-untyped=yes";
declare option xdmp:ouput "omit-xml-declaration=yes";
declare option xdmp:update "false";
(:declare option xdmp:transaction-mode "query";:)

declare variable $CONTROLLER-EXTENSION-NAMESPACE := "http://xquerrail.com/controller/extension";
declare variable $BASE-CONTROLLER-NAMESPACE := "http://xquerrail.com/controller/base";

(:~
 : Returns whether the controller exists or not.
 :)
declare function dispatcher:controller-exists(
  $controller-uri as xs:string
) as xs:boolean {
	module:resource-exists($controller-uri)
};

(:~
 : Determines if the extension for the controller exists or a plugin exists.
~:)
declare function dispatcher:extension-action-exists(
  $action as xs:string
) as xs:boolean {
  fn:exists(dispatcher:extension-action($action))
};

(:~
 : Checks that a given controller function exists
 :)
declare function dispatcher:action-exists(
  $controller-uri,
  $controller-location,
  $controller-action
) as xs:boolean {
  (
    domain:module-exists($controller-location) and
    domain:module-function-exists($controller-uri, $controller-location, $controller-action, ())
  )
};

declare function dispatcher:extension-action(
  $action as xs:string
) as xs:string? {
  (:let $controller-extension-namespace := "http://xquerrail.com/controller/extension":)
  let $controller-locations := config:controller-extension-location()
  return fn:head(
    for $controller-location in $controller-locations
    return
      if (
        dispatcher:action-exists($CONTROLLER-EXTENSION-NAMESPACE, $controller-location, "initialize") and
        dispatcher:action-exists($CONTROLLER-EXTENSION-NAMESPACE, $controller-location, $action)
      ) then
        $controller-location
      else
        ()
  )
};

(:
 : get a model function, either from model-module or base-module
:)
declare function dispatcher:get-controller-action(
  $application as xs:string,
  $controller as xs:string,
  $action as xs:string
) as xdmp:function? {
  let $controller-uri := config:controller-uri($application, $controller)
  let $controller-location := config:controller-location($application, $controller)
  return
    if (dispatcher:action-exists($controller-uri, $controller-location, $action)) then
      xdmp:function(fn:QName($controller-uri, $action), $controller-location)
    else
      let $controller-location := dispatcher:extension-action($action)
      return
        if (fn:exists($controller-location)) then
          xdmp:function(fn:QName($CONTROLLER-EXTENSION-NAMESPACE, $action), $controller-location)
        else
          if (dispatcher:action-exists($BASE-CONTROLLER-NAMESPACE, config:get-base-controller-location(), $action)) then
            xdmp:function(xs:QName("base:" || $action), config:get-base-controller-location())
          else
            ()
};

(:~
 : Checks whether the given view exists in modules database or on filesystem location
 :)
declare function dispatcher:view-exists($view-uri as xs:string) as xs:boolean
{
	module:resource-exists($view-uri)
};

(:~
 :  Returns an errorcode for a given response/request.
 :  If defined the routing will use the application error handler
 :  or if not will use the framework internal one.
 :  @param $ex - Error XML response
 :)
declare function dispatcher:error(
  $ex as element(error:error)
) {
  let $error-map := map:map()
  let $request := if(request:request() instance of map:map) then request:request() else map:map()
  let $_:=
    (
     map:put($error-map,"error",$ex),
     map:put($error-map,"request",request:request()),
     map:put($error-map,"response",response:response())
    )
  return (
    xdmp:log(("Error::[",$ex,"]"),"debug"),
    xdmp:invoke( config:error-handler(),(xs:QName("_ERROR"),$error-map))
  )
};


declare %private function dispatcher:dump-request() {
  if (request:param("debug") eq "true") then (
  	xdmp:log(
      (
        "DUMP-REQUEST",
        text{"url", request:url()},
        text{"format", request:format()},
        text{"method", request:method()},
        "headers", xdmp:to-json(request:get-headers()),
        "params", xdmp:to-json(request:params()),
        "body", request:body()
      ),
      "info"
    )
	)
	else ()
};

(:~
 :  Executes a named controller using REST methods interface
 :)
declare function dispatcher:invoke-controller()
{
  let $application as xs:string? := (request:application(),config:default-application())[1]
  let $controller as xs:string   := (request:controller(),config:default-controller())[1]
  let $action as xs:string       := (request:action())[1]
  let $route  as xs:string?      := request:route()[1]
  let $controller-location       := config:controller-location($application, $controller)
  let $controller-uri            := config:controller-uri($application, $controller)
  let $_ := xdmp:log(
  	text {
  	  "dispatcher:invoke-controller()", "$application", $application, "$controller", $controller, "$action", $action,
  	  "$route", $route, "$controller-location", $controller-location, "$controller-uri", $controller-uri, "method", request:method()
  	},
  	"fine"
  )
  let $_ := dispatcher:dump-request()
  let $request := request:request()
  let $controller-action := dispatcher:get-controller-action($application, $controller, $action)
  let $base-invoke :=  xdmp:function(xs:QName("base:invoke"), config:get-base-controller-location())
  let $eval-options := dispatcher:get-eval-options($action, $controller-action, $route)
  let $_ := xdmp:log(text{"action", $action, $route, xdmp:describe($eval-options)})
  (:let $_ := xdmp:log(text{"$controller-action", xdmp:describe($controller-action)}):)

  return
    if (fn:exists($controller-action)) then
    (
      let $controller-location := xdmp:function-module($controller-action)
      let $controller-uri := fn:namespace-uri-from-QName(fn:function-name($controller-action))
      let $controller-initialize :=
        if (dispatcher:action-exists($controller-uri, $controller-location, "initialize")) then
          xdmp:function(fn:QName($controller-uri,"initialize"),$controller-location)
        else
          ()
      return
      if (fn:empty($eval-options)) then (
        if (fn:exists($controller-initialize)) then $controller-initialize($request) else (),
        if ($controller-location eq config:get-base-controller-location()) then $base-invoke($action) else $controller-action()
      )
      else
        xdmp:invoke-function(
          function() {
            try {
              xdmp:log(text{"invoke action", $action, xdmp:transaction(), xdmp:get-transaction-mode()}),
              if (fn:exists($controller-initialize)) then $controller-initialize($request) else (),
              if ($controller-location eq config:get-base-controller-location()) then $base-invoke($action) else $controller-action(),
              if ($eval-options/eval:isolation eq "different-transaction" or $eval-options/eval:transaction-mode eq "update") then
              (
                xdmp:log((text{"About to commit", xdmp:transaction(), xdmp:get-transaction-mode()})),
                xdmp:commit()
              )
              else
                ()
            } catch ($ex) {
              if ($eval-options/eval:isolation eq "different-transaction" or $eval-options/eval:transaction-mode eq "update") then
              (
                xdmp:log((text{"About to roolback", xdmp:transaction(), xdmp:get-transaction-mode()})),
                xdmp:rollback()
              )
              else (),
              xdmp:rethrow()
            }
          },
          $eval-options
        )
    )
    else
      fn:error(xs:QName("ACTION-NOT-EXISTS"),"The action '" || $action || "' for controller '" || $controller || "' does not exist",($action,$controller))


(:  let $results :=
    if(dispatcher:controller-exists($controller-location) and
      dispatcher:action-exists($controller-uri,$controller-location,$action)
    ) then
      let $controller-func := xdmp:function(fn:QName($controller-uri,$action),$controller-location)
      return $controller-func()
    else if(dispatcher:extension-action-exists($action)) then
      let $controller-location := dispatcher:extension-action($action)
      let $extension-init   :=  xdmp:function(xs:QName("extension:initialize"),$controller-location)
      let $extension-action :=  xdmp:function(xs:QName("extension:" || $action),$controller-location)
      return (
        $extension-init(request:request()),
        $extension-action()
      )
    else if(fn:function-available("base:" || $action )) then (
      let $base-init   :=  xdmp:function(xs:QName("base:initialize"),"../base/base-controller.xqy")
      let $base-invoke :=  xdmp:function(xs:QName("base:invoke"),"../base/base-controller.xqy")
      return
      if (fn:empty($eval-options)) then (
        $base-init(request:request()),
        $base-invoke($action)
      )
      else
        xdmp:invoke-function(
          function() {
            try {
              $base-init($request),
              $base-invoke($action),
              if ($eval-options/eval:isolation eq "different-transaction") then
              (
                xdmp:log((text{"About to commit", xdmp:transaction(), xdmp:get-transaction-mode()})),
                xdmp:commit()
              )
              else
                ()
            } catch ($ex) {
              xdmp:rethrow(),
              if ($eval-options/eval:isolation eq "different-transaction") then
              (
                xdmp:log((text{"About to roolback", xdmp:transaction(), xdmp:get-transaction-mode()})),
                xdmp:rollback()
              )
              else ()
            }
          },
          $eval-options
        )
    )
    else fn:error(xs:QName("ACTION-NOT-EXISTS"),"The action '" || $action || "' for controller '" || $controller || "' does not exist",($action,$controller))
  return $results
:)};

declare function dispatcher:get-eval-options(
  $action as xs:string,
  $controller-action,
  $route
) as element(eval:options)? {
  if (("delete", "create", "login", "logout", "update", "remove", "patch", "save") = $action) then
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
    </options>
(:  else if (("get", "search", "list") = $action) then
    <options xmlns="xdmp:eval">
      <isolation>same-statement</isolation>
      <transaction-mode>query</transaction-mode>
    </options>
:)  else
    ()
};

(:~
 :   Creates the appropriate engine and generates the output response
 :)
declare function dispatcher:invoke-response(
  $request as map:map,
  $response as map:map
) {
  let $application := request:application()[1]
  let $controller := request:controller()[1]
  let $action := request:action()[1]
  let $format := request:format()[1]
  let $debug  := request:debug()[1]
  let $view-uri := fn:concat("/",$application,"/views/",$controller,"/",$controller,".",$action,".",$format,".xqy")
  return (
    if(response:set-response($response,$request)) then (
      (: Provides the view if exists :)
      if(dispatcher:view-exists($view-uri)) then
        if(response:view()) then
          ()
        else (response:set-view($action))
      else
        ()
      ,
      if(response:is-download()) then
      (
        xdmp:set-response-content-type(response:content-type()),
        response:body()
      )
      else
        let $engine := engine:supported-engine($request, $response)
        let $_ :=
        if(fn:not(dispatcher:view-exists($view-uri)))
          then response:set-base(fn:true())
          else ()
        return engine:initialize($engine, $request, $response)
    )
    else
      fn:error(xs:QName("INVALID-RESPONSE"),"Invalid Response",($response))
  )
};

xdmp:log(text{"dispatcher.web", xdmp:transaction(), xdmp:get-transaction-mode(), if (fn:exists(xdmp:request-timestamp())) then "query" else "update"}),
(:xdmp:set-transaction-mode("auto"),:)
try {
  (:Initialize Interceptors:)
  let $init := interceptor:before-request()
  return (
    if(fn:normalize-space(request:redirect()) ne "" and fn:exists(request:redirect())) then  (
      xdmp:redirect-response(request:redirect()),
      xdmp:log(xdmp:log(string-join(("dispatcher::after-request::[",request:redirect(),"]"),""),"debug"))
    )
    else
      let $request := request:parse($init, xdmp:function(xs:QName("engine:set-format")))
      let $request  := interceptor:after-request(request:request())
      return
        if (response:has-error()) then
          fn:error(xs:QName("RESPONSE-HAS-ERROR"))
        else if(request:redirect()) then
          xdmp:redirect-response(request:redirect())
        else if(response:response-code() and response:response-code()[1] >= 400) then
          xdmp:set-response-code(response:response-code()[1], response:response-code()[2])
        else
          let $response :=
            if(fn:normalize-space(request:redirect()) ne ""  and fn:exists(request:redirect())) then
              xdmp:redirect-response(request:redirect())
            else
              let $response := dispatcher:invoke-controller()
              let $response :=
                if($response instance of map:map) then
                  $response
                else (
                  response:initialize(map:new()),
                  response:set-body($response),
                  response:response()
                )
              let $response := interceptor:before-response($request, $response)
              let $response := dispatcher:invoke-response($request, $response)
              let $response := interceptor:after-response(request:request(),$response)
              return
                if(response:redirect()) then
                  xdmp:redirect-response(response:redirect())
                else
                (
                  (: Set HTTP headers :)
                  for $key in map:keys(response:response-headers())
                    return xdmp:add-response-header($key,response:response-header($key))
                  ,
                  (: Set the response content type :)
                  if(fn:exists(response:content-type())) then
                     xdmp:set-response-content-type(response:content-type())
                  else
                    (),
                  (: Set the response code :)
                  if(fn:exists(response:response-code())) then
                    xdmp:set-response-code(response:response-code()[1], response:response-code()[2])
                  else
                    $response
                )
          return  $response
    (:xdmp:log((text{"About to commit", xdmp:transaction(), xdmp:get-transaction-mode()})),:)
    (:,:)
    (:xdmp:commit():)
  )
} catch($ex) {
  (:xdmp:log($ex, "error"),:)
  dispatcher:error($ex)
  (:,:)
  (:xdmp:commit():)
}
(:,
(
  xdmp:log((text{"About to commit", xdmp:transaction(), xdmp:get-transaction-mode()})),
  xdmp:commit()
)


:)
