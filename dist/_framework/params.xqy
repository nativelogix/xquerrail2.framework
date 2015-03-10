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