xquery version "1.0-ml";
(:~ 

Copyright 2011 - NativeLogix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.




 :)
(:~
   Responsible for Configuring database indexes and other database related functionality.
   You must run initialize before you run initialize-database to reflect latest application domain changes.
   You must also add a route from your application to access this endpoint.
 :)
import module namespace config ="http://xquerrail.com/config" at "config.xqy";
import module namespace database = "http://xquerrail.com/database" at "database.xqy";

xdmp:set-response-content-type("application/xml"),
<initialize-database> {
  let $params := map:new((
    map:entry("mode",xdmp:get-request-field("mode","apply"))
  ))
  return
    database:initialize($params)
  
}</initialize-database>