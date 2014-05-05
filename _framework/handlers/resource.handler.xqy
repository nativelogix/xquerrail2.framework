xquery version "1.0-ml";
(:~
 : Resource Handler allows to customize how resources are handled by the application
 :)
import module namespace request     = "http://xquerrail.com/request"     at "/_framework/request.xqy";
import module namespace config      = "http://xquerrail.com/config"      at "/_framework/config.xqy";

declare namespace handler = "http://xquerrail.com/handler";

declare function handler:resource-path($path) {
    let $root := fn:replace(xdmp:modules-root(),"\\","/")
    let $new-path := 
        if(fn:ends-with($root,"/")) then $root || $path
        else $root || "/" || $path
    return $new-path
};

declare function handler:load($uri) {
  let $content-type := xdmp:uri-content-type($uri)
  
  return
    if($content-type = ("application/vnd.marklogic-xdmp"))
    then xdmp:invoke($uri)
    else 
        if(xdmp:modules-database() = 0 ) 
        then xdmp:external-binary(handler:resource-path($uri))
        else 
           xdmp:eval("fn:doc('" || $uri || "')/node()",
              (),
              <options xmlns="xdmp:eval">
                 <database>{xdmp:modules-database()}</database>
              </options>
           )
};
let $request := request:parse(())
let $origin := request:origin()
let $origin := if(fn:contains($origin,"?")) then fn:substring-before($origin,"?") else $origin
let $accept-type := request:get-header("Accept-Encoding")
let $can-compress := fn:contains($accept-type,"gzip") and fn:not( xdmp:uri-content-type($origin) = ("application/vnd.marklogic-xdmp"))
let $resource := handler:load($origin)
let $resource := 
  if($can-compress) then 
    xdmp:gzip(
     document {$resource}
    )
  else $resource
let $etag := 
   if($resource ! . instance of binary()) 
   then xdmp:md5($resource)
   else xdmp:md5(
    fn:string-join(
     for $r in $resource/node()
     return
       typeswitch($r)
         case node() return xdmp:quote($r)
         default return fn:string($r)
     ,"")
    )
return

if($can-compress) then 
    let $current := fn:format-dateTime(fn:current-dateTime(),"[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] [ZN,*-3]")
    let $expires := fn:format-dateTime(fn:current-dateTime() + xs:yearMonthDuration("P1Y"),"[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] [ZN,*-3]")
    let $last-modified := fn:format-dateTime(fn:current-dateTime() - xs:dayTimeDuration("P30D"),"[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] [ZN,*-3]")
    return 
      if(fn:not($resource)) then  
        xdmp:set-response-code("404","Document does not exist")
      else (
            xdmp:set-response-content-type(xdmp:uri-content-type($origin)),
            xdmp:add-response-header("Expires",$expires),
            xdmp:add-response-header("Date",$current),
            xdmp:add-response-header("Last-Modified",$last-modified),
            xdmp:add-response-header("ETag",$etag),
            if($can-compress) then xdmp:add-response-header("Content-Encoding","gzip") else (),
            $resource
      )
else $resource
       