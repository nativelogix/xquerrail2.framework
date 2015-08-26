xquery version "1.0-ml";
(:~
   Responsible for Configuring database indexes and other database related functionality.
   You must run initialize before you run initialize-database to reflect latest application domain changes.
   You must also add a route from your application to access this endpoint.
 :)
import module namespace config ="http://xquerrail.com/config" at "config.xqy";
import module namespace database = "http://xquerrail.com/database" at "database.xqy";

xdmp:set-response-content-type("application/xml"),
<initialize-database> {
database:initialize(map:entry("mode", xdmp:get-request-field("mode", "echo")))
}</initialize-database>
