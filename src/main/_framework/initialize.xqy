xquery version "1.0-ml";
(:~Responsible for refreshing the application cache for all servers including task server.
   The application cache expands all the domains includes and keeps them in a server variable
   corresponding the the configuration uri.
 :)
import module namespace config ="http://xquerrail.com/config" at "config.xqy";
let $http-method := xdmp:get-request-method()
let $application :=
  if ($http-method eq "GET") then
    ()
  else if ($http-method eq "POST") then
    xdmp:get-request-body()/node()
  else
    fn:error(xs:QName("UNSUPPORTED-HTTP-METHOD"), text{"Unsupported HTTP method", $http-method})
return (
  xdmp:set-response-content-type("application/xml"),
  <domains xmlns="http://xquerrail.com/domain">
  {config:refresh-app-cache($application)}</domains>,
  xdmp:spawn(
    "initialize-taskserver.xqy",
    if (fn:exists($application)) then
      (xs:QName("config:application"), $application)
    else
      (xs:QName("config:application"), <config:application/>)
  )
)

