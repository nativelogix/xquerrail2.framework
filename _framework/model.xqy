xquery version "1.0-ml";
(:~
 : Model model Application framework model functions
 :)
module namespace model = "http://xquerrail.com/model";

import module namespace js = "http://xquerrail.com/helper/javascript" at "/_framework/helpers/javascript.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "/_framework/domain.xqy";

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
  $field as element(),
  $instance as element()
){
   typeswitch($field)
     case element(domain:model) return 
       js:o((
         for $f in $field/(domain:container|domain:attribute|domain:element)
         return model:build-json($f,$instance)
       ))
     case element(domain:element) return
        let $field-value := domain:get-field-value($field,$instance)
        return       
        if($field/domain:attribute) then 
           js:no($field/@name,(
               js:no("_attributes",
                 for $field in $field/(domain:attribute)
                 return 
                   model:build-json($field,$instance)
               ),
               js:pair("value",$field-value)
           ))
       else if($field/@occurrence = ("+","*")) then
           let $field-value := domain:get-field-value($field,$instance)
           return 
              if($field/@reference) then 
                  js:na($field/@name,
                  for $ref in $field-value 
                  return 
                    js:o((
                        js:pair("reference",fn:true()),
                        js:pair("text", js:string($ref)),
                        js:pair("id", js:string($ref/@ref-id)),
                        js:pair("type",js:string($ref/@type))
                     ))
                 )
              else js:na($field/@name,for $ref in $field-value return $ref)              
     else if($field/@reference and $field/@type eq "reference") then
            js:no($field/@name,(
               js:pair("reference",fn:true()),
               js:pair("text", fn:string($field-value)),
               js:pair("id", js:string($field-value/@ref-id)),
               js:pair("type",fn:data($field-value/@ref))
             ))
     else if($field/@type eq "binary") then 
       js:no($field/@name,(
               js:pair("uri", fn:string($field-value)),
               js:pair("filename", fn:data($field-value/@filename)),
               js:pair("contentType",fn:data($field-value/@content-type))
       ))   
     else if($field/@type eq "identity")
     then js:pair($field/@name,js:string($field-value))
     else js:pair($field/@name,$field-value)
     case element(domain:attribute) return
         let $field-value := domain:get-field-value($field,$instance)
         return        
             js:pair(fn:concat("@",$field/@name),$field-value)
     case element(domain:container) return 
         js:no($field/@name, (
            for $field in $field/domain:element
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