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
