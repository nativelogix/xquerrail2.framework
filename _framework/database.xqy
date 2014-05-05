xquery version "1.0-ml";

module namespace database = "http://xquerrail.com/database";

import module namespace config = "http://xquerrail.com/config"
    at "/_framework/config.xqy";
 
import module namespace domain = "http://xquerrail.com/domain"
    at "/_framework/domain.xqy";
    
import module namespace admin = "http://marklogic.com/xdmp/admin" 
   at "/MarkLogic/admin.xqy";
   
declare namespace xdmp="http://marklogic.com/xdmp";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace err="http://marklogic.com/xdmp/error";
declare namespace ho="http://marklogic.com/xdmp/hosts";
declare namespace as="http://marklogic.com/xdmp/assignments";
declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace mt="http://marklogic.com/xdmp/mimetypes";
declare namespace pki="http://marklogic.com/xdmp/pki";

(:~
 : Initialize a database and build all relevant index configurations
 :)
declare function initialize($application-name as xs:string,$environment as xs:string) {
   let $domain :=  config:get-domain($application-name) 
   let $models :=  $domain/domain:model/domain:get-model(./@name)
   let $field-index-map := map:map()
   let $_ := 
            for $m in $models
            let $model := domain:get-model($m/@name)//(domain:element|domain:attribute)
            return
               assign-field-index($field-index-map)
   return 
      build-indexes($field-index-map)   
};
(:~
 : 
 :)
declare function assign-field-index($map as map:map,$field as element()) {
    let $index-type := fn:string($field/@type)
    let $index := 
        switch($type)
          case "element" return         
            <range-element-index>
               <scalar-type>{$type}</scalar-type>
               <namespace-uri>{$namespace}</namespace-uri>
               <localname>{$name}</localname>
               <range-value-positions>false</range-value-positions>
               <invalid-values>reject</invalid-values>
            </range-element-index>
          case "element-attribute" return
            <range-element-attribute-index xmlns="">
               <scalar-type>{$type}</scalar-type>
               <parent-namespace-uri></parent-namespace-uri>
               <parent-local-name>{$namespace}</parent-local-name>
               <namespace-uri>{$namespace}</namespace-uri>
               <localname>{$name}</localname>
               <range-value-positions>false</range-value-positions>
               <invalid-values>reject</invalid-values>
            </range-element-index>
         default return ()      
};

declare function database:resolve-systype($field)
{
   let $data-type := element{$field/@type}{$field}
   return 
     typeswitch($data-type)
     case element(uuid) return "string"
     case element(identity) return "string"
     case element(create-timestamp) return "dateTime"
     case element(create-user) return "string"
     case element(update-timestamp) return "dateTime"
     case element(update-user) return "string"
     case element(modify-user) return "string"
     case element(binary) return ()
     case element(schema-element) return ()
     case element(query) return "cts:query"
     case element(point) return "point"
     case element(string) return "string"
     case element(integer) return "int"
     case element(int) return "int"
     case element(long) return "long"
     case element(double) return "double"
     case element(decimal) return "decimal"
     case element(float) return "float"
     case element(boolean) return "boolean"
     case element(anyURI) return "anyURI"
     case element(dateTime) return "dateTime"
     case element(date) return "date"
     case element(duration) return "string"
     case element(dayTime) return "dayTimeDuration"
     case element(yearMonth) return "gYearMonth"
     case element(reference) return "element-attribute-value"
     default return fn:error(xs:QName("UNRESOLVED-DATATYPE"),$field)
};

declare function database:resolve-index-type($field)
{
   if($field instance of domain:attribute) 
   then "attribute"
   else 
      if($field instance of domain:element) then 
           switch($field/@type)
              case "point" return "long-lat-point"
              default return "element"
         
      else ()
};

declare function  build-index-script($map as map:map) {
  ()   
};

declare function apply-configuration($configuration) {
()
};
