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

