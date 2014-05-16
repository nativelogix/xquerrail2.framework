xquery version "1.0-ml";

module namespace cache = "http://xquerrail.com/cache";

declare option xdmp:mapping "false";

declare variable $SERVER-FIELD-CACHE-LOCATION := "server-field";
declare variable $DATABASE-CACHE-LOCATION := "database";
declare variable $DEFAULT-CACHE-LOCATION := $DATABASE-CACHE-LOCATION;
declare variable $DEFAULT-CACHE-USER := "anonymous";

declare variable $CONFIG-CACHE-TYPE := "config" ;
declare variable $DOMAIN-CACHE-TYPE := "domain";
declare variable $APPLICATION-CACHE-TYPE    := "application";

declare variable $CACHE-BASE-KEY := "http://xquerrail.com/cache/";
declare variable $CONFIG-CACHE-KEY := $CACHE-BASE-KEY || "config" ;
declare variable $DOMAIN-CACHE-KEY := $CACHE-BASE-KEY || "domains/";
declare variable $APPLICATION-CACHE-KEY    := $CACHE-BASE-KEY || "applications/";
declare variable $CACHE-COLLECTION := "cache:domain";

declare variable $CACHE-PERMISSIONS := (
  xdmp:permission("xquerrail","read"),
  xdmp:permission("xquerrail","update"),
  xdmp:permission("xquerrail","insert"),
  xdmp:permission("xquerrail","execute")
);

declare %private function get-cache-key($type as xs:string, $key as xs:string?) as xs:string {
  switch($type)
    case $DOMAIN-CACHE-TYPE return $DOMAIN-CACHE-KEY || $key
    case $APPLICATION-CACHE-TYPE return $APPLICATION-CACHE-KEY || $key
    case $CONFIG-CACHE-TYPE return $CONFIG-CACHE-KEY
    default return fn:error(xs:QName("INVALID-CACHE-KEY"), "Invalid Cache Key", "[" || $type || "] - [" || $key || "]")
};

declare %private function validate-cache-location($type as xs:string) {
  switch($type)
    case $DEFAULT-CACHE-LOCATION return ()
    case $SERVER-FIELD-CACHE-LOCATION return ()
    default return fn:error(xs:QName("INVALID-CACHE-TYPE"), "Invalid Cache Type", $type)
};

declare %private function get-user-id($user as xs:string?) as xs:integer {
  xdmp:user(($user, $DEFAULT-CACHE-USER)[1])
};

declare %private function cache-location($location as xs:string?) {
  ($location, $DEFAULT-CACHE-LOCATION)[1]
};

declare function set-cache($type as xs:string, $key as xs:string, $value) as empty-sequence() {
  set-cache($type, $key, $value, ())
};

declare function set-cache($type as xs:string, $key as xs:string, $value, $user as xs:string?) as empty-sequence() {
  let $_ := xdmp:log(("set-cache [" || $type || "] - [" || $key || "]"), "debug")
  let $_ := (
    validate-cache-location($type)
    ,
    switch($type)
    case "database" return
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
    default return
        xdmp:set-server-field($key, $value)
  )
  return ()
};

declare function get-cache($type as xs:string, $key as xs:string) {
  get-cache($type, $key, ())
};

declare function get-cache($type as xs:string, $key as xs:string, $user as xs:string?) {
  validate-cache-location($type)
  ,
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
};

declare function get-cache-keys($type as xs:string, $path as xs:string) as xs:string* {
  get-cache-keys($type, $path, ())
};

declare function get-cache-keys($type as xs:string, $path as xs:string?, $user as xs:string?) as xs:string* {
  validate-cache-location($type)
  ,
  switch($type)
    case $SERVER-FIELD-CACHE-LOCATION
      return xdmp:get-server-field-names()
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

declare function remove-cache($type as xs:string, $key as xs:string) as empty-sequence() {
  remove-cache($type, $key, ())
};

declare function remove-cache($type as xs:string, $key as xs:string, $user as xs:string?) as empty-sequence() {
  validate-cache-location($type)
  ,
  switch($type)
    case $SERVER-FIELD-CACHE-LOCATION
      return xdmp:set-server-field($key, ())
    default
      return
      xdmp:eval('
      declare variable $key external;
      function() {
         xdmp:document-delete($key),
         xdmp:commit()
      }()',
      (xs:QName("key"), $key),
      <options xmlns="xdmp:eval">
       <isolation>different-transaction</isolation>
       <transaction-mode>update</transaction-mode>
       <user-id>{get-user-id($user)}</user-id>
      </options>
      )
};

declare function clear-cache($type as xs:string, $key as xs:string) as empty-sequence() {
  clear-cache($type, $key, ())
};

declare function clear-cache($type as xs:string, $key as xs:string, $user as xs:string?) as empty-sequence() {
  validate-cache-location($type)
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

declare function is-cache-empty($type as xs:string, $base-key as xs:string) as xs:boolean {
  is-cache-empty($type, $base-key, ())
};

declare function is-cache-empty($type as xs:string, $base-key as xs:string, $user as xs:string?) as xs:boolean {
  validate-cache-location($type)
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

declare function get-application-cache($key as xs:string) {
  get-application-cache((), $key)
};

declare function get-application-cache($type as xs:string?, $key as xs:string) {
  get-application-cache($type, $key, ())
};

declare function get-application-cache($type as xs:string?, $key as xs:string, $user as xs:string?) {
  get-cache(cache-location($type), get-cache-key($APPLICATION-CACHE-TYPE, $key), $user)
};

declare function set-application-cache($key as xs:string, $value) as item()* {
  set-application-cache((), $key, $value)
};

declare function set-application-cache($type as xs:string?, $key as xs:string, $value) as item()* {
  set-application-cache($type, $key, $value, ())
};

declare function set-application-cache($type as xs:string?, $key as xs:string, $value, $user as xs:string?) as item()* {
  set-cache(cache-location($type), get-cache-key($APPLICATION-CACHE-TYPE, $key), $value, $user)
};

declare function remove-application-cache($key as xs:string) as empty-sequence() {
  remove-application-cache((), $key)
};

declare function remove-application-cache($type as xs:string?, $key as xs:string) as empty-sequence() {
  remove-application-cache(cache-location($type), $key, ())
};

declare function remove-application-cache($type as xs:string?, $key as xs:string, $user as xs:string?) as empty-sequence() {
  remove-cache(cache-location($type), get-cache-key($APPLICATION-CACHE-TYPE, $key), $user)
};

declare function is-application-cache-empty() as xs:boolean {
  is-application-cache-empty((), ())
};

declare function is-application-cache-empty($type as xs:string?, $user as xs:string?) as xs:boolean {
  is-cache-empty(cache-location($type), $APPLICATION-CACHE-KEY, $user)
};

(: Domain cache implementation :)

declare function get-domain-cache($key as xs:string) {
  get-domain-cache((), $key)
};

declare function get-domain-cache($type as xs:string?, $key as xs:string) {
  get-domain-cache($type, $key, ())
};

declare function get-domain-cache($type as xs:string?, $key as xs:string, $user as xs:string?) {
  get-cache(cache-location($type), get-cache-key($DOMAIN-CACHE-TYPE, $key), $user)
};

declare function set-domain-cache($key as xs:string, $value) as empty-sequence() {
  set-domain-cache((), $key, $value)
};

declare function set-domain-cache($type as xs:string?, $key as xs:string, $value) as empty-sequence() {
  set-domain-cache($type, $key, $value, ())
};

declare function set-domain-cache($type as xs:string?, $key as xs:string, $value, $user as xs:string?) as empty-sequence() {
  set-cache(cache-location($type), get-cache-key($DOMAIN-CACHE-TYPE, $key), $value, $user)
};

declare function remove-domain-cache($key as xs:string) as empty-sequence() {
  remove-domain-cache($DEFAULT-CACHE-LOCATION, $key)
};

declare function remove-domain-cache($type as xs:string, $key as xs:string) as empty-sequence() {
  remove-domain-cache($type, $key, ())
};

declare function remove-domain-cache($type as xs:string?, $key as xs:string, $user as xs:string?) as empty-sequence() {
  remove-cache(cache-location($type), get-cache-key($DOMAIN-CACHE-TYPE, $key), $user)
};

(: Config cache implementation :)

declare function get-config-cache() {
  get-config-cache(())
};

declare function get-config-cache($type as xs:string?) {
  get-config-cache($type, ())
};

declare function get-config-cache($type as xs:string?, $user as xs:string?) {
  get-cache(cache-location($type), get-cache-key($CONFIG-CACHE-TYPE, ()), $user)
};

declare function set-config-cache($value) as item()* {
  set-config-cache((), $value)
};

declare function set-config-cache($type as xs:string?, $value) as item()* {
  set-config-cache($type, $value, ())
};

declare function set-config-cache($type as xs:string?, $value, $user as xs:string?) as item()* {
  set-cache(cache-location($type), get-cache-key($CONFIG-CACHE-TYPE, ()), $value, $user)
};

declare function remove-config-cache() as empty-sequence() {
  remove-config-cache($DEFAULT-CACHE-LOCATION)
};

declare function remove-config-cache($type as xs:string) as empty-sequence() {
  remove-config-cache($type, ())
};

declare function remove-config-cache($type as xs:string?, $user as xs:string?) as empty-sequence() {
  remove-cache(cache-location($type), get-cache-key($CONFIG-CACHE-TYPE, ()), $user)
};
