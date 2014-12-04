xquery version "1.0-ml";
(:~
 : Supports Common database operations such as
 : applying indexes based on domain model configuration
 :    - key fields
 :    - keyLabel fields
 :    - any field with domain:navigation/@searchType = ("range","path)
 :    - any field with domain:navigation/@sortable = "true"
 : applying index configuration based on application environment (dev,prod,qa)
 : unapply all indexes
 :)
module namespace database = "http://xquerrail.com/database";

import module namespace config = "http://xquerrail.com/config" at "config.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "domain.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
   
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace xs   = "http://www.w3.org/2001/XMLSchema";
declare namespace db   = "http://marklogic.com/xdmp/database";
declare namespace gr   = "http://marklogic.com/xdmp/group";
declare namespace err  = "http://marklogic.com/xdmp/error";
declare namespace ho   = "http://marklogic.com/xdmp/hosts";
declare namespace as   = "http://marklogic.com/xdmp/assignments";
declare namespace fs   = "http://marklogic.com/xdmp/status/forest";
declare namespace mt   = "http://marklogic.com/xdmp/mimetypes";
declare namespace pki  = "http://marklogic.com/xdmp/pki";

declare variable $INDEX-CACHE := ();

(:~
 : Initialize a database and build all relevant index configurations
 :)
declare function initialize($params as map:map) {
   let $build := 
     for $application in config:get-applications()
     let $domain :=  config:get-domain($application/@name) 
     let $indexes := database:build-range-indexes($domain)
     let $apply := 
       if(map:get($params,"mode") = "apply") 
       then database:apply-indexes($indexes[fn:not(database:index-exists(.))])
       else if(map:get($params,"mode") = "unapply")
       then database:unapply-indexes($indexes)
       else $indexes
     return $apply
   return
     $build
};

(:~
 : Configures the domain Indexes defined by data models
~:)
declare function database:build-range-indexes($domain as element(domain:domain)) {
   let $index-map := map:map()
   let $log := xdmp:log(fn:concat("Indexing:",fn:count($domain/domain:model[@type ne "abstract"])),"debug")
   let $index-fields := 
      for $model in $domain/domain:model[@persistence ne "abstract"]
      let $key-field := domain:get-model-key-field($model)
      let $keyLabel-field := domain:get-model-keyLabel-field($model) 
      let $index-fields := $model//(domain:element|domain:attribute)[domain:navigation/@searchType = ("range","path")]
      let $indexes := (
        database:create-range-index-spec($key-field,"range"),
        database:create-range-index-spec($keyLabel-field,"range"),
        for $index-field in $index-fields
        let $index-type := $index-field/domain:navigation/@searchType
        return database:create-range-index-spec($index-field,$index-type)
      )
      let $indexes := 
        for $index in $indexes
        return 
           if(map:contains($index-map,database:index-spec-key($index))) then () else ($index,map:put($index-map,database:index-spec-key($index),"")) 
      return $indexes
   return $index-fields
};

(:~
 : Creates an unique key for index ignoring positional and accept/reject
~:)
declare function database:index-spec-key($index) {
   typeswitch($index)
     case element(db:range-element-index) return 
        fn:string-join((
            $index/db:scalar-type,
            $index/db:namespace-uri,
            $index/db:localname,
            $index/db:collation
        ),"|")
     case element(db:range-element-attribute-index) return 
        fn:string-join((
            $index/db:scalar-type,
            $index/db:parent-namespace-uri,
            $index/db:parent-localname,
            $index/db:namespace-uri,
            $index/db:localname,
            $index/db:collation
        ),"|")
     case element(db:path-range-index) return 
        fn:string-join((
            $index/db:scalar-type,
            $index/db:namespace-uri,
            $index/db:path-expression,
            $index/db:collation)
        ,"|")
     default return fn:error(xs:QName("UNHANDLED-INDEX-KEY-SPEC"),"Cannot create spec key for" || fn:node-name($index))
};

(:~
 : Creates the Range Index Specification for each field
 :)
declare function database:create-range-index-spec($field,$indexType) {
  if(fn:exists($field)) then 
    switch($indexType)
      case "range" return 
         typeswitch($field)
         case element(domain:element) return
            admin:database-range-element-index(
               domain:get-field-scalar-type($field),
               domain:get-field-namespace($field),
               $field/@name,
               if(domain:get-field-scalar-type($field) = ("anyURI","string"))
               then domain:get-field-collation($field)
               else "",
               if($field/domain:navigation/@positional = "true") then fn:true() else fn:false(),
               if($field/domain:constraint/@required  = "true") then "reject" else "ignore"
            )
         case element(domain:attribute) return 
            admin:database-range-element-attribute-index(
               domain:get-field-scalar-type($field),
               domain:get-field-namespace($field/..),
               fn:data($field/../@name),
               "",
               $field/@name,
               if(domain:get-field-scalar-type($field) = ("anyURI","string"))
               then domain:get-field-collation($field)
               else "",
               if($field/domain:navigation/@positional = "true") then fn:true() else fn:false(),
               if($field/domain:constraint/@required  = "true") then "reject" else "ignore"
            )
         default return fn:error(xs:QName("INDEX-LOGIC"))
      case "path" return 
         admin:database-range-path-index(
            xdmp:database(),
            domain:get-field-scalar-type($field),
            domain:get-field-absolute-xpath($field),
            if(domain:get-field-scalar-type($field) = ("anyURI","string"))
            then domain:get-field-collation($field)
            else "",
            if($field/domain:navigation/@positional = "true") then fn:true() else fn:false(),
            if($field/domain:constraint/@required  = "true") then "reject" else "ignore"
         )
      default return fn:error(xs:QName("NON-INDEXABLE-TYPE"),fn:concat("Cannot index field type of ", fn:local-name($field)))
    else ()
};

declare function database:database-range-indexes() {
  if($INDEX-CACHE) then $INDEX-CACHE
  else (xdmp:set($INDEX-CACHE,(
    admin:database-get-range-path-indexes(admin:get-configuration(),xdmp:database()),
    admin:database-get-range-element-indexes(admin:get-configuration(),xdmp:database()),
    admin:database-get-range-element-attribute-indexes(admin:get-configuration(),xdmp:database())
  )),$INDEX-CACHE)
};

(:~
 : Removes all possible indexes that may have been created from domains.  
 : Warning: This does not take into account indexes that were added manually or from another process.
~:)
declare function database:unapply-indexes($indexes) {
    let $indexes := $indexes ! database:matching-index(.)
    let $config := admin:get-configuration()
      let $database := xdmp:database()
      let $delete-indexes := 
        fn:fold-left(function($c,$i){
            typeswitch($i)
               case element(db:range-path-index) return admin:database-delete-range-path-index($c,xdmp:database(),$i)
               case element(db:range-element-index) return admin:database-delete-range-element-index($c,xdmp:database(),$i)
               case element(db:range-element-attribute-index) return admin:database-delete-range-element-attribute-index($c,xdmp:database(),$i)
               case element(db:range-field-index) return admin:database-delete-range-field-index($c,xdmp:database(),$i)
               default return ()
            },
        ?,?)
      let $config := $delete-indexes($config,$indexes)
      return 
         (admin:save-configuration-without-restart($config),$config)
    
};

(:~
 : Adds all possible indexes that may have been created from domains, that have not been applied to database already
 :)
declare function database:apply-indexes($indexes) {
  let $indexes := $indexes[fn:not(database:index-exists(.))] 
  let $config := admin:get-configuration()
  let $database := xdmp:database()
  let $add-indexes := 
    fn:fold-left(function($c,$i){
        typeswitch($i)
           case element(db:range-path-index) return admin:database-add-range-path-index($c,xdmp:database(),$i)
           case element(db:range-element-index) return admin:database-add-range-element-index($c,xdmp:database(),$i)
           case element(db:range-element-attribute-index) return admin:database-add-range-element-attribute-index($c,xdmp:database(),$i)
           case element(db:range-field-index) return admin:database-add-range-field-index($c,xdmp:database(),$i)
           default return ()
        },
    ?,?)
  let $config := $add-indexes($config,$indexes)
  return 
     (admin:save-configuration-without-restart($config),$config)
};

(:~
 : Returns the matching index based on a subset of relevant fields required from index structure.  This ensures that 
 : the index matching the database is returned vs a newly created one.
 :)
declare function database:matching-index($index)  {
  typeswitch($index)
   case element(db:range-element-index) return  
     database:database-range-indexes()[self::db:range-element-index][
        ./db:namespace-uri = $index/db:namespace-uri and
        ./db:localname = $index/db:localname and 
        ./db:scalar-type = $index/db:scalar-type
     ]
   case element(db:range-element-attribute-index) return 
     database:database-range-indexes()[self::db:range-element-attribute-index][
        ./db:parent-localname = $index/db:parent-localname and
        ./db:parent-namespace-uri = $index/db:parent-namespace-uri and
        ./db:namespace-uri = $index/db:namespace-uri and
        ./db:localname = $index/db:localname and 
        ./db:scalar-type = $index/db:scalar-type
      ]
   case element(db:range-path-index) return 
     database:database-range-indexes()[self::db:range-path-index][
       ./db:path-expression = $index/db:path-expression and 
       ./db:scalar-type = $index/db:scalar-type
     ]
   default return ()
};
(:~
 : Checks if the index already exists in the configuration.  
 : This function ignores db:range-value-positions and db:invalid-values
 : If you need exact value matching then use matching index function.
 :)
declare function database:index-exists($index) as xs:boolean {
   typeswitch($index)
   case element(db:range-element-index) return  fn:exists(
     database:database-range-indexes()[self::db:range-element-index][
        ./db:namespace-uri = $index/db:namespace-uri and
        ./db:localname = $index/db:localname and 
        ./db:scalar-type = $index/db:scalar-type
     ])
   case element(db:range-element-attribute-index) return fn:exists(
     database:database-range-indexes()[self::db:range-element-attribute-index][
        ./db:parent-localname = $index/db:parent-localname and
        ./db:parent-namespace-uri = $index/db:parent-namespace-uri and
        ./db:namespace-uri = $index/db:namespace-uri and
        ./db:localname = $index/db:localname and 
        ./db:scalar-type = $index/db:scalar-type
      ])
   case element(db:range-path-index) return fn:exists(
     database:database-range-indexes()[self::db:range-path-index][
       ./db:path-expression = $index/db:path-expression and 
       ./db:scalar-type = $index/db:scalar-type
     ])
   default return fn:error(xs:QName("UNHANDLED-INDEX-TYPE"),"Index Type",fn:local-name($index))
};

