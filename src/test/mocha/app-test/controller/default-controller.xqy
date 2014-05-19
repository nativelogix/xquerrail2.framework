xquery version "1.0-ml";
(:~
 : Default Application Controller
~:)
module namespace controller = "http://xquerrail.com/app-test/controller/default";

import module namespace request = "http://xquerrail.com/request" at "../../../../main/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../../../main/_framework/response.xqy";
import module namespace base = "http://xquerrail.com/controller/base" at "../../../../main/_framework/base/base-controller.xqy";

declare function controller:main()
{
  controller:index()
};

declare function controller:index()
{(
    response:set-controller("default"),
    response:set-action("index"),
    (:response:set-template("main"),:)
    response:set-view("index"),
    response:set-title(fn:concat("Welcome: ",xdmp:get-current-user())),
    response:add-httpmeta("cache-control","public"),
    response:flush()
)};

declare function controller:login()
{
  base:login()
};

declare function controller:logout()
{
  base:logout()
};
