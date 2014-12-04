xquery version "1.0-ml";

module namespace extension = "http://xquerrail.com/application/extension";

declare option xdmp:mapping "false";

declare variable $USE-MODULES-DB := (xdmp:modules-database() ne 0);

declare function extension:initialize(
) as empty-sequence() {
  xdmp:set-server-field("custom-bootstrap-test", fn:current-dateTime())[0]
};
