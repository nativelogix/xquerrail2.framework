xquery version "1.0-ml";
(:~
 : The domain controller is responsible for all domain functions.
 : Any actions specified in the base controller will be globally accessible by each domain controller.
 :
 : @author   : Gary Vidal
 : @version  : 2.0
 :)

module namespace controller = "http://xquerrail.com/controller/domains";

(:Global Import Module:)
import module namespace request = "http://xquerrail.com/request" at "../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../response.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "../config.xqy";
import module namespace module-loader = "http://xquerrail.com/module" at "../module.xqy";

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
  config:get-domain(request:application())
};
