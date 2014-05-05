Routing controls all incoming requests into your application.  Routing is maintained in your `/_config/routes.xml`. There are two types of routes in XQuerrail routing module, "Controller" routes and "Resource" routes. A route is composed of a id and a pattern(expressed as a Regular Expression), with some options to configure various redirection features.  Each routes options will be dependent on the type of route you are specifying.

To understand how routing works lets look at a few types of routes and how the options to write custom url endpoints.

##Resource Routes
Resource routes can be thought of as a passthrough routing for things like images,javascript, css files or anything that is not specifically controlled or requires management from XQuerrail.  A resource route is specified by specifying the `@is-resource` attribute to "true" on the route element.  It is important to define resource routes as close to the top and before any controller routes that may collide with the resource uri.  This allows XQuerrail to bypass processing all of the routes and returning the first match.  The default router by default will select the first matching route closest to the top of the routes.xml file.
 
```xml 
<routes  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://xquerrail.com/routing file:../_framework/schemas/routing.xsd">
   <!--Define Resources Before Controllers-->
   <route id="_resources" pattern="^/resources/*" is-resource="true">
      <prepend></prepend>
   </route>
   ...
</routes>
```

##Options for configuring resource routes

###to 

`<to>/path-to-actual-resource</to>` - Takes the current matched route in the pattern and calls the to endpoint.  This allows you to hide where an actual url is located to the given resource. The following route makes the call to the `/_framework/initialize` module relative to the root directory of your application.  

```xml
http://yourhost:port/initialize
  <route id="_initialize" pattern="initialize.xqy" is-resource="true">
      <to>/_framework/initialize.xqy</to>
   </route>
```

###prepend

`<prepend>/prepended-path</prepend>` - takes the value of the matched uri and prepends the value to the original uri.

```xml
  <route id="_initialize" pattern="/favicon.ico" is-resource="true">
      <prepend>/resources/</prepend>
   </route>
```

###replace

The replace element matches a pattern specified by the @match attribute and replaces it with the value specified in the `<replace>...</replace>` element text.  The following example matches uri that matches `/public/images/` and rewrites the output to `/public/img/`

`<replace match="regex-pattern">/replacement-uri</replace>` - takes the value of the matched uri and adds an additional match and replaced grouped patterns into a new url pattern. 
   <route id="_initialize" pattern="^/public/images/" is-resource="true">
      <replace match="images">img</replace>
   </route>
```xml
[Example Here]
```

##Controller Routes

Controller routes enable URLS to be routed to controller actions.  A controller route is implicitly defined by creating a route and not assigning the `@is-resource` attribute. There is only one subelement that is required to ensure proper routing to a controller called the `<default/>` element. You must specify the @key attribute to "_controller" and define the routing notation expressed in the form
`application:controller:action:format`. For example consider the following route below for mapping `/controller-name/` or `/controller-name` without trailing slash.  The purpose of the route is to execute the default function for a controller.  Since we want the route to be generic to cover all cases we use RegEx groups to extract out the controller name and assign it to the given controller as noted in example below:

```xml
<route id="demo_default_index" pattern="^/(\i\c*[^/])/?$" method="">
  <default key="_controller">demo:$1:index:html</default>    
</route>
```

##Mapping URI Parts using `param` element

Often when defining RESTful resource uri's you will want to use parts of the URL to represent parameters passed to your controller by name.  This can be achieved by using the param element in your controller.  The param element allows you to specify the param name using the `@key` attribute and a replacement pattern available from the uri part.  The following example shows a way to map RESTful routes for all controllers where the second part of the uri represents the id to retrieve a document

```xml
   <route id="controller_rest" pattern="^/(\i\c)*/(\w)*)$" method="get">
      <default key="_controller">application:$1:get:xml</default>
      <param key="id">$2</param>
   </route>
```

##Constraining routes by method type(POST|GET|PUT|DELETE)
Optionally you can specify that a route can match a given pattern but be constrained by the method type of the request. So the same url can matched but only if a route specifies the `@method` attribute then that route is selected over a route that matches but does not match the method parameter.

Consider the following route configuration to provide a rest based approach to creating/updating/deleting a resource.  Lets say that we want to map our controllers to use the same uri but vary the http-method to define what action is called.  When creating the uri we want our urls to be 

`/countries/CA[GET]` - Calls the get action for the countries whose ID is CA

```xml
<route id="restful-get" pattern="^/(\i\c*[^/])/(\w+)$" method="get">
  <default key="_controller">demo:$1:get:xml</default>  
  <param key="id">$1</param>    
</route>
```

```xml
/countries/CA[POST] - Updates the country CA whose ID is CA.
<route id="restful-get" pattern="^/(\i\c*[^/])/(\w+)$" method="post">
  <default key="_controller">demo:$1:post:xml</default>  
  <param key="id">$1</param>    
</route>
```

```xml
/countries/CA[DELETE] - Deletes the country whose ID is CA from database.
<route id="restful-get" pattern="^/(\i\c*[^/])/(\w+)$" method="delete">
  <default key="_controller">demo:$1:delete:xml</default>  
  <param key="id">$1</param>    
</route>
```
