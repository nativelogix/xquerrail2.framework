xquery version "1.0-ml";
module namespace setup = "http://xquerrail.com/test/setup";

import module namespace app = "http://xquerrail.com/application" at "/main/_framework/application.xqy";
import module namespace config = "http://xquerrail.com/config" at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/main/_framework/domain.xqy";
import module namespace model = "http://xquerrail.com/model/base" at "/main/_framework/base/base-model.xqy";

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

declare function create-instances(
  $model-name as xs:string,
  $instances as item()*,
  $test-collection as xs:string
) as empty-sequence() {
  let $model := domain:get-model($model-name)
  return
    for $instance in $instances return (
      setup:invoke(
        function() {
          model:create($model, $instance, $test-collection)
        }
      )
    )[0]
};

declare function random() as xs:string {
  fn:string(xdmp:random(1000000))
};

declare function random($name as xs:string) as xs:string {
  fn:concat($name, "-", random())
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

