(:
Copyright 2014 MarkLogic Corporation

XQuerrail - blabla
:)

xquery version "1.0-ml";

(:~
: Javascript Helper library
: Uses simple construct to build objects of json objects
 :)
module  namespace helper = "http://xquerrail.com/helper/javascript";

(:~ Helper functions for json  :)
(:~
: Converts dateTime to epoch date
 :)
declare %private function helper:dateTime-to-epoch($dateTime as xs:dateTime)
{
xs:unsignedLong(
($dateTime - xs:dateTime('1970-01-01T00:00:00'))
div xs:dayTimeDuration('PT1S') )
};

(:~
:  Converts date to epoch date
 :)
declare %private function helper:date-to-epoch($date as xs:date)
{
xs:unsignedLong(
(fn:dateTime($date,xs:time("00:00:00")) - xs:dateTime('1970-01-01T00:00:00'))
div xs:dayTimeDuration('PT1S') )
};

declare function helper:date($date as xs:date) {
helper:literal("new Date(" || helper:date-to-epoch($date) ||")")
};

declare function helper:dateTime($dateTime as xs:dateTime) {
helper:literal("new Date(" || helper:dateTime-to-epoch($dateTime) || ")")
};
declare function helper:literal($value as item()) {
json:unquotedString($value)
}; 
(:~
: Function automatically generates json string
 :)
declare function helper:json($value as item()) {
if($value instance of json:object or $value instance of json:array)
then xdmp:to-json($value)
else xdmp:to-json(helper:entry("value",$value))
};

(:~
: Builds a json object
 :)
declare function helper:object($values as item()*) {
let $obj := json:object()
return (
for $value in $values 
return 
if($value instance of json:object or $value instance of json:array)
then xdmp:set($obj,$obj + $value)
else fn:error(xs:QName("NON-JSON-TYPE"),"The type you provided is not json"),
$obj
)
};
(:~
: Builds an array
 :)
declare function helper:array($values as item()*) {
    let $array := json:array()
    return (
        for $value in $values 
        return
        json:array-push($array,$value),
        $array
    )
};
(:~
: A entry represents a key value structure
 :)
declare function helper:entry($key as xs:string,$value as item()*) {
    let $entry  := json:object()
    return (
    map:put($entry,$key,$value),
    $entry
    )
};
declare function helper:keyvalue($key as xs:string,$value as xs:anyAtomicType) {
    helper:entry($key,$value)
};
declare function helper:variable($key as xs:string,$json as item()*) {
   if($json instance of json:object or $json instance of json:array) 
   then fn:concat("var ", $key, " = ", xdmp:to-json($json),";")
   else fn:error(xs:QName("JSON-VARIABLE-TYPE"),"JSON Variable must be of type json:object or json:array")
};
(:~
: Short Hand Notation for helper:entry
 :)
declare function helper:e($key,$value) {helper:entry($key,$value)};
(:~
: Short Hand Notation for helper:keyvalue
 :)
declare function helper:kv($key,$value)  {helper:keyvalue($key,$value)};
(:~
: Short Hand Notation for helper:object
 :)
declare function helper:o($values) {helper:object($values)};
(:~
: Short Hand Notation for helper:json
 :)
declare function helper:j($json) {helper:json($json)};
(:~
: Short Hand Notation for helper:array
 :)
declare function helper:a($values) {helper:array($values)};
(:~
: Short hand notation for helper:literal
 :)
declare function helper:l($value) {helper:literal($value)};
(:~
: Short hand notation for helper:datTime
 :)
declare function helper:dtm($value as xs:dateTime)  {helper:dateTime($value)};
(:~
: Short hand notation for helper:date
 :)
declare function helper:dt($value as xs:date) {helper:date($value)};


