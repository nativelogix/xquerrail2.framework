xquery version "1.0-ml";

module namespace cache = "http://xquerrail.com/cache";

declare namespace server-status = "http://marklogic.com/xdmp/status/server";

declare option xdmp:mapping "false";

declare variable $USE-MODULES-DB := (xdmp:modules-database() ne 0);

declare variable $SERVER-FIELD-CACHE-LOCATION := "server-field";
declare variable $DATABASE-CACHE-LOCATION := "database";
declare variable $DEFAULT-CACHE-LOCATION := $DATABASE-CACHE-LOCATION;
declare variable $DEFAULT-CACHE-USER := "anonymous";

declare variable $CONFIG-CACHE-TYPE := "config" ;
declare variable $DOMAIN-CACHE-TYPE := "domain";
declare variable $APPLICATION-CACHE-TYPE := "application";

declare %private variable $UNDEFINED-VALUE := "$$UNDEFINED-VALUE$$";
declare %private variable $CACHE-BASE-KEY := "http://xquerrail.com/cache/";
declare %private variable $TIMESTAMP-CACHE := cache:get-server-field-cache-map("timestamp-cache");

declare variable $CONFIG-CACHE-KEY := cache:cache-base() || "config/" ;
declare variable $DOMAIN-CACHE-KEY := cache:cache-base() || "domains/";
declare variable $APPLICATION-CACHE-KEY := cache:cache-base() || "applications/";
declare variable $GLOBAL-CACHE-KEY := cache:cache-base() || "global/";
declare variable $CACHE-COLLECTION := "cache:domain";

declare variable $CACHE-PERMISSIONS := (
  xdmp:permission("xquerrail","read"),
  xdmp:permission("xquerrail","update"),
  xdmp:permission("xquerrail","insert"),
  xdmp:permission("xquerrail","execute")
);

declare variable $CACHE-MAP := map:new();

declare function cache:cache-base() as xs:string {
  let $server-status := xdmp:server-status(xdmp:host(), xdmp:server())
  return fn:concat($CACHE-BASE-KEY, fn:string($server-status/server-status:server-name), "/", fn:string($server-status/server-status:port), "/")
};

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

declare %private function cache:contains-cache-map-for-type(
  $type as xs:string,
  $key as xs:string
) {
  let $cache := cache:get-cache-map-type($type)
  return map:contains($cache, $key)
};

declare %private function cache:get-cache-map-for-type(
  $type as xs:string,
  $key as xs:string
) {
  let $cache := cache:get-cache-map-type($type)
  return map:get($cache, $key)
};

declare %private function cache:set-cache-map-for-type(
  $type as xs:string,
  $key as xs:string,
  $value
) {
  let $cache := cache:get-cache-map-type($type)
  return map:put($cache, $key, $value)
};

declare %private function cache:clear-cache-map-for-type(
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

declare %private function cache:server-field-cache-map-key(
  $key as xs:string
) as xs:string {
  cache:server-field-cache-map-key((), $key)
};

declare %private function cache:server-field-cache-map-key(
  $application as xs:string?,
  $key as xs:string
) as xs:string {
  if (fn:exists($application)) then 
    fn:concat($APPLICATION-CACHE-KEY, $key) 
  else 
    fn:concat($GLOBAL-CACHE-KEY, $key)
};

declare function cache:contains-server-field-cache-map(
  $key as xs:string
) as xs:boolean {
  cache:contains-server-field-cache-map((), $key)
};

declare function cache:contains-server-field-cache-map(
  $application as xs:string?,
  $key as xs:string
) as xs:boolean {
  let $key := cache:server-field-cache-map-key($application, $key)
    (:if (fn:exists($application)) then 
      fn:concat($APPLICATION-CACHE-KEY, $key) 
    else 
      fn:concat($GLOBAL-CACHE-KEY, $key):)
  return cache:contains-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key)
};

declare function cache:get-server-field-cache-map(
  $key as xs:string
) as json:object {
  cache:get-server-field-cache-map((), $key)
};

declare function cache:get-server-field-cache-map(
  $application as xs:string?,
  $key as xs:string
) as json:object {
  let $key := cache:server-field-cache-map-key($application, $key)
  return
    if (cache:is-cache-empty($cache:SERVER-FIELD-CACHE-LOCATION, $key)) then
      let $cache := json:object()
      return (
        cache:set-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key, $cache),
        $cache
      )
    else
      cache:get-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key)
};

declare function cache:domain-model-cache(
) as json:object {
  cache:get-server-field-cache-map("domain-model-cache")
};

(:~
 : Contains the cacked key from the given cache
 :)
declare function cache:contains-cache-map(
	$cache as map:map,
  $key as xs:string
) as xs:boolean {
  map:contains($cache, $key)
};

(:~
 : Gets the cached value from the given key
 :)
declare function cache:get-cache-map(
  $cache as map:map,
  $key as xs:string
) {
  let $value := map:get($cache, $key)
  return
    if ($value instance of xs:string and $value = $UNDEFINED-VALUE) then
      ()
    else
      $value
};

(:~
 : Sets the cached value for the given key
 :)
declare function cache:set-cache-map(
  $cache as map:map,
  $key as xs:string,
  $value
) {
  map:put(
    $cache,
    $key,
      if (fn:exists($value)) then
        $value
      else
        $UNDEFINED-VALUE
  ),
  $value
};

declare function cache:remove-server-field-maps() {
  (:for $key in cache:get-cache-keys($cache:SERVER-FIELD-CACHE-LOCATION, $GLOBAL-CACHE-KEY)
  return cache:remove-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key):)
  cache:remove-server-field-maps(())
};

declare function cache:remove-server-field-maps($application as xs:string?) {
  let $keys := 
    if (fn:exists($application)) then
      fn:concat($APPLICATION-CACHE-KEY, $application)
    else
      $GLOBAL-CACHE-KEY
  return
    for $key in cache:get-cache-keys($cache:SERVER-FIELD-CACHE-LOCATION, $keys(:fn:concat($APPLICATION-CACHE-KEY, $application):))
    return cache:remove-cache($cache:SERVER-FIELD-CACHE-LOCATION, $key)
};

declare function cache:set-cache($key as xs:string, $value as item()*) as empty-sequence() {
  cache:set-cache($DEFAULT-CACHE-LOCATION, $key, $value)
};

declare function cache:set-cache($type as xs:string, $key as xs:string, $value) as empty-sequence() {
  cache:set-cache($type, $key, $value, ())
};

declare function cache:set-cache($type as xs:string, $key as xs:string, $value, $user as xs:string?) as empty-sequence() {
  cache:set-cache($type, $key, $value, $user, fn:false())
};

declare function cache:set-cache(
  $type as xs:string,
  $key as xs:string,
  $value,
  $user as xs:string?,
  $transient as xs:boolean
) as empty-sequence() {
  cache:set-cache($type, $key, $value, $user, $transient, fn:false())
};

declare function cache:set-cache(
  $type as xs:string,
  $key as xs:string,
  $value,
  $user as xs:string?,
  $transient as xs:boolean,
  $database-persist as xs:boolean
) as empty-sequence() {
  let $document-insert := function($key, $value, $user) {
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
    ),
    (:xdmp:log(text{"xdmp:document-timestamp($key)", xdmp:document-timestamp($key)}),:)
    cache:set-cache-map(
      $TIMESTAMP-CACHE,
      $key,
      xdmp:document-timestamp($key)
    )
  }
  return (
    cache:validate-cache-location($type)
    ,
    cache:set-cache-map-for-type($type, $key, $value)
    ,
    if ($transient) then
      ()
    else
      switch($type)
        case $SERVER-FIELD-CACHE-LOCATION
          return xdmp:set-server-field($key, $value)
        default return
          $document-insert($key, $value, $user)
    ,
    if ($database-persist and $type ne $DATABASE-CACHE-LOCATION) then
      $document-insert($key, $value, $user)
    else
      ()
  )[0]
};

declare function cache:get-cache($key as xs:string) {
  cache:get-cache($DEFAULT-CACHE-LOCATION, $key, ())
};

declare function cache:get-cache(
  $type as xs:string, 
  $key as xs:string
) {
  cache:get-cache($type, $key, ())
};

declare function cache:get-cache(
  $type as xs:string, 
  $key as xs:string, 
  $user as xs:string?
) {
  cache:get-cache($type, $key, $user, fn:false())
};

declare function cache:get-cache(
  $type as xs:string,
  $key as xs:string,
  $user as xs:string?,
  $database-fallback as xs:boolean
) {
  let $fn-doc := function($key, $user) {
    xdmp:eval('
      declare variable $key external;
      function() {
        fn:doc($key)/node()
      }()',(xs:QName("key"), $key),
      <options xmlns="xdmp:eval">
        <isolation>different-transaction</isolation>
        <user-id>{get-user-id($user)}</user-id>
      </options>
    )
  }
  let $_ := cache:validate-cache-location($type)
  let $value := cache:get-cache-map-for-type($type, $key)
  let $value :=
    if (fn:exists($value)) then
      $value
    else
    (
      let $value :=
        switch($type)
          case $SERVER-FIELD-CACHE-LOCATION
            return xdmp:get-server-field($key)
          default 
            return $fn-doc($key, $user)
      let $_ := cache:set-cache-map-for-type($type, $key, $value)
      return $value
    )
  return $value
};

declare function cache:contains-cache(
  $type as xs:string,
  $key as xs:string
) as xs:boolean {
  cache:contains-cache($type, $key, ())
};

declare function cache:contains-cache(
  $type as xs:string,
  $key as xs:string,
  $user as xs:string?
) as xs:boolean {
  (cache:contains-cache-map-for-type($type, $key) or cache:get-cache-keys($type, $key, $user) = $key)
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
  cache:clear-cache-map-for-type($type, $key)
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
  cache:clear-cache-map-for-type($type, $key)
  ,
  switch($type)
    case $SERVER-FIELD-CACHE-LOCATION
      return xdmp:set-server-field($key, ())
    default
      return
      xdmp:eval('
      declare variable $CACHE-BASE external;
      function() {
         xdmp:directory-delete($CACHE-BASE),
         xdmp:commit()
      }()',
      (xs:QName("CACHE-BASE"), cache:cache-base()),
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
