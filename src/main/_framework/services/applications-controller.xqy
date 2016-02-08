xquery version "1.0-ml";
(:~
 : Responsible to return the list of applications defined in XQuerrail
 :)

import module namespace config ="http://xquerrail.com/config" at "../config.xqy";

let $http-method := xdmp:get-request-method()
let $format := fn:head((fn:tokenize(xdmp:get-original-url(), "\.")[fn:last()], config:default-format()))
let $_ :=
  if ($http-method eq "GET") then
    ()
  else
    fn:error(xs:QName("UNSUPPORTED-HTTP-METHOD"), text{"Unsupported HTTP method", $http-method})
return
  if ($format eq "xml") then (
    xdmp:set-response-content-type("application/xml"),
    element {fn:QName("http://xquerrail.com/application", "applications")} {
      for $application in config:get-applications()
      let $domain-link := fn:concat("/applications/", fn:string($application/@name) , "/domain/get.", $format)
      return element {fn:QName("http://xquerrail.com/application", "application")} {
        element {fn:QName("http://xquerrail.com/application", "name")} {
          fn:string($application/@name)
        },
        element {fn:QName("http://xquerrail.com/application", "domain")} {
          element {fn:QName("http://xquerrail.com/application", "timestamp")} { fn:string(config:get-domain($application/@name)/@timestamp) },
          element {fn:QName("http://xquerrail.com/application", "link")} { $domain-link }
        }
      }
    }
  ) else if ($format eq "json") then (
    xdmp:set-response-content-type("application/json"),
    let $json := json:object()
    let $_ := map:put(
      $json,
      "applications",
      json:to-array(
        for $application in config:get-applications()
        let $domain-link := fn:concat("/applications/", fn:string($application/@name) , "/domain/get.", $format)
        let $json-application := json:object()
        let $_ := map:put($json-application, "name", fn:string($application/@name))
        let $_ := map:put(
          $json-application,
          "domain",
          map:new((
            map:entry("timestamp", fn:string(config:get-domain($application/@name)/@timestamp)),
            map:entry("link", $domain-link)
          ))
        )
        return $json-application
      )
    )
    return xdmp:to-json($json)
  ) else (
    fn:error(xs:QName("UNSUPPORTED-FORMAT"), text{"Unsupported format", $format})
  )
