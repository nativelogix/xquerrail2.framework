xquery version "1.0-ml";
(:~
 : Model #1 Controller
~:)
module namespace controller = "http://xquerrail.com/app-test/controllers/model1";

import module namespace request = "http://xquerrail.com/request" at "/main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/main/_framework/response.xqy";
import module namespace base-controller = "http://xquerrail.com/controller/base" at "/main/_framework/base/base-controller.xqy";
import module namespace base-model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";

declare function controller:find()
{
  <find>
    { attribute array { fn:true() } }
    { base-model:find(base-controller:model(), base-controller:get-params()) }
  </find>
};

declare function controller:find-empty()
{
  <find-empty>
    { attribute array { fn:true() } }
    { attribute type { base-controller:model()/@name } }
  </find-empty>
};

declare function controller:multi-find()
{
  let $instances1 := base-model:find(base-controller:model(), base-controller:get-params())
  let $instances2 := base-model:find(domain:get-model("model2"), base-controller:get-params())
  return
  <multi-find>
    { attribute multi { fn:true() } }
    { $instances2 }
    { $instances1 }
  </multi-find>
};
