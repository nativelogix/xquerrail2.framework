xquery version "1.0-ml";

import module namespace app = "http://xquerrail.com/application" at "../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "../main/_framework/base/base-model.xqy";

declare option xdmp:mapping "false";

declare variable $TEST-APPLICATION :=
<application xmlns="http://xquerrail.com/config">
  <base>/main</base>
  <config>/test/_framework/model-test/_config</config>
</application>
;

app:bootstrap($TEST-APPLICATION),
domain:get-model("model2")