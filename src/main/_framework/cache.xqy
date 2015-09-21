xquery version "1.0-ml";

module namespace cache = "http://xquerrail.com/cache";

declare option xdmp:mapping "false";

declare variable $SERVER-FIELD-CACHE-LOCATION := "server-field";
declare variable $DATABASE-CACHE-LOCATION := "database";
declare variable $DEFAULT-CACHE-LOCATION := $DATABASE-CACHE-LOCATION;
declare variable $DEFAULT-CACHE-USER := "anonymous";

declare variable $CONFIG-CACHE-TYPE := "config" ;
declare variable $DOMAIN-CACHE-TYPE := "domain";
declare variable $APPLICATION-CACHE-TYPE := "application";

declare variable $CACHE-BASE-KEY := "http://xquerrail.com/cache/";
declare variable $CONFIG-CACHE-KEY := $CACHE-BASE-KEY || "config/" ;
declare variable $DOMAIN-CACHE-KEY := $CACHE-BASE-KEY || "domains/";
declare variable $APPLICATION-CACHE-KEY    := $CACHE-BASE-KEY || "applications/";
declare variable $CACHE-COLLECTION := "cache:domain";

declare variable $CACHE-PERMISSIONS := (
  xdmp:permission("xquerrail","read"),
  xdmp:permission("xquerrail","update"),
  xdmp:permission("xquerrail","insert"),
  xdmp:permission("xquerrail","execute")
);

declare variable $CACHE-MAP := map:new();

declare %private function cache:get-cache-map-type(
  $type as xs:string
) as map:map {
  let $_ :=
    if (map:contains($CACHE-MAP, $type)) then
      ()
    else
      map:put($CACHE-MAP, $type, map:new())
  return map:get($CACHE-MAP, $type)
};

declare %private function cache:get-cache-map(
  $type as xs:string,
  $key as xs:string
) {
  let $cache := cache:get-cache-map-type($type)
  return map:get($cache, $key)
};

declare %private function cache:set-cache-map(
  $type as xs:string,
  $key as xs:string,
  $value
) {
  let $cache := cache:get-cache-map-type($type)
  return map:put($cache, $key, $value)
};

declare %private function cache:clear-cache-map(
  $type as xs:string,
  $key as xs:string
) {
  let $cache := cache:get-cache-map-type($type)
  return map:delete($cache, $key)
};

declare %private function cache:get-cache-key($type as xs:string, $key as xs:string?) as xs:string {
  switch($type)
    case $DOMAIN-CACHE-TYPE return $DOMAIN-CACHE-KEY || $key
    case $APPLICATION-CACHE-TYPE return $APPLICATION-CACHE-KEY || $key
    case $CONFIG-CACHE-TYPE return $CONFIG-CACHE-KEY || $key
    default return fn:error(xs:QName("INVALID-CACHE-KEY"), "Invalid Cache Key", "[" || $type || "] - [" || $key || "]")
};

declare %private function cache:validate-cache-location($type as xs:string) {
  switch($type)
    case $DEFAULT-CACHE-LOCATION return ()
    case $SERVER-FIELD-CACHE-LOCATION return ()
    default return fn:error(xs:QName("INVALID-CACHE-TYPE"), "Invalid Cache Type", $type)
};

declare %private function cache:get-user-id($user as xs:string?) as xs:integer {
  xdmp:user(($user, $DEFAULT-CACHE-USER)[1])
};

declare %private function cache:cache-location($location as xs:string?) {
  ($location, $DEFAULT-CACHE-LOCATION)[1]
};

declare function cache:set-cache($key as xs:string, $value as item()*) as empty-sequence(){
  cache:set-cache($DEFAULT-CACHE-LOCATION, $key, $value)
};

declare function cache:set-cache($type as xs:string, $key as xs:string, $value) as empty-sequence() {
  cache:set-cache($type, $key, $value, ())
};

declare function cache:set-cache($type as xs:string, $key as xs:string, $value, $user as xs:string?) as empty-sequence() {
  cache:set-cache($type, $key, $value, $user, fn:false())
};

declare function cache:set-cache($type as xs:string, $key as xs:string, $value, $user as xs:string?, $transient as xs:boolean) as empty-sequence() {
  xdmp:log(text{"set-cache", $type, $key, $transient}, "finest"),
  (
    cache:validate-cache-location($type)
    ,
    cache:set-cache-map($type, $key, $value)
    ,
    if ($transient) then
      ()
    else
      switch($type)
        case $SERVER-FIELD-CACHE-LOCATION
          return xdmp:set-server-field($key, $value)
        default return
          xdmp:eval('
            declare variable $key as xs:string external;
            declare variable $value as node() external;
            declare variable $CACHE-PERMISSIONS external;
            declare variable $CACHE-COLLECTION external;
            function() {
               xdmp:document-insert($key,$value,$CACHE-PERMISSIONS/*,($CACHE-COLLECTION)),
               xdmp:commit()
            }()',
            (xs:QName("key"),$key,
            xs:QName("value"),$value,
            xs:QName("CACHE-PERMISSIONS"),<x>{$CACHE-PERMISSIONS}</x>,
            xs:QName("CACHE-COLLECTION"),$CACHE-COLLECTION),
            <options xmlns="xdmp:eval">
             <isolation>different-transaction</isolation>
             <transaction-mode>update</transaction-mode>
             <user-id>{get-user-id($user)}</user-id>
            </options>
          )
  )[0]
};

declare function cache:get-cache($key as xs:string) {
  cache:get-cache($DEFAULT-CACHE-LOCATION, $key, ())
};

declare function cache:get-cache($type as xs:string, $key as xs:string) {
  cache:get-cache($type, $key, ())
};

declare function cache:get-cache($type as xs:string, $key as xs:string, $user as xs:string?) {
  let $_ := (
    xdmp:log((text{"get-cache", $type, $key, $user}), "finest"),
    cache:validate-cache-location($type)
  )
  let $value := cache:get-cache-map($type, $key)
  let $value :=
    if (fn:exists($value)) then
      $value
    else
    (
      let $value :=
        switch($type)
          case $SERVER-FIELD-CACHE-LOCATION
            return xdmp:get-server-field($key)
          default return
            xdmp:eval('
              declare variable $key external;
              function() {
                 fn:doc( $key)
              }()',(xs:QName("key"),$key),
              <options xmlns="xdmp:eval">
                <isolation>different-transaction</isolation>
                <user-id>{get-user-id($user)}</user-id>
              </options>
            )
      let $_ := cache:set-cache-map($type, $key, $value)
      return $value
    )
  return $value
};

declare function cache:get-cache-keys($type as xs:string, $path as xs:string) as xs:string* {
  cache:get-cache-keys($type, $path, ())
};

declare function cache:get-cache-keys($type as xs:string, $path as xs:string?, $user as xs:string?) as xs:string* {
  cache:validate-cache-location($type)
  ,
  switch($type)
    case $SERVER-FIELD-CACHE-LOCATION
      return xdmp:get-server-field-names()[fn:starts-with(., $path)]
    default
      return
      xdmp:eval(
        'declare variable $DOMAIN-CACHE-KEY as xs:string external;
        function() {cts:uris((),(),cts:directory-query($DOMAIN-CACHE-KEY,"infinity"))}()',
        (xs:QName("DOMAIN-CACHE-KEY"),$path),
        <options xmlns="xdmp:eval">
          <isolation>different-transaction</isolation>
          <user-id>{get-user-id($user)}</user-id>
        </options>
      )
};

declare function cache:remove-cache($type as xs:string, $key as xs:string) as empty-sequence() {
  cache:remove-cache($type, $key, ())
};

declare function cache:remove-cache($type as xs:string, $key as xs:string, $user as xs:string?) as empty-sequence() {
  cache:validate-cache-location($type)
  ,
  cache:clear-cache-map($type, $key)
  ,
  switch($type)
    case $SERVER-FIELD-CACHE-LOCATION
      return xdmp:set-server-field($key, ())
    default
      return
      xdmp:eval('
      declare variable $key external;
      declare variable $CACHE-COLLECTION external;
      function() {
        if (fn:exists($key)) then
          (xdmp:collection-delete($CACHE-COLLECTION),
                    xdmp:commit())
        else
          ()
        (: if (fn:doc-available($key)) then (
         xdmp:document-delete($key),
         xdmp:commit()
        ) else () :)
      }()',
      (xs:QName("key"), $key,
      xs:QName("CACHE-COLLECTION"),<x>{$CACHE-COLLECTION}</x>),
      <options xmlns="xdmp:eval">
       <isolation>different-transaction</isolation>
       <transaction-mode>update</transaction-mode>
       <user-id>{get-user-id($user)}</user-id>
      </options>
      )
};

declare function cache:clear-cache($key as xs:string) as empty-sequence() {
  clear-cache($DEFAULT-CACHE-LOCATION, $key, ())
};

declare function cache:clear-cache($type as xs:string, $key as xs:string) as empty-sequence() {
  clear-cache($type, $key, ())
};

declare function cache:clear-cache($type as xs:string, $key as xs:string, $user as xs:string?) as empty-sequence() {
  cache:validate-cache-location($type)
  ,
  cache:clear-cache-map($type, $key)
  ,
  switch($type)
    case $SERVER-FIELD-CACHE-LOCATION
      return xdmp:set-server-field($key, ())
    default
      return
      xdmp:eval('
      declare variable $CACHE-BASE-KEY external;
      function() {
         xdmp:directory-delete($CACHE-BASE-KEY),
         xdmp:commit()
      }()',
      (xs:QName("CACHE-BASE-KEY"), $CACHE-BASE-KEY),
      <options xmlns="xdmp:eval">
       <isolation>different-transaction</isolation>
       <transaction-mode>update</transaction-mode>
       <user-id>{get-user-id($user)}</user-id>
      </options>
      )
};

declare function cache:is-cache-empty($type as xs:string, $base-key as xs:string) as xs:boolean {
  cache:is-cache-empty($type, $base-key, ())
};

declare function cache:is-cache-empty($type as xs:string, $base-key as xs:string, $user as xs:string?) as xs:boolean {
  cache:validate-cache-location($type)
  ,
  switch($type)
    case $SERVER-FIELD-CACHE-LOCATION
      return fn:empty(xdmp:get-server-field($base-key))
    default
      return
      xdmp:eval('
        declare variable $base-key external;
        function() {
          fn:empty(xdmp:directory($base-key))
        }()',(xs:QName("base-key"),$base-key),
        <options xmlns="xdmp:eval">
          <isolation>different-transaction</isolation>
          <user-id>{get-user-id($user)}</user-id>
        </options>
      )
};

(: Application cache implementation :)

declare function cache:get-application-cache($key as xs:string) {
  cache:get-application-cache((), $key)
};

declare function cache:get-application-cache($type as xs:string?, $key as xs:string) {
  cache:get-application-cache($type, $key, ())
};

declare function cache:get-application-cache($type as xs:string?, $key as xs:string, $user as xs:string?) {
  cache:get-cache(cache:cache-location($type), cache:get-cache-key($APPLICATION-CACHE-TYPE, $key), $user)
};

declare function cache:set-application-cache($key as xs:string, $value) as item()* {
  cache:set-application-cache((), $key, $value)
};

declare function cache:set-application-cache($type as xs:string?, $key as xs:string, $value) as item()* {
  cache:set-application-cache($type, $key, $value, ())
};

declare function cache:set-application-cache($type as xs:string?, $key as xs:string, $value, $user as xs:string?) as empty-sequence() {
  cache:set-cache(cache:cache-location($type), cache:get-cache-key($APPLICATION-CACHE-TYPE, $key), $value, $user)
};

declare function cache:remove-application-cache($key as xs:string) as empty-sequence() {
  cache:remove-application-cache((), $key)
};

declare function cache:remove-application-cache($type as xs:string?, $key as xs:string) as empty-sequence() {
  cache:remove-application-cache(cache:cache-location($type), $key, ())
};

declare function cache:remove-application-cache($type as xs:string?, $key as xs:string, $user as xs:string?) as empty-sequence() {
  cache:remove-cache(cache:cache-location($type), cache:get-cache-key($APPLICATION-CACHE-TYPE, $key), $user)
};

declare function cache:is-application-cache-empty($key as xs:string) as xs:boolean {
  cache:is-application-cache-empty((), $key)
};

declare function cache:is-application-cache-empty($type as xs:string?, $key as xs:string) as xs:boolean {
  cache:is-application-cache-empty($type, $key, ())
};

declare function cache:is-application-cache-empty($type as xs:string?, $key as xs:string, $user as xs:string?) as xs:boolean {
  cache:is-cache-empty(cache:cache-location($type), cache:get-cache-key($APPLICATION-CACHE-TYPE, $key), $user)
};

(: Domain cache implementation :)

declare function cache:get-domain-cache($key as xs:string) {
  cache:get-domain-cache((), $key)
};

declare function cache:get-domain-cache($type as xs:string?, $key as xs:string) {
  cache:get-domain-cache($type, $key, ())
};

declare function cache:get-domain-cache($type as xs:string?, $key as xs:string, $user as xs:string?) {
  cache:get-cache(cache:cache-location($type), cache:get-cache-key($DOMAIN-CACHE-TYPE, $key), $user)
};

declare function cache:set-domain-cache($key as xs:string, $value) as empty-sequence() {
  cache:set-domain-cache((), $key, $value)
};

declare function cache:set-domain-cache($type as xs:string?, $key as xs:string, $value) as empty-sequence() {
  cache:set-domain-cache($type, $key, $value, ())
};

declare function cache:set-domain-cache($type as xs:string?, $key as xs:string, $value, $user as xs:string?) as empty-sequence() {
  cache:set-domain-cache($type, $key, $value, $user, fn:false())
};

declare function cache:set-domain-cache($type as xs:string?, $key as xs:string, $value, $user as xs:string?, $transient as xs:boolean) as empty-sequence() {
  cache:set-cache(cache:cache-location($type), cache:get-cache-key($DOMAIN-CACHE-TYPE, $key), $value, $user, $transient)
};

declare function cache:remove-domain-cache($key as xs:string) as empty-sequence() {
  cache:remove-domain-cache($DEFAULT-CACHE-LOCATION, $key)
};

declare function cache:remove-domain-cache($type as xs:string, $key as xs:string) as empty-sequence() {
  cache:remove-domain-cache($type, $key, ())
};

declare function cache:remove-domain-cache($type as xs:string?, $key as xs:string, $user as xs:string?) as empty-sequence() {
  cache:remove-cache(cache:cache-location($type), cache:get-cache-key($DOMAIN-CACHE-TYPE, $key), $user)
};

(: Config cache implementation :)

declare function cache:get-config-cache($key as xs:string) {
  cache:get-config-cache((), $key)
};

declare function cache:get-config-cache($type as xs:string?, $key as xs:string?) {
  cache:get-config-cache($type, $key, ())
};

declare function cache:get-config-cache($type as xs:string?, $key as xs:string?, $user as xs:string?) {
  cache:get-cache(cache:cache-location($type), cache:get-cache-key($CONFIG-CACHE-TYPE, $key), $user)
};

declare function cache:set-config-cache($key as xs:string?, $value) as empty-sequence() {
  cache:set-config-cache((), $key, $value)
};

declare function cache:set-config-cache($type as xs:string?, $key as xs:string?, $value) as empty-sequence() {
  cache:set-config-cache($type, $key, $value, ())
};

declare function cache:set-config-cache($type as xs:string?, $key as xs:string?, $value, $user as xs:string?) as empty-sequence() {
  cache:set-cache(cache:cache-location($type), cache:get-cache-key($CONFIG-CACHE-TYPE, $key), $value, $user)
};

declare function cache:remove-config-cache($key as xs:string?) as empty-sequence() {
  cache:remove-config-cache($DEFAULT-CACHE-LOCATION)
};

declare function cache:remove-config-cache($type as xs:string, $key as xs:string?) as empty-sequence() {
  cache:remove-config-cache($type, $key, ())
};

declare function cache:remove-config-cache($type as xs:string?, $key as xs:string?, $user as xs:string?) as empty-sequence() {
  cache:remove-cache(cache:cache-location($type), cache:get-cache-key($CONFIG-CACHE-TYPE, $key), $user)
};
