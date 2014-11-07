xquery version "1.0-ml";

module namespace ml-security = "http://xquerrail.com/interceptor";

import module namespace interceptor = "http://xquerrail.com/interceptor" at "../interceptor.xqy";
import module namespace response = "http://xquerrail.com/response" at "../response.xqy";
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace config  = "http://xquerrail.com/config"  at "../config.xqy";


declare function ml-security:name()
{
  xs:QName("interceptor:ml-security")
};


declare function ml-security:is-anonymous($configuration as element(config:config)) {
  fn:exists(ml-security:get-roles()[. = $configuration/config:anonymous-user/@value])
};

declare function ml-security:get-roles()
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

declare function ml-security:implements() as xs:QName*
{
   (
     xs:QName("interceptor:after-request")
   )
};

declare function ml-security:after-request(
   $request as map:map,
   $configuration as element()
)
{
     request:initialize($request),
     let $context := interceptor:get-context()
     let $scope   := interceptor:get-matching-scopes($configuration)[1]
     let $roles   := ml-security:get-roles()
     let $bypassed  :=
         if(ml-security:is-anonymous($configuration) and
            request:get-header("BYPASS-AUTHENTICATION") = $configuration/config:bypass-credentials/config:token)
         then
             xdmp:login(
                 $configuration/config:bypass-credentials/config:username,
                 $configuration/config:bypass-credentials/config:password
             )
         else fn:false()
     let $authorization := xdmp:get-request-header("Authorization")
     let $_ := xdmp:log(("context:", $context," scope::", $scope, " authorization::", $authorization, " bypassed::", $bypassed), "debug")
     return
       if($bypassed) then ()
       else
       if($authorization and fn:starts-with($authorization, "Basic ")) then
          let $user := xdmp:get-request-username()
          let $password :=
             fn:substring-after(
                xdmp:base64-decode(
                   fn:substring-after($authorization, "Basic ")
                ),
                fn:concat($user, ":")
             )
          return xdmp:login($user, $password)
       else if($scope//config:allow-role = $roles or $scope/config:allow-role = "*" or fn:not($scope//config:deny-role  = $roles)) then
       (
          xdmp:log(("$roles", $roles))
          (:if(request:param("returnUrl") != "" and request:param("returnUrl"))
          then request:set-redirect(request:param("returnUrl"))
          else (),
          xdmp:log(("Not-Redirecting::",xdmp:get-current-user(), $context,$scope),"debug"):)
       )
       else (
        xdmp:log(text{"request:format()", request:format()}),
        if (request:format() eq "html") then (
          if(request:param("returnUrl") and request:param("returnUrl") !="")
          then request:set-redirect(request:param("returnUrl"))
          else request:set-redirect(
            fn:concat($configuration/config:login-url/@url,"?returnUrl=",xdmp:url-encode(request:origin()))
          )
          ,
          xdmp:log(("Redirecting::",request:redirect(),$context,$scope),"debug")
        )
        else if (request:format() eq ("json", "xml")) then (
          response:set-response-code(401, "Unauthorized")
        )
        else
          ()
       )
};
