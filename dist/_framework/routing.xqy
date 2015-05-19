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
 : Provides Routing Module for allowing URL mapping to controllers and resources.
 : The entry module for the xquerrail rewriter will call the get-route method which returns
 : a string of the rewritten url.
 :)
module namespace routing ="http://xquerrail.com/routing";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";

declare %private variable $INITIALIZE-ROUTE :=
  <route id="xquerrail_initialize" pattern="^/initialize(.xqy)?$" is-resource="true" xmlns="http://xquerrail.com/routing">
    <to>{config:resolve-path(config:framework-path(), "initialize.xqy")}</to>
  </route>
;

declare variable $routes := config:get-routes();

declare function routing:get-routes() {
  element {$routes/fn:name()} {
    $routes/namespace::*,
    $routes/attribute::*,
    $routing:INITIALIZE-ROUTE,
    $routes/node()
  }
};

declare function routing:get-route-by-id($id as xs:string
) as element(routing:route)? {
  fn:zero-or-one(routing:get-routes()//routing:route[@id eq $id])
};

(:~
 : Function returns if a given route is valid according to schema definition
 :)
declare function routing:route-valid($route as element(routing:route))
{
  fn:true()
};

(:~
 : Converts a list of map values to a parameter string
 :)
declare function routing:map-to-params($map as map:map)
{
  fn:string-join(
   for $k in map:keys($map)
   order by $k
   return
   for $v in map:get($map,$k)
   return
      fn:concat($k,"=",fn:string($v))
  ,"&amp;")
};

(:~
 : Returns the default route for a given url
 : @param $url - Url to find the matching route.
 :)
declare function routing:get-route($url as xs:string)
{
  let $params-map := map:map()
  let $params := if(fn:contains($url,"?")) then fn:substring-after($url,"?") else ()
  let $path   := if(fn:contains($url,"?")) then fn:substring-before($url,"?") else $url
  let $request-method := fn:lower-case(xdmp:get-request-method())
  let $matching-routes := routing:get-routes()//routing:route[fn:matches($path, ./@pattern, "six")]
  let $matching-route := (
    if($matching-routes[$request-method eq @method]) then
      $matching-routes[$request-method eq @method]
    else
      $matching-routes[fn:not(@method)]
  )[1]

  let $is-resource := xs:boolean(($matching-route/@is-resource, fn:false())[1])
  let $route :=
    if($is-resource) then
      let $resource-path :=
        if($matching-route/routing:to) then
          fn:concat($matching-route/(@to,routing:to)[1],"?",$params)
        else if($matching-route/routing:replace) then
         fn:concat(fn:replace($path,$matching-route/@path,$matching-route/routing:replace),"?",$params)
        else if($matching-route/routing:prepend) then
         fn:concat($matching-route/routing:prepend,$path,"?",$params)
        else
          $path
      return
        if(config:resource-handler()) then
          fn:concat(
            config:resource-handler()/@resource,"?_url=",
            $resource-path,
            if($params ne "") then
              fn:concat("&amp;",$params)
            else
              ()
          )
        else
          $resource-path
    else if($matching-route) then
      let $controller := $matching-route/routing:default[@key eq "_controller"]
      let $parts      := fn:tokenize(fn:normalize-space($controller),":")
      let $add-params := (
        map:put($params-map,"_route",fn:data($matching-route/@id)),
        map:put($params-map,"_url",xdmp:url-encode($url)),
        for $p in $matching-route/routing:param
        return
          if(fn:matches($p,"\$\d")) then
            map:put($params-map,$p/@key, fn:replace($path,$matching-route/@pattern,$p))
          else
            map:put($params-map,$p/@key,$p/text())
      )
      let $defaults   :=
        for $i in (1 to 4)
        let $value := fn:string(fn:subsequence($parts,$i,1))
        return (:Need to support regex parameters:)
          if ($i eq 1) then
            map:put($params-map,"_application",$value)
          else if($i eq 2) then
            if(fn:matches($value,"^\$\d+")) then
              let $controller := fn:replace($path,$matching-route/@pattern,$value)
              return map:put($params-map,"_controller",fn:concat(fn:lower-case(fn:substring($controller, 1, 1)),fn:substring($controller, 2, fn:string-length($controller))))
            else
              map:put($params-map,"_controller",($value,config:default-controller())[1])
          else if($i eq 3) then
            if(fn:matches($value,"^\$\d+")) then
              let $action := fn:replace($path,$matching-route/@pattern,$value)
              return map:put($params-map,"_action",fn:concat(fn:lower-case(fn:substring($action, 1, 1)),fn:substring($action, 2, fn:string-length($action))))
            else
              map:put($params-map,"_action",($value,config:default-action())[1])
          else if($i eq 4) then
            if(fn:matches($value,"^\$\d+")) then
              map:put($params-map,"_format",fn:replace($path,$matching-route/@pattern,$value))
            else
              map:put($params-map,"_format",$value)
          else ()
      let $new-url := fn:concat(config:get-dispatcher(),"?",map-to-params($params-map),if($params ne "") then fn:concat("&amp;",$params) else ())
      return
      (
        xdmp:log(("rewriter url:",$new-url),"finest"),
        if(fn:normalize-space($new-url) eq "") then
          fn:error(xs:QName("NO-ROUTE"),fn:concat("No Route for ", $path), $path)
        else
          $new-url
      )
    else
      (
        xdmp:log(("Not Routing Right",$url),"debug"),
        "/" ,
        xdmp:set-response-code(404,$path)
      )
  return (xdmp:log(("route:",$route),"finest"),$route)
};
