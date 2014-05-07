In the most basic terms a controller takes information from an incoming request and returns a response either directly or via the response library. The functionality of the controller is to return some output that will be used to further render the required response.  

##Configuring your first controller

Creating a controller is starts by creating a file in your `/application/controller/` directory.  The filename must match the convention `{controller-name}-controller.xqy`.  Also how you define your module namespace is very important as it must start with your application @namespace, followed by `/controller/` and finally the name of your controller (ex. `/app/controller/countryCodes`.  
```
(:/app/controller/countries-controller.xqy:)
(:Module Namespace Header:)
module namespace controller = "http://my-application-namespace/controller/my-controller-name";
...
(:Any libraries:)
...
(:All functions :)
```
The convention allows XQuerrail to properly route requests to your controller actions.  Any differences in the conventions will cause failures to find the module matching your controller definition.  

Your first controller will require a few imports to ensure all request/responses managed by your controller functions can see the global scope, but not necessarily a requirement.  Your actions do not take arguments as all arguments are passed via the request object. So it makes your code modular enough to accept new parameters without having to change your action signature.

```xquery
xquery version "1.0-ml";
(:Define your namespace and controller name:)
module namespace controller = "http://myapp/demo/controller/my-controller-name";
(:Required Imports:)
import module namespace request = "http://xquerrail.com/request" at "/_framework/request.xqy";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";
(:Each action is a function that takes zero arguments:)
(:Accessing parameters is done through making calls the request:param() function :)
declare function controller:index() {...};
declare function controller:get() {...};
declare function controller:delete() {...};
```

##Accessing Request Methods

All request information is accessible via the request library that was imported into your controller library.  The request library wraps all http request data including headers, parameters and any additional http data.  It also include convenient functions for common http headers and reading cookie data.  The purpose of using the request library functions vs. the xdmp:get-request-** function is that it allows your controller to be tested without the need for an actual HTTP context.  Another advantage of using request functions is that it supports changing the incoming request and passing between different modules. In actuality the request is just a map:map and the functions common to an http context.  Each xdmp:get-request-* function has an equivalent request function, but the syntax varies a bit.  In the XQuerrail request context `xdmp:get-request-field-*` are actually just named `request:param` and `xdmp:get-request-header-*` is simply is `request:header*`. See documentation for request library for all functions available. In the following example the controller action(function) is reading request and building a request.

```xquery
declare function controller:my-action() {
  let $param           := request:param("my-parameter")
  let $param-w-default := request:param("param-w-default","true")
  let $content-type    := request:header("Content-Type")
  let $accept          := request:header("Accept")
  return
    (...)
};
```

##Creating a Response

A response is simply anything you return from your controller actions.  A basic can response can be a direct xml output or a response map:map.  The value of using the response library is it allows you to additionally add header, set various response options, such as setting slots(information about templates).  The following example the controller just returns a simple xml representation of the parameter passed from the request.

```xquery 
/hello/world.xml?name=Bob
module namespace hello = "http://myapplication/controller/hello";
declare function hello:world() {
  <hello>{request:param("name")}</hello>
};
```

A more complicated example sets various response options.  You will notice that the last value in the sequence is the response:flush() method which basically just returns the map as the output of the controller.  

```xquery
declare function controller:index()
{(
    response:set-controller("default"),
    response:set-action("index"),
    response:set-template("main"),
    response:set-view("index"),
    response:set-title(fn:concat("Welcome: ",request:user()),
    response:add-httpmeta("cache-control","public"),
    response:flush()
)};
```

##Using the response:* library
The response library module provides alot of features for outputting content for various formats.  The response library does not specially generate anything other than a map:map which is then rendered via a rendering engine(see [Rendering Engine|rendering].  The basic output for a response object is the `response:set-body($output)` setter method. Based on the format of the request the appropriate engine will be called to render any view specific or format specific output.

###Data Methods
`response:set-body($body as item()*)` - Sets the main output value. There are various places to add to the response.

`response:set-data($data as item()*)` - Sets any specific output data used to possibly render the output.  There is no 
restriction to what you pass in.

`response:set-slot($name, $data)` - A slot is special output directive that is used in rendering/templating engine to override a slot(data placeholder).  

###Output Methods

`response:add-header($key,$value)` - Adds a response header to the output.

`response:redirect($uri)` - Immediately redirects the response to a url instead of rendering a view.

`response:set-error($code,$message)` - Throws an error with a specific code.

`response:set-code($code)` - Sets the response code for the http response.

`response:flush()` - Just outputs the response map. The response map uses the keys defined in the response library and adds a special key to distinguish the output from a simple map.

###Context Functions
`response:set-controller($name)` - This call does not change the controller or invoke the controller, it only makes the rendering(engine) switch the context to that controller.  Useful if delegating responsiblity to another controllers view logic.

`response:set-action($name)` - same as controller but again only changes the name of the context response's action.

`response:set-template($name)` - sets the main template used to render the response.

`response:set-view($name)` - sets the view used to render the response. This allows actions to represent multiple views or vice versa.

##Best Practices for Controller Logic.

There are a few convention you should follow in general to ensure maximum re-usability of your controller logic. 
* Keep your controllers as light-weight as possible. Use controllers to broker communication between libraries and view logic.  If you are persisting or providing complex business logic, favor encapsulating those into other library modules  and communicating with them by importing them. 
* Try to not render any format specific output such as html.  Use views to provide different representations for the same output.
* Make the output of your response encapsulate all the information required to render the view. 


##Extending/Overriding Scaffolded Controllers.

[TODO]
