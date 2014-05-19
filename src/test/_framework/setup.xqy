xquery version "1.0-ml";
module namespace setup = "http://xquerrail.com/test/setup";

import module namespace app = "http://xquerrail.com/application" at "../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../main/_framework/config.xqy";

declare option xdmp:mapping "false";

declare function setup() as empty-sequence()
{
  ()
};

declare function teardown() as item()*
{
  app:reset()
};
