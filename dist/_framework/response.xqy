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
 : Response Helper function wrapper.
 :)
module namespace response = "http://xquerrail.com/response";

import module namespace request = "http://xquerrail.com/request" at "request.xqy";
import module namespace config  = "http://xquerrail.com/config"  at "config.xqy";
import module namespace util = "http://xquerrail.com/util" at "lib/util.xqy";

declare namespace domain = "http://xquerrail.com/domain";


declare variable $CONTENT-TYPE := "response:content-type";

declare variable $CONTEXT     := "response:context";
declare variable $DOCTYPE     := "response:doctype";
declare variable $CODE        := "response:code";
declare variable $ENCODING    := "response:encoding";
declare variable $VIEW        := "response:view";
declare variable $REDIRECT    := "response:redirect";
declare variable $TEMPLATE    := "response:template";
declare variable $BODY        := "response:body";
declare variable $APPLICATION := "response:application";
declare variable $FORMAT      := "response:format";
declare variable $CONTROLLER  := "response:controller";
declare variable $ACTION      := "response:action";
declare variable $ERROR       := "response:error";
declare variable $PARTIAL     := "response:partial";
declare variable $BASE        := "response:base";
declare variable $MODEL       := "response:model";
declare variable $DOWNLOAD    := "response:download";

declare variable $USER        := "response:user";
(:Default Prefix for Slots:)
declare variable $HEADER       := "response:header::";
declare variable $PARAMETER    := "response:parameter::";
declare variable $SLOT-PREFIX  := "response:slot::";
declare variable $META         := "response:meta::";
declare variable $HTTPMETA     := "response:httpmeta::";
declare variable $STYLESHEET   := "response:stylesheet::";
declare variable $JAVASCRIPT   := "response:javascript::";
declare variable $COOKIE       := "response:cookie::";
declare variable $FLASH        := "response:flash::";
(:~
 : Response Map used to store all response information
 :)
declare variable $response := map:map();

declare function response:__init__() {
   response:initialize-flash()[0]
};

declare function response:__destroy__() {
   response:save-flash()[0]
};
declare function response:initialize($response)
{
   response:initialize($response,())
};

(:~
 : Initializes a response and returns a new response object
 :)
declare function response:initialize(
    $response as map:map,
    $request as map:map?
)
{
   let $init := response:set-response($response)
   let $defaults :=
     if(fn:exists($request))
     then response:set-defaults($request)
     else ()
   return
   if($init) then ()
   else fn:error(xs:QName("INITIALIZATION-ERROR"),"Unable to initialize response",$response)
};

declare function response:set-response($_response)
{
  response:set-response($_response,map:map())
};

declare function response:set-base($isbase as xs:boolean)
{
   map:put($response,$BASE,$isbase)
};

declare function response:base()
{
   map:get($response,$BASE) eq fn:true()
};
(:~
 : Sets the response object for convenience features
 :)
declare function response:set-response(
  $_response as map:map,
  $_request as map:map?
) {
  try {
   (xdmp:set($response, $_response),response:set-defaults($_request),fn:true() )
  } catch($ex)
  {
    xdmp:rethrow()
  }
};

(:~
: Sets the defaults from the request map
:)
declare private function response:set-defaults($_request)
{
   let $_ := request:initialize($_request)
   return
    if(fn:exists($_request)) then (
        if(fn:exists(response:application())) then () else response:set-application(fn:data(request:application())),
        if(fn:exists(response:controller()))  then () else response:set-controller(fn:data(request:controller())),
        if(fn:exists(response:action()))      then () else response:set-action(fn:data(request:action())),
        if(fn:exists(response:view()))        then () else response:set-view(fn:data(request:action())),
        if(fn:exists(response:format()))      then () else response:set-format(fn:data(request:format())),
        if(fn:exists(response:partial()))     then () else response:set-partial(fn:data(request:partial())),
        if(fn:exists(response:user()))        then () else response:set-user(fn:data(request:user-name()))
   ) else ()

};
declare function response:set-user($user)
{
   map:put($response,$USER,$user)
};

declare function response:user()
{
   map:get($response,$USER)
};

declare private function response:save-flash() {
  (
    let $flash-map := map:map()
    let $_  :=
        for $fl in map:keys($response)[fn:starts-with(.,$FLASH)]
        return map:put($flash-map,$fl,map:get($response,$fl))
    return(
      xdmp:log(("Saving Flash",$flash-map), "debug"),()
      (:DISABLED:: xdmp:set-session-field("FLASH",$flash-map):)
  ))
};
declare private function response:initialize-flash() as empty-sequence() {
    let $sess-field := () (:DISABLING xdmp:get-session-field("FLASH"):)
    let $_ :=       xdmp:log(("Loading Flash",$sess-field), "debug")
    let $flash-map  :=
        if($sess-field instance of map:map)
        then $sess-field
        else map:map()
    let $_ := for $key in map:keys($flash-map) return map:put($response,$key,map:get($flash-map,$key))
    return ()
};

declare function response:has-flash() as xs:boolean {
   fn:exists(map:keys($response)[fn:starts-with(., $FLASH)])
};

declare function response:has-flash($code) as xs:boolean{
   fn:exists(map:get($response,fn:concat($FLASH,$code)))
};

(:~
 : The Flash message is a convenient may to store information
 : between requests redirects for validation and other things.
 : THe flash object is cleared between request/response calls.
 : @param $name as xs:string
 :)
declare function response:set-flash($name as xs:string,$message as xs:string)
{
  map:put($response,fn:concat($FLASH,$name),$message)
};

declare function response:flash($code){
    map:get($response,fn:concat($FLASH,$code))
};

(:~
 : In order to Route the request you must flush the map at the end
 : of a controller response.  The map is used by the dispatcher
 : finalize the rendering process.
 :)
declare function response:flush()
{
    $response
};

(:~
 :
 :)
declare function response:response()
{
    $response
};


declare function response:error()
{
   map:get($response,$ERROR)
};

declare function response:set-error(
  $code as xs:integer,
  $error as item()
) {
  map:put($response,$ERROR,($code,$error))
};

declare function response:has-error()
{
  fn:exists(map:get($response,$ERROR))
};
declare function response:set-format($format)
{
   map:put($response,$FORMAT,$format)
};
declare function response:format()
{
   map:get($response,$FORMAT)
};
declare function response:set-body($body)
{
  map:put($response,$BODY,$body)
};
declare function response:body()
{
  map:get($response,$BODY)
};
declare function response:set-context($context)
{
  map:put($response,$CONTEXT,$context)
};
declare function response:context()
{
  map:get($response,$CONTEXT)
};


declare function response:set-response-code(
    $code as xs:integer,
    $message as xs:string
)
{
  map:put($response,$CODE,($code,$message))
};

declare function response:response-code()
{
   map:get($response,$CODE)
};

declare function response:set-content-type(
    $name as xs:string
)
{
    map:put($response,$CONTENT-TYPE,$name)
};

declare function response:content-type()
{
  map:get($response,$CONTENT-TYPE)
};

declare function response:set-application($application as xs:string)
{
   map:put($response,$APPLICATION,$application)
};
declare function response:application()
{
   map:get($response,$APPLICATION)
};
declare function response:set-controller($controller as xs:string)
{
   map:put($response,$CONTROLLER,$controller)
};

declare function response:controller()
{
  map:get($response,$CONTROLLER)
};

declare function response:set-action($action as xs:string)
{
   map:put($response,$ACTION,$action)
};

declare function response:action()
{
   map:get($response,$ACTION)
};
declare function response:partial()
{
  let $is-partial := map:get($response,$PARTIAL)
  return
    $is-partial

};

declare function response:set-partial($view as xs:boolean)
{
    map:put($response,$PARTIAL,$view)
};

declare function response:set-view($view as xs:string)
{
  map:put($response,$VIEW,$view)
};

declare function response:view()
{
 map:get($response,$VIEW)
};

declare function response:set-template($template as xs:string)
{
  map:put($response,$TEMPLATE,$template)
};

declare function response:template()
{
  map:get($response,$TEMPLATE)
};
declare function response:redirect($controller as xs:string,$action as xs:string) {
   response:redirect($controller,$action,config:default-format())
};
declare function response:redirect($controller as xs:string,$action as xs:string,$format)
{
     map:put($response,$REDIRECT,fn:concat("/",$controller,"/",$action,".",$format))
};
(:~
 : Sets the response redirect uri.  Redirection is not immediately processed an deferred by dispatcher
 : to allow interceptors to interact with the response before redirection
 : @param $uri - is the complete uri of the redirection response
 :)
declare function response:redirect($uri as xs:string)
{

   map:put($response,$REDIRECT,$uri)
};
(:~
 : Returns the definition of the redirection
 :)
declare function response:redirect()
{
   map:get($response,$REDIRECT)
};
(:~
 :
 :)
declare function response:add-header($key as xs:string,$value as xs:string*)
{
   response:add-response-header($key,$value)
};

(:~
 : Adds a response header to response
 :)
declare function response:add-response-header($key as xs:string,$value as xs:string*)
{
   map:put($response,fn:concat($HEADER,fn:lower-case($key)),fn:string-join($value,"; "))
};

(:~
 : Returns a response header by key
 :)
declare function response:response-header($key as xs:string)
{
   map:get($response,fn:concat($HEADER,fn:lower-case($key)))
};

declare function response:response-headers() as map:map
{
   let $headers := map:map()
   return
   (
   for $k in map:keys($response)[fn:starts-with(.,$HEADER)]
   return map:put($headers,fn:replace($k,$HEADER,""),map:get($response,$k)),
   $headers
   )
};

declare function response:add-param(
  $key as xs:string,
  $value as xs:string
) as empty-sequence()
{
   let $pkey := fn:concat($PARAMETER,$key)
   return
     map:put($response,$pkey,(map:get($response,$pkey),$value))
};

declare function response:set-param(
  $key as xs:string,
  $value as xs:string
) as empty-sequence() {
   let $pkey := fn:concat($PARAMETER,$key)
   return
     map:put($response,$pkey,$value)
};

declare function response:delete-param($key as xs:string)
{
   let $pkey := fn:concat($PARAMETER,$key)
   return
   map:delete($response,$pkey)
};

declare function response:delete-param($key as xs:string,$value as xs:string)
{
  let $pkey := fn:concat($PARAMETER,$key)
  return
    map:put($response,$pkey, map:get($response,$pkey)[. != $value])
};

declare function response:param($key)
{
   map:get($response,fn:concat($PARAMETER,$key))
};


declare function response:get-data($key as xs:string)
{
   map:get($response,$key)
};

declare function response:set-data($key as xs:string,$value as item()*)
{
  map:put($response,$key,$value)
};

declare function response:data($key as xs:string)
{
  response:get-data($key)
};

declare function response:add-data($key as xs:string,$value as item()*)
{
  map:put($response,$key,(map:get($response,$key),$value))
};

(:~
 : Returns all slots defined in response
 :)
declare function response:slots()
{
  for $slot in map:keys($response)[fn:starts-with(.,$SLOT-PREFIX)]
  return
     fn:replace($slot,$SLOT-PREFIX,"")
};

declare function response:set-slot($key,$value)
{
   map:put($response,fn:concat($SLOT-PREFIX,$key),$value)
};

declare function response:has-slot($key)
{
  fn:exists(map:get($response,fn:concat($SLOT-PREFIX,$key)))
};

declare function response:slot($key)
{
   map:get($response,fn:concat($SLOT-PREFIX,$key))
};
(:~
 :
 :)
declare function response:set-title($value)
{
  map:put($response,"TITLE",
     if($value instance of attribute())
     then fn:data($value)
     else $value)
};

(:~
 : Set the title for the given response page
 :)
declare function response:title()
{
  map:get($response,"TITLE")
};

(:~
 :META~

 :)
declare function response:add-meta($key,$value)
{
  map:put($response,fn:concat($META,$key),$value)
};

declare function response:add-meta($key as xs:string,$value as xs:string,$append as xs:boolean)
{
     let $mkey := fn:concat($META,$key)
     return
     if($append)
     then  map:put($response,$mkey,(map:get($response,$mkey),$value))
     else  map:put($response,$mkey,$value)
};

declare function response:meta($key)
{
   map:get($response,fn:concat($META,$key))
};

declare function response:meta-keys()
{
   for $n in map:keys($response)[fn:starts-with(.,$META)]
   return
      fn:replace($n,$META,"")
};

declare function response:metas()
{
   for $key in response:meta-keys()
   for $m  in response:meta($key)
   return
    element meta{
      attribute name{$key},
      attribute content {$m}
    }
};

(:~HTTP META :)
declare function response:add-httpmeta($key,$value)
{
  map:put($response,fn:concat($HTTPMETA,$key),$value)
};

declare function response:add-httpmeta($key as xs:string,$value as xs:string,$append as xs:boolean)
{
     let $mkey := fn:concat($HTTPMETA,$key)
     return
     if($append)
     then  map:put($response,$mkey,(map:get($response,$mkey),$value))
     else  map:put($response,$mkey,$value)
};

declare function response:httpmeta($key)
{
   map:get($response,fn:concat($HTTPMETA,$key))
};

declare function response:httpmeta-keys()
{
   for $n in map:keys($response)[fn:starts-with(.,$HTTPMETA)]
   return
      fn:replace($n,$HTTPMETA,"")
};

declare function response:httpmetas()
{
   for $key in response:httpmeta-keys()
   for $m  in response:httpmeta($key)
   return
    element meta{
      attribute http-equiv{$key},
      attribute content {$m}
    }
};

(:Cookies:)
(:~
 : Returns an RFC 822 compliant date string from the given dateTime,
 : that is suitable for use in a cookie header.
 :
 : @param $date the date and time to convert into a string
 :
 : @return the RFC 822 complient date string.
 :
 :)
declare %private function response:get-cookie-date-string($date as xs:dateTime) as xs:string
{
  let $gmt := xs:dayTimeDuration("PT0H")
  let $date := fn:adjust-dateTime-to-timezone($date, $gmt)
  let $day := util:two-digits(fn:day-from-dateTime($date))
  let $month := fn:month-from-dateTime($date)
  let $year := fn:string(fn:year-from-dateTime($date))
  let $hours := util:two-digits(fn:hours-from-dateTime($date))
  let $minutes := util:two-digits(fn:minutes-from-dateTime($date))
  let $seconds := util:two-digits(xs:integer(fn:round(fn:seconds-from-dateTime($date))))
  let $monthNames := ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  return fn:concat(
    $day, "-",
    $monthNames[$month], "-",
    $year, " ",
    $hours, ":",
    $minutes, ":",
    $seconds, " GMT"
  )
};

declare function response:set-cookie(
  $name as xs:string,
  $value as xs:string,
  $max-age as xs:duration?,
  $secure-flag as xs:boolean?,
  $domain as xs:string?,
  $path as xs:string?
) as xs:string? {
    fn:string-join(
      (
        fn:concat(xdmp:url-encode($name), "=", xdmp:url-encode($value)),
        "HttpOnly",
        if (fn:exists($max-age)) then
          fn:concat("Max-Age=", util:total-seconds-from-duration($max-age))
        else
          ()
        ,
        if ($secure-flag) then
          "Secure"
        else
          ()
        ,
        if ($domain) then
          fn:concat("Domain=", $domain)
        else
          ()
        ,
        if ($path) then
          fn:concat("Path=", $path)
        else
          ()
       )
       , "; "
    )
};

declare function response:add-cookie(
  $name as xs:string,
  $value as xs:string,
  $max-age as xs:duration?,
  $secure-flag as xs:boolean?,
  $domain as xs:string?,
  $path as xs:string?
) as empty-sequence() {
  xdmp:add-response-header("Set-Cookie", response:set-cookie($name, $value, $max-age, $secure-flag, $domain, $path)
  )
};

declare function response:add-cookie(
  $name as xs:string,
  $value as xs:string
) as empty-sequence() {
  response:add-cookie($name, $value, (), (), (), ())
};

declare function response:cookies(
) as map:map {
  let $cookies := request:get-header("Cookie")
  return
  map:new((
    for $cookie in fn:tokenize($cookies, "; ")
    return
      map:entry(xdmp:url-decode(fn:substring-before($cookie, "=")), xdmp:url-decode(fn:substring-after($cookie, "=")))
  ))
};

declare function response:cookie(
  $name as xs:string
) as xs:string? {
  map:get(response:cookies(), $name)
};

declare function response:remove-cookie(
  $name as xs:string
) as empty-sequence() {
  response:remove-cookie($name, (), (), ())
};

declare function response:remove-cookie(
  $name as xs:string,
  $secure-flag as xs:boolean?,
  $domain as xs:string?,
  $path as xs:string?
) as empty-sequence() {
  response:add-cookie($name, "", xs:dayTimeDuration('PT0S'), $secure-flag, $domain, $path)
};

(:Javascript Response Functions:)
(:~
 : Retuns a list of all the javascripts defined in the response
 :)
declare function response:javascripts()
{
  for $k in map:keys($response)[fn:starts-with(.,$JAVASCRIPT)]
  return
     fn:substring-after($k,$JAVASCRIPT)
};
(:~
 : Adds a javascript by name and adds options to it.
 :)
declare function response:add-javascript(
$name as xs:string,
$position as xs:string,
$options as element(response:options)
) {
   map:put($response,fn:concat($JAVASCRIPT,$name),
   (<script type="text/javascript" src="{config:resource-directory()}/{$name}.js">//</script>,
     $options
     )
   )
};
(:~
 : Add a javscript library by name
 :)
declare function response:add-javascript($name)
{
   map:put($response,fn:concat($JAVASCRIPT,$name),
   let $url :=
      fn:concat(
        config:resource-directory(),
        if(fn:ends-with(config:resource-directory(),"/")) then () else "/",
        $name,
        ".js")
   return
       <script type="text/javascript" src="{$url}">//</script>
   )
};
(:~
 : Removes a javascript by its name
 :)
declare function response:remove-javascript($name)
{
  map:delete($response,fn:concat($JAVASCRIPT,$name))
};
(:~
 : Clears out all javascripts for the output
:)
declare function response:clear-javascripts()
{
  for $k in map:keys($response)[fn:starts-with(.,$JAVASCRIPT)]
  return map:delete($response,$k)
};

(:Stylesheets:)
(:~
 : Returns all the stylesheets defined in the response
 :)
declare function response:stylesheets()
{
  for $k in map:keys($response)[fn:starts-with(.,$STYLESHEET)]
  return
     fn:substring-after($k,$STYLESHEET)
};
(:~
 : Adds a stylesheet by its name from the resource-directory in config.xml
 :)
declare function response:add-stylesheet($name)
{
   map:put($response,fn:concat($STYLESHEET,$name),
         <link rel="stylesheet" href="/{config:resource-directory()}/css/{$name}.css" type="text/css" media="all" />
   )
};
(:~
 : Adds a stylesheet by name
  :)
declare function response:add-stylesheet($name as xs:string,$params as xs:string*)
{
   map:put($response,fn:concat($STYLESHEET,$name),
         <link rel="stylesheet" href="{config:resource-directory()}/css/{$name}.css" type="text/css" media="all" />
   )
};
(:~
 : Removes a stylesheet from the response by name
 : @param $name - The name of stylesheet to remove.
 :)
declare function response:remove-stylesheet($name)
{
  map:delete($response,fn:concat($STYLESHEET,$name))
};
(:~
 : Clears all response stylesheets
  :)
declare function response:clear-stylesheets()
{
  for $k in map:keys($response)[fn:starts-with(.,$STYLESHEET)]
  return map:delete($response,$k)
};
(:~
 : Sets the model for the response
  :)
declare function response:set-model($model as element(domain:model)?) {
  map:put($response,$MODEL,$model)
};
(:~
 : Returns the model set for the response
  :)
declare function response:model() {
  map:get($response,$MODEL)
};
(:~
 : Sets the is-download to a given value
 :)
declare function response:is-download($value as xs:boolean) {
  map:put($response,$DOWNLOAD,$value)
};

(:~
 : Returns if the response is a download. This will set the Content-Disposition header as an attachment.
:)
declare function response:is-download() as xs:boolean {
  map:get($response,$DOWNLOAD) = fn:true()
};
(:~
 : Sets the response code
 :)
declare function response:set-code($code as xs:integer) {
  map:put($response,$CODE,$code)
};
(:~
 : Returns the response code
  :)
declare function response:code() {
   map:get($response,$CODE)
};
