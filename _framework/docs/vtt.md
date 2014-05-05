When building applications using various formats for output.  You will want to take advantage of XQuerrail's rich composition language and ability to compose output to handle the various output formats your application will require to render.  At a high-level, views and templates use the same underlying structure, except that views are controller specific and templates are reusable blocks of rendering logic that can be re-used.  


##Views
Views are controller specific main modules that express format specific output. To create a view you simply create a file in the `/views/(controller-name)/{controller}.{action}.{format}.xqy`. Once a view is created you simply add your html or xml specific xquery code to render the view.  The output could be a full xquery module or simply some static xhtml/xml output that uses ***tags***.  In the following example, the view uses tags to render simple output from the response

`/controller/hello.html?`
```xquery
<div xmlns="http://www.w3.org/1999/xhtml">
  <h2><?title?></h2>
  <div class="content">
    <?if response:data("name")?>
    	Hello <span><?echo response:data("name")?></span>
    <?else?>
        Who are you?
    <?endif?>
  </div>
</div>
```

> * It is important to note that you cannot use tags that are scoped to local data in your view module.  This is due to the fact that the processing of the tags happens in the rendering engine not the view. This is by design as the view should be only specific to rendering output and be simple enough to allow web developers to quickly write views without any xquery expertise.  But in the case you need to, you can just write Plain old XQuery to access locally defined variables.

To access response information you must import the response library, create a $response variable and initialize the response.in order to access it with values specified from your controller.To access the request you must import the request or use ML built-ins such as `xdmp:get-request-*` functions.  The following view imports the response

```xquery
(:Import the response module:)
import module namespace response  = "http://xquerrail.com/response" at "/_framework/response.xqy";
(:Declare the external variable name request:)
declare variable $response as map:map external;

(:Initialize the response to allow using response object:)
response:initialize($response),
(:Now write your xquery:)
let $somevar := response:body()/*:var
return
 <div xmlns="http://www.w3.org/1999/xhtml">
 {$somevar}
 </div>
```

> In a future release this requirement may not be necessary as we will automatically populate this via an internal mechanism of the response. The response is passed via an xdmp:invoke call, so the response is passed by value not referene, so changing the response in your view, will not be visible to the engine or other processing.


##Templates

Templates are expressed exactly like views but reside in the application template directory.  Templates should be reusable blocks of code that express composition and reuse across your application.  The advantage of using templates is that it allows you to compose smaller templates and combine them together in various ways. To create a template simply create a file in your template directory using the following convention `{template-name}.{format}.xqy`. 

The following example represents a default template that specifies importing other templates and places where all views will be rendered. 

`/application/templates/main.html.xqy`
```xml
<html xmlns="http://www.w3.org/1999/xhtml">
  <!--Represents the <head/>-->
    <?template name="head"?>
	<body>
      <?template name="header"?>
	  <div class="container">
	  	<?template name="sidebar"?>
	  	<div class="content">
          <?view?>
	  	</div>
	  </div>
	  <?template name="footer"?> 
	</body>
</html>
```

##Tags

Tags are basically processing-instructions, that are actually converted into function calls to render output.  XQuerrail provides a number of ***tags*** that are built-in such as boolean expressions, sequence processing, and various code evaluation such as xslt rendering.  Developers can actually implement their own tags that are expressed as custom library modules that implement the tag specification. Each format emits its own set of tags that are specific the type of format you outputting. The built-in tags are as follows for each format

###Global Tags

`<?template name="name"?>` - Renders a template at that specific location.

`<?view?>` - is a placeholder that specifies where the view will be rendered.  When using templates you will want all views to be rendered in a specific location in the layout.

`<?has_slot name="(name of slot)"?>...<?end_has_slot?>` - Returns the output of an expression if a slot is set in the response object.

`<?slot?>...<?endslot?>` - Provides a place holder for which when not provided the placeholder value is rendered.  If a response:slot value is set matching a key, then the body of the slot is rendered.

`<?if (expression)?>..<?else?>...<?endif?>` - Provides if/else conditional processing.

`<?echo (expression)?>` - Evaluates the value of the expression contained in the body of the processing-instruction.  This is a very simple way to evaluate any xquery code.

`<?for var="" in=""?>...<?elsefor?>..<?endfor?>` - Provides the ability to iterate over a sequence of values similar to a flwor expression.  Additionally, you can specify an output if the sequence of values is empty.

`<?role name=""?>...<?endrole?>` - Renders the sequence of nodes if the role assigned to current user matches the defined roles.

`<?xsl xsl="(uri-of-xsl)" source="(expression)" ?>` - Executes an xslt stylesheet against the specified source

`<?to-json?>` - Use the built-in json:transform-to-json to generate json outpu.

###HTML specific tags

`<?title?>` - Renders the title specified in the response:title() function

`<?include-metas?>` - Renders the `<meta/>` html elements specified using the response:metas()

`<?include-http-metas?>` - Renders an `<http-meta/>` tag for each value specified in reponse:http-metas() function

`<?controller-script?>` - Renders an `<script/>` tag pointing the a controller javascript resource. If the file does not exist the tag will not be rendered.

`<?controller-stylesheet?>` - Renders the `<link/>` attribute pointing to a css stylesheet resource.  If the file does not exist the tag will not be rendered.

`<?controller-list (class="") (uiclass="") ?>` - Returns a `<ul><li><a href=""/>` element with a list of all controller specified in the application domain.   

**Options**
* **@class** - Specifying the @class attribute will filter those controllers that match a given @class attribute are rendered. 
* **@uiclass** - Specifies the @uiclass adds a class attribute to the `<ul/>` element.
* **@id** - Adds an @id to the `xml<ul/>`.
* **@itemclass** - adds an additional @class attribute to each `<li/>` element.

`<?javascript-include?>` - Renders a `<script/>` tag that @src=`{resource-directory}/js/*`.  You only need to match the name and the include file will handle the extension for you<sup>*</sup>.  

`<?stylesheet-include?>` - Renders a `<link/>` tag that @href=`{resource-directory}/css/{filename}`. You only need to match the name and the include file `.css` extension for you.<sup>*</sup>.  


**If the resource is nested in a folder under the resource base directory you must return the relative path of the file to the directory.

###Creating your own application tags

When the default tags are not enough and you would like to implement your own. A tag is a library module following the naming convention for tags and implement the required tag functions.  The naming convention for tags is `/tags/{tag-name}-tag.xqy`.  There a few functions that can be implemented to support how a tag gets called, but the only tag that is required is the `tag:apply()` function.  The basic structure of a tag module is as follows:

```xquery
module namespace tag = "http://xquerrail.com/tag";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy"

(:Renders the tag:)
declare function tag:apply(
	$tag as processing-instruction(), 
	$response as map:map
) { ... };

(:Parse the tag into a representation used from a downstream process 
 such as a posted back value from your tag
:)
declare function tag:parse(
	$tag as processing-instruction(),
	$request as map:map
) { ... };

```

The following example reads in the value of the response:body() and outputs it in a `<pre/>` tag.

`/tags/hello-tag.xqy`
```xquery
module namespace tag = "http://xquerrail.com/tag";
import module namespace response = "http://xquerrail.com/response"
   at "/_framework/response.xqy";
(:The :)   
declare function tag:apply($tag as processing-instruction() ,$response as map:map)
{
   response:initialize($response),
   let $mode  := ($_node/@mode,"edit")[1]
   let $size  := ($_node/@size,"small")[1]
   let $_ := formbuilder:mode($mode)
   let $_ := formbuilder:size($size)
   let $control := formbuilder:form-field(response:model(),fn:data($_node/@name))
   return
     if($control) then $control else (xdmp:log(("form:field::",response:model())),<div>Error</div>)
};

``` 

* Tags are not format specific like templates as you are free to express any output you would like and specify how the output is rendered. 