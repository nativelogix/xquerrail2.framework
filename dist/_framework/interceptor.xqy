xquery version "1.0-ml";
(:~ 

Copyright 2011 - NativeLogix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.




 :)
(:~
 : Controls request/response pipeline interception.  In cases where the application requires the ability to intercept
 : the request/response at various points in the execution context of the dispatcher.
 :
 :)
module namespace interceptor = "http://xquerrail.com/interceptor";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace module = "http://xquerrail.com/module" at "module.xqy";
import module namespace request = "http://xquerrail.com/request" at "request.xqy";
import module namespace response = "http://xquerrail.com/response" at "response.xqy";

declare option xdmp:mapping "false";

declare variable $URI-LOCATION-CACHE := map:map() ;

(:~
 : Returns the interceptor configuration for the application. This is a wrapper call for config:interceptor-config()
 :)
declare function interceptor:config() as element()
{
   config:interceptor-config()
};
(:~
 : Returns the context node associated with the current application:controller:action
 :)declare function interceptor:get-context()
{
   fn:string-join((
       xdmp:get-request-field("_application",config:default-application()),
       xdmp:get-request-field("_controller",config:default-controller()),
       xdmp:get-request-field("_action",config:default-action()),
       xdmp:get-request-field("_format",config:default-format())
    ),":")
};
(:~
 : Returns a list of matching scopes from an interceptor configuration
 : @param $configuration - Configuration XML definition
 :)
declare function interceptor:get-matching-scopes($configuration) {
   let $context := interceptor:get-context()
   let $context-tokens := fn:tokenize($context,":")
   let $scopes := $configuration/config:scope
   return (
      $scopes[@context eq $context],
      for $scope in $scopes
      let $scope-tokens := fn:tokenize($scope/@context,":")
      let $matches :=
         for $scope-token at $pos in $scope-tokens
         return
             if($scope-token eq "*")
             then fn:true()
             else $scope-tokens[$pos] eq $context-tokens[$pos]
      where every $m in $matches satisfies $m eq fn:true()
      return
          $scope
  )
};

declare function interceptor:location-uri(
  $configuration as element(config:interceptor)
  ) as xs:string? {
  if (map:contains($URI-LOCATION-CACHE, $configuration/@name)) then
    map:get($URI-LOCATION-CACHE, $configuration/@name)
  else
    let $location-uri :=
      if (fn:exists($configuration/@uri)) then
        if (fn:starts-with($configuration/@uri, "/")) then
          if (module:resource-exists($configuration/@uri)) then
            $configuration/@uri
          else
            ()
        else
          let $location-uri := config:resolve-path(config:extensions-path(), $configuration/@uri)
          return
            if (module:resource-exists($location-uri)) then
              $location-uri
            else
              ()
      else
        let $location-uri := config:resolve-path(config:framework-path(), fn:concat("interceptors/interceptor.",$configuration/@name,".xqy"))
        return
        if (module:resource-exists($location-uri)) then
          $location-uri
        else
          ()
    return (
      map:put($URI-LOCATION-CACHE, $configuration/@name, $location-uri),
      $location-uri
    )
};
(:~
 : Executes all before request interceptor(s) using the given configuration for that interceptor
 : The before-request interceptor executes before the response has been created or initialized
 :)
declare function interceptor:before-request (
) {
   for $int in config:get-interceptors("before-request")
   (:let $location-uri := fn:concat("interceptors/interceptor.",$int/@name,".xqy"):)
   let $location-uri := interceptor:location-uri($int)
   return
    if (fn:empty($location-uri)) then
      xdmp:log((text{"Could not find location-uri for interceptor"}, $int))
    else
     let $function     := xdmp:function(xs:QName("interceptor:before-request"), $location-uri)
     let $config :=
        if($int/@resource)
        then config:get-resource($int/@resource)
        else if($int/@dbresource) then
            fn:doc($int/@dbresource)
        else <config/>
     let $invoke := xdmp:apply($function,$config)
     return (
       if($invoke instance of map:map)
       then request:initialize($invoke)
       else (),
       xdmp:log(("interceptor:ml-security::before-request",$config,"debug"))
    )
};
(:~
 : Executes all after-request interceptors.  The after-request interceptor is called after the response has been initializes
 : and the controller action has been called.
 : @param $request - A request map that correspondes to the current request map.
 :)
declare function interceptor:after-request(
$request as map:map
){(
      interceptor:invoke-after-request(
        $request,
        config:get-interceptors("after-request"),
        fn:false()
   )
)};
(:~
 : Recursively calls interceptors until either a redirect occurs
 : or all interceptors have run completely
 :)
declare function interceptor:invoke-after-request(
  $request as map:map,
  $interceptors as element(config:interceptor)*,
  $is-redirected as xs:boolean
) {
  if(fn:not($is-redirected) and $interceptors) then
    let $int := $interceptors[1]
    (:let $location-uri := fn:concat("interceptors/interceptor.",$int/@name,".xqy"):)
    let $location-uri := interceptor:location-uri($int)
     return
      if (fn:empty($location-uri)) then
        xdmp:log((text{"Could not find location-uri for interceptor"}, $int))
      else
    let $function     := xdmp:function(xs:QName("interceptor:after-request"),$location-uri)
    let $config :=
       if($int/@resource)
       then config:get-resource($int/@resource)
       else if($int/@dbresource) then
           fn:doc($int/@dbresource)
       else <config/>
    let $invoke := xdmp:apply($function,$request,$config)
    let $_ := request:initialize($request)
    return
      if(request:redirect()) then interceptor:invoke-after-request($request,(),fn:true())
      else interceptor:invoke-after-request($request,$interceptors[2 to fn:last()],fn:false())
  else $request
};

(:~
 : Executes all interceptors after the controller action has been called
 : and before the response is processed by the designated engine.
 : @param $request the request map
 :)
declare function interceptor:before-response(
  $request as map:map?,
  $response as item()*
) as item()*
{(
   let $_response := $response
   let $_ :=
        for $int in config:get-interceptors("before-response")
        (:let $location-uri := fn:concat("interceptors/interceptor.",$int/@name,".xqy"):)
    let $location-uri := interceptor:location-uri($int)
     return
      if (fn:empty($location-uri)) then
        xdmp:log((text{"Could not find location-uri for interceptor"}, $int))
      else
        let $function     := xdmp:function(xs:QName("interceptor:before-response"),$location-uri)
        let $config :=
           if($int/@resource)
           then config:get-resource($int/@resource)
           else if($int/@dbresource) then
               fn:doc($int/@dbresource)
           else <config/>
        let $invoke := xdmp:apply($function,$request,$response,$config)
        return
         xdmp:set($_response,
          if($invoke instance of map:map)
          (:then response:set-response($invoke):)
          then $invoke
          else $_response)
   return $_response
)};

(:~
 : Executes all interceptors after the response has been rendered by the engine
 : and is flushed out to the calling context.
 : it is important that each interceptor is ordered correctly to ensure each interceptor
 : can handle the response properly
 : @param $request - the request map:map
 : @param $response - the response output after invoke-response is called.
 : @return any output by passing through all interceptors
 :)
declare function interceptor:after-response(
  $request as map:map,
  $response as item()*
) as item()*{(
   let $_response := $response
   let $_ :=
        for $int in config:get-interceptors("after-response")
        (:let $location-uri := fn:concat("interceptors/interceptor.",$int/@name,".xqy"):)
    let $location-uri := interceptor:location-uri($int)
     return
      if (fn:empty($location-uri)) then
        xdmp:log((text{"Could not find location-uri for interceptor"}, $int))
      else
        let $function     := xdmp:function(xs:QName("interceptor:after-response"),$location-uri)
        let $config :=
           if($int/@resource)
           then config:get-resource($int/@resource)
           else if($int/@dbresource) then
                fn:doc($int/@dbresource)
           else <config/>
        return xdmp:set($_response, xdmp:apply($function,$request,$response,$config))
   return  $_response
)};
