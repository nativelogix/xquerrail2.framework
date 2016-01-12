xquery version "1.0-ml";
(:~Responsible for refreshing the application cache for all servers including task server.
   The application cache expands all the domains includes and keeps them in a server variable
   corresponding the the configuration uri.
 :)

import module namespace config ="http://xquerrail.com/config" at "config.xqy";
declare namespace http = "xdmp:http";
declare namespace domain = "http://xquerrail.com/domain";

let $http-method := xdmp:get-request-method()
let $body :=
  if ($http-method eq "GET") then
    ()
  else if ($http-method eq "POST") then
    xdmp:get-request-body()/node()
  else
    fn:error(xs:QName("UNSUPPORTED-HTTP-METHOD"), text{"Unsupported HTTP method", $http-method})
return (
  xdmp:set-response-content-type("application/xml"),
  if (xs:boolean(xdmp:get-request-field("domain-ready"))) then
    <domains xmlns="http://xquerrail.com/domain">
      <ready>
      {
        try {
          fn:exists(config:get-domain())
        } catch ($ex) {
          fn:false()
        }
      }
      </ready>
    </domains>
  else if (xs:boolean(xdmp:get-request-field("clear-cache"))) then
  (
    element domain:clear-cache {
      config:clear-cache(fn:true()),
      fn:current-dateTime()
    }
  )
  else if (xs:boolean(xdmp:get-request-field("hosts"))) then
  (
    element domain:hosts {
      xdmp:hosts() ! element domain:host {xdmp:host-name(.)}
    }
  )
  else
  (
    element { fn:QName("http://xquerrail.com/domain", "domains") } {
      attribute mlVersion { xdmp:version() },
      config:refresh-app-cache($body)
    }
  )
)
