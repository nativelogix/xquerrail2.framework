xquery version "1.0-ml";

module namespace model = "http://xquerrail.com/app-test/models/model1";

import module namespace domain = "http://xquerrail.com/domain" at "../../../../../main/_framework/domain.xqy";
import module namespace base = "http://xquerrail.com/model/base" at "../../../../../main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare function model:model() {
  domain:get-model("model1")
};

