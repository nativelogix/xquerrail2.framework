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
 : Utilities library
~:)
module namespace util = "http://xquerrail.com/util";

(:~
 : Internal function to return a string representation
 : of an integer that contains two digits. If the number
 : has less than two digits it is padded with zeros. If
 : it has more than two digits, it is truncated, and the
 : least significant digits are returned.
 :
 : @param $num the number to convert
 :
 : @return the two digit string
 :
 :)
declare function util:two-digits(
  $num as xs:integer
) as xs:string {
  let $result := fn:string($num)
  let $length := fn:string-length($result)
  return if($length > 2) then fn:substring($result, $length - 1)
    else if($length = 1) then fn:concat("0", $result)
    else if($length = 0) then "00" else $result
};

declare function util:total-seconds-from-duration(
  $duration as xs:dayTimeDuration?
)  as xs:decimal? {
  $duration div xs:dayTimeDuration('PT1S')
};