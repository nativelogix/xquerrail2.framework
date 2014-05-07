(:
Copyright 2014 MarkLogic Corporation

XQuerrail - blabla
:)

xquery version "1.0-ml";
(:~
  Xml to JSON Serializer/Deserializer that used to use marklogic Builtins and map:map 
  Options : 
      type = ("array", "boolean", "long", "decimal", "xhtml")
      
  TODO: Schema inference on types?
        ElementName fixing for javascript based on some feature I don't remember
        Namespace support using . notation
        ie. dc.identifier dc="http://purl.org/dc/elements/1.1"
            <some.element xmlns="urn:some"/>  translates to : "some.some_x25_element" : ""
 :)
module namespace json = "http://xquerrail.com/helper/json";

declare namespace js = "http://marklogic.com/xdmp/json";
declare namespace jsonx = "http://www.ibm.com/xmlns/prod/2009/jsonx";

declare option xdmp:mapping "false";

(:module namespace json = "http://marklogic.com/mwt/json";:)

(:We should keep a global map of all namespaces:)
declare variable $NAMESPACE-MAP := js:object();
declare variable $SERIALIZE-OPTIONS := (
	 "serialize-attributes", (:Determines if attributes are serialized:)
	 "serialize-processing-instructions", (:Determines if processing-instructions are serialized:)
	 "infer-numbers", (:Determines whether numbers are infered automatically:)
	 "infer-arrays", (:Determines whether arrays are infered automatically:)
	 "use-date-constructor", (:Determines if a date constructor is used:)
	 "empty-as-null", (:Determines if empty &lt;node/&gt; is mapped to null value:)
	 "xson" (:Serializes Xml as XSON:)
	)	
;
declare variable $DEFAULT-OPTIONS := (
    "use-date-constructor",
    "empty-as-null",
    "serialize-attributes",
    "infer-numbers",
    "attributes-as-elements"
);
declare variable $DESERIALIZE-OPTIONS :=
 (
     "format-jsonx",
     "format-xml"
 );
declare variable $DATE-REGEX := "/Date\((\d*)\)/";

(:Some stolen functions from CQ:)
(:~ get the epoch seconds  :)
declare function json:get-epoch-seconds($dt as xs:dateTime)
  as xs:unsignedLong
{
  xs:unsignedLong(
    ($dt - xs:dateTime('1970-01-01T00:00:00Z'))
    div xs:dayTimeDuration('PT1S') )
};

(:~ get the epoch seconds  :)
declare function json:get-epoch-seconds()
  as xs:unsignedLong
{
  json:get-epoch-seconds(fn:current-dateTime())
};

(:~ convert epoch seconds to dateTime  :)
declare function json:epoch-seconds-to-dateTime($v)
  as xs:dateTime
{
  xs:dateTime("1970-01-01T00:00:00-00:00")
  + xs:dayTimeDuration(fn:concat("PT", $v, "S"))
};

declare function json:duration-to-microseconds($d as xs:dayTimeDuration)
 as xs:unsignedLong {
   xs:unsignedLong( $d div xs:dayTimeDuration('PT0.000001S') )
};


(:Main JSON methods:)
(:~
 : Parses Xml Structure and generates JSON object
 : @param $node - Element or Document to convert to JSON
 : @param $options - Serialization Options
 : @return JSON 
 :)
declare function json:serialize($node as node(),$options as xs:string*) {
     if($options = "xson") then
      json:build-xson($node,$options)
     else
      json:build-json($node,js:object(), $options)
};
(:~
 : Parses Xml Structure and generates JSON object
 : @param $node - Element or Document to convert to JSON
 : @return JSON 
 :)
declare function json:serialize($node as node()) as xs:string {
	json:serialize($node,())
};

(:~
 :  Deserializes a json string to xml
 :  @param $json - JSON string
 :  @return an sequence
 :)
declare function json:deserialize($json as xs:string)
{
   json:deserialize($json,())
};
(:~
 :  Deserializes a json string to xml
 :  @param $json - JSON string
 :  @return an xml sequence
 :)
declare function json:deserialize($json as xs:string, $options as xs:string*) 
{
   let $json-fix := 
   	fn:replace(fn:replace($json,"(:\s?)null",'$1"__null__"')
   	,"\[\]",'"__empty-array__"')
   let $json-map := xdmp:from-json($json-fix)
   return 
       json:build-jsonx($json-map,$options)

};


declare function json:build-jsonx($map as map:map, $options as xs:string*)
{
  for $item in document{$map}/map:map/map:entry
  return
  if(fn:count($item/map:value/*) eq 1) then
     json:parse-value($item/@key, $item/map:value,$options)
  else 
  for $value in $item/map:value
  return
    json:parse-value($item/@key, $value,$options)
};

declare function json:parse-value(
$name as xs:string, 
$value as element(map:value),
$options as xs:string*){
 if($value/@xsi:type eq xs:QName("map:map")) then
           <jsonx:object name="{$name}">{json:build-jsonx(map:map($value/map:map),$options)}</jsonx:object>
      else if($value/@xsi:type eq xs:QName("xs:string")) then 
       	   json:parse-string($name,$value,$options)
      else if($value/@xsi:type = (xs:QName("xs:integer"),xs:QName("xs:long"),xs:QName("xs:decimal"),xs:QName("xs:float"))) then 
          <jsonx:number name="{$name}">{$value/text()}</jsonx:number>
      else if($value/@xsi:type eq xs:QName("xs:boolean")) then
       	   <jsonx:boolean name="{$name}">{xs:boolean($value)}</jsonx:boolean>
      else fn:error(xs:QName("UNHANDLED-CONDITION"),xdmp:describe($name))

};
declare function json:parse-string($name as xs:string,$value as xs:string,$options as xs:string*) as element()?
{
    if(fn:matches($value,$DATE-REGEX)) then
    	<jsonx:date name="{$name}">{
    	json:epoch-seconds-to-dateTime(xs:decimal(fn:replace($value,$DATE-REGEX,"$1")))
    	}</jsonx:date>
    else if(fn:matches($value,"__null__")) then
    	<jsonx:null name="{$name}"/>
    else if(fn:matches($value,"__empty-array__")) then
    	<jsonx:object name="{$name}">{()}</jsonx:object>
    else 
       <jsonx:string name="{$name}">{$value}</jsonx:string>
 
};
(:~
   Recursive map builder for JSON

   @param $nodes - List of nodes to serialize
   @param $parent - parent map:entry used to build map
   @param $options - list of options used during serialization process
   @return map:map of converted xml
 :)
declare function json:build-json($nodes as node()*, $parent as map:map,$options as xs:string*) as map:map {
let $_process  := 
   for $node in $nodes
   return
    typeswitch($node)
      case document-node() return
        json:build-json($node/node(),$parent,$options)
      case processing-instruction() return
        if($options = "serialize-pi") then
	        json:put($parent,fn:concat("@pi:",fn:local-name($node)),fn:data($node))
        else 
           ()
      case element() return
         let $ns_map    := js:object()
         let $child_map := js:object()
         let $attr_map  := js:object()
         let $array_map := js:object()
	 let $attributes := 
	    if($options = "serialize-attributes") then 
		    for $attr in $node/@*[fn:local-name(.) ne ("type")]
		    return 
		    	if($options = "attributes-as-elements") then
		    	   json:put($attr_map,fn:local-name($attr),json:serialize-value($attr,$options))
		    	else 
		    	   json:put($child_map,fn:local-name($attr),json:serialize-value($attr,$options))
	    else ()
	    
         return
                (	(:Add Attributes if required:)
		 	if(map:count($attr_map) gt 0) then
		 	    json:put($child_map,"_attributes_",$attributes)
		 	else (),
		 	if($node/element()) then
		 	    let $child-match := every $c in $node/element() satisfies fn:local-name($c) eq fn:local-name($node/element()[1])
		 	    return
		 	    (: If the element is xhtml treat as string and quote:)
		       	    if($node/@type eq "xhtml" or fn:namespace-uri($node) eq "http://w3.org/1999/xhtml") then
		       	        json:put($parent,fn:local-name($node),xdmp:quote($node/node()))
		       	    (: Handle Array Types:)
		       	    else if($node/@type eq "array" and $child-match) then
		       	    	 let $children := 
		       	    	    for $a in $node/element()
		       	    	    return  json:build-json($a,$array_map,$options)
	                    	 return
	                    	   json:put($parent,fn:local-name($node),$children)                    	 
	                    else 
                       	     json:put($parent,fn:local-name($node),json:build-json($node/element(),$child_map,$options))     
		        else
		        	if($node/@type eq "array") then (:Hack to create empty array:)
	                      	     json:put($parent, fn:local-name($node), js:array()) 
	                        else 
	        		     json:put($parent,fn:local-name($node),json:serialize-value($node,$options))
        	)
      (:Some Unaccounted error in logic:)
      default return fn:error(xs:QName("UNMAPPED-TYPE"),xdmp:node-kind($node),())
   return 
     $parent
};
declare function json:get-scoped-namespaces($node as element()*,$map as element(map:map))
{
  ()
};
(:~
   Recursive map builder for XSON(JSONXML)

   @param $nodes - List of nodes to serialize
   @param $parent - parent map:entry used to build map
   @param $options - list of options used during serialization process
   @return map:map of converted xml
 :)
declare function json:build-xson($nodes as node()*, $options as xs:string*) {
let $_process  := 
   for $node in $nodes
   return
    typeswitch($node)
      case document-node() return
        json:build-xson($node/node(),$options)
      case processing-instruction() return
        if($options = "serialize-pi") then
	       json:serialize-item(fn:concat("@pi:",fn:local-name($node)),fn:data($node))
        else 
           ()
      case element() return
         let $ns_map    := js:object()
         let $child_map := js:object()
         let $attr_map  := js:object()
         let $array_map := js:object()
         let $namespaces      :=   
                if(fn:not($node/ancestor::element())) then
	         	for $prefix in (fn:in-scope-prefixes($node),$node/@xmlns:*)
	         	let $prefix-ns := fn:namespace-uri-for-prefix($prefix,$node)
	         	let $ns-name   := 
	         		if($prefix eq "") 
	         		then "xmlns" else fn:concat("xmlns$",$prefix)
			where $prefix ne "xml"
	         	return json:serialize-item($ns-name,$prefix-ns)    	
                else ()
	 let $attributes := 
		    for $attr in $node/@*
		    return 
        		json:serialize-item(fn:local-name($attr),json:serialize-value($attr,$options))
	    
         return
                (       $namespaces,
                	$attributes,
                        (:if the node has child elements then :)
                   	if($node/element()) then
		 	    let $child-match := every $c in $node/element() satisfies fn:local-name($c) eq fn:local-name($node/element()[1])
		 	    return
		 	    (: If the element is xhtml treat as string and quote:)
		       	    if($node/@type eq "xhtml" or fn:namespace-uri($node) eq "http://w3.org/1999/xhtml") then
		       	        json:serialize-item(fn:local-name($node),xdmp:quote($node/node()))
		       	    (: Handle Array Types:)
		       	    else if($node/@type eq "array" or $child-match) then
		       	    	 let $children := 
		       	    	    for $a in $node/element()
		       	    	    return  json:build-xson($a,$options)
	                    	 return 
	                    	  $children          	 
	                    else 
                       	     json:serialize-item(fn:local-name($node),json:build-xson($node/element(),$options))     
		        else    (: An Empty Array will report like a regular node since we dont do schema serializer would have no clue. :)
		        	if($node/@type eq "array") then (:Hack to create empty array:)
	                      	     json:serialize-item(fn:local-name($node), "__empty-array__") 
	                        else 
	        		     json:serialize-item(fn:local-name($node),json:serialize-value($node,$options))
        	)
      (:Some Unaccounted error in logic:)
      default return fn:error(xs:QName("UNMAPPED-TYPE"),xdmp:node-kind($node),())
   return 
     $_process
};

declare function json:serialize-item($name as xs:string,$value) {
  let $map := js:object()
  let $val := json:put($map,$name,$value)
  return
    xdmp:to-json($map)
};
(:~
  Resolves a value using options and various checks
 :)
declare private function json:serialize-value($elem as node(), $options as xs:string*)
{
  let $value-map := js:object()
  let $value := 
  	if(fn:not(fn:exists($elem/node())) and $options = "empty-as-null") then
	    if($elem instance of attribute()) then fn:data($elem) else ()
	else if($elem castable as xs:dateTime) then
	    if($options = "use-date-constructor") then
	    	fn:concat("/Date(", json:get-epoch-seconds(xs:dateTime($elem)) , ")/")
	    else 
	    	fn:string($elem)
	else if($elem castable as xs:date) then
 	    if($options = "use-date-constructor") then
	    	fn:concat("/Date(", 
	    		json:get-epoch-seconds(fn:dateTime($elem,xs:time("00:00:00"))) , 
	    	")/")
	    else 
	    	fn:string($elem)
	else if($elem/@type="boolean" or $elem = ("true","false")) then
		xs:boolean($elem)	
	else if($elem/@type eq "long" or $elem castable as xs:long or 
		$elem/@type eq "integer" or $elem castable as xs:integer) then
		xs:long($elem)
	else if($elem/@type eq "decimal" or $elem castable as  xs:decimal) then 
		xs:decimal($elem)	
	else if($options = "infer-numbers" and $elem castable as xs:decimal) then 
		xs:decimal($elem)	 	
	else if($options = "infer-numbers" and $elem castable as xs:long) then
		xs:long($elem)	
	else fn:string($elem)
    return 
       if($options = "xson") then 
          (json:put($value-map,"$t",$value),$value-map)
       else 
          fn:data($value)
};
(:~
   Checks if a map contains a key and appends items as a sequence or creates a new map:entry
 :)
declare private function json:put($map as map:map,$key as xs:string,$value as item()*) {
 let $item := map:get($map,$key)
 let $_    := 
   if($key eq "") then 
     ()
   else
     if(fn:not(fn:empty($item))) then
     	map:put($map,$key,($item,$value))
     else 
     	map:put($map,$key,$value)
 return $map
};

declare function json:to-json($node as item()) {
 
 json:to-json($node,$DEFAULT-OPTIONS)
};

declare function json:to-json($node, $options) {
   xdmp:to-json(json:serialize($node,$options))
};


