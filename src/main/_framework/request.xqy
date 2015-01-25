xquery version "1.0-ml";

(:~
 : This request controls all serialization of request map
 : - All HTTP request elements in a single map:map type.
 :)
module namespace request = "http://xquerrail.com/request";

import module namespace mljson  = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";

declare option xdmp:mapping "false";

declare private variable $REQUEST-ID        := "request:request";
declare private variable $BODY              := "request:body";
declare private variable $BODY-XML          := "request:body-xml";
declare private variable $BODY-TEXT         := "request:body-text";
declare private variable $BODY-BINARY       := "request:body-binary";
declare private variable $METHOD            := "request:method";
declare private variable $CONTENT-TYPE      := "request:content-type";
declare private variable $BODY-TYPE         := "request:body-type";
declare private variable $PROTOCOL          := "request:protocol";
declare private variable $USERNAME          := "request:username";
declare private variable $USERID            := "request:userid";
declare private variable $PATH              := "request:path";
declare private variable $URL               := "request:url";
declare private variable $ORIGIN            := "request:origin";
declare private variable $CONTEXT           := "request:context";
declare private variable $APPLICATION       := "request:application";
declare private variable $CONTROLLER        := "request:controller";
declare private variable $ACTION            := "request:action";
declare private variable $FORMAT            := "request:format";
declare private variable $ROUTE             := "request:route";
declare private variable $VIEW              := "request:view";
declare private variable $PARTIAL           := "request:partial";
declare private variable $REDIRECT          := "request:redirect";
declare private variable $REDIRECT-CODE     := "request:redirect-code";
declare private variable $FILTERS           := "filters";
declare private variable $DEBUG             := "request:debug";
declare private variable $COLLECTION        := "request:collection";
declare private variable $HEADER-PREFIX     := "request:header::";
declare private variable $PARAM-PREFIX      := "request:param::";
declare private variable $PARAM-CONTENT-TYPE-PREFIX := "request:field-content-type::";
declare private variable $PARAM-FILENAME-PREFIX   := "request:field-filename::";
declare private variable $ERROR             := "request:error";
declare private variable $ERROR-CODE        := "request:error-code";
declare private variable $ERROR-MESSAGE     := "request:error-message";
declare private variable $SYS-PARAMS := ("_application","_controller","_action","_view","_context","_format","_url","_route","_partial","_debug");
declare private variable $IS-MULTIPART      := "request:multipart";
declare private variable $MULTIPART-BOUNDARY := "request:multipart-boundary";

(:~Global Request Variable  :)
declare private variable $request as map:map :=
 let $init := map:map()
 return (
    map:put($init,"type", $REQUEST-ID),
    $init
 );

(:~
 : Decodes a binary request into string
 :)
declare function request:hex-decode($hexBin as xs:hexBinary) as xs:string {
    request:hex-decode($hexBin, fn:floor(fn:string-length(fn:string($hexBin)) div 2))
};

(:~
 : Binary Decoder used for 4.1x before xdmp:binary-decode()
 :)
declare function request:hex-decode($hexBin as xs:hexBinary, $length as xs:integer) as xs:string {
    let $string := fn:substring(fn:string($hexBin),1,$length * 2)
    let $bytes as xs:integer* :=
        for $pos in 1 to fn:string-length($string)
        let $half-byte := fn:substring($string, $pos, 1)
        let $next-half-byte := fn:substring($string, $pos + 1, 1)
        where ($pos mod 2) = 1
        return
            xdmp:hex-to-integer(fn:concat($half-byte, $next-half-byte))

    return
        fn:codepoints-to-string($bytes)
};

(:~
 : Returns the map:map of the request
 :)
declare function request:request()
{
  $request
};

(:~
 : Joins a request map with another request-map
 :)
declare function request:joinx($params as map:map)
{
   let $_ := xdmp:set($request, $request + ($request - $params) )
   return $request
};
(:~
 :  Wraps the http response into a map:map
 :  Accessing the map can be used the following keys
 :  map:get($response, "field:xxx")
 :  Accessors:
 :      request:header::xxxx
 :      request:param::xxxx
 :      request:body
 :)
declare function request:initialize($_request as map:map) as empty-sequence() {
  xdmp:set($request:request, $_request)
};


declare function request:parse($parameters) as map:map {
  request:parse($parameters, ())
};

(:~
 :  Parses the map pulling all the required information from http request
 :)
declare function request:parse($parameters, $set-format) as map:map {

   (:Insert all custom headers:)
   let $headers :=
        for $i in xdmp:get-request-header-names()
        return
            for $j in xdmp:get-request-header($i)
            return
               map:put($request, fn:concat($HEADER-PREFIX,$i),$j)
   (:Map All common request information:)
   let $rests :=
      (
        map:put($request, $APPLICATION,xdmp:get-request-field("_application",config:default-application())),
        map:put($request, $CONTROLLER, xdmp:get-request-field("_controller",config:default-controller())),
        map:put($request, $ACTION,     xdmp:get-request-field("_action",config:default-action())),
        map:put($request, $FORMAT,     xdmp:get-request-field("_format"(:,config:default-format():))),
        map:put($request, $VIEW,       xdmp:get-request-field("_view",request:action())),
        map:put($request, $ORIGIN,     xdmp:get-request-field("_url",xdmp:get-request-field("_url"))),
        map:put($request, $ROUTE,      xdmp:get-request-field("_route","")),
        map:put($request, $PARTIAL,    xdmp:get-request-field("_partial","false")),
        map:put($request, $DEBUG,      xdmp:get-request-field("_debug","false")[1]),
        map:put($request, $COLLECTION, xdmp:get-request-field("_collection")),
        map:put($request, $METHOD,     xdmp:get-request-method()),
        map:put($request, $PATH,       xdmp:get-request-path()),
        map:put($request, $URL,        xdmp:get-request-url()),
        map:put($request, $PROTOCOL,   xdmp:get-request-protocol()),
        map:put($request, $USERNAME,   xdmp:get-request-username()),
        map:put($request, $USERID,     xs:unsignedLong(xdmp:get-request-user()))
      )
   let $fields :=
         for $i in xdmp:get-request-field-names()[fn:not(. = $SYS-PARAMS)]
         let $fieldname := fn:concat($PARAM-PREFIX,$i)
         let $filename := xdmp:get-request-field-filename($i)
         let $content-type := xdmp:get-request-field-content-type($i)
         return
            (:Load All Request Fields:)
            for $j in xdmp:get-request-field($i)
            let $filename-key := fn:concat($PARAM-FILENAME-PREFIX,$i)
            let $value :=
                 if($j castable as xs:string and fn:not($j instance of binary()))
                 then
                    if(fn:contains($j,"\{|\}")) then
                    let $json:= xdmp:from-json(fn:normalize-space($j))
                    return
                         if($json instance of element(json))
                         then $json
                         else fn:string($j)
                    else $j
                 else if($j castable as xs:long or $j castable as xs:integer)
                 then xs:long($j)
                 else $j
            return (
                if(map:contains($request,$fieldname)) then map:put($request,$fieldname,(map:get($request,$fieldname),$value))
                else map:put($request, $fieldname,$value)
                , (:Write out the filename info:)
                if($filename) then (
                   map:put($request,fn:concat($PARAM-FILENAME-PREFIX,$i),$filename),
                   map:put($request,fn:concat($PARAM-CONTENT-TYPE-PREFIX,$i),$content-type)
                )
                else  ()
            )
    let $_content-type := fn:normalize-space(fn:tokenize(xdmp:get-request-header("Content-Type"), ";")[1])
    let $is-multipart  := ($_content-type ! fn:normalize-space(.)) = "multipart/form-data"
    let $accept-types := xdmp:uri-format($_content-type)
    let $_ := map:put($request, $CONTENT-TYPE, $_content-type)
    let $_ :=
        if($is-multipart)
        then (
            map:put($request,$IS-MULTIPART,$is-multipart),
            map:put($request,$MULTIPART-BOUNDARY,$_content-type[fn:contains(.,"boundary")]/fn:substring-after(.,"boundary="))
        )
        else ()
    let $_ :=
         if ($_content-type = "application/json" or fn:contains($_content-type,"application/json"))
         then if(xdmp:get-request-method() = ("PUT","POST") and xdmp:get-request-body())
              then map:put($request, $BODY, xdmp:from-json(xdmp:get-request-body())[1])
              else if(xdmp:get-request-method() = "PATCH" and xdmp:get-request-body())
              then map:put($request, $BODY, xdmp:from-json(xdmp:get-request-body()))
              else ()
         else if($_content-type  = ("application/xml","text/xml"))
         then map:put($request, $BODY, xdmp:get-request-body("xml"))
         else map:put($request, $BODY, xdmp:get-request-body($accept-types))

    let $_ :=
      if ((fn:empty(request:format()) or request:format() eq "") and fn:exists($set-format)) then
        map:put(
          $request,
          $FORMAT,
          fn:head((
            xdmp:apply($set-format, $request),
            config:default-format()
          ))
        )
      else
        ()
   return $request
};

(:~
 : Get the application from the request
 :)
declare function request:application(){
  map:get($request,$APPLICATION)
};

(:~
 :  Gets the controller from the request
 :)
declare function request:controller() {
    map:get($request,$CONTROLLER)
};

(:~
 :  Gets that action Parameters of the request
 :)
declare function request:action() {
    map:get($request,$ACTION)
};

(:~
 : Selects the file format of the requestt
 :)
declare function request:format() {
   map:get($request,$FORMAT)
};

(:~
 : Gets the route selected for the request
 :)
declare function request:route() {
   map:get($request,$ROUTE)
};

(:~
 : Gets the view selected for the request
 :)
declare function request:view() {
   map:get($request,$VIEW)
};
declare function request:origin() {
  map:get($request,$ORIGIN)
};
(:~
 : Returns if the request has been past the debug option
 :)
declare function request:debug() {
  map:get($request,$DEBUG) eq "true"
};
declare function request:url() {
   map:get($request,$URL)
};
(:~
 : Returns the method for a given request
 : the method returns the http verb such as POST,GET,DELETE
 : etc.
 :)
declare function request:method() {
    map:get($request,$METHOD)
};

(:~
 :  Get the original Path of the request
 :)
declare function request:path() {
    map:get($request,$PATH)
};

(:~
 :  Get the protocal of the request
 :)
declare function request:protocol() {
    map:get($request,$PROTOCOL)
};

(:~
 : Returns the body element of an http:request. Use the request:body-type()
 : function to determine the underlying datatype
 :)
declare function request:body() {
    map:get($request,$BODY)
};

(:~
 :  Returns the body type of the given request such as (xml, binary, text)
 :)
declare function request:body-type(){
    map:get($request,$BODY-TYPE)
};

(:~
 : Returns if a request is a partial request common in ajax calls
 :)
declare function request:partial(){
  let $is-partial := map:get($request,$PARTIAL)
  return
    if($is-partial) then
      if($is-partial eq "true")
      then fn:true()
      else fn:false()
    else
      fn:false()
};

(:~
 :  Returns the list of parameters of just parameters in a map
 :)
declare function request:params()  as map:map{
    let $new-map := map:map()
    let $_ :=
        (
            for $key in map:keys($request)[fn:starts-with(.,$PARAM-PREFIX)]
            return
                map:put($new-map,fn:substring-after($key,$PARAM-PREFIX),map:get($request,$key)),
            (:Add param with format $key:filename key:content-type:)
            for $key in map:keys($request)[fn:starts-with(.,$PARAM-FILENAME-PREFIX)]
            return map:put($new-map, fn:concat(fn:substring-after($key,$PARAM-FILENAME-PREFIX),"_filename"),map:get($request,$key))
            ,
            for $key in map:keys($request)[fn:starts-with(.,$PARAM-CONTENT-TYPE-PREFIX)]
            return map:put($new-map, fn:concat(fn:substring-after($key,$PARAM-CONTENT-TYPE-PREFIX),"_content-type"),map:get($request,$key))
        )
    return
        $new-map
};

(:~
 : Returns a list parameter names from request as sequence of string values
 :)
declare function request:param-names()
{
    for $key in map:keys($request)[fn:starts-with(.,$PARAM-PREFIX)]
    return fn:substring-after($key, $PARAM-PREFIX)
};

(:~
 :  Gets a parameter value by name
 :)
declare function request:param($name as xs:string) {
   let $key-name := fn:concat($PARAM-PREFIX,$name)
   return
    map:get($request,$key-name)
};
declare function request:params-to-querystring(){
 fn:string-join(
   let $params := request:params()
   for $k in map:keys($params)
   order by $k
   return
   for $v in map:get($params,$k)
   return
      fn:concat($k,"=",xdmp:url-encode(fn:string($v)))
  ,"&amp;")
};
(:~
 : Retrieves a field if it is available and returns.
 : If field does not exist returns default.
 :)
declare function request:param($name as xs:string,$default as item()*) {
  let $field := request:param($name)
  return
    if($field)
    then $field
    else $default
};
(:~
 : Returns a parameter casted as the type you specify.
 : Use the generic type of the asset to resolve as the underlying type
 :)
declare function request:param-as(
    $name as xs:string,
    $type as xs:string,
    $default as item()
) as item()*
{
    let $value := request:param($name,$default)
    return
      if($type eq "xs:integer" and $value castable as xs:integer)
      then $value cast as xs:integer
      else if($type eq "xs:unsignedInteger" and $value castable as xs:unsignedInt)
      then $value cast as xs:unsignedInt
      else if($type eq "xs:long" and $value castable as xs:long)
      then $value cast as xs:long
      else if($type eq "xs:unsignedLong" and $value castable as xs:unsignedLong)
      then $value cast as xs:unsignedLong
      else if($type eq "xs:decimal" and $value castable as xs:decimal)
      then $value cast as xs:decimal
      else if($type eq "xs:float" and $value castable as xs:float)
      then $value cast as xs:float
      else if($type eq "xs:double" and $value castable as xs:double)
      then $value cast as xs:double
      else if($type eq "xs:boolean" and $value castable as xs:boolean)
      then $value cast as xs:boolean
      else if($type eq "xs:string" and $value castable as xs:string)
      then $value cast as xs:string
      else if($type eq "element" and $value instance of element())
      then $value
      else fn:error(xs:QName("PARAM-EXCEPTION"),"Parameter Type is not supported",($type,$name))
};

(:~
 :  Returns the parameters of the request as a map
 :)
declare function request:params-as-map()
{
   let $new-map := map:map()
   let $fields := request:params()
   let $insert :=
        for $field in map:keys($fields)
        let $value := map:get($fields,$field)
        return
          map:put($new-map,fn:substring-after($value,$PARAM-PREFIX),$value)
  return
    $new-map
};

(:~
 :  Returns the filename for the param
 :)
declare function request:param-filename($name as xs:string) {
    map:get($request,fn:concat($PARAM-FILENAME-PREFIX,$name))
};
(:~
 :  Returns the associated content-type for the given param
 :  In cases where the request has multipart/mime data on the form
 :  you can extract the type based request from client
 :)
declare function request:param-content-type(
    $field as xs:string
)
{
   map:get($request,fn:concat($PARAM-CONTENT-TYPE-PREFIX,$field))
};

(:~
 : Gets a all response header object
 :)
declare function request:get-headers() {
    let $new-map := map:map()
    let $_ :=
        for $key in map:keys($request)[fn:starts-with(.,"request:header::")]
        return
            map:put($new-map,fn:substring-after($key,$HEADER-PREFIX),map:get($request,$key))
    return
        $new-map
};

(:~
 : Gets a specific header parameter by name
 :  @param $name - Name of the header parameter (ie. Content-Length)
 :)
declare function request:get-header($name as xs:string) {
   let $key-name := fn:concat($HEADER-PREFIX,$name)
   return
     map:get($request,$key-name)
};

(:~
 :  Gets a specific header parameter by name and its default value if not present
 :  @param $name - Name of the header parameter (ie. Content-Length)
 :  @param $defualt - Default value if header parameter is not present.
 :)
declare function request:get-header($name as xs:string,$default as xs:anyAtomicType) {
  if(request:get-header($request,$name))
  then request:get-header($request,$name)
  else $default
};

(:Common HTTP Request Header PARAMs wrapper:)

(:~
 : Returns the given Accept-Language from the HTTP request
 :)
declare function request:locale()
{
  map:get($request,fn:concat($HEADER-PREFIX,"Accept-Language"))
};
(:~
 : Returns the Content-Length header param
 :)
declare function request:content-length()
{
   map:get($request,fn:concat($HEADER-PREFIX,"Content-Length"))
};
(:~
 : Returns the User-Agent header from a given request
 :)
declare function request:user-agent()
{
  map:get($request,fn:concat($HEADER-PREFIX,"User-Agent"))
};

(:~
 : Returns the Referer header from a given request
 :)
declare function request:referer()
{
  map:get($request,fn:concat($HEADER-PREFIX,"Referer"))
};

(:~
 : Returns the Accept-Encoding header from a given request
 :)
declare function request:encoding()
{
    map:get($request,fn:concat($HEADER-PREFIX,"Accept-Encoding"))
};

(:~
 : Returns the Connection header from a given request
 :)
declare function request:connection()
{
    map:get($request,fn:concat($HEADER-PREFIX,"Connection"))
};
(:~
 : Returns the Authorization Header from the request
 :)
declare function request:authorization()
{
    map:get($request,fn:concat($HEADER-PREFIX,"Authorization"))
};
(:~
 : Returns the Cookies from the request
 :)
declare function request:cookies()
{
    map:get($request,fn:concat($HEADER-PREFIX,"Cookie"))
};

(:~
 : Returns the Cookies by name from the request
 : @param $name - name of cookie
 :)

declare function request:cookie($name
) as xs:string* {
  let $cookies := request:cookies()
  return
    for $cookie in fn:tokenize(request:cookies(), "; ")
      return
        if (xdmp:url-decode(fn:substring-before($cookie, "=")) = $name) then
          xdmp:url-decode(fn:substring-after($cookie, "="))
        else
          ()
};

(:
 : Returns the Content-Type header from the request
:)
declare function request:content-type() {
  map:get($request,$CONTENT-TYPE)
};

(:~
 : Returns the current user-id for the request
 :)
declare function request:user-id()
{
   map:get($request,$USERID)
};

(:~
 : Returns the current user name
 :)
declare function request:user-name() {
   map:get($request,$USERNAME)
};

(:~
 : Returns the unique key of the current request.
 :)
declare function request:session-id() as xs:string {
   request:cookie("SessionID")[1]
};

(:~
 : Returns the unique key of the current request.
 :)
declare function request:request-id() {
   xdmp:request()
};

(:~
 : Returns the anonymous users name
 :)
declare function request:anonymous-user()
{
  config:anonymous-user(request:application())
};


(:----Query Constructs----:)
(:~
 : Converts a JSON map into a request parameter
 :)
declare private function request:convert-json-map($map as map:map) {
    for $key in map:keys($map)
    let $val := map:get($map,$key)
    return
        element {$key} {
            if($val instance of map:map) then request:convert-json-map($val) else $val
        }
};

(:~
 :  Using JQGrid you can parse a query from field using simple language, parses from JSON into CTS Query
 :)
declare function request:build-query($params)
{
  let $filters :=
     if($params instance of element(item))
     then $params
     else $params//item
  let $value-query :=
    for $item in $filters
    return
      if($item/op eq "eq") then
        cts:element-value-query(xs:QName($item/field),$item/data)
      else if($item/op eq "ne") then
        cts:not-query( cts:element-value-query(xs:QName($item/field),$item/data))
      else if($item/op eq "bw") then
         cts:element-word-query(xs:QName($item/field),fn:concat($item/data,"*"))
      else if($item/op eq "bn") then
         cts:not-query( cts:element-word-query(xs:QName($item/field),fn:concat($item/data,"*")))
      else if($item/op eq "ew") then
         cts:element-word-query(xs:QName($item/field),fn:concat("*",$item/data))
      else if($item/op eq "en") then
         cts:not-query( cts:element-word-query(xs:QName($item/field),fn:concat("*",$item/data)))
      else if($item/op eq "cn") then
         cts:element-word-query(xs:QName($item/field),fn:concat("*",$item/data,"*"))
      else if($item/op eq "nc") then
         cts:not-query( cts:element-word-query(xs:QName($item/field),fn:concat("*",$item/data,"*")))
       else if($item/op eq "nu") then
         cts:element-query(xs:QName($item/field),cts:and-query(()))
      else if($item/op eq "nn") then
         cts:element-query(xs:QName($item/field),cts:or-query(()))
      else if($item/op eq "in") then
        cts:element-value-query(xs:QName($item/field),$item/data)
      else if($item/op eq "ni") then
        cts:not-query( cts:element-value-query(xs:QName($item/field),$item/data))
      else ()
  return
  if($params//groupOp eq "AND") then
    cts:and-query($value-query)
  else if($params//groupOp eq "OR") then
    cts:or-query($value-query)
  else $value-query
};

(:~
 : Returns the parse Query from JQGrid
 :)
declare function request:parse-query()
{
 let $filters  :=
  if(request:param("_search", "false") = "true")
  then if(request:param("filters",()))
       then xdmp:from-json(request:param($request,"filters"))
       else
        <item>
           <field>{request:param($request,"searchField")}</field>
           <op>{request:param($request,"searchOper")}</op>
           <data>{request:param($request,"searchString")}</data>
        </item>
  else ()
  return
     request:build-query($filters)
};

(:~
 : Redirects the request before sent to response
 :)
declare function request:set-redirect($uri)
{
   map:put($request,$REDIRECT,fn:data($uri))
};

(:~
 : Redirects the request and sends the redirect response code
 :)
declare function request:set-redirect(
    $uri as xs:string,
    $redirect-code as xs:integer,
    $message as xs:string
) {
    (
        request:set-redirect($uri),
        map:put($request,$REDIRECT-CODE,$redirect-code)
    )
};

(:~
 : Gets the redirect URL from the request
 :)
declare function request:redirect()  as xs:string?
{
  map:get($request,$REDIRECT)
};

(:~
 : Get the redirect code for a given request.
 :)
declare function request:redirect-code()  as xs:integer?
{
  map:get($request,$REDIRECT-CODE)
};
(:~
 : Adds a request parameter
 :)
declare function request:add-param(
  $name,
  $value as item()*
) {
     map:put($request,fn:concat($PARAM-PREFIX,$name),$value)
};

(:~
 : Adds a request parameter from a map:map
 :)
declare function request:add-params(
  $params as map:map
) as empty-sequence() {
   for $k in map:keys($params)
   return
     map:put($request,fn:concat($PARAM-PREFIX,$k),map:get($params,$k))
};

(:~
 : Serializes the request to an xml element definition
 :)
declare function request:serialize()
{
    element {"request"} {
        for $r in request:param-names()
        return element{$r} {request:param($r) }
    }
};

(:~
 : Removes a parameter from the request
 : @param name  Parameter Key to remove.
 :)
declare function request:remove-param($name as xs:string)
{
    map:delete($request:request, fn:concat($PARAM-PREFIX,$name))
};

(:Create An Error Handler:)
declare function request:set-error(
  $code as xs:integer,
  $message as xs:string
) {
   map:put($request,$ERROR,fn:true()),
   map:put($request,$ERROR-CODE,$code),
   map:put($request,$ERROR-MESSAGE,$message)

};
(:~
 :  Returns if an error was thrown
 :)
declare function request:error() as xs:boolean {
  map:get($request,$ERROR) = fn:true()
};

declare function request:error-code() as xs:integer? {
   map:get($request,$ERROR-CODE)
};

declare function request:error-message()  as xs:string {
  map:get($request,$ERROR-MESSAGE)
};

declare function request:is-multipart() as xs:boolean {
  fn:string(map:get($request,$IS-MULTIPART)) eq "true"
};

declare function request:multipart-boundary() {
  fn:string(map:get($request,$MULTIPART-BOUNDARY))
};
