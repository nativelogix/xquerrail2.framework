xquery version "1.0-ml";

module namespace controller = "http://xquerrail.com/app-test/controllers/programs";

import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace base = "http://xquerrail.com/controller/base" at "/main/_framework/base/base-controller.xqy";

declare function controller:model() {
  domain:get-model("programm")
};

declare function controller:my-action() {
  <response>{xdmp:random()}</response>
};
