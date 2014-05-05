xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/xdmp/json"
    at "/MarkLogic/json/json.xqy";
    
declare namespace local = "urn:local";

declare variable $_ERROR as map:map external;
declare variable $ERROR as map:map := 
try{$_ERROR }catch($ex){map:map()};
  
declare function local:render-html-error($error)
{
   typeswitch($error)
     case document-node() return local:render-html-error($error/node())
     case element(error:error) return
        <div class="error-container">
          <table id="error-header" cellpadding="0" cellspacing="0" border="0" width="90%">
             <tr><td>Code:</td><td>{fn:data($error/error:code)}</td></tr>
             <tr><td>Name:</td><td>{fn:data($error/error:name)}</td></tr>
             <tr><td>XQuery Version:</td><td>{fn:data($error/error:xquery-version)}</td></tr>
             <tr><td>Message:</td><td>{fn:data($error/error:message)}</td></tr>
             <tr>
                 <td>Formatted:</td>
                 <td>{fn:data($error/error:format-string)}</td>
             </tr>
             <tr>
                <td>Retryable:</td>
                <td>{fn:data($error/error:retryable)}</td>
             </tr>
             <tr>
                <td>Expression:</td>
                <td>{fn:data($error/error:expr)}</td>
             </tr>
          </table>
        {
          for $n in $error/error:stack
          return 
             local:render-html-error($n)
        }</div>
     case element(error:stack) return
        <div id="error-stack" class="ui-widget-container">
          <h2>Stack Output:</h2>
          <table id="error-table" cellpadding="0" cellspacing="0" border="0" >
            <thead>
             <tr class="header">
                <th>Module URI</th>
                <th>Line</th>
                <th>Column</th>
                <th style="width:500px;">Operation</th>
                <th>Variables</th>
             </tr>
           </thead>
          {for $s in $error/error:frame 
           return local:render-html-error($s)
          }
          </table>
        </div>
     case element(error:frame) return 
        <tr class="error-item">
           <td class="error-uri">{fn:data($error/error:uri)}</td>
           <td class="error-line"   align="right">{fn:data($error/error:line)}</td>
           <td class="error-column" align="right">{fn:data($error/error:column)}</td>
           <td class="operation">{fn:data($error/error:operation)}&nbsp;</td>
           <td>{local:render-html-error($error/error:variables)}&nbsp;</td>
        </tr>
     case element(error:variables) return
        <table class="variables" cellspacing="0" cellpadding="0" border="0">
        <tr class="variable-header">
           <td colspan="2">Variables:</td>
        </tr>
        {
         for $v in $error/error:variable 
         return 
            <tr class="variable-item">
              <td class="variable-name">${fn:data($v/error:name)}</td>
              <td class="variable-value">{fn:data($v/error:value)}</td>
            </tr>
        }
        </table>
     default return ()
};
declare function local:render-json-error($error)
{
   typeswitch($error)
     case document-node() return local:render-html-error($error/node())
     case element(error:error) return
       let $json-obj := json:object()
       let $_ := (
          map:put($json-obj,"code",fn:data($error/error:code)),
          map:put($json-obj,"name",fn:data($error/error:name)),
          map:put($json-obj,"xquery_version",fn:data($error/error:xquery-version)),
          map:put($json-obj,"message",fn:data($error/error:message)),
          map:put($json-obj,"format_string",fn:data($error/error:format-string)),
          map:put($json-obj,"retryable",fn:data($error/error:retryable)),
          map:put($json-obj,"expr",fn:data($error/error:expr)),
          map:put($json-obj,"data",for $datum in $error/error:data/error:datum return fn:string($datum)),
          map:put($json-obj,"stack",local:render-json-error($error/error:stack))
       )
       return 
         $json-obj
     case element(error:stack) return
        let $stack := json:array()
        let $_ := for $frame in $error/error:frame
                  return json:array-push($stack,local:render-json-error($frame))
        return 
            $stack
     case element(error:frame) return 
        let $frame := json:object() 
        let $_ := (
            map:put($frame,"uri",fn:data($error/error:uri)),
            map:put($frame,"line",fn:data($error/error:line)),
            map:put($frame,"column",fn:data($error/error:column)),
            map:put($frame,"operation",fn:data($error/error:operation)),
            map:put($frame,"context_item",fn:data($error/error:context-item)),
            map:put($frame,"context_position",fn:data($error/error:context-position)),
            map:put($frame,"xquery_version",fn:data($error/error:xquery-version)),
            map:put($frame,"variables",local:render-json-error($error/error:variables))
        ) 
        return 
           $frame
     case element(error:variables) return
     let $var-array := json:array()
     let $_ := for $var in $error/error:variable
               return json:array-push($var-array,local:render-json-error($var))
     return 
        $var-array
     case element(error:variable) return
        let $obj := json:object() 
        let $_ := (
            map:put($obj,"name",fn:data($error/error:name)),
            map:put($obj,"value",fn:data($error/error:value))
        )
        return  $obj
     default return ()
};
declare function local:render-html-request($request)
{(
 <table xmlns="http://www.w3.org/1999/xhtml">{
   for $k in map:keys($request)
   order by $k
   return
      <tr><td>{$k}</td>
          <td>{
          if(some $x in map:get($request,$k) satisfies $x castable as xs:hexBinary)
          then "(binary)"
          else try{ map:get($request,$k)} catch($ex){"error"}
          }
          </td>
      </tr>
 }</table>
)};

declare function local:render-html-response($request)
{(
 <table xmlns="http://www.w3.org/1999/xhtml">{
   for $k in map:keys($request)
   order by $k
   return
      <tr><td>{$k}</td>
          <td>{map:get($request,$k)}
          </td>
      </tr>
 }</table>
)};
declare function local:render-json-request($request) {
    let $obj := json:object()
    let $headers := json:array()
    let $params := json:array()
    let $keys := for $k in  map:keys($request) order by $k return $k
    let $_ := (
         for $k in $keys
         let $key := fn:replace($k,"^request:","")
         order by $k
         return
          if(fn:matches($key,"^header::")) then
             let $hd := json:object()
             let $_ := (
                map:put($hd,"name",fn:replace($key,"^header::","")),
                map:put($hd,"value", if(some $x in map:get($request,$k) satisfies $x instance of binary() and fn:not($x castable as xs:long))
                  then "(binary)"
                  else try{ map:get($request,$k)} catch($ex){"error"}
                )
             )
             return json:array-push($headers,$hd)
          else if(fn:matches($key,"^param::")) then
             let $pm := json:object()
             let $_ :=  (
                map:put($pm,"name",fn:replace($key,"^param::","")),             
                map:put($pm,"value", if(some $x in map:get($request,$k) satisfies $x instance of binary() and fn:not($x castable as xs:long))
                  then "(binary)"
                  else try{ map:get($request,$k)} catch($ex){"error"}
                ))
             return json:array-push($params,$pm)
          else 
             map:put($obj,$key, if(some $x in map:get($request,$k) satisfies $x castable as xs:hexBinary)
               then "(binary)"
               else try{ map:get($request,$k)} catch($ex){"error"}
             )
    )
    let $_ :=
        (
            map:put($obj,"headers",$headers),
            map:put($obj,"params",$params)
        )
    return $obj
};
declare function local:render-json-response($request) {
    let $obj := json:object()
    let $_ := (
    for $k in map:keys($request)
    order by $k
    return
        map:put($obj,fn:replace($k,"^response:",""), if(some $x in map:get($request,$k) satisfies $x castable as xs:hexBinary)
          then "(binary)"
          else try{ map:get($request,$k)} catch($ex){"error"}
        )
    )
    return $obj
}; 
xdmp:set-response-code(500,<e>{map:get($ERROR,"error")}</e>//error:format-string),
let $request := map:get($ERROR,"request")
let $format  := map:get($request,"request:format")
return
if($format = "xml") then (
    xdmp:set-response-content-type("text/xml"), 
    map:get($ERROR,"error")
)
else if($format = "json") then (
    xdmp:set-response-content-type("application/json"), 
    let $obj := json:object()
    let $json-error := local:render-json-error(map:get($ERROR,"error"))
    let $_ := (
        map:put($obj,"error",$json-error),
        map:put($obj,"request",local:render-json-request(map:get($ERROR,"request"))),
        map:put($obj,"response",local:render-json-response(map:get($ERROR,"response")))
    )
    return 
        xdmp:to-json($obj)
)
else (
    xdmp:set-response-content-type("text/html"), 
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>    
         <title>Application Error</title>
      </head>
      <body>
         <h1 class="error-header">Application Error!</h1>
         {local:render-html-error(map:get($ERROR,"error"))}
         <h2>Request Variables</h2>
         {local:render-html-request(map:get($ERROR,"request"))}
         <h2>Response Variables</h2>
         {local:render-html-request(map:get($ERROR,"response"))}
      </body>
    </html>)