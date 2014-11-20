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

module namespace delete = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "../interceptor.xqy";
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace config  = "http://xquerrail.com/config"  at "../config.xqy";

   
declare function delete:name()
{
  xs:QName("interceptor:security")
};


declare function delete:is-anonymous($configuration as element(config:config)) {
  fn:exists(delete:get-roles()[. = $configuration/config:anonymous-user/@value])
};

declare function delete:get-roles()
{
   xdmp:eval('
   import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
   sec:get-role-names(xdmp:get-current-roles())
   ',(), 
     <options xmlns="xdmp:eval">
        <database>{xdmp:security-database()}</database>
     </options> 
   )
};

declare function delete:implements() as xs:QName*
{  (
     xs:QName("interceptor:after-request")
   )
};

declare function delete:after-request(
   $request as map:map,
   $configuration as element()
)
{
     request:initialize($request),
     
     let $token := request:param("errorCode")
     let $context := interceptor:get-context()
     let $scope   := interceptor:get-matching-scopes($configuration)[1]
     let $roles   := delete:get-roles() ! fn:string(.)

     return
     if($scope) then 
         if($token = "ASC-DOC_DELETE_ERROR_001")
         (:if($scope//config:allow-role = $roles or $scope/config:allow-role = "*" ) :)
         then  ()
         else (
            (:request:set-redirect("/public/error403.html", 401,"delete Error"):)
            fn:error(xs:QName("Not-Allowed"),"ASC-DOC_DELETE_ERROR_001",request:format())
         ) else()
};
