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

module namespace generator  = "http://xquerrail.com/generator";

declare variable $xquery-extension := "(xqy|xq|xquery|xqm)$";
(:~
 : Recursively processes a filesystem path and returns all files matching the criteria specified
 :)
declare function generator:recurse-fs(
  $path as xs:string,
  $filter as xs:string
) {
  generator:recurse-fs($path,$filter,"zzzzz") 
};

(:~
 : Recursively processes a filesystem path and returns all files matching the criteria specified
 :)
declare function generator:recurse-fs(
 $path as xs:string,
 $filter as xs:string,
 $exclude as xs:string
) {
 let $entries := xdmp:filesystem-directory($path)
 return
    for $entry in $entries/dir:entry[(fn:matches(dir:filename,$filter) and fn:not(fn:matches(dir:pathname,$exclude))) or dir:type = "directory"]
    return
      switch($entry/dir:type)
        case "file" return <file name="{$entry/dir:filename}" path="{$entry/dir:pathname}"/>
        case "directory" return generator:recurse-fs($entry/dir:pathname,$filter,$exclude)
        default return ()
};

(:~
 : Gets a list of filesystem resources
 :)
declare function generator:get-filesystem-modules(
  $path as xs:string,
  $filter as xs:string*,
  $excludes as xs:string
) {
  generator:recurse-fs($path,$filter,$excludes)  
};

declare function generator:get-database-modules(
  $base-path as xs:string
) {
  cts:uris() ! <file name="{fn:tokenize(.,"/")[fn:last()]}" path="{.}"/>
};

(:~
 : Get a list of all the modules located in a directory 
~:)
declare function genenerator:get-modules(
  $base-path as xs:string
) {
  if(xdmp:modules-database() = 0)
  then generator:get-filesystem-modules(xdmp:modules-root() || $base-path)
  else generator:get-modules-modules(xdmp:modules-root() || $base-path)
};

(:~
 : Extracts the definition of an configured xquery-extension
~:)
declare function generator:get-module-definition(
 $module-namespace  as xs:string,
 $module-location as xs:string
) {
   let $ext-ns := $extension/@namespace 
   let $functions := xdmp:eval(
    fn:concat("import module namespace __1 = '", $module-namespace, "' at '", $module-location, "'; "
   ,"xdmp:functions()[fn:namespace-uri-from-QName(fn:function-name(.))= '", $ext-ns , "'] "))
   let $functions := 
     for $function in $functions
     let $arity := fn:function-arity($function)
     let $function-name := fn:function-name($function)
     return  
       <function xmlns="http://xquerrail.com/extension" name="{fn:local-name-from-QName($function-name)}">
          <return>{xdmp:function-return-type($function)}</return>
          {
            for $anntype in $annotations 
            let $annotation := xdmp:annotation($function,$anntype)
            return  
              if($annotation) 
              then <implements name="{fn:local-name-from-QName($anntype)}">{$annotation}</implements>
              else ()
          }
          <parameters>
          {for $pos in (1 to $arity)
           let $name := xdmp:function-parameter-name($function,$pos)
           let $type := xdmp:function-parameter-type($function,$pos)
           return  
              <parameter name="{$name}" type="{$type}"/>
          }
          </parameters>
       </function>
    return
      <library name="{$module-name}" location="{$module-location}">
        {$extension/@*,$functions}
      </library>
};
