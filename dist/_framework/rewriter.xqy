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
import module namespace app = "http://xquerrail.com/application" at "application.xqy";
import module namespace config = "http://xquerrail.com/config" at "config.xqy";

declare namespace routing = "http://xquerrail.com/routing";
declare option xdmp:mapping "false";
let $_ := app:bootstrap()
let $request := xdmp:get-request-url()
let $router := config:get-route-module()
let $routing := xdmp:function(xs:QName("routing:get-route"),$router)
return
   xdmp:apply($routing,$request)