xquery version "1.0-ml";
(:~
 : Model model Application framework model functions
 :)
module namespace model = "http://xquerrail.com/helper/model";

import module namespace js = "http://xquerrail.com/helper/javascript" at "/_framework/helpers/javascript-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/_framework/domain.xqy";
import module namespace config = "http://xquerrail.com/config" at "/_framework/config.xqy";

declare option xdmp:mapping "false";

declare variable $NL as xs:string := 
    if(xdmp:platform() eq "winnt") 
    then fn:codepoints-to-string((13,10))
    else "&#xA;"
;    
(:~
 :  Does an update by iterating the element structure and looking for named element 
 :  by local-name and updating it with a new value
 :)
declare function model:update-partial($current as element(), $update as map:map)
{  
   let $cur-map := $update
   let $name-keys :=  map:keys($update)
   let $update-nodes  := 
      for $node in $current/element()
      let $lname     := fn:local-name($node)
      let $nname     := fn:node-name($node)
      let $positions := (fn:index-of($name-keys,$lname), fn:index-of($name-keys,$nname))[1]
      let $match-key := 
        if($positions) then
          $name-keys[$positions]
        else
          ()
      return
        if($match-key) then
            (
             element {fn:node-name($node)}
             {
              let $value := map:get($update,$match-key)
              return 
              if($value instance of node()) then
                 $value/node()
              else 
                $value
             },
             map:delete($cur-map,$match-key)
            )
        else $node
   return
        element {fn:node-name($current)}
        {
          $current/@*,
          $update-nodes
        }
};

declare function model:eval-document-insert(
  $uri as xs:string,
  $root as node()
)
{
   let $stmt := 
   '
    declare variable $uri as xs:string external;
    declare variable $root as node() external;
    xdmp:document-insert($uri,$root)
   '
   return
     xdmp:eval($stmt,
      (
       xs:QName("uri"),$uri,
       xs:QName("root"),$root
      )
      ,
      <options xmlns="xdmp:eval">
         <isolation>different-transaction</isolation>
         <prevent-deadlocks>false</prevent-deadlocks>
      </options>
      )
};

declare function model:eval-document-insert(
  $uri as xs:string,
  $root as node(),
  $permissions as element(sec:permission)+
)
{
  let $stmt := 
   '
    declare variable $uri as xs:string external;
    declare variable $root as node() external;
    declare variable $permissions as element(sec:permission)+ external;

    xdmp:document-insert($uri,$root,$permissions)
   '
   return
     xdmp:eval($stmt,
      (
       xs:QName("uri"),$uri,
       xs:QName("root"),$root,
       xs:QName("permissions"),$permissions
      )
      ,
      <options xmlns="xdmp:eval">
         <isolation>different-transaction</isolation>
         <prevent-deadlocks>false</prevent-deadlocks>
      </options>
      )
};

declare function model:eval-document-insert(
  $uri as xs:string,
  $root as node(),
  $permissions as element(sec:permission)+,
  $collections as xs:string+
)
{
  let $stmt := 
   '
    declare variable $uri as xs:string external;
    declare variable $root as node() external;
    declare variable $permissions as element(sec:permission)+ external;
    declare variable $collections as xs:string+ external;
    xdmp:document-insert($uri,$root,$permissions,$collections)
   '
   return
     xdmp:eval($stmt,
      (
       xs:QName("uri"),$uri,
       xs:QName("root"),$root,
       xs:QName("permissions"),$permissions,
       xs:QName("collections"),$collections
      )
      ,
      <options xmlns="xdmp:eval">
         <isolation>different-transaction</isolation>
         <prevent-deadlocks>false</prevent-deadlocks>
      </options>
      )
};

declare function model:eval-document-insert(
  $uri as xs:string,
  $root as node(),
  $permissions as element(sec:permission)+,
  $collections as xs:string+,
  $quality as xs:int?
)
{
  let $stmt := 
   '
    declare variable $uri as xs:string external;
    declare variable $root as node() external;
    declare variable $permissions as element(sec:permission)* external;
    declare variable $collections as xs:string* external;
    declare variable $quality as xs:int? external;
    xdmp:document-insert($uri,$root,$permissions,$collections,$quality)
   '
   return
     xdmp:eval($stmt,
      (
       xs:QName("uri"),$uri,
       xs:QName("root"),$root,
       xs:QName("permissions"),$permissions,
       xs:QName("collections"),$collections,
       xs:QName("quality"),$quality
      )
      ,
      <options xmlns="xdmp:eval">
         <isolation>different-transaction</isolation>
         <prevent-deadlocks>false</prevent-deadlocks>
      </options>
      )
};

declare function model:eval-document-insert(
  $uri as xs:string,
  $root as node(),
  $permissions as element(sec:permission)*,
  $collections as xs:string*,
  $quality as xs:int?,
  $forest-ids as xs:unsignedLong*
)
{
   let $stmt := 
   '
    declare variable $uri as xs:string external;
    declare variable $root as node() external;
    declare variable $permissions as element(sec:permission)* external;
    declare variable $collections as xs:string external;
    declare variable $quality as xs:int? external;
    declare variable $forest-ids as xs:unsignedLong external;
    (:Parse forest-ids and $collections:)
    xdmp:document-insert($uri,$root,$permissions,$collections,$quality,$forest-ids)
   '
   return
     xdmp:eval($stmt,
      (
       xs:QName("uri"),$uri,
       xs:QName("root"),$root,
       xs:QName("permissions"),$permissions,
       xs:QName("collections"),$collections,
       xs:QName("quality"),$quality,
       xs:QName("forest-ids"),$forest-ids
      )
      ,
      <options xmlns="xdmp:eval">
         <isolation>different-transaction</isolation>
         <prevent-deadlocks>false</prevent-deadlocks>
      </options>
      )
}; 

(:
   Eval insert over xdmp:node-insert-child
:)
declare function model:eval-node-insert-child(
  $parent as node(),
  $new as node()
)
{
  let $stmt := 
  '  declare variable $parent as node() external;
     declare variable $new as node() external;
     xdmp:node-insert-child($parent,$new)
  ' 
  return
    xdmp:eval($stmt,
    (
        xs:QName("parent"),$parent,
        xs:QName("new"),$new
    ),
      <options xmlns="xdmp:eval">
         <isolation>different-transaction</isolation>
         <prevent-deadlocks>false</prevent-deadlocks>
      </options>
    )
};

declare function model:build-json( 
   $field as element() ,
   $instance as element() )
{
  model:build-json($field,$instance,fn:true())
};

declare function model:build-json(
  $field as element(),
  $instance as element(),
  $include-root as xs:boolean
){
   typeswitch($field)
     case element(domain:model) return 
       js:o((
         for $f in $field/(domain:container|domain:attribute|domain:element)
         return model:build-json($f,$instance,$include-root)
       ))
     case element(domain:element) return
        let $field-value := domain:get-field-value($field,$instance)
        return  (
            for $field in $field/(domain:attribute) return model:build-json($field,$instance,$include-root),
           if($field/@reference and $field/@type eq "reference") then
                let $value := domain:get-field-value($field,$instance)
                return 
                  if(fn:not($value)) then js:kv($field/@name,())
                  else 
                   js:kv($field/@name,js:o((
                        js:kv("reference",fn:true()),
                        js:kv("text", fn:string($field-value)),
                        js:kv("id", $field-value/@ref-id),
                        js:kv("type",fn:data($field-value/@ref))
                    )))
            else if($field/@type eq "binary") then 
               let $value := domain:get-field-value($field,$instance)
               return 
                   if($value) then 
                       js:kv($field/@name,(
                           js:kv("uri", fn:string($field-value)),
                           js:kv("filename", fn:data($field-value/@filename)),
                           js:kv("contentType",fn:data($field-value/@content-type))
                       )) 
                   else js:kv($field/@name,"")       
               else if($field/@type eq "identity") then 
                   js:kv($field/@name,fn:string($field-value))
               else if($field/@type eq "schema-element") 
                    then js:kv($field/@name,$field-value/node() ! xdmp:quote(.))
               else if(domain:model-exists($field/@type)) then
                 if($field/@occurrence = ("*","+")) then
                    js:kv($field/@name,js:a(
                       for $v in $field-value
                       return js:o((
                             domain:get-model($field/@type) ! model:build-json(.,$v)
                       ))
                    ))
                 else js:kv($field/@name,
                       for $v in $field-value
                       return js:o((
                             domain:get-model($field/@type) ! model:build-json(.,$v)
                       ))
                    )
         
               else 
                    if($field/@occurrence = ("*","+")) 
                    then js:kv($field/@name, js:a($field-value ! fn:data(.)[. ne ""]))
                    else 
                        if($field/@type = "string")
                        then js:kv($field/@name,($field-value)[1])
                        else js:kv($field/@name, ($field-value,"")[1])
      )
     case element(domain:attribute) return
         let $field-value := domain:get-field-value($field,$instance)
         return        
             js:kv(fn:concat(config:attribute-prefix(),$field/@name),$field-value)
     case element(domain:container) return 
         js:kv($field/@name, js:o(
            for $field in $field/(domain:element|domain:container|domain:attribute)
            return model:build-json($field,$instance)
          ))
     default return ()
};

declare function model:to-json(
  $model as element(domain:model),
  $instance as element()
 ) {
   if($model/@name eq fn:local-name($instance)) 
   then model:build-json($model,$instance)
   else fn:error(xs:QName("MODEL-INSTANCE-MISMATCH"),
      fn:string(
        <msg>{$instance/fn:local-name(.)} does not have same signature model name:{fn:data($model/@name)}</msg>)
      )
 };