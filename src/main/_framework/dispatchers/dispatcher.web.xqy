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
import module namespace config      = "http://xquerrail.com/config"      at "../config.xqy";
import module namespace base        = "http://xquerrail.com/controller/base" at "../base/base-controller.xqy";
import module namespace domain      = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace engine      = "http://xquerrail.com/engine" at "../engines/engine.base.xqy";
import module namespace interceptor = "http://xquerrail.com/interceptor" at "../interceptor.xqy";
import module namespace module-loader = "http://xquerrail.com/module" at "../module.xqy";
import module namespace request     = "http://xquerrail.com/request"     at "../request.xqy";
import module namespace response    = "http://xquerrail.com/response"    at "../response.xqy";
import module namespace routing     = "http://xquerrail.com/routing" at "../routing.xqy";
import module namespace logger      = "http://xquerrail.com/logger"      at "../logger.xqy";

declare namespace dispatcher     = "http://xquerrail.com/dispatcher";

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

declare variable $domain:REQUEST-EXTERNAL as json:object external := json:object();
declare variable $domain:REQUEST-BODY-EXTERNAL external := ();

declare variable $EVENT-NAME := "xquerrail.dispatcher.web";
declare variable $BASE-CONTROLLER-NAMESPACE := "http://xquerrail.com/controller/base";
declare variable $CONTROLLER-INITIALIZE-ACTION := "initialize";

declare function dispatcher:get-controller-action(
  $application as xs:string,
  $action as xs:string,
  $controller-namespace as xs:string?,
  $controller-location as xs:string?
) as xdmp:function? {
  let $module-type :=
    if ($controller-namespace eq $domain:CONTROLLER-EXTENSION-NAMESPACE) then
      "controller-extension"
    else if ($controller-namespace eq $BASE-CONTROLLER-NAMESPACE) then
      "base-controller"
    else if ($controller-namespace eq $domain:DOMAINS-CONTROLLER-NAMESPACE) then
      "domains-controller"
    else
      "controller"
  return module-loader:load-function-module(
    $application,
    $module-type,
    $action,
    if ($action ne $CONTROLLER-INITIALIZE-ACTION) then 0 else 1,
    $controller-namespace,
    $controller-location
  )
};

(:
 : get a controller action, either from controller model, controller extensions or base-controller
:)
declare function dispatcher:get-controller-action(
  $application as xs:string,
  $controller as xs:string,
  $action as xs:string
) as xdmp:function? {
  let $controller-namespace := config:controller-uri($application, $controller)
  let $controller-locations := config:controller-location($application, $controller)
  let $functions :=
    for $controller-location in $controller-locations
    let $function := dispatcher:get-controller-action(
      $application,
      $action,
      $controller-namespace,
      $controller-location
    )
    return $function
  let $functions :=
    if (fn:exists($functions)) then
      $functions
    else
      let $function :=
        dispatcher:get-controller-action(
        $application,
        $action,
        $domain:CONTROLLER-EXTENSION-NAMESPACE,
        ()
      )
      return
        if (fn:exists($function)) then
          $function
        else
          let $function :=
            if ($controller eq "domains") then
              dispatcher:get-controller-action(
              $application,
              $action,
              $domain:DOMAINS-CONTROLLER-NAMESPACE,
              ()
            )
            else
              ()
          return
            if (fn:exists($function)) then
              $function
            else
              let $function :=
                dispatcher:get-controller-action(
                $application,
                $action,
                $BASE-CONTROLLER-NAMESPACE,
                ()
              )
              return
                if (fn:exists($function)) then
                  $function
                else
                  ()

  return
    if (fn:count($functions) eq 2) then
    (
      logger:trace($EVENT-NAME, (text{"Found 2 controller actions. Will be using the first", $functions[1]}, $functions)),
      $functions[1]
    )
    else
      $functions
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
  return xdmp:invoke(config:error-handler(), (xs:QName("_ERROR"), $error-map))
};


declare %private function dispatcher:dump-request() {
  if (request:param("debug") eq "true") then (
    logger:info(
      (
        "DUMP-REQUEST",
        text{"url", request:url()},
        text{"format", request:format()},
        text{"method", request:method()},
        "headers", xdmp:to-json(request:get-headers()),
        "params", xdmp:to-json(request:params()),
        "body", request:body()
      )
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
  let $_ := logger:trace(
    $EVENT-NAME,
    text {
      "dispatcher:invoke-controller()", "$application", $application, "$controller", $controller, "$action", $action,
      "$route", $route, "$controller-location", $controller-location, "$controller-uri", $controller-uri, "method", request:method()
    }
  )
  let $_ := dispatcher:dump-request()
  let $request := request:request()
  let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after request:request"})
  let $controller-action := dispatcher:get-controller-action($application, $controller, $action)
  let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after dispatcher:get-controller-action"})
  return
    if (fn:exists($controller-action)) then
    (
      let $controller-location := xdmp:function-module($controller-action)
      (: TODO: Ugly hack for controller extension :)
      let $controller-uri :=
        if ($route eq "xquerrail_domains") then
          $domain:DOMAINS-CONTROLLER-NAMESPACE
        else
          $controller-uri
      (:let $controller-uri := ():)
      let $controller-initialize := dispatcher:get-controller-action($application, "initialize", $controller-uri, $controller-location)
      return (
        if (fn:exists($controller-initialize)) then
          $controller-initialize($request)
        else
          (),
        $controller-action()
      )
    )
    else
      fn:error(xs:QName("ACTION-NOT-EXISTS"),"The action '" || $action || "' for controller '" || $controller || "' does not exist",($action,$controller))
};

declare function dispatcher:get-eval-options(
  $route as xs:string,
  $action as xs:string,
  $method as xs:string
) as element(eval:options)? {
  let $route := routing:get-route-by-id($route)
  let $eval-options :=
    if ($action = ("login", "logout")) then
      <options xmlns="xdmp:eval">
        <transaction-mode>update</transaction-mode>
      </options>
    else if (fn:exists($route/eval:options)) then
      $route/eval:options
    else if ($route/@transaction-mode = ("update")) then
      <options xmlns="xdmp:eval">
        <transaction-mode>{fn:data($route/@transaction-mode)}</transaction-mode>
      </options>
    else if ($route/@transaction-mode = ("query")) then
      ()
    else
      let $method := fn:upper-case($method)
      return
        if ($method = ("DELETE", "PATCH", "POST", "PUT")) then
          <options xmlns="xdmp:eval">
            <transaction-mode>update</transaction-mode>
          </options>
        else
          ()
  return
    if (fn:exists(request:timestamp())) then
      element eval:options {
        $eval-options/*[. except $eval-options/eval:timestamp],
        element eval:timestamp {request:timestamp()}
      }
    else
      $eval-options
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
  return (
    if(response:set-response($response,$request)) then (
      logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "dispatcher:invoke-response - response:set-response:true"}),
      if (xdmp:request-timestamp()) then
        response:add-header("ETag", xs:string(xdmp:request-timestamp()))
      else
        ()
      ,
      if (fn:not(response:view()) and fn:exists($action)) then
        (
          logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "dispatcher:invoke-response - before - response:set-view"}),
          response:set-view($action)
        )
      else
        ()
      ,
      if(response:is-download()) then
      (
        logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "dispatcher:invoke-response - response:is-download:true"}),
        xdmp:set-response-content-type(response:content-type()),
        response:body()
      )
      else
        let $engine := engine:supported-engine($request, $response)
        let $_ := response:set-base(fn:true())
        return (
          logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "dispatcher:invoke-response - before - engine:initialize"}),
          engine:initialize($engine, $request, $response)
        )
    )
    else
      fn:error(xs:QName("INVALID-RESPONSE"),"Invalid Response",($response))
  )
};

declare function dispatcher:is-reponse-object(
  $response as item()*
) as xs:boolean {
  (
    $response instance of map:map and
    (some $item in map:keys($response) satisfies fn:starts-with($item, "response:"))
  )

};

declare function dispatcher:process-request() {
  (:If the request is external then you cant rely on xdmp:get-request-xxx:)
  if (fn:exists($domain:REQUEST-BODY-EXTERNAL))
    then map:put($domain:REQUEST-EXTERNAL, "request:body", $domain:REQUEST-BODY-EXTERNAL)
  else (),
  if(map:count($domain:REQUEST-EXTERNAL) gt 0)
  then request:initialize($domain:REQUEST-EXTERNAL)
  else request:parse(())[0],
  let $is-external := map:count($domain:REQUEST-EXTERNAL) gt 0
  let $route :=
    if($is-external)
    then (request:route(),"GET")[1]
    else xdmp:get-request-field("_route","")
  let $action :=
     if($is-external)
     then request:action()
     else xdmp:get-request-field("_action","")
  let $method :=
    if($is-external)
    then request:method()
    else xdmp:get-request-method()
  let $eval-options :=
    dispatcher:get-eval-options(
      $route,
      $action,
      fn:upper-case($method)
    )
  let $process := function() {
    try {
      let $init := interceptor:before-request()
      let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - interceptor:before-request"})
      let $request :=
        if(map:count($domain:REQUEST-EXTERNAL) gt 0)
        then request:initialize($domain:REQUEST-EXTERNAL)
        else (
          request:initialize(map:new()),
          request:parse($init, xdmp:function(xs:QName("engine:set-format")))
        )
      let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - request:parse"})
      let $request := interceptor:after-request(request:request())
      let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - interceptor:after-request"})
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
              let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - dispatcher:invoke-controller"})
              let $response :=
                if(dispatcher:is-reponse-object($response)) then
                  $response
                else (
                  response:initialize(map:new()),
                  response:set-body($response),
                  response:response()
                )
              let $response := interceptor:before-response($request, $response)
              let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - interceptor:before-response"})
              let $response := dispatcher:invoke-response($request, $response)
              let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - dispatcher:invoke-response"})
              let $response := interceptor:after-response(request:request(),$response)
              let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - interceptor:after-response"})
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
    } catch($ex) {
      dispatcher:error($ex)
    }
  }
  let $_ := logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "dispatcher:process-request - before", $action, $route, xdmp:describe($eval-options)})
  return
    if (fn:empty($eval-options)) then (
      $process()
    )
    else (
      logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "before - xdmp:invoke-function"}),
      xdmp:invoke-function(
        function() {
          logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "before - $process"}),
          $process(),
          logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "before - commmit"}),
          xdmp:commit(),
          logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "after - commit"})
        },
        $eval-options
      )
    )

};
logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "start", xdmp:get-transaction-mode(), if (fn:exists(xdmp:request-timestamp())) then "query" else "update"}),
if (fn:exists(xdmp:request-timestamp())) then
  ()
else logger:error("dispatcher.web is running in 'update' transaction type"),
(:Initialize Interceptors:)
let $_ := interceptor:before-request()
return
  if(fn:normalize-space(request:redirect()) ne "" and fn:exists(request:redirect())) then  (
    xdmp:redirect-response(request:redirect()),
    logger:trace($EVENT-NAME, string-join(("dispatcher::after-request::[",request:redirect(),"]"),""))
  )
  else
    dispatcher:process-request(),
logger:trace($EVENT-NAME, text{xdmp:transaction(), xdmp:elapsed-time(), "completed"})
