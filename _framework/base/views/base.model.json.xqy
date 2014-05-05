xquery version "1.0-ml";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";
import module namespace jsh = "http://xquerrail.com/helper/javascript"
    at "/_framework/helpers/javascript-helper.xqy";

import module namespace domain  = "http://xquerrail.com/domain"
    at "/_framework/domain.xqy";

declare variable $response as map:map external;
declare function domain:build-json($context) {
   typeswitch($context)
    case element(domain:domain) return
      ()
    case element(domain:model) return 
      jsh:e("model",jsh:o((
       for $attr in $context/@*
       return jsh:e(fn:local-name($attr),fn:data($attr)),
       $context/(domain:directory|domain:document|domain:navigation) ! domain:build-json(.),
       jsh:e("fields",jsh:a((
          for $node in $context/(domain:element|domain:attribute|domain:container)
          return domain:build-json($node)          
       ))),
       jsh:e("optionlists",jsh:a((
          for $node in $context/domain:optionlist
          return domain:build-json($node)          
          ))
       ),
       domain:get-model-controller($context/@name) ! domain:build-json(.)
    )))
    case element(domain:binaryDirectory) return
      jsh:e("binaryDirectory", jsh:e("uri",fn:data($context)))  
    case element(domain:directory) return 
      jsh:e("directory", jsh:e("uri",fn:data($context)))    
    case element(domain:document) return 
       jsh:e("document", jsh:o((
            jsh:e("uri",fn:data($context)),
            jsh:e("root",fn:data($context/@root))
       )))
    case element(domain:element) return 
     jsh:o((
            jsh:e("_type","element"),
            for $attr in $context/@*
            return jsh:e(fn:local-name($attr),fn:data($attr)),
            if($context/(domain:attribute|domain:element|domain:container)) then 
                for $node in $context/(domain:attribute|domain:element)
                return 
                   domain:build-json($node)
            else (),
            $context/(domain:navigation|domain:constraint|domain:ui) ! domain:build-json(.)            
       ))
    case element(domain:attribute) return 
         jsh:o((
            for $attr in $context/@*
            return jsh:e(fn:local-name($attr),fn:data($attr)),
            $context/(domain:navigation|domain:constraint|domain:ui) ! domain:build-json(.)     
       ))
    case element(domain:container) return 
         jsh:o((
            jsh:e("_schemaType","element"),
            $context/@name ! jsh:e("name",fn:data(.)),
            jsh:e("namespace",fn:data($context/@namespace)),
            jsh:e("prefix",fn:data($context/@prefix)), 
            jsh:e("label",fn:data($context/@label)),
            jsh:e("description",fn:data($context/@description)),
            jsh:e("fields",jsh:a(
            if($context/(domain:attribute|domain:element))
            then for $node in $context/(domain:attribute|domain:element)
                 return 
                     domain:build-json($node)
            else ()  
            )),
            $context/(domain:navigation|domain:constraint|domain:ui) ! domain:build-json(.)
       ))
    case element(domain:navigation) return 
      jsh:e("navigation",jsh:o((
        for $nav in $context/@*
        return
          jsh:e(fn:local-name($nav),fn:data($nav))
       )))
    case element(domain:ui) return 
        jsh:e("ui",jsh:o(
          for $nav in $context/@*
          return jsh:e(fn:local-name($nav),fn:data($nav))
        ))
    case element(domain:constraint) return 
       jsh:e("constraint",jsh:o((
       for $nav in $context/@*
       return jsh:e(fn:local-name($nav),fn:data($nav))
       )))
    case element(domain:controller) return
       jsh:e("controller",jsh:o((
          for $nav in $context/@*
          return jsh:e(fn:local-name($nav),fn:data($nav)),
          jsh:e("actions",domain:get-controller-actions($context/@name))
          ))
       )
    case element(domain:optionlist) return
       jsh:o((
       for $nav in $context/@*
       return jsh:e(fn:local-name($nav),fn:data($nav)),
       jsh:e("options",jsh:a((
        for $option in $context/domain:option
        return
            jsh:o((
                jsh:e("label",fn:data(($option/@label,$option/text())[1])),
                jsh:e("value",fn:data($option))
            ))
       )))
       ))
    default return fn:error((),"NO Parsing for", fn:local-name($context))
};
response:initialize($response),
domain:build-json(response:model())
