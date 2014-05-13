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
      config:set-base-path(xs:string(get-base()/config:base)),
      config:set-config-path((xs:string(get-base()/config:config), "/_config")[1])
    )
  ,
  xdmp:log(("Bootstrap XQuerrail Application [" || config:version() || "] - [" || config:last-commit() || "]", "base [" || config:get-base-path() || "] - config [" || config:get-config-path() || "] - framework [" || config:framework-path() || "]"), "info")
  ,
  config:get-config()
  )
};

declare %private function get-base() as element(config:application) {
  let $base := (get-base-safe("/base.xqy"), get-base-safe("base.xqy"))[1]
  return
    if ($base) then $base
    else fn:error(xs:QName("BASE-NOTFOUND"), "Cannot find /base.xqy or base.xqy")
};

declare %private function get-base-safe($path as xs:string) as element(config:application)? {
  try {
    xdmp:invoke($path)
  }
  catch * {
    ()
  }
}; 
