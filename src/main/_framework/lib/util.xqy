xquery version "1.0-ml";
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