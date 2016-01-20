xquery version "1.0-ml";

module namespace timing = "http://xquerrail.com/timing";

declare option xdmp:mapping "false";

declare %private variable $TIMINGS := map:map();
declare %private variable $HISTORY := json:object();

declare function timing:start(
  $key as xs:string
) as xs:duration {
  xdmp:elapsed-time() ! (map:put($TIMINGS, $key, .), .)
};

declare function timing:stop(
  $key as xs:string
) as xs:duration {
  if(map:contains($TIMINGS,$key)) then (
    xdmp:elapsed-time() ! (
      map:put($TIMINGS, $key, . - map:get($TIMINGS, $key)),
      map:put($HISTORY, $key, (map:get($HISTORY, $key), map:get($TIMINGS, $key))),
      map:get($TIMINGS, $key)
    ))
  else
    fn:error(xs:QName("NO-START-TIMER"), "Timer with " || $key || " does not exist", $key)
};

declare function timing:wrap-timer(
  $key as xs:string,
  $func as function(*)
) {
  start($key)[0],
  $func(),
  stop($key)[0]
};

declare function timing:history(
) as json:object {
  $HISTORY
};
