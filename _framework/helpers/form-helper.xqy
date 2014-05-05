xquery version "1.0-ml";

module namespace form = "http://xquerrail.com/helper/form";

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace config = "http://xquerrail.com/config"
at "/_framework/config.xqy";

import module namespace domain = "http://xquerrail.com/domain" 
at "/_framework/domain.xqy";

import module namespace js    = "http://xquerrail.com/helper/javascript"
at "/_framework/helpers/javascript-helper.xqy";

import module namespace response = "http://xquerrail.com/response"
at "/_framework/response.xqy";

import module namespace base = "http://xquerrail.com/model/base"
  at "/_framework/base/base-model.xqy";

declare option xdmp:output "indent=yes";
declare option xdmp:output "method=xml";
declare option xdmp:ouput "omit-xml-declaration=yes";
declare option xdmp:mapping "false";

declare variable $FORM-MODE-EDIT := "edit";
declare variable $FORM-MODE-NEW  := "new";
declare variable $FORM-MODE-READONLY := "uneditable-input";
declare variable $FORM-SIZE-CLASS    := config:property("FORM-SIZE-CLASS","input-xxlarge");
declare variable $FORM-OUTER-CONTAINER-CLASS := config:property("FORM-OUTER-CONTAINER-CLASS","form-group");
declare variable $FORM-INNER-CONTAINER-CLASS := config:property("FORM-INNER-CONTAINER-CLASS","controls");
declare variable $FORM-LABEL-CLASS := config:property("FORM-LABEL-CLASS","control-label");
declare variable $FORM-INPUT-CLASS := config:property("FORM-INPUT-CLASS","form-control");

declare variable $FORM-MODE := "";

declare function form:size($size as xs:string) {
   xdmp:set($FORM-SIZE-CLASS,$size)
};

declare function form:mode($mode as xs:string) {
  xdmp:set($FORM-MODE,$mode)
};
(:~
 : Returns the computed identity field in the form of the 
 : fieldname + hashvalue, so it is unique across elements
 : with same name but in different containers 
~:)
declare function form:get-field-name($field as node()) {
    domain:get-field-name-key($field)  
};
(:~
 : Returns the computed identity field in the form of the 
 : fieldname + hashvalue, so it is unique across elements
 : with same name but in different containers 
~:)
declare function form:get-field-id($field as node()) {
    domain:get-field-id($field)  
};

(:~
 : Loads the response into the formbuilder
~:)
declare function form:initialize-response($response) {
    response:initialize($response)
};

declare function form:build-form(
 $domain-model as node(),
 $response as map:map?)
as item()*
{
    let $init := response:initialize($response)
    let $_ := xdmp:log(("form:build-form::",response:body()),"debug")
    for $field in $domain-model/(domain:attribute|domain:element|domain:container)
    return 
      form:build-form-field($field)
};

declare function form:form-field(
    $domain-model as element(domain:model),
    $fieldname as xs:string
) {
    for $field in $domain-model//(domain:attribute|domain:element|domain:container)[@name = $fieldname]
    return 
      form:build-form-field($field)
};

declare function form:build-form-field(
    $field as node()
) {
   let $value :=  form:get-value-from-response($field)
   let $type := (fn:data($field/domain:ui/@type),fn:data($field/@type))[1]
   let $label := fn:data($field/@label)
   return
   typeswitch($field)
     case element(domain:container) return
       <fieldset> 
        <legend>{fn:data(($field/@label,$field/@name)[1])}</legend>
        {
            for $containerField in $field/(domain:attribute|domain:element|domain:container)
            return
                form:build-form-field($containerField) 
        }
      </fieldset>
     case element(domain:element) return
             (form:control($field,$value))
     case element(domain:attribute) return
           <div class="form-group type_{$type}">{ (form:control($field,$value)) }</div>
     default return ()
};

declare function form:control($field,$value)
{
  let $type := (fn:data($field/domain:ui/@type),fn:data($field/@type))[1]
  let $qtype := element {fn:QName("http://www.w3.org/1999/xhtml",$type)} { $type }
  return
    typeswitch($qtype)
     (: Complex Element :)
      case element(schema-element) return form:complex($field,$value)
      case element(html-editor)    return form:complex($field,$value)
      case element(textarea)       return form:complex($field,$value)
      case element(reference)      return form:reference($field,$value)
      case element(grid)           return form:build-child-grid($field,$value)
      case element(instance)       return form:complex($field,$value)
      case element(query)          return form:complex($field,$value)
      
      (:Text Elements:)
      case element(identity)  return form:hidden($field,$value)
      case element(string)    return form:text($field,$value)
      case element(integer)   return form:text($field,$value)
      case element(long)      return form:text($field,$value)
      case element(decimal)   return form:text($field,$value)
      case element(float)     return form:text($field,$value)
      case element(anyURI)    return form:text($field,$value)
      case element(yearMonth) return form:text($field,$value)
      case element(monthDay)  return form:text($field,$value)
      
      case element(boolean)   return form:checkbox($field,$value)
      case element(password)  return form:password($field,$value)
      case element(email)     return form:text($field,$value)
      
      (:Choice Elements:)
      case element(list)         return form:list($field,$value)
      case element(radiolist)    return form:list($field,$value)
      case element(checkboxlist) return form:list($field,$value)
      case element(choice)       return form:list($field,$value)
      
      (:Date Time Controls:)
      case element(date)     return form:text($field,$value)
      case element(dateTime) return form:text($field,$value)
      case element(time)     return form:time($field,$value)
      
      (:Hidden Controles:)     
      case element(hidden)  return form:hidden($field,$value)
       
      (:Other Controls:)
      case element(lookup)     return form:lookup($field,$value)
      case element(binary)     return form:binary($field,$value)
      case element(file)       return form:binary($field,$value)
      case element(fileupload) return form:binary($field,$value)

     (:Custom Rendering:)
      case element() return form:custom($field,$value)
      
      default return <div class="error">No Render for field type {$type}.</div>
};

declare function form:get-value-from-response($field as element()) {

    let $model := $field/ancestor::domain:model
    let $name := fn:data($field/@name)
    let $ns := domain:get-field-namespace($field)
    
    (: Verify you only pull the approprite node just incase the body is a sequence :)
    (:let $node := response:body()/*[fn:local-name(.) = $name]:)
    let $node := domain:get-field-value($field,response:body())
    let $_ := xdmp:log(("field:node::",$node),"debug")
    return
        if($field/@type = ("reference","binary")) 
        then $node
        else if($field/@type = "schema-element") then 
          $node/node()
        else 
            if($node) 
            then fn:data($node)
            else fn:data($field/@default)
};

declare function form:get-value-by-name-from-response($name as xs:string) {
    let $value := response:body()//*[fn:string(fn:node-name(.)) = $name]
    return 
        $value
};

declare function form:before($field)
{
  if($field/@label and fn:not($field/domain:ui/@type = "hidden")) 
  then 
    <label for="{form:get-field-name($field)}" class="control-label {$FORM-LABEL-CLASS}">
        {fn:data($field/@label)}
    </label> 
  else ()
};

declare function form:after($field)
{
    let $type := ($field/domain:ui/@type,$field/@type)[1]
    let $id   := domain:get-field-id($field)
    let $qtype := element {$type} {$type}
    return
      typeswitch($qtype)
        case element(html-editor) return ()
        case element(code-editor) return ()   
       default return ()
};

declare function form:attributes($field)
{(
    if(($field/domain:navigation/@editable = 'false' and $FORM-MODE = "edit")
        or ($field/domain:navigation/@newable = 'false' and $FORM-MODE = "new")
        or ($FORM-MODE = "readonly")
       ) 
    then attribute readonly { "readonly" } 
    else if($field/@occurrence = ("*","+")) then
        attribute multiple {"multiple"}
    else (),
    if($field/@type eq "boolean")
    then attribute class {"field checkbox"}
    else if($field/@type eq "schema-element" or $field/domain:ui/@type = "textarea")
         then  attribute class {($FORM-INPUT-CLASS, "textarea",$FORM-SIZE-CLASS,$field/@name,$field/domain:ui/@type)}
    else attribute class {($FORM-INPUT-CLASS,$FORM-SIZE-CLASS,$field/@type,$field/@name,$field/domain:ui/@class/fn:tokenize(.,"\s"))},
    attribute placeholder {($field/@label,$field/@name)[1]},
    let $constraint  := $field/domain:constraint
    return (
        if($constraint/@required = "true")                then attribute required  {$constraint/@required eq "true"}    else (),
        if($constraint/@minLength castable as xs:integer) then attribute minlength {xs:integer($constraint/@minLength)} else (),
        if($constraint/@maxLength castable as xs:integer) then attribute maxlength {xs:integer($constraint/@maxLength)} else (),
        if($constraint/@minValue ne "" )                  then attribute minValue  {xs:integer($constraint/@minValue)}  else (),
        if($constraint/@maxValue ne "")                   then attribute maxValue  {xs:integer($constraint/@maxValue)}  else ()
    )
)};

declare function form:validation($field) {
    let $constraint  := $field/domain:constraint
    return (
        if($constraint/@required = "true")                then attribute required  {$constraint/@required eq "true"}    else (),
        if($constraint/@minLength castable as xs:integer) then attribute minlength {xs:integer($constraint/@minLength)} else (),
        if($constraint/@maxLength castable as xs:integer) then attribute maxlength {xs:integer($constraint/@maxLength)} else (),
        if($constraint/@minValue ne "" )                  then attribute minValue  {xs:string($constraint/@minValue)}   else (),
        if($constraint/@maxValue ne "")                   then attribute maxValue  {xs:string($constraint/@maxValue)}   else ()
    )
};

declare function form:values($field,$value)
{
 let $list  := (
        $field/ancestor::domain:model/domain:optionlist[@name = $field/domain:constraint/@inList],
        domain:get-optionlist($field/domain:constraint/@inList)
 )[1]
 let $is-multi := $field/@occurrence  = ("+","*")
 let $default  := $field/@default
 let $value    := if($value[. ne ""]) then $value else $default
 let $readonly := $field/domain:navigation/@editable eq 'false'
 return 
 if($list and fn:not($readonly)) then
    for $option in $list/domain:option
    return
        <option value="{$option/text()}">
            {   if($value = $option/text()) then
                    attribute selected {"selected" }
                else (),
                (fn:data($option/@label),$option/text())[1]
            }
        </option>
  else 
    if(fn:data($field/@type = "boolean")) 
    then (   
            attribute value {$value},
            if(xs:boolean($value) eq fn:true()) 
            then attribute checked {"checked"}
            else ()
    ) else  attribute value {fn:string-join($value,",")}
};

(:~
 : Custom Rendering of controls
 : Formats : 
 :   (application):(helper|model|tag):function-name($field,$value)
 :   The method should take a field and value
~:)
declare function form:custom($field,$value)
{
  let $renderer := $field/domain:ui/@renderer
  let $context := fn:tokenize($renderer,":")
  let $source  := $context[1]
  let $type    := $context[2]
  let $action  := $context[3]
  let $apply   := ()
  return 
     $apply
};
(:~
 : Function binds controls to their respective request data 
 : from the request map;
~:)
declare function form:text($field,$value)
{
  <div class="{$FORM-OUTER-CONTAINER-CLASS}">{
       form:before($field),
       <div class="{$FORM-INNER-CONTAINER-CLASS}">{       
            if($field/domain:constraint/@inList and fn:not($field/domain:navigation/@editable eq 'false')) then
            <select id="{form:get-field-id($field)}" name="{form:get-field-name($field)}">
            {form:attributes($field)}
            {form:values($field,$value)}
            </select>
            else 
            if($field/@occurrence = ("*","+"))
            then 
                for $val at $pos in ($value, if($value) then () else "")
                return
                  <input id="{form:get-field-name($field)}[{$pos - 1}]" name="{form:get-field-id($field)}" type="text">
                  {form:attributes($field)}
                  {form:values($field,$val)}
                  </input>
             else 
                  <input id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" type="text">
                  {form:attributes($field)}
                  {form:values($field,$value)}
                  </input>
       }</div>
       ,
       form:after($field)
  }</div>
};
(:~
 : Renders a list of radio boxes 
~:)
declare function form:list($field,$value) {
    let $type as xs:string := ($field/domain:ui/@type,$field/@type)[1]
    let $ui-type := 
        if($type = ("radio","radiolist")) 
        then "radio"
        else if($type = ("checkbox","checkboxlist")) 
        then "checkbox"
        else fn:error(xs:QName("FIELD-OPTION-TYPE-ERROR"),"Type is not value for renderlist",$type)        
    return (
       form:before($field), 
       if($field/domain:constraint/@inList) then 
         let $optionlist := domain:get-field-optionlist($field)
         for $option in $optionlist/domain:option
         let $label := (fn:data($option/@label),fn:data($option))[1]
         return (
         <label class="value {$FORM-LABEL-CLASS}">
           <input name="{form:get-field-name($field)}" type="{$ui-type}">
           {form:attributes($field)}
           {attribute value {$option/text()}}
           {
            if($value = fn:data($option)) 
            then attribute checked {"checked"}
            else ()            
           }
           </input>
           {$label}
          </label>
          )
       else if($field/@type = "reference") then 
            ()
       else ()
       ,
       form:after($field)
  )          
};
(:~
 : Renders a value as a checkbox
~:)
declare function form:checkbox-value(
$field as element(),
$mode as xs:string,
$value as item()*
) {  
  if($mode eq "true")
  then attribute value { xs:string($value) eq "true"}
  else attribute value {xs:string($value) eq "false"}
};

declare function form:checkbox($field,$value)
{
  <div class="{$FORM-OUTER-CONTAINER-CLASS}">{
   form:before($field),
    <div class="{$FORM-INNER-CONTAINER-CLASS}">     
      <label class="checkbox inline">
       <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="radio" value="true">
       {form:attributes($field)}
       {
        if($value castable as xs:boolean) 
        then if($value cast as xs:boolean  = fn:true()) then attribute checked{"checked"} else ()
        else () 
       }
       True
       </input>
       </label>
       <label class="checkbox inline">
       <input name="{form:get-field-name($field)}" type="radio" value="false"  >
       {form:attributes($field)}
       {if($value castable as xs:boolean) 
        then if($value cast as xs:boolean  = fn:false()) then attribute checked{"checked"} else ()
        else () 
       }
       False
       </input>
       </label>       
       {form:after($field)}
       </div>
    }</div>
};

declare function form:money($field,$value)
{(
           form:before($field), 
           <input id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" type="text">
           {form:attributes($field)}
           {form:values($field,$value)}
           </input>,
           form:after($field)
)};

declare function form:number($field,$value)
{
(
   form:before($field), 
   <input id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" type="text">
   {form:attributes($field)}
   {form:values($field,$value)}
   </input>,
   form:after($field)
)
};
declare function form:password($field,$value)
{
 <div class="{$FORM-OUTER-CONTAINER-CLASS}">{(
   form:before($field), 
   <div class="{$FORM-INNER-CONTAINER-CLASS}">
         <input id="{form:get-field-name($field)}" name="{form:get-field-name($field)}" type="password">
         {form:attributes($field)}
         {form:values($field,$value)}
         </input>
   </div>,
   form:after($field)
   )}</div>
};


declare function form:choice($field,$value)
{(
       form:before($field), 
       <select id="{form:get-field-name($field)}" name="{form:get-field-name($field)}">
       {form:attributes($field)}
       {form:values($field,$value)}
       </select>,
       form:after($field)
)};


declare function form:time($field,$value)
{ <div class="{$FORM-OUTER-CONTAINER-CLASS}">{
       form:before($field),
       <div class="{$FORM-INNER-CONTAINER-CLASS}">
         <div id="{form:get-field-name($field)}_time" class="input-append">
            <input id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" type="text" data-format="hh:MM:ss">
            {form:attributes($field)}
            {form:values($field,$value)}
            </input>
            <span class="add-on"><i class="icon-time"></i></span>
         </div>
       </div>
       ,
       form:after($field)
  }</div>
};

declare function form:date($field,$value)
{  <div class="{$FORM-OUTER-CONTAINER-CLASS}">{
       form:before($field),
       <div class="{$FORM-INNER-CONTAINER-CLASS}">
         <div class="input-append">
            <input id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" type="text">
            {form:attributes($field)}
            {form:values($field,$value)}
            </input>
            <span class="add-on"><i class="icon-calendar" data-date-icon="icon-calendar"> </i></span>
         </div>
       </div>
       ,
       form:after($field)
  }</div>
};

declare function form:hidden($field,$value)
{(
   <input id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" type="hidden">
   {form:attributes($field)}
   {form:values($field,$value)}
   </input>,
   form:after($field)
)};
declare function form:binary-content-type-icon($value) {
    let $content-type := $value/@content-type
    return 
      if($content-type and $content-type ne "")
      then fn:replace(fn:replace($content-type,"/","-"),"\.","")
      else "unknown"
};
(:~
 : Returns a url reference for binary instance  
~:)
declare function form:binary-url($field,$value) {
  let $model := $field/ancestor::domain:model
  let $application := response:application()
  let $application := if($application) then $application else domain:get-default-application()
  let $controller := domain:get-model-controller($application,$model)
  let $identity-field := domain:get-model-identity-field($model)
  let $id := domain:get-field-value($identity-field,response:body())
  return
    fn:concat("",$controller/@name,"binary?name=",$field/@name,"&amp;uuid=",$id)
};

declare function form:binary($field,$value) {
  <div class="{$FORM-INNER-CONTAINER-CLASS}">{
       form:before($field),
       <div class="{$FORM-INNER-CONTAINER-CLASS}">       
            <input id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" type="file">
            {form:attributes($field)}
            {form:values($field,$value)}
            </input>
            <span class="links">
                <strong>File: {fn:string($value/@filename)}</strong>
                <a href="{form:binary-url($field,$value)}" class="filename">
                <span class="icon-download-alt pull-right"></span>
                </a>
            </span>
       </div>
       ,
       form:after($field)
  }</div>
};

declare function form:schema-element($field,$value) 
{(
 <div class="{$FORM-OUTER-CONTAINER-CLASS}">{
  form:before($field),
  <div class="{$FORM-INNER-CONTAINER-CLASS}">  
    <textarea name="{form:get-field-name($field)}" id="{form:get-field-id($field)}">
        { form:attributes($field) }
        { if( $value/element() or $value instance of element() and $value) then xdmp:quote($value) else $value}
     </textarea>
   </div>,
   form:after($field)
   }</div>
)};

declare function form:complex($field,$value) 
{(
  <div class="{$FORM-OUTER-CONTAINER-CLASS}">{ 
       form:before($field), 
       <div class="{$FORM-INNER-CONTAINER-CLASS}">
        <textarea name="{form:get-field-name($field)}" id="{domain:get-field-id($field)}">
            { form:attributes($field) }
            { if( $field/@type = "schema-element") then xdmp:quote($value) else $value}
         </textarea>
       </div>,
       form:after($field)
   }</div>
)};

declare function form:build-child-grid($field,$value) {
    let $fieldKey := form:get-field-name($field)
    
	let $fieldSchema := () (: js:o((
	   for $item in $field/domain:ui/domain:gridColumns/domain:gridColumn
       let $name := fn:data($item/@name)
       let $type := fn:data($item/@type)
	   return
	      js:kv$name, 
	        js:o((js:kv("type", js:string($type))
	      )))
    )):)
	
	let $columnSchema := 
	 js:a(
     	   for $item in $field/domain:ui/domain:gridColumns/domain:gridColumn
     	   let $name := fn:data($item/@name)
         	   let $label := (fn:data($item/@label),fn:data($field/@label),fn:data($field/@name))[1]
     	   let $type :=  (fn:data($item/@type), "string")[1]
     	   let $visible := 
     	      if($item/@type eq "hidden" or $field/@type eq "identity")
     	      then fn:false()
     	      else fn:true()
     	   return
              js:o((
                js:kv($FORM-INPUT-CLASS,$name),
                js:kv("title",$label),
                js:kv("sortable",fn:true()),
                js:kv("resizable",fn:true()),
                js:kv("type",$type),
                js:kv("visible",$visible)
              ))
	 )
	 
     let $modelData := ()

	return
	(
     form:before($field), 
      <div class="complexGridWrapper">
           <div id="{$fieldKey}" class="complexGrid"></div>
           <script type="text/javascript">
                buildEditGrid('{$fieldKey}', {$modelData},   {$columnSchema}) 
           </script>
       </div>,
      form:after($field)
   )
};

declare function form:lookup($field,$value) {
    let $application := response:application()
    let $modelName := fn:tokenize(fn:data($field/@reference),":")[2]
    let $reference := fn:data($field/@reference)
    let $refTokens := fn:tokenize($reference,":")
    let $refParent   := $refTokens[1]
    let $refType     := $refTokens[2]
    let $refAction   := $refTokens[3]
    let $value := 
        if($value[. ne ""]) then $value else fn:data($field/@default)
    let $fieldName  := form:get-field-name($field)
    let $lookupReference := (
        fn:data($field/domain:ui/@lookup),
        domain:get-model-controller-name($application,$refType)
        )[1]
    let $refController := 
        let $tokenz := fn:tokenize($lookupReference,":")
        return
          if(fn:count($tokenz) = 2) 
          then fn:concat("/",$tokenz[1],"/",$tokenz[2],".xml")
          else if(fn:count($tokenz) = 1) then
               fn:concat("/",$tokenz[1],"/lookup.xml")      
          else fn:error(xs:QName("LOOKUP-REFERENCE-ERROR"),"Unable to resolve reference",$tokenz)
    return
      <div class="{$FORM-OUTER-CONTAINER-CLASS}">
       {form:before($field)}  
       <div class="{$FORM-INNER-CONTAINER-CLASS}">
            <input id="{$fieldName}" name="{$fieldName}" type="hidden" data-lookup="{$refController}" value="{$value/@ref-id}">
            {   (:Added validation Rendering:)
                form:validation($field),
                if($field/@occurrence = ("*","+")) 
                then (
                    attribute multiple { "multiple" },
                    attribute class {($FORM-INPUT-CLASS, "lookup", $FORM-SIZE-CLASS,$field/@name  )}
                    )
                 else (
                     attribute class {($FORM-INPUT-CLASS, "lookup", $FORM-SIZE-CLASS,$field/@name )}
                 )
                   
             }
            </input>
       </div>       
       {form:after($field)}
      </div>
};

declare function form:reference($field,$value) {
    let $application := response:application()
    let $modelName := fn:tokenize(fn:data($field/@reference),":")[2]
    let $reference := fn:data($field/@reference)
    let $refTokens := fn:tokenize($reference,":")
    let $refParent   := $refTokens[1]
    let $refType     := $refTokens[2]
    let $refAction   := $refTokens[3]
    let $form-mode := 
      if($FORM-MODE = "readonly") then "readonly" 
      else if($FORM-MODE = "new" and fn:not($field/domain:navigation/@newable = "false"))      then ()
      else if($FORM-MODE = "edit" and fn:not($field/domain:navigation/@editable = "false")) then ()
      else "readonly"
    return
    <div class="{$FORM-OUTER-CONTAINER-CLASS}">
           { form:before($field) }
       <div class="{$FORM-INNER-CONTAINER-CLASS}">    
           <select id="{form:get-field-name($field)}" name="{form:get-field-id($field)}" >{   
                form:validation($field),
                if(($field/domain:navigation/@editable = 'false' and $FORM-MODE = "edit")
                    or ($field/domain:navigation/@newable = 'false' and $FORM-MODE = "new")
                    or ($FORM-MODE = "readonly")
                ) 
                then attribute readonly { "readonly" } 
                else (),
               if($field/@occurrence = ("*","+")) 
               then (
                   attribute multiple { "multiple" },
                   attribute class {($FORM-INPUT-CLASS, $FORM-SIZE-CLASS,"select", "multiselect",$field/@name )}
                   )
                else (
                    attribute class {($FORM-INPUT-CLASS, "select",$FORM-SIZE-CLASS,$field/@name )},
                    if($form-mode = "readonly") then () else <option value="">Please select {fn:data($field/@label)}</option>
                )
            }
            {
                (: Build Model Refrences using the lookup feature in the base model :)
                if($refParent = 'model') then
                     let $lookups := base:lookup(domain:get-domain-model($modelName),map:map())
                     return
                        if($form-mode = "readonly") 
                        then <option value="{$value/@ref-id}" selected="selected">{fn:string($value)}</option>
                        else 
                           for $lookup in $lookups/*:lookup
                           let $key := fn:normalize-space(fn:string($lookup/*:key))
                           let $label := $lookup/*:label/text()
                           return 
                             element option {
                                  attribute value {$key},
                                  if($value/@ref-id = $key) 
                                  then attribute selected { "selected" } 
                                  else (),
                                  $label
                             }
                (: Build Abstract Model References using the base model functions :)       
                else if($refParent = 'application') then  
                    if($refParent eq "application" and $refType eq "model")
                    then 
                      let $domains := xdmp:value(fn:concat("domain:model-",$refAction))
                      for $model in $domains
                      let $key := fn:data($model/@name)
                      let $label := fn:data($model/@label)
                      return
                          element option {
                              attribute value { $key },
                              if($value/@ref-id = $key) 
                              then attribute selected { "selected" }
                              else (),
                              $label
                          }
                     else ()
                else ()
             }
           </select>         
        </div>           
           { form:after($field) }
    </div>
};
(:~
 : Builds a grid column from 
 :)
declare function form:field-grid-column(
$field as element()){
   form:field-grid-column($field,map:map())
};
(:~
 : Creates a grid column specification to be used in jqgrid control.
 :
~:)
declare function form:field-grid-column(
  $field as element(),
  $options as map:map
) {
    let $model-name := fn:data($field/ancestor::domain:model/@name)
    let $field-name := fn:data($field/@name)
    let $model-identity-field := domain:get-model-identity-field($field/ancestor::domain:model)
    let $field-name-key := form:get-field-name($field)
    let $field-id-key   := form:get-field-id($field)
    let $field-type := fn:local-name($field)
    let $label      := (map:get($options,"label"),fn:data($field/@label))[1]
    let $dataType   := (map:get($options, "type"), fn:data($field/@type))[1]
    let $listable   := (map:get($options, "listable"),$field/domain:navigation/@listable, $field/domain:navigation/@visible,"true")[1]
    let $colWidth   := (map:get($options, "width"), fn:data($field/domain:ui/(@gridWidth|@colWidth)/xs:integer(.)),200) [1]
    let $align      := 
        if(map:get($options,"align")) then map:get($options,"align")
        else if($dataType = "boolean") then "center" 
        else if($dataType = ("decimal","float","double")) then "right"
        else "left"
    let $sortable := ($field/domain:navigation/@sortable,"true")[1]
    let $formatter :=  
         if(map:get($options,"formatter"))
         then js:kv("fomatter",map:get($options,"formatter"))
         else if($field/domain:ui/@formatter ne "" and fn:exists($field/domain:ui/@formatter)) 
         then js:kv("formatter",fn:data($field/domain:ui/@formatter))
         else if($field/@occurrence = ("+","*")) then js:kv("formatter",js:literal("arrayFormatter"))
         else if($dataType eq "binary") then js:kv("formatter",js:literal("binaryFormatter"))
         else if($dataType eq "boolean") then (js:kv("formatter","checkbox"),js:kv("align","center"))
         else ()
    let $hidden := 
      if(fn:exists(map:get($options,"hidden")))
      then map:get($options,"hidden")
      else $field/domain:ui/@type eq "hidden" or $field/domain:navigation/@listable eq "false"
    let $xmlmap-key := fn:concat(fn:replace($field-name-key,"\."," > "))
    return
    if($listable = "true") then
         js:o((
             js:kv("name",$field-name-key),
             js:kv("label",$label),
             js:kv("index",$field-name-key),
             if($field is $model-identity-field) 
             then js:kv("key",fn:true()) else (),
             js:kv("xmlmap",if($field-type = "attribute") then "[" || $field-name || "]" else $xmlmap-key),
             js:kv("jsonmap", $field-name-key),
             js:kv("dataType",$dataType),
             js:kv("resizable",fn:true()),
             js:kv("fixed",fn:true()),
             js:kv("sortable",$sortable),
             js:kv("width",$colWidth),
             js:kv("align",$align),
             js:kv("searchable",$field/domain:navigation/@searchable eq "true"),
             js:kv("hidden",$hidden),
             $formatter
         ))
     else ()
};

(:~
 :    Assigns validation constraints to input 
 :    Assumes the use of bassistance.de jquery.validation.js
~:)
declare function form:build-validation($model) {
  js:o((
    js:e("rules",(
        for $f in $model//(domain:element|domain:attribute|domain:container)
        let $constraint := $f/domain:constraint
        return
          if($constraint) 
          then js:entry(form:get-field-name($f), (
            if($constraint/@required = "true") then js:kv("required",$constraint/@required eq "true") else (),
            if($constraint/@minLength castable as xs:integer) then js:kv("minlength",xs:integer($constraint/@minLength)) else (),
            if($constraint/@maxLength castable as xs:integer) then js:kv("maxlength",xs:integer($constraint/@maxLength)) else (),
            if($constraint/@minValue ne "" )  then js:kv("min",xs:integer($constraint/@minValue)) else (),
            if($constraint/@maxValue ne "")  then js:kv("max",xs:integer($constraint/@maxValue)) else ()
            
          ))
          else ()
    ))
  ))
};

(:~
 : Builds a javascript context object that can be used to drive navigation
~:)
declare function form:context(
   $response as map:map
) {(
   response:initialize($response)[0],
   js:variable("context", 
        js:o((
           js:kv("application",response:application()),
           js:kv("controller", response:controller()),
           js:kv("action",response:action()),
           js:kv("view",response:view()),
           if(response:model())
           then 
              let $identityField := domain:get-model-identity-field(response:model())
              let $keyLabelField := domain:get-model-keyLabel-field(response:model())
              return (
              js:kv("currentId",domain:get-field-value($identityField,response:body())/fn:data(.)),
              js:kv("currentLabel",domain:get-field-value($keyLabelField,response:body())/fn:data(.)),
              js:kv("modelName",response:model()/@name),
              js:kv("modelId",domain:get-model-identity-field-name(response:model())),
              js:kv("modelKeyLabel",fn:string(domain:get-model-keyLabel-field(response:model())/@name)),
              js:kv("modelIdSelector",
               let $idField := domain:get-model-identity-field(response:model())
               return 
                 if($idField instance of element(domain:attribute)) 
                 then "[" || $idField/@name || "]"
                 else fn:string($idField/@name)
               )
           )
           else ()
        ))
   ))
};