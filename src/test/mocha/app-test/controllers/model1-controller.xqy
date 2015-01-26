xquery version "1.0-ml";
(:~
 : Default Application Controller
~:)
module namespace controller = "http://xquerrail.com/app-test/controllers/model1";

import module namespace request = "http://xquerrail.com/request" at "../../../../main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../../../main/_framework/response.xqy";
import module namespace base = "http://xquerrail.com/controller/base" at "../../../../main/_framework/base/base-controller.xqy";

declare function controller:info()
{
  (:<message><info>hello</info></message>:)
  <message><info>{
    processing-instruction {"test-processing-instruction"} {}
    }</info></message>

};
