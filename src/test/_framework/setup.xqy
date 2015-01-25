xquery version "1.0-ml";
module namespace setup = "http://xquerrail.com/test/setup";

import module namespace app = "http://xquerrail.com/application" at "../../main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "../../main/_framework/config.xqy";

declare option xdmp:mapping "false";

declare function setup(
  $application as element(config:application)
) as empty-sequence() {
  (app:reset(), app:bootstrap($application))[0]
};

declare function teardown() as empty-sequence()
{
  teardown(())
};

declare function teardown($collection as xs:string?) as empty-sequence()
{
  if ($collection) then
    xdmp:invoke-function(
      function() {
        xdmp:collection-delete($collection)
        , xdmp:commit()
      },
      <options xmlns="xdmp:eval">
        <transaction-mode>update</transaction-mode>
        <isolation>different-transaction</isolation>
      </options>
    )
  else
    ()
  ,
  xdmp:directory-delete("/test/")
  ,
  app:reset()
};

declare function random() as xs:string {
  fn:string(xdmp:random(1000000))
};

declare function invoke($fn as function(*)) {
  xdmp:invoke-function(
    function() {
      xdmp:apply($fn)
      ,
      xdmp:commit()
    },
    <options xmlns="xdmp:eval">
      <transaction-mode>update</transaction-mode>
      <isolation>different-transaction</isolation>
    </options>
  )
};

declare function eval($fn as function(*)) {
  xdmp:apply($fn)
};

