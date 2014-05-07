xquery version "1.0-ml";

(:~
 : Utility library for building parameter maps
 :)
module namespace params = "http://xquerrail.com/params";

declare variable $PARAMS as map:map := map:map();

(:~
 : Sets the params based on an existing map:map
 : @param $param  - map:map to load into param context
 :)
declare function load($params as map:map) {
   xdmp:set($PARAMS,$params)
};

declare function params() {
  $PARAMS
};
(:~
 : Creates a single value key map
 :)
declare function param($key as xs:string,$value as item()*)
{
   let $map := map:map()
   return (
      map:put($map,$key,$value),
      $map
   )
};

(:~
   Joins all the parameter maps together
 :)
declare function new($values as map:map*)
{
   let $output := map:map()
   let $x := 
       for $v in $values
       for $k in map:keys($v)
       return map:put($output,$k,map:get($v,$k))
   return ($output,xdmp:set($PARAMS,$output))
};

declare function get($key as xs:string) {
    map:get($PARAMS,$key)
};

declare function delete($key as xs:string) {
  map:delete($PARAMS,$key)
};

declare function put($key as xs:string,$value as item()*) {
   map:put($PARAMS,$key,$value)      
};
declare function push($key as xs:string,$value as item()*) {
   map:put($PARAMS,$key,
     (map:get($PARAMS,$key),$value))
};
declare function pop($key as xs:string,$count) {
   let $values := map:get($PARAMS,$key)
   let $pop := ()
   return
      ()
};
declare function clear() {
   map:clear($PARAMS)
};