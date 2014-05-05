xquery version "1.0-ml";
(:~
 : Builds a instance of an element based on a domain:model
 : Provides a caching mechanism to optimize speedup of calling builder functions.
 :)
module namespace builder = "http://xquerrail.com/builder";

import module namespace domain  ="http://xquerrail.com/domain"
  at "/_framework/domain.xqy";

import module namespace config = "http://xquerrail.com/config" at
"/_framework/config.xqy";

declare namespace as = "http://www.w3.org/2009/xpath-functions/analyze-string";

(:Options Definition:)
declare option xdmp:mapping "false";
declare option xdmp:output "indent-untyped=yes";

declare variable $COLLATION := "http://marklogic.com/collation/codepoint";
declare variable $SIMPLE-TYPES := 
(
    "string",
);
declare variable $builder-cache := map:map();
declare variable $reference-cache := map:map();
declare variable $binary-dependencies := map:map();
declare variable $current-identity := ();
declare function builder:get-reference-cache($key as xs:string) {
   map:get($reference-cache,$key)
};

declare function builder:set-reference-cache($key as xs:string,$value as item()*) {
  map:put($reference-cache,$key,$value)
};

(:~
 : Returns the current-identity field for use when instance does not have an existing identity
 :)
declare function  builder:get-identity(){
  if(fn:exists($current-identity))
  then $current-identity
  else 
    let $id := builder:generate-uuid()
    return 
       (xdmp:set($current-identity,$id),$id)
 };
 
declare function builder:add-builder(
  $model as element(domain:model)
) {
   let $builder := xdmp:value(builder:build($model))
   return (
        map:put($builder-cache,$model/@name,$builder),
        $builder
   )
};

declare function builder:builder(
  $model as element(domain:model)
) {
   let $current := map:get($builder-cache, $model/@name)
   return
     if(fn:exists($current)) 
     then $current
     else builder:add-builder($model)
};

declare function builder:builder-exists($model) {
   map:contains($builder-cache, $model/@name)
};

declare function builder:build($field as element()) {
    let $namespace := domain:get-field-namespace($field)
    let $occurrence := ($field/@occurrence)
    return
    typeswitch($field)
       case element(domain:model) return 
         fn:string-join(
           ("function($model as element(domain:model), $params as map:map, $current as node()* ) {&#xA;",
           xdmp:quote(element {fn:QName($namespace,$field/@name)} 
           {
             for $n in $field/(domain:attribute|domain:element|domain:container)
             return
                builder:build($n)
           }),
           "&#xA;}")," ")
     case element(domain:attribute) return
       attribute {
         fn:QName($namespace,$field/@name)} {
           "{",
             fn:concat("builder:",fn:string($field/@type),"(", fn:data($field/@name),",$current)"),
           "}"
         }
     case element(domain:element) return (
         " for $c in $current return ",
         " let $value := ",builder:build-value($field),
         " return ",
         switch($field/@type)
           case "reference" return builder:build-reference($field)
           default return 
                 element{fn:QName($namespace,$field/@name)} {
                 "{",
                   (fn:concat("builder:",fn:data($field/@type)), "(" ,$field, ",$params,$current)"),
                 "}"
                }
       )
     case element(domain:container) return element {fn:QName($namespace,$field/@name)} {
       for $n in $field/(domain:element|domain:attribute|domain:container)
       return
         builder:build($n)
     }
     default return () 
 };
 declare function builder:build-value(
   $field
 ) {
    let $id       := domain:get-field-id($field)
    let $name     := fn:data($field/@name)
    let $xpath    := domain:get-field-xpath($field)
    let $type     := $field/@type
    let $default  := $field/@default
    let $nullable := $field/@nullable
    let $default  := 
        if($default) then builder:quote-value($default)
        default return $default
    return
      fn:concat("fn:head( if(map:get($params,'",$name,"')) then map:get($params,'",$name,"') ",
                " else if(map:get($params,'",$id,"')) then map:get($params,'",$id, "')",
                " else if($c",$xpath,") then $c
                " else " if($field/@default) then  else "()"
      )
 };

 
 (:~
: Builds a static reference query for a field
: @param $domain-model the model of the document
: @return the document
 :) 
declare function builder:build-reference(
   $field as element()
) as xs:string {    
    let $domain-model := domain:get-field-reference-model($field)
    let $name         := fn:data($domain-model/@name)
    let $id-field     := domain:get-model-identity-field($domain-model)
    let $key-field    := domain:get-model-key-field($domain-model) 
    let $key-value    := domain:get-field-id($key-field)
    let $namespace    := domain:get-field-namespace($domain-model)
    let $predicate    :=
            if ($domain-model/@persistence = 'document') then
                let $rootNode := fn:data($domain-model/domain:document/@root)
                let $xpath := 
                     if($namespace) 
                     then fn:concat("/*:", $rootNode, "[fn:namespace-uri(.) = '", $namespace, "']/*:", $name, "[fn:namespace-uri(.) = '", $namespace, "']")
                     else fn:concat("/", $rootNode, "/", $name)
                return
                (: Create a constraint :)
                fn:concat('fn:doc("', $domain-model/domain:document/text() , '")', $xpath )
            else 
                fn:concat("/*:",$name, "[fn:namespace-uri(.) = '", $namespace, "']") 
    let $query := 
        typeswitch($field)
            case element(domain:element)   return
               fn:string(<q>cts:element-range-query(fn:QName("{$namespace}","{fn:data($key-field/@name)}"),"=",$value)</q>)
            case element(domain:attribute) return 
                fn:string(<q>cts:element-attribute-range-query(fn:QName("{fn:data($namespace)}","{fn:data($key-field/parent::*/@name)}"),"=",$value)</q>)
            default return 
                fn:error(xs:QName("UNREFERENCABLE-TYPE"),"Type cannot be referenced",$field)
    return 
          xdmp:pretty-print(fn:string(
            <stmt>cts:search({$predicate},{$query}, ("filtered"))
            ! .
            </stmt>))
 };
 
declare function builder:generate(
  $model as element(domain:model),
  $params as map:map,
  $current as element()?
) {
   let $update-function := builder:builder($model)
   return
        $update-function($model,$params,$current)
};

(:~
 : Generates a UUID based on the SHA1 algorithm.
     map:get($params,$field)
 : Wallclock will be used to make the UUIDs sortable.
 : Note when calling function the call will reset the current-identity.  
 :)
declare function builder:generate-uuid($seed as xs:integer?) 
    as xs:string
{
  let $hash := (:Assume FIPS is installed by default:)
     if(fn:starts-with(xdmp:version(),"6"))
     then xdmp:apply(xdmp:function(xs:QName("xdmp:hmac-sha1")),"uuid",fn:string($seed))
     else xdmp:apply(xdmp:function(xs:QName("xdmp:sha1")),fn:string($seed))
  let $guid := fn:replace($hash,"(\c{8})(\c{4})(\c{4})(\c{4})(\c{12})","$1-$2-$3-$4-$5")
  return (xdmp:set($current-identity,$guid),$guid)
};

(:~
 :  Generates a UUID based on randomization function
 :)
declare function builder:generate-uuid() as xs:string
{
    builder:generate-uuid(xdmp:random()) 
};

(:~
 : Creates an identity element based on existing data model
 :)
declare function builder:identity($field,$params,$current) {
     if($current) 
     then fn:data($current)
     else builder:generate-uuid() 
};

(:~
 : Builder for create timestamp type.
 : The create timestamp must a dateTime value as return
 :)
declare function builder:create-timestamp($field,$params,$current) as xs:dateTime {
     if($current) 
     then fn:data($current)
     else  fn:current-dateTime()
};

(:~
 : Builder for create-user type
 :)
declare function builder:create-user($field,$params,$current) as item()? {
     if($current) 
     then fn:data($current)
     else  xdmp:get-current-user()
};

declare function builder:update-timestamp($field,$params,$current) {
  fn:current-dateTime()
};

declare function builder:update-user($field,$params,$current) {
  xdmp:get-current-user()
};

declare function builder:string($field,$params,$current) {
   (map:get($params,$field/@name),$current,fn:data($field/@default))[1] ! . cast as xs:string?
};

declare function builder:integer($field,$params,$current) {
   (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:integer?
};

declare function builder:int($field,$params,$current) {
  (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:integer?
};

declare function builder:long($field,$params,$current) {
 (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:long?
};

declare function builder:double($field,$params,$current) {
 (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:double?
};

declare function builder:decimal($field,$params,$current) {
    (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:decimal?
};

declare function builder:float($field,$params,$current) {
    (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:float?
};

declare function builder:boolean($field,$params,$current) {
(map:get($params,$field/@name),$current,$field/@default)[1][. castable as xs:boolean] ! . cast as xs:boolean?
};

declare function builder:anyURI($field,$params,$current) {
    (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:anyURI?
};

declare function builder:dateTime($field,$params,$current) {
    (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:dateTime?
};

declare function builder:date($field,$params,$current) {
    (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:date?
};

declare function builder:yearMonth($field,$params,$current) {
    (map:get($params,$field/@name),$current,$field/@default)[1][. ne ""] ! . cast as xs:gYearMonth?
};

declare function builder:monthDay($field,$params,$current) {
    (map:get($params,$field/@name),$current[. ne ""],$field/@default)[1][. ne ""] ! . cast as xs:gMonthDay?
};
(:~
 : Resolves references based on selector pattern
 : {application}:{model}:{function}
 : application:model:{function}
 :)
declare function builder:reference($field as element(),$params as map:map,$current as node()?) {
    let $references :=
        for $ref in builder:reference-resolve($field,$params)
        return 
        element reference {
            $ref/@*,
            $ref/node()
        }
    return
      if($references) then $references/(@*|node())
      else if($current) then $current/(@*|node())
      else ()
};
(:~
 :  Resolves the reference type and calls the appropriate reference functions
 :)
declare function builder:reference-resolve($field as element(), $params as map:map) {
    let $refTokens := fn:tokenize(fn:data($field/@reference), ":")
    let $element := element {$refTokens[1]} { $refTokens[1] }
    return 
        typeswitch ($element) 
        case element(model) 
        return  builder:reference-model($field,$params)
        case element(application)
        return builder:reference-application($field,$params)
        default return ()   
};

(:~
 : This function will call the appropriate reference type model to build 
 : a reference between two models types.
 : @param $reference is the reference element that is used to contain the references
 : @param $params the params items to build the relationship
 :)
 declare function builder:reference-model($field as element(), $params as map:map)
 as element()* 
 {
     let $tokens := fn:tokenize($field/@reference,":")
     let $model-name := $tokens[2]
     let $func-name  := $tokens[3]
     let $ref-model  := domain:get-model($model-name)
     let $keyLabel   := $ref-model/@keyLabel
     let $ref-id     := domain:get-model-identity-field($ref-model) 
     let $ref-params := map:map()
     let $_ := (
        map:put($ref-params,"uuid",map:get($params,$field/@name))
     )
     let $ref-value := builder:reference-value($ref-model,$ref-params)
     return
     if($ref-value) then  
        element reference {
          attribute ref-type {"model"},
          attribute ref {$ref-model/@name},
          attribute ref-uuid { $ref-model/(@uuid|*:uuid)[1]/text() },
          attribute ref-id   { fn:data($ref-value/(@*|node())[fn:local-name(.) = $ref-id/@name])},
          fn:data($ref-value/node()[fn:local-name(.) = $keyLabel])
        }
     else ()
 };
(:~
: Retrieves a model document by id
: @param $domain-model the model of the document
: @param $params the values to pull the id from
: @return the document
 :) 
declare function builder:reference-value(
   $domain-model as element(domain:model), 
   $params as map:map
) as element()? {    
    (: Get document identifier from parameters :)
    (: Retrieve document identity and namspace to help build query :)
    let $name := fn:data($domain-model/@name)
    let $id-field   := domain:get-model-identity-field($domain-model)
    let $key-field := domain:get-model-key-field($domain-model) 
    let $key-value := domain:get-field-id($key-field)
    let $nameSpace := domain:get-field-namespace($domain-model)
    let $value := (map:get($params,$key-field/@name),map:get($params,$key-value),map:get($params,$id-field))[1]
    let $cache-key := fn:normalize-space(fn:concat($name ,"::", $value))
    let $cache-value := builder:get-reference-cache($cache-key)
    return 
       if($cache-value) then ($cache-value)
       else        
        let $stmt := 
          fn:normalize-space(fn:string(
          <stmt>cts:search({
                (: Build a query to search within the give document :)
                if ($domain-model/@persistence = 'document') then
                    let $rootNode := fn:data($domain-model/domain:document/@root)
                    (: if namespaces are given use it :)
                    let $xpath := 
                        if($nameSpace) then
                           fn:concat("/*:", $rootNode, "[fn:namespace-uri(.) = '", $nameSpace, "']/*:", $name, "[fn:namespace-uri(.) = '", $nameSpace, "']")
                        else 
                            fn:concat("/", $rootNode, "/", $name)
                    return
                        (: Create a constraint :)
                        fn:concat('fn:doc("', $domain-model/domain:document/text() , '")', $xpath )
                else 
                    (: otherwise for document persistance search against the proper root node :)
                    fn:concat("/*:",$name, "[fn:namespace-uri(.) = '", $nameSpace, "']") 
            },
            cts:or-query((
                if($key-field instance of element(domain:attribute)) 
                then cts:element-attribute-range-query(fn:QName("{$nameSpace}","{$name}"),fn:QName("","{$id-field}"),"=","{$value}","collation={$COLLATION}")
                else cts:element-range-query(fn:QName("{$nameSpace}","{fn:data($key-field/@name)}"),"=","{$value}","collation={$COLLATION}")
            )), ("filtered"))
            </stmt>))
           let $stmt-value := xdmp:value($stmt)
        return (
               builder:set-reference-cache($cache-key,$stmt-value),
               $stmt-value
            )
};
(:~
 :
 :)
declare  function builder:reference-application($field,$params){
   let $reference := fn:data($field/@reference)
   let $ref-tokens := fn:tokenize($reference,":")
   let $ref-parent   := $ref-tokens[1]
   let $ref-type     := $ref-tokens[2]
   let $ref-action   := $ref-tokens[3]
   let $localName := fn:data($field/@name)
   let $ns := ($field/@namespace,$field/ancestor::domain:model/@namespace)[1]
   let $qName := fn:QName($ns,$localName)
   return
      if($ref-parent eq "application" and $ref-type eq "model")
      then 
        let $domains := xdmp:value(fn:concat("domain:model-",$ref-action))
        let $key := domain:get-field-id($field)
        return
            for $value in map:get($params, $key)
            let $domain := $domains[@name = $value] 
            return
                if($domain) then
                     element { $qName } {
                         attribute ref-type { "application" },
                         attribute ref-id { fn:data($domain/@name)},
                         attribute ref { $field/@name },
                         fn:data($domain/@label)
                     }
                else ()
      else if($ref-parent eq "application" and $ref-type eq "class")
      then  xdmp:apply(xdmp:function("model",$ref-action),$ref-type)
      else fn:error(xs:QName("REFERENCE-ERROR"),"Invalid Application Reference",$ref-action)
 };
 
(:~
 : Converts the value of a schema element
 :)
declare function builder:schema-element($field,$params,$current) {
      if(map:get($params,$field/@name)) then map:get($params,$field/@name)
      else if($current) then $current/node()
      else () (:There is no default so return empty:)
};

declare function builder:binary($field,$params,$current) {
    let $model := $field/ancestor-or-self::domain:model
    let $field-id := domain:get-field-id($field)
    let $fileType := ($field/@fileType,"auto")[1]
    let $binary := map:get($params,$field-id)
    let $binary := if($binary) then $binary else map:get($params,fn:data($field/@name))
    let $binaryFile := 
    if(fn:exists($binary)) then 
      if($fileType eq "xml") then
          if ($binary instance of binary ()) then
              xdmp:unquote(xdmp:binary-decode($binary,"utf-8"))
          else
              xdmp:unquote($binary/node()) 
      else if($fileType eq "text") then
          xdmp:binary-decode($binary,"utf-8")
      else $binary
    else ()                    
    let $fileURI := $field/@fileURI
    let $fileURI := 
            if($fileURI and $fileURI ne "")               
            then builder:build-uri($fileURI,$model,$params) 
            else 
              let $binDirectory := $model/domain:binaryDirectory
              let $hasBinDirectory := 
                   if($binDirectory or $fileURI) then () 
                   else fn:error(xs:QName("MODEL-MISSING-BINARY-DIRECTORY"),"Model must configure field/@fileURI or model/binaryDirectory if binary/file fields are present",$field-id)
              return 
                   builder:build-uri($binDirectory,$model,$params) 
    let $filename := 
        if(map:get($params,fn:concat($field-id,"_filename")))
        then map:get($params,fn:concat($field-id,"_filename"))
        else map:get($params,fn:concat($field/@name,"_filename"))
    let $fileContentType := 
         if(map:get($params,fn:concat($field-id,"_content-type")))
         then map:get($params,fn:concat($field-id,"_content-type"))
         else map:get($params,fn:concat($field/@name,"_content-type"))
    let $binary-ref := 
     if(fn:exists($binary)) then (
        element binary {
            attribute type {"binary"},
            attribute content-type {$fileContentType}, 
            attribute filename {$filename},
            attribute filesize {
             if($binaryFile instance of binary())
             then xdmp:binary-size($binaryFile)
             else fn:string-length(xdmp:quote($binaryFile))      
            },
            text {$fileURI}
         },
         if($fileURI ne $current/text()) 
         then  xdmp:document-delete($current/text())
         else  (),
        (:Binary Dependencies will get replaced automatically:)             
         map:put($binary-dependencies,$fileURI,$binaryFile)                        
     )
     else 
         $current
     return
        $binary-ref/(@*|node())
       
};

declare function builder:query($field,$params,$current) {
  (map:get($params,$field/@name),$current[. ne ""],$field/@default)[1] ! . cast as cts:query?
};

declare function builder:point($field,$params,$current) {
 (map:get($params,$field/@name),$current[. ne ""],$field/@default)[1] ! . cast as cts:point
};


(:~
 : Builds an XPath Expression to get field definition from a given model. 
 : Relative to the model parent
 :) 
declare function builder:get-field-path(
   $field as element()
) {
   fn:string-join((
     "$model",
     let $ancestors := $field/ancestor-or-self::*[fn:not(fn:local-name(.) = ("model","domain"))]
     for $a in $ancestors 
     return
        fn:concat("/domain:",fn:local-name($a),"[@name = '", $a/@name , "']")
   ),"")
};  

(:~
 :  Builds a URI with variable placeholders
 :  @param $uri - Uri to format. Variables should be in form $(var-name)
 :  @param $model -  Model to use for reference
 :  @param $instance - Instance of asset can be map or instance of element from domain
 :)
declare function builder:build-uri($uri as xs:string,$model as element(domain:model),$instance as item()) {
  let $token-pattern := "\$\((\i\c*)\)"
  let $patterns := fn:analyze-string($uri,$token-pattern)
  return 
    fn:string-join(
     for $p in $patterns/as:*
     return 
     typeswitch($p)
        case element(as:non-match) return $p
        case element(as:match) return 
            let $field-name := fn:data($p/as:group[@nr=1])
            let $field := $model//(domain:attribute|domain:element)[@name eq $field-name]
            let $data :=
                if($instance instance of map:map) 
                then 
                    let $field-id := domain:get-field-id($field)
                    let $id-value := map:get($instance,$field-id)
                    return
                        if($id-value) 
                        then $id-value
                        else map:get($instance,$field-name)                        
                else                 
                    if($field/@type eq "reference") 
                    then domain:get-field-reference($field,$instance)
                    else domain:get-field-value($field,$instance)
            return 
              if($data) 
              then $data 
              else if($field/@type eq "identity") then builder:get-identity()
              else fn:error(xs:QName("EMPTY-URI-VARIABLE"),"URI Variables must not be empty",$field-name)
        default return ""
    ,"")
};