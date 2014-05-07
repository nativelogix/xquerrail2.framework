(:
Copyright 2014 MarkLogic Corporation

XQuerrail - blabla
:)

xquery version "1.0-ml";

module namespace cache = "http://xquerrail.com/cache";

declare variable $DEFAULT-CACHE-LOCATION := "database";
declare variable $DEFAULT-CACHE-USER := "anonymous";

declare variable $CACHE-BASE-KEY := "http://xquerrail.com/cache/";
declare variable $DOMAIN-CACHE-KEY := $CACHE-BASE-KEY || "domains/";
declare variable $APP-CACHE-KEY    := $CACHE-BASE-KEY || "applications/";

declare function set-cache($key,$value) {
   
};

declare function get-domain-cache($key) {
   switch($type)
     case "domain" return domain
     default return fn:error(xs:QName("INVALID-CACHE-TYPE"),"Invalid Cache Type", $type)
};

declare function clear-cache($type) {

};