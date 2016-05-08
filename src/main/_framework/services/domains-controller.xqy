xquery version "1.0-ml";
(:~
 : The domain controller is responsible for all domain functions.
 :
 : @author   : Richard Louapre
 : @version  : 2.0
 :)

module namespace controller = "http://xquerrail.com/controller/domains";

(:Global Import Module:)
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../response.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "../config.xqy";
import module namespace module-loader = "http://xquerrail.com/module" at "../module.xqy";
import module namespace swagger = "http://xquerrail.com/helper/swagger" at "../helpers/swagger-helper.xqy";

(:Global Option:)
declare option xdmp:mapping "false";

declare %config:module-location function controller:module-location(
) as element(module)* {
  element module {
    attribute type {"domains-controller"},
    attribute namespace { $domain:DOMAINS-CONTROLLER-NAMESPACE },
    attribute location { module-loader:normalize-uri((config:framework-path(), "/services/domains-controller.xqy")) }
  }
};

(:~
 : Initiailizes the request to allow calling into request:* and response:* functions.
 : @param $request - Request map:map representing the request.
 : @return true if the request/response was initialized properly
 :)
declare function controller:initialize(
  $request as map:map
) {
  request:initialize($request),
  response:initialize(map:map(),$request)
};

(:~
 : Returns the model associated with the controller.  All actions in base use the controller to define the model.
 :)
declare function controller:get(
) {
  let $domain := config:get-domain(request:application())
  let $response :=
    if(request:format() = "json")
    then  swagger:to-json($domain,request:params())
    else $domain
  return (
     response:initialize(map:new(),request:request()),
     response:set-content-type(config:get-engines-configuration()/config:engines/config:engine[@format eq request:format()]/config:mimetypes/config:mimetype/fn:string()),
     response:set-body($response),
     response:flush()
  )
};
