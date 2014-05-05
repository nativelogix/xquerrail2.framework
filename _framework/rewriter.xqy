xquery version "1.0-ml";
(:~
 : Responsible for URL rewriting
 : The rewriter intercepts URLs and rewrites the URL.
 : The rewriter is used to invoke the controller, run tests, and simulate the REST web service.
 : In most cases it delegates to the front-controller (/dispatcher.xqy).
 : or to a resource uri located in the filesystem
 :
 : @see http://developer.marklogic.com
 : Setting Up URL Rewriting for an HTTP App Server
 : @see app/controller.xqy
 :
 :)
import module namespace config = "http://xquerrail.com/config" at "/_framework/config.xqy";
declare namespace routing = "http://xquerrail.com/routing";
declare option xdmp:mapping "false";
let $request := xdmp:get-request-url()
let $router := config:get-route-module()
let $routing := xdmp:function(xs:QName("routing:get-route"),$router)
return
   xdmp:apply($routing,$request)