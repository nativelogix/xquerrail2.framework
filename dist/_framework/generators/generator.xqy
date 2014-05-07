(:
Copyright 2014 MarkLogic Corporation

XQuerrail - blabla
:)

xquery version "1.0-ml";

module namespace generator = "http://xquerrail.com/generator";

import module namespace config = "http://xquerrail.com/config" at "../config.xqy";
        
declare variable $ANNOTATIONS := (
    xs:QName("generator:name"),
    xs:QName("generator:implements"),
    xs:QName("generator:directive"),
    xs:QName("generator:apply"),
    xs:QName("generator:dependencies"),
    xs:QName("generator:formats")
);
(:~
 : Defines the type of 
~:)
declare variable $GENERATOR-TYPES := (
    "EL",(:Element:)
    "AT" (:Attribute:),
    "PI" (:Processing-Instruction:),
    "PP" (:PI with _PI closing:)
    "CM" (:Comment:)
);

declare variable $GENERATOR-MAP := map:map();

(:~
 : Defines the allowed targets of the generator output
~:)
declare function $GENERATOR-FORMATS := (
    "xml",
    "text",
    "binary"
);
(:~
 : Initializes the generator with any specific directives
~:)
declare function generator:initialize(){
  ()
};

(:~
 : Generates the template output.
~:)
declare function generator:generate(
    $generator-name as xs:string,
    $template as item()*,
    $values as map:map
) as item()*{
 
};

