module namespace json="http://marklogic.com/json";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare variable $jsonBits as xs:string* := ();
declare variable $keyObjectStack as xs:string* := ();
declare variable $typeStack as xs:string* := ();

(:
XXX:
    * Sanitize element names
    * Convert wide encoded unicode chars: \uFFFF\uFFFF
:)

declare variable $json:DEBUG as xs:boolean := false();
declare function json:dateTime-to-epoch($date as xs:dateTime)
{
     xs:unsignedLong(
    ($date - xs:dateTime('1970-01-01T00:00:00Z'))
    div xs:dayTimeDuration('PT1S') )
};
declare function json:jsonToXML(
    $json as xs:string
)
{
    let $bits := string-to-codepoints(replace($json, "\n", ""))
    let $set := xdmp:set($jsonBits, for $bit in $bits return codepoints-to-string($bit))

    let $typeBits := json:getType(1)
    let $type := $typeBits[1]
    let $typeEndLocation := $typeBits[2]
    let $location :=
        if($type = ("object", "array", "string", "number","date"))
        then 1
        else $typeEndLocation
    let $xmlString := string-join((json:typeToElement("json", $type), json:dispatch($location), "</json>"), "")
    let $debug := if($json:DEBUG) then xdmp:log($xmlString, "debug") else ()
    return xdmp:unquote($xmlString)
};

declare private function json:dispatch(
    $location as xs:integer
) as xs:string*
{
    let $currentBit := $jsonBits[$location]
    where exists($currentBit)
    return
        if($currentBit eq "{" (:":))
        then json:startObject($location)
        else if($currentBit eq "}")
        then json:endObject($location)
        else if($currentBit eq ":")
        then json:buildObjectValue($location + 1)
        else if($currentBit eq "[")
        then json:startArray($location)
        else if($currentBit eq "]")
        then json:endArray($location)
        else if($currentBit eq "," and $typeStack[last()] eq "object")
        then (json:endObjectKey(), json:startObjectKey($location + 1))
        else if($currentBit eq "," and $typeStack[last()] eq "array")
        then (json:endArrayItem(), json:startArrayItem($location + 1))
        else if($currentBit eq """")
        then json:readCharsUntil($location + 1, """")[2]
        else
            (: XXX - Encode unicode :)
            if($currentBit eq "\")
            then json:dispatch($location + 2)
            else json:dispatch($location + 1)
};


(: Javascript object handling :)

declare private function json:startObject(
    $location as xs:integer
) as xs:string*
{
    let $location := json:readCharsUntilNot($location + 1, " ")
    return
        if($jsonBits[$location] eq "}")
        then (xdmp:set($typeStack, ($typeStack, "emptyobject")), json:endObject($location))
        else (xdmp:set($typeStack, ($typeStack, "object")), json:startObjectKey($location))
};

declare private function json:endObject(
    $location as xs:integer
) as xs:string*
{
    let $isEmpty := $typeStack[last()] eq "emptyobject"
    let $set := xdmp:set($typeStack, $typeStack[1 to last() - 1])
    return
        if($isEmpty)
        then json:dispatch($location + 1)
        else (json:endObjectKey(), json:dispatch($location + 1))
};

declare private function json:startObjectKey(
    $location as xs:integer
) as xs:string*
{
    let $location := json:readCharsUntilNot($location, " ")

    let $valueBits :=
        if($jsonBits[$location] eq """")
        then json:readCharsUntil($location + 1, """")
        else json:readCharsUntil($location, ":")
    let $location :=
        if($jsonBits[$location] eq """")
        then $valueBits[1] + 1
        else $valueBits[1]
    let $keyName := $valueBits[2]

    let $typeBits := json:getType($location + 1)
    let $type := $typeBits[1]
    let $set := xdmp:set($keyObjectStack, ($keyObjectStack, $keyName))
    return (
        json:typeToElement($keyName, $type),
        if($type = ("null", "boolean:true", "boolean:false"))
        then json:dispatch($typeBits[2])
        else json:dispatch($location)
    )
};

declare private function json:endObjectKey(
) as xs:string*
{
    let $latestObjectName := $keyObjectStack[last()]
    let $set := xdmp:set($keyObjectStack, $keyObjectStack[1 to last() - 1])
    return concat("</", $latestObjectName, ">")
};

declare private function json:buildObjectValue(
    $location as xs:integer
) as xs:string*
{
    let $location := json:readCharsUntilNot($location, " ")
    let $currentBit := $jsonBits[$location]
    return
        if($currentBit eq ("[", "{") (:":))
        then json:dispatch($location)
        else
            let $deepValues :=
                if($currentBit eq """")
                then json:readCharsUntil($location + 1, ("""", "}"))
                else json:readCharsUntil($location, (",", "}"))
            let $location :=
                if($currentBit eq """")
                then $deepValues[1] + 1
                else $deepValues[1]
            let $normalizedValue :=
                if($currentBit eq """")
                then $deepValues[2]
                else normalize-space($deepValues[2])
            return ($normalizedValue, json:dispatch($location))
};


(: Javascript array handling :)

declare private function json:startArray(
    $location as xs:integer
) as xs:string*
{
    let $location := json:readCharsUntilNot($location + 1, " ")
    return
        if($jsonBits[$location] eq "]")
        then (xdmp:set($typeStack, ($typeStack, "emptyarray")), json:endArray($location))
        else (xdmp:set($typeStack, ($typeStack, "array")), json:startArrayItem($location))
};

declare private function json:endArray(
    $location as xs:integer
) as xs:string*
{
    let $isEmpty := $typeStack[last()] eq "emptyarray"
    let $set := xdmp:set($typeStack, $typeStack[1 to last() - 1])
    return
        if($isEmpty)
        then json:dispatch($location + 1)
        else (json:endArrayItem(), json:dispatch($location + 1))
};

declare private function json:startArrayItem(
    $location as xs:integer
) as xs:string*
{
    let $location := json:readCharsUntilNot($location, " ")
    let $typeBits := json:getType($location)
    let $type := $typeBits[1]
    let $typeEndLocation := $typeBits[2]
    return (
        json:typeToElement("item", $type),
        if($type = ("null", "boolean:false", "boolean:true"))
        then json:dispatch($typeEndLocation)
        else if($type = ("object", "array"))
        then json:dispatch($location)
        else
            let $valueBits :=
                if($jsonBits[$location] eq """")
                then json:readCharsUntil($location + 1, ("""", "]"))
                else json:readCharsUntil($location, (",", "]"))

            let $location :=
                if($jsonBits[$location] eq """")
                then $valueBits[1] + 1
                else $valueBits[1]
            return ($valueBits[2], json:dispatch($location))
    )
};

declare private function json:endArrayItem(
) as xs:string*
{
    "</item>"
};


(: Helper functions :)

declare private function json:getType(
    $location as xs:integer
)
{
    let $location := json:readCharsUntilNot($location, " ")
    let $currentBit := $jsonBits[$location]
    return
        if($currentBit eq """")
        then "string"
        else if($currentBit eq "[")
        then "array"
        else if($currentBit eq "{" (:":))
        then "object"
        else if(string-join($jsonBits[$location to $location + 3], "") eq "null")
        then ("null", $location + 4)
        else if(string-join($jsonBits[$location to $location + 3], "") eq "true")
        then ("boolean:true", $location + 4)
        else if(string-join($jsonBits[$location to $location + 4], "") eq "false")
        then ("boolean:false", $location + 5)
        else "number"
};

declare private function json:typeToElement(
    $elementName as xs:string,
    $type as xs:string
) as xs:string
{
    if($type eq "null")
    then concat("<", $elementName, " type='null'>")
    else if($type eq "boolean:true")
    then concat("<", $elementName, " boolean='true'>")
    else if($type eq "boolean:false")
    then concat("<", $elementName, " boolean='false'>")
    else concat("<", $elementName, " type='", $type, "'>")
};

declare private function json:readCharsUntil(
    $location as xs:integer,
    $stopChars as xs:string+
)
{
    if($jsonBits[$location] = $stopChars)
    then ($location, "")
    else
        let $newLocation := $location
        let $stringBits :=

            let $continue := true()
            let $lastReadLocation := -1
            for $something in ($location to count($jsonBits))
            where $something > $lastReadLocation and $continue
            return
                let $parts := json:unescapeIfUnicodeChar($something)
                let $set := xdmp:set($lastReadLocation, $parts[1])
                let $currentBit := json:escapeChar($parts[2])
                where $continue
                return
                    if($currentBit = $stopChars and not($parts[3]))
                    then xdmp:set($continue, false())
                    else (
                        $currentBit,
                        xdmp:set($newLocation, $lastReadLocation)
                    )
        return ($newLocation + 1 , string-join($stringBits, ""))
};

declare private function json:readCharsUntilNot(
    $location as xs:integer,
    $ignoreChar as xs:string
) as xs:integer
{
    if($jsonBits[$location] ne $ignoreChar)
    then $location
    else json:readCharsUntilNot($location + 1, $ignoreChar)
};

declare private function json:escapeChar(
    $char as xs:string
) as xs:string
{
    if($char eq "<")
    then "&amp;lt;"
    else if($char eq "&amp;")
    then "&amp;amp;"
    else $char
};

(:
returns the real location to operate off of as the first item in the
sequence, the unescaped char as the second and if it was escaped as the third
:)
declare private function json:unescapeIfUnicodeChar(
    $startingLocation as xs:integer
)
{
    let $unescapedString := ()
    let $escaped := false()
    let $newLocation :=
        if($jsonBits[$startingLocation] eq "\")
        then
            if($jsonBits[$startingLocation + 1] eq "u")
            then
                let $hex := string-join($jsonBits[$startingLocation + 2 to $startingLocation + 5], "")
                let $set := xdmp:set($unescapedString, codepoints-to-string(xdmp:hex-to-integer($hex)))
                return $startingLocation + 5
            else if($jsonBits[$startingLocation + 1] eq "n")
            then
                let $set := xdmp:set($unescapedString, codepoints-to-string(10))
                return $startingLocation + 1
            else
                let $set := xdmp:set($escaped, true())
                let $set := xdmp:set($unescapedString, $jsonBits[$startingLocation + 1])
                return $startingLocation + 1
        else $startingLocation

    let $finalChar := ($unescapedString, $jsonBits[$newLocation])[1]
    return ($newLocation, $finalChar, $escaped)
};




declare function json:xmlToJSON(
    $element as element()
) as xs:string
{
    json:processElement($element)
};

declare private function json:processElement(
    $element as element()
) as xs:string
{
    if($element/@type = "object")
    then json:outputObject($element)
    else if($element/@type = "array")
    then json:outputArray($element)
    else if($element/@type = "null")
    then "null"
    else if(exists($element/@boolean))
    then xs:string($element/@boolean)
    else if($element/@type = "number")
    then xs:string($element)
    else if($element/@type = "date")
    then  
        if($element castable as xs:dateTime) then
            let $date := $element cast as xs:dateTime
            let $tz := fn:timezone-from-dateTime($date)
            let $tm-part := fn:substring(fn:replace(fn:string(xs:time("00:00:00") - $tz),":",""),1,4)
            return
               concat("""\\/Date(",json:dateTime-to-epoch($date),"000+",$tm-part, ")\\/""")
        else """\/Date(0+0000)\/"""
       
    else concat('"', json:escape($element), '"')
};

declare private function json:outputObject(
    $element as element()
) as xs:string
{
    let $keyValues :=
        for $child in $element/*
        return concat('"', local-name($child), '":', json:processElement($child))
    return concat("{", string-join($keyValues, ","), "}")
};

declare private function json:outputArray(
    $element as element()
) as xs:string
{
    let $values :=
        for $child in $element/*
        return json:processElement($child)
    return concat("[", string-join($values, ","), "]")
};

(: Need to backslash escape any double quotes, backslashes, and newlines :)
declare private function json:escape(
    $string as xs:string
) as xs:string
{
    let $string := replace($string, "\\", "\\\\")
    let $string := replace($string, """", "\\""")
    let $string := replace($string, codepoints-to-string((13, 10)), "\\n")
    let $string := replace($string, codepoints-to-string(13), "\\n")
    let $string := replace($string, codepoints-to-string(10), "\\n")
    return $string
};



