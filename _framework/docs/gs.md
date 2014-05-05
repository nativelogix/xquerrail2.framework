##Configuring XQuerrail in MarkLogic

Getting started with XQuerrail is pretty straightforward. You will need to configure your MarkLogic Database and Application servers and configure some settingsin your application server.


### Installation Instructions
* Download XQuerrail2 from git.
* Install into local machine accessible from your MarkLogic install.
* Create a database and forest to house your application

###Setup for application server
* Create an http application server that points to the XQuerrail2 source.
*  Set the root to `{filesystem-dir}/src` directory
*  Set the rewriter to `/_framework/rewriter.xqy`
 * If you are using application-level security you will need to configure the **anonymous-user** and **xquerrail **roles to ensure you have the appropriate access to your application code.
 * See (roles and user setup page)
* Navigate to the url specified by the application server.

##XQuerrail Directory Structure
Out of the box when you download xquerrail2 there is a demo application that is prewired with some basic templates and views to get you started.  The first thing you will want to establish the definition of your application. All configuration files for xquerrail2 are located in the `/_config/` directory.

###Configuration Files
All configuration files are located under the `/src/_config/` directory:
* `config.xml` - Provides the configuration options for the xquerrail framework and all applications
* `routes.xml` - Defines the how xquerrail will route incoming url-requests to controllers and resources. See Routing for specific details on how to configure routing.
* `ml-security.xml` - Defines the configuration for using the ml-security interceptor. This provides basic support for using application-level authentication. You can adapt this interceptor to support write your own custom authentication provider.
* `compressor.xml` - Defines the configuration for using the compressor interceptor. The compression interceptor allows for the ability to configure compression of output for controllers. 

###The "Framework" 

The XQuerrail framework is encapsulated in a single directory that drives all the features. The following outlines the directory structure for the XQuerrail framework and the functions for each file:
* `/_framework` - Global directory for xquerrail internals
 * `/base/` -  Provides the base implementation for all global controller, model, views and templates and most of the dynamic features for building applications.
 * `/dispatchers/` - Dispatchers are "Front Controllers" that provide the routing for all incoming controller requests and outgoing responses.
 * `/docs/` - Any XQuerrail specific documentation 
 * `/engines/` - Engines are responsible for all transformation and response rendering of views and templates. When building multi-concern applications between html/rest via json or xml. The rendering "engine" is the final modules responsible for all output.
 * `/handlers/` - Like dispatchers, handlers are responsible for resource output such for any public resources or non-controller requests.  The handler is responsible for composing the output for delivery. This includes adding compression, cache headers and any other type of custom logic before rendering resources.
 * `/helpers/` - Helpers are libraries that provide some powerful utilities to help interact with framework features. Features such as rendering json, html form building.  
 * `/interceptors/` - Interceptors provide dependency injection by allowing developers to implement a seperation of concerns.  Interceptors provide features like security, compression and authorization.
 * `/lib/` - Provide third party dependencies such as cprof, xray, xquery-docs, and xquery parsing libraries. In "coming release" these dependencies will be managed via a package manager for inclusion in your application
 * `/schemas/` - Provides schema definitions for all configuration files and documentation on the schemas.  This allows some editors to attach to schemas and provide type-ahead support and validation when building config files. 

### Resource and Public directories

`/resources/`
XQuerrail provides a default resource directory to store common js, css and img files. The resource directory operate outside of the framework and can pretty much have any type of file or even xquery code.  The `routes.xml` configuration defines which folder(s) serve as resource directories. If you like to call your resource directory as something else like say "public" then you can simply locate the resource route inside the routes.xml to change it to a different folder name.


