xquery version "1.0-ml";

module namespace authorization = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "/_framework/interceptor.xqy";
import module namespace request = "http://xquerrail.com/request" at "/_framework/request.xqy";
import module namespace config  = "http://xquerrail.com/config"  at "/_framework/config.xqy";

   
declare function authorization:name()
{
  xs:QName("interceptor:security")
};


declare function authorization:is-anonymous($configuration as element(config:config)) {
  fn:exists(authorization:get-roles()[. = $configuration/config:anonymous-user/@value])
};

declare function authorization:get-roles()
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

declare function authorization:implements() as xs:QName*
{  (
     xs:QName("interceptor:after-request")
   )
};

declare function authorization:after-request(
   $request as map:map,
   $configuration as element()
)
{
     request:initialize($request),
     let $context := interceptor:get-context()
     let $scope   := interceptor:get-matching-scopes($configuration)[1]
     let $roles   := authorization:get-roles() ! fn:string(.)

     return
         if($scope//config:allow-role = $roles or $scope/config:allow-role = "*" ) 
         then  ()
         else (
            request:set-redirect("/public/error403.html", 401,"Authorization Error")
         )
};
