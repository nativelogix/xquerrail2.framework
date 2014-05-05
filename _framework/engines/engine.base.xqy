xquery version "1.0-ml";
(:~
 : Performs core engine for transformation and base implementation for 
 : different format engines
 :)
module namespace engine = "http://xquerrail.com/engine";

import module namespace request = "http://xquerrail.com/request"
   at "/_framework/request.xqy";
   
import module namespace response = "http://xquerrail.com/response"
   at "/_framework/response.xqy";
   
import module namespace config = "http://xquerrail.com/config"
   at "/_framework/config.xqy";

import module namespace json="http://marklogic.com/xdmp/json"
     at "/MarkLogic/json/json.xqy";
     


declare namespace tag = "http://xquerrail.com/tag";    

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";


declare variable $engine-transformer as xdmp:function? := xdmp:function(xs:QName("engine:transformer"));
declare variable $visitor := map:map();
declare variable $_child-engine-tags := map:map();
declare variable $_helpers := map:map();
declare variable $_plugins := map:map();

(:~
 : registers a plugin with the engine
 :)
declare function  engine:register-plugin($plugin as xdmp:function)
{
   map:put($_plugins,xdmp:function-name($plugin),$plugin)
};

(:~
 : Returns a list of plugin names registered with egine
 :)
declare function engine:plugin-names()
{
   map:keys($_plugins)
};

(:~
 : Returns a list of plugins registered with engine
 :)
declare function engine:plugins()
{
   for $p in map:keys($_plugins) return map:get($_plugins,$p)
};

(:~
 : The for iterator requires a global stack
:)
declare variable $this-values := map:map();

(:~
 : To allow your engine to route transform calls from base
 : You must register your engines transformer function in
 : order for the base engine to route any functions you will handle
 :)
declare function engine:set-engine-transformer($func as xdmp:function)
{
   xdmp:set($engine-transformer,$func)
};

(:~
 : Register any custom tags you will be overriding from custom engine
 :)
declare function engine:register-tags($tagnames as xs:QName*)
{
  for $tag in $tagnames
  return
    map:put($_child-engine-tags,fn:string($tag),$tag)
};
(:~
 : Check to see if a tag has been registered with the engine
 :)
declare function engine:tag-is-registered(
  $tag as xs:string
)
{
  if(fn:exists(map:get($_child-engine-tags,fn:string($tag)))) 
  then fn:true()
  else fn:false()
};

(:~
 : Marks that a node has been visited during transformation
 : When building custom tag that requires a closing tag 
 : ensure that you consume the results you process or you
 : will find duplicate or spurious output results 
 :)
declare function engine:consume($node)
{
  (
     map:put($visitor,fn:generate-id($node),"x")
  )
};
(:
: Marks that a node has been visited and returns that node
:)
declare function engine:visit($node)
{
  (
     map:put($visitor,fn:generate-id($node),"x"),$node
  )
};
(:~
 :  Returns boolean value of whether a node has been visited.
 :)
declare function engine:visited($node)
{   if($node instance of json:object) 
    then fn:exists(map:get($visitor,fn:generate-id(<x>{$node}</x>/*)))
    else fn:exists(map:get($visitor,fn:generate-id($node)))
};

(:~
 : Transforms an if tag for processing
 :)
declare function engine:transform-if($node as node())
{
  let $endif := $node/following-sibling::processing-instruction("endif")[1]
  let $else  := $node/following-sibling::processing-instruction("else")[1]
  let $overlap := $node/following-sibling::processing-instruction("if")[. << $endif]
  let $_ := 
     if($overlap) 
     then fn:error(xs:QName("TAG-ERROR"),"Overlapping if tags")
     else ()  
  let $ifvalue := 
        if($else) then (
            $node/following-sibling::node()[. << $else]
        )
        else (
            xdmp:log(("IF Condition:",$node/following-sibling::node()[. << $endif]),"debug"),
            $node/following-sibling::node()[. << $endif]
        )
  let $elsevalue := 
        if($else) then $else/following-sibling::node()[. << $endif]
        else ()
  let $condition := xdmp:value(fn:concat("if(", fn:data($node), ") then fn:true() else fn:false()"))
  return
    (
    engine:consume($endif),
    engine:consume($else),
    if($condition eq fn:true()) 
    then (
          for $n in $ifvalue return engine:transform($n),
          for $n in $elsevalue return engine:consume($n),
          for $n in $ifvalue return engine:consume($n)
         )
    else ( 
           for $n in $elsevalue return engine:transform($n),
           for $n in $ifvalue return engine:consume($n),
           for $n in $elsevalue return engine:consume($n)
         )
    )
};

(:~
 : The for tag must handle its one process 
   and return the context to the user
 :)
declare function engine:process-for-this(
   $this-tag as processing-instruction("this"),
   $this)
{
  let $this-value := fn:string($this-tag)
  return
     (engine:consume($this-tag),
      for $v in xdmp:value($this-value) 
      return 
        typeswitch($v)
          case element() return engine:transform($v)
          case processing-instruction() return engine:transform($v)
          case attribute() return fn:data($v)
          default return $v
     ) 
};

(:~
 : The for tag must handle its one process 
   and return the context to the user
 :)
declare function engine:process-for-context($nodes,$context,$key)
{
   for $node in $nodes
   return
     typeswitch($node)
     case element() return
            if($node//processing-instruction("this"))
            then element {fn:node-name($node)}
            {
              $node/@*,
              engine:process-for-context($node/node(),$context,$key)
            }
            else engine:transform($node)
      case processing-instruction("this") return engine:process-for-this($node,$context)   
      default return $node  
};
(:~
   Syntax :
    <?for $data//search-result ?>
       <div>
          <?fragment name="" location="" ?>
          <h2 class="title"><?this $this/title?></h2>
          <div><?this fn:string($this/@uri)?> </div>
          <div class="snippet">
            <?this $this/snippet/*?> 
          </div>
       </div>
    <?else?>
    <div>No Search Results Found...</div>
    <?endfor?>
:)
declare function engine:transform-for(
   $for-tag as processing-instruction("for")
)
{
    let $endfor-tag := $for-tag/following-sibling::processing-instruction("endfor")
    let $elsefor-tag := $for-tag/following-sibling::processing-instruction("elsefor")
    let $overlap := $for-tag/following-sibling::processing-instruction("for")[. << $for-tag]
    (:Validate Conditions here:)
    let $_ := 
       (  
         if($overlap) 
         then fn:error(xs:QName("TAG-ERROR"),"Overlapping <?for?> tags")
         else (),
         if($endfor-tag) 
         then () 
         else fn:error(xs:QName("TAG-ERROR"),"Missing <?endfor?> tag")
       )   
     
    (:Now Worry about the values:)   
    let $for-process := xdmp:unquote(fn:concat("<for ", fn:data($for-tag),"/>"))/*:for
    let $for-values := xdmp:value(fn:string($for-process/@in))
    let $var-name := fn:string($for-process/@var)
    let $for-data := 
        if($elsefor-tag) 
        then $for-tag/following-sibling::node()[. << $elsefor-tag] 
        else $for-tag/following-sibling::node()[. << $endfor-tag]
    let $elsefor-data := 
        if($elsefor-tag) 
        then $elsefor-tag/following-sibling::node()[. << $endfor-tag] 
        else ()
    return
     (
        engine:consume($for-tag),
        engine:consume($endfor-tag),
        engine:consume($elsefor-tag),
        if(fn:exists($for-values)) then
        (
           for $d in $elsefor-data return engine:consume($d),
           for $v in $for-values return engine:process-for-context($for-data,$v,$var-name),
           for $d in $for-data return engine:consume($d)
        )  
        else
        (
           for $d in $elsefor-data return engine:transform($d),
           for $d in $for-data return engine:consume($d),
           for $d in $elsefor-data return engine:consume($d)
        )            
     )
};

declare function engine:transform-has_slot($node as node())
{
  let $end_tag := $node/following-sibling::processing-instruction("end_has_slot")
  let $content := $node/following-sibling::node()[. << $end_tag]
  let $tag_data := xdmp:unquote(fn:concat("<has_slot ",fn:data($node)," />"))/*
  let $slot := fn:string($tag_data/@slot) 
  return 
  (
    engine:consume($end_tag),
    if(response:has-slot($slot)) 
    then (
          for $n in $content return engine:transform($n),
          for $n in $content return engine:consume($n)
         )
    else ( 
          for $n in $content return engine:consume($n)
         )  
  ) 
};

declare function engine:transform-slot($node as node())
{
  let $tag_data := xdmp:unquote(fn:concat("<slot ",fn:data($node)," />"))/*
  let $slot := $tag_data/@name
  let $endslot := $node/following-sibling::processing-instruction("endslot")[1]
  let $is_closed := if($endslot) then () else fn:error(xs:QName("MISSING-END-TAG"),"slot tag is missing end tag <?endslot?>")
  let $slotcontent := $node/following-sibling::node()[. << $endslot]
  let $setslot := response:slot($slot)
  let $log := xdmp:log(("slot:",$setslot))
  return
  (  engine:consume($endslot),
     if(fn:exists($setslot)) 
     then ( (:Consume the slots data and then render the passed slot value:)
           for $n in $slotcontent return (engine:consume($n)),
           for $n in $setslot return (engine:transform($n), engine:consume($n))
         )
     else for $n in $slotcontent return (engine:transform($n), engine:consume($n))
  )  
};

declare function engine:template-uri($name)
{
  fn:concat(config:application-directory(response:application()),"/templates/",$name,".html.xqy")
};

declare function engine:module-file-exists($path as xs:string) as xs:boolean
{
   let $fs-path := if(xdmp:platform() eq "winnt") then "\\" else "/"
   return
   if(xdmp:modules-database() eq 0) 
   then xdmp:filesystem-file-exists(
           fn:concat(xdmp:modules-root(),$fs-path,fn:replace($path,"\\|/",$fs-path))
        )
   else 
      xdmp:eval('declare variable $uri as xs:string external ;
      fn:doc-available($uri)',
      (fn:QName("","uri"),$path),
         <options xmlns="xdmp:eval">
            <database>{xdmp:modules-database()}</database>
         </options>   
      )
};

declare function engine:view-exists($view-uri as xs:string) as xs:boolean
{
	if (xdmp:modules-database() ne 0) then
      let $context-uri := fn:replace(fn:concat(xdmp:modules-root(),$view-uri),"//|\\","/")
      return
      xdmp:eval('declare variable $uri external; fn:doc-available($uri)',
      (fn:QName("","uri"),$context-uri),
         <options xmlns="xdmp:eval">
            <database>{xdmp:modules-database()}</database>
         </options>   
      )
	else
		xdmp:uri-is-file($view-uri)
};
declare function engine:view-uri($controller,$action) {
  engine:view-uri($controller,$action,config:default-format())
};
(:~
 : Returns a view URI based on a controller/action
 :)
declare function engine:view-uri($controller,$action,$format)
{ 
   engine:view-uri($controller,$action,$format,fn:true())
};
(:~
 : Returns a view URI based on a controller/action
 :)
declare function engine:view-uri($controller,$action,$format,$checked as xs:boolean)
{

  let $view-uri := fn:concat(config:application-directory(response:application()),"/views/",$controller,"/",$controller,".",$action,".",$format,".xqy")
  return 
  if(engine:view-exists($view-uri)) 
  then $view-uri
  else 
    let $base-view-uri := fn:concat(config:base-view-directory(), "/base.", $action, ".",$format, ".xqy")
    return
      if(engine:view-exists($base-view-uri)) then 
         $base-view-uri
      else if($checked) then 
        fn:error(xs:QName("ERROR"),"View Does not exist",$base-view-uri)
      else $view-uri
};
declare function engine:render-template($response)
{
    let $template-uri := 
        fn:concat(
            config:application-directory(response:application()),
            "/templates/",
            response:template(),
            ".html.xqy")
            
    let $template-nodes :=  xdmp:invoke($template-uri,(xs:QName("response"),$response))
    
		(: SJC: Want to see the specific errors, like if there was a problem in the template.
        try{ xdmp:invoke($template-uri,(xs:QName("response"),$response)) } 
        catch *  {
            fn:error(xs:QName("TEMPLATE-NOT-EXISTS"),fn:concat("A template named '",
            	response:template(),"' does not exist at '",
            	config:application-directory(response:application()),
            	"/templates/'"),($template-uri))
        }
		:)
    for $n in $template-nodes
    return 
      engine:transform($n)
};
(:~
 : Partial rendering intercepts a call and routes only the view, even if a template is defined.
 : This is to support ajax type calls for rendering views in a frame or container
 :)
declare function engine:render-partial($response)
{
   engine:render-view()
};

(:Documentation:)
declare function engine:render-view()
{
    let $view-uri := engine:view-uri(fn:data(response:controller()),fn:data((response:action(),response:view())[1]),fn:data(response:format()))
    return 
    if($view-uri and engine:view-exists($view-uri))
    then
         for $n in xdmp:invoke($view-uri,(xs:QName("response"),response:response() ))
         return 
           engine:transform($n)
    else fn:error(xs:QName("VIEW-NOT-EXISTS"),"View does not exist ",($view-uri))
};

declare function engine:transform-template($node)
{
   let $dummy := xdmp:unquote(fn:concat("<template ",fn:data($node),"/>"))/*
   for $n in xdmp:invoke(engine:template-uri(fn:data($dummy/@name)),
     (
        fn:QName("","response"),response:response() 
     )
     ) 
     return engine:transform($n)
};

declare function engine:transform-view($node)
{
   let $dummy := xdmp:unquote(fn:concat("<view ",fn:data($node),"/>"))/*
   let $view  := response:view()
   let $controller := response:controller()
   return   
     for $n in 
     xdmp:invoke(
        engine:view-uri($controller,$view),(
        fn:QName("","response"),response:response()
     ))  
     return engine:transform($n)
};

declare function engine:transform-dynamic($node as node())
{
  let $engine-tag-qname := fn:concat("engine:",fn:local-name($node))
  let $is-registered := engine:tag-is-registered($engine-tag-qname)
  return 
        if($is-registered) 
        then xdmp:apply($engine-transformer,$node)
        else 
          let $name := fn:local-name($node)
          let $func-name := xs:QName(fn:concat("tag:apply"))
          let $func-uri  := fn:concat(config:application-directory(response:application()),"/tags/",$name,"-tag.xqy")
          let $func := xdmp:function($func-name,$func-uri)
          return
             xdmp:apply($func,$node,response:response())
        
};
declare function engine:transform-echo($node as processing-instruction("echo")){
   let $value := fn:data($node)
   return
     xdmp:value($value)
};  
declare function engine:transform-xsl($node) {
   let $_node  := xdmp:unquote(fn:concat("<xsl ",fn:data($node),"/>"))/node()
   let $source := xdmp:value($_node/@source)
   let $params := if($_node/@params) then xdmp:value($_node/@params) else map:map()
   let $xsl    := $_node/@xsl
   return
       xdmp:xslt-invoke($xsl,$source,$params)
};

declare function engine:transform-to-json($node) {
   let $_node    := xdmp:unquote(fn:concat("<to-json ",fn:data($node),"/>"))/node()
   let $source   := xdmp:value($_node/@source)
   let $strategy := ($_node/@strategy,"full")[1]
   let $config   := json:config($strategy)
   return 
     xdmp:from-json(json:transform-to-json($source,$config))
};

declare function engine:get-role-names() {
   xdmp:eval('
     import module namespace sec="http://marklogic.com/xdmp/security" at 
         "/MarkLogic/security.xqy";
     sec:get-role-names(xdmp:get-current-roles()) ! xs:string(.)
   ',
   (),
   <options xmlns="xdmp:eval">
     <database>{xdmp:security-database()}</database>
   </options>)
};

declare function engine:transform-role($node) {
  let $tag_data := xdmp:unquote(fn:concat("<role ",fn:data($node)," />"))/*
  let $role-names := fn:tokenize($tag_data/@roles,",|\s") ! fn:normalize-space(.)
  let $endrole := $node/following-sibling::processing-instruction("endrole")[1]
  let $is_closed := if($endrole) then () else fn:error(xs:QName("MISSING-END-TAG"),"slot tag is missing end tag <?endrole?>")
  let $rolecontent := $node/following-sibling::node()[. << $endrole]
  let $admin-role := xdmp:role("admin")
  let $sys-roles :=  engine:get-role-names()
  let $_ := xdmp:log(($sys-roles,"rolenames:",$role-names))
  return
  (  engine:consume($endrole),
     if($sys-roles = $role-names) 
     then (     
        xdmp:log("Is in Role"),
        for $n in $rolecontent return (engine:transform($n),engine:consume($n))
     )
     else for $content in $rolecontent return engine:consume($content)
  )  
};
(:
  Core processing-instructions and any other data should be handled here
:)
declare function engine:transform($node as item())
{  
   if(engine:visited($node))
   then  ()    
   else(
       typeswitch($node)
         case processing-instruction("template") return engine:transform-template($node)
         case processing-instruction("view")     return engine:transform-view($node) 
         case processing-instruction("if")       return engine:transform-if($node)
         case processing-instruction("for")      return engine:transform-for($node)
         case processing-instruction("has_slot") return engine:transform-has_slot($node)
         case processing-instruction("slot")     return engine:transform-slot($node)
         case processing-instruction("echo")     return engine:transform-echo($node)
         case processing-instruction("xsl")      return engine:transform-xsl($node)
         case processing-instruction("to-json")  return engine:transform-to-json($node)
         case processing-instruction("role")     return engine:transform-role($node)
         case processing-instruction()           return engine:transform-dynamic($node)
         case element() return
           element {fn:node-name($node)}
           {
             for $n in $node/(@*|node())
             return engine:transform($n)
           }
         case attribute() return 
            if(fn:matches(fn:string($node),"<\?\i\c*\s(.*)\?>")) 
            then attribute {fn:name($node)} {for $n in xdmp:unquote(fn:concat("<node>",fn:data($node),"</node>"))/* return engine:transform($n)}                 
            else $node
         case text() return $node
         default return $node
     )    
};

(:~
 : Takes a sequence of parts and builds a uri normalizing out repeating slashes 
 : @param $parts URI Parts to join
 :)
declare function engine:normalize-uri(
  $parts as xs:string*
) as xs:string {
   engine:normalize-uri($parts,"")
 };
(:~
 : Takes a sequence of parts and builds a uri normalizing out repeating slashes 
 : @param $parts URI Parts to join
 : @param $base Base path to attach to 
~:)
declare function engine:normalize-uri(
  $parts as xs:string*,
  $base as xs:string
) as xs:string {
  let $uri := 
    fn:string-join(
        fn:tokenize(
          fn:string-join($parts ! fn:normalize-space(fn:data(.)),"/"),"/+")
    ,"/")
  let $final := fn:concat($base,$uri)
  return  
     if(fn:matches($final,"^(http(s)?://|/)"))
     then $final
     else "/" || $final 
};