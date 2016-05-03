xquery version "1.0-ml";
(:~
 : Handle MarkLogic API incompatibility
~:)
module namespace api = "http://xquerrail.com/xdmp/api";

declare option xdmp:mapping "false";

(:~ version returns MarkLogic Server version as decimal :)
declare function api:version(
) as xs:decimal {
  xs:decimal(fn:concat(fn:substring-before(xdmp:version(), "."), ".", fn:replace(fn:substring-after(xdmp:version(), "."), "[-\.]", "")))
};

declare function api:is-ml-8(
) as xs:boolean {
  fn:starts-with(xdmp:version(), "8")
};

declare function api:from-json(
  $arg as xs:string
) as item()* {

  if (api:is-ml-8()) then
    xdmp:function(xs:QName("xdmp:from-json-string"))($arg)
  else
    xdmp:function(xs:QName("xdmp:from-json"))($arg)
};

(: TODO: Use javascript server-side mime-type - application/vnd.marklogic-javascript :)
declare function api:is-javascript-modules(
  $location as xs:string
) as xs:boolean {
  fn:ends-with(fn:lower-case($location), ".sjs")
};

declare function api:trace-enabled(
  $event-name as xs:string
) as xs:boolean {
  if (api:version() ge 8.05) then
    xdmp:function(xs:QName("xdmp:trace-enabled"))($event-name)
  else
    fn:true()
};

