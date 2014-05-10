xquery version "1.0-ml";

module namespace app = "http://xquerrail.com/application";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";

declare option xdmp:mapping "false";

declare function app:bootstrap() as item()* {
  app:bootstrap(())
};

declare function app:bootstrap($application as element(config:application)?) as item()* {
  if (fn:empty($application) and config:get-base-path() and config:get-config-path())
  then ()
  else
  (
    if ($application) 
    then (
      config:set-base-path(xs:string($application/config:base)),
      config:set-config-path((xs:string($application/config:config), "/_config")[1])
    )
    else (
      config:set-base-path(xs:string(xdmp:invoke("base.xqy")/config:base)),
      config:set-config-path((xs:string(xdmp:invoke("base.xqy")/config:config), "/_config")[1])
    )
  ,
  xdmp:log(("Bootstrap XQuerrail Application [" || config:version() || "] - [" || config:last-commit() || "]", "base [" || config:get-base-path() || "] - config [" || config:get-config-path() || "] - framework [" || config:framework-path() || "]"), "info")
  ,
  config:get-config()
  )
};
