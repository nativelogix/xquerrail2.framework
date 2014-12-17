xquery version "1.0-ml";

module namespace custom-engine = "http://xquerrail.com/engine/customer";

import module namespace engine  = "http://xquerrail.com/engine" at "/main/_framework/engines/engine.base.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace domain = "http://xquerrail.com/domain"  at "/main/_framework/domain.xqy";

declare option xdmp:mapping "false";
declare option xdmp:output "method=xml";

(:~
 : You initialize your variables
 :)
declare variable $request := map:map() ;
declare variable $response := map:map();
declare variable $context := map:map();

(:~
   Initialize  Any custom tags your engine handles so the system can call
   your custom transform functions
 :)
declare variable $custom-engine-tags as xs:QName* :=
(
  xs:QName("custom-engine:test-processing-instruction")
);

(:~
 : The Main Controller will call your initialize method
 : and register your engine with the engine.base.xqy
 :)
declare function custom-engine:initialize($response, $request) {
  engine:register-tags($custom-engine-tags)
};

declare function custom-engine:test-processing-instruction(
  $node as item()
) {
  <custom>PIPPO</custom>
};

(:~
  Handle your custom tags in this method or the method you have assigned
  initialized with the base.engine
  It is important that you only handle your custom tags and
  any content that is required to be consumed by your tags
 :)
declare function custom-engine:custom-transform(
  $node as item()
) {
  typeswitch($node)
  case processing-instruction("test-processing-instruction") return custom-engine:test-processing-instruction($node)
  default return engine:transform($node)
};
