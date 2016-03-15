xquery version "1.0-ml";

module namespace context = "http://xquerrail.com/context";

(:Options Definition:)
declare option xdmp:mapping "false";

declare %private variable $CACHE := map:new((
  map:entry(
    "private",
    json:object(
      <json:object xmlns:json="http://marklogic.com/xdmp/json" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <json:entry key="roles">
          <json:value xsi:nil="true"></json:value>
        </json:entry>
        <json:entry key="user">
          <json:value xsi:type="xs:string">{xdmp:get-current-user()}</json:value>
        </json:entry>
        <json:entry key="database-name">
          <json:value xsi:type="xs:string">{xdmp:database-name(xdmp:database())}</json:value>
        </json:entry>
      </json:object>
    )
  ),
  map:entry("public", json:object())
));

declare %private function context:private-map() as map:map {
  map:get($CACHE, "private")
};

declare %private function context:public-map() as map:map {
  map:get($CACHE, "public")
};

declare function context:user() as xs:string {
  map:get(context:private-map(), "user")
};

declare function context:user(
  $user as xs:string?
) as empty-sequence() {
  if (fn:exists($user)) then
    map:put(context:private-map(), "user", $user)
  else
    ()
};

declare function context:roles() {
  map:get(context:private-map(), "roles")
};

declare function context:add-role(
  $role as xs:string?
) as empty-sequence() {
  if (fn:exists($role)) then
    map:put(context:private-map(), "roles", (context:roles(), $role))
  else
    ()
};

declare function context:remove-role(
  $role as xs:string?
) as empty-sequence() {
  if (fn:exists($role)) then
    map:put(context:private-map(), "roles", fn:remove(context:roles(), fn:index-of(context:roles(), $role)))
  else
    ()
};

declare function context:server(
  $id as xs:unsignedLong+
) as empty-sequence() {
  map:put(context:private-map(), "server", $id)
};

declare function context:server(
) as xs:unsignedLong+ {
  if (map:contains(context:private-map(), "server")) then
    map:get(context:private-map(), "server")
  else
    xdmp:server()
};

declare function context:database-name() as xs:string {
  map:get(context:private-map(), "database-name")
};

declare function context:database-name(
  $database-name as xs:string?
) as empty-sequence() {
  if (fn:exists($database-name)) then
    map:put(context:private-map(), "database-name", $database-name)
  else
    ()
};

declare function context:keys(
) as xs:string* {
  map:keys(context:public-map())
};

declare function context:get(
  $key as xs:string
) as item()* {
  map:get(context:public-map(), $key)
};

declare function context:put(
  $key as xs:string,
  $value as item()*
) as empty-sequence() {
  map:put(context:public-map(), $key, $value)
};

declare function context:contains(
  $key as xs:string
) as xs:boolean {
  map:contains(context:public-map(), $key)
};
