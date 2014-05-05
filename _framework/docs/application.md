The first thing you will want to do is establish the default behavior of your XQuerrail application. This is configured in the `/_config/config.xml`.  XQuerrail by default is configured to act as an html/rest based application.  This means that any requests that do not specify a format extension such as .html or .xml will automatically be routed to the html engine for processing.  In order to configure your first app you will only need to configure the `<application/>` definition.

##Configuring your application
* Locate the default entry in your `config.xml` called `<application name="demo">...`
* Here is an example of the demo configuration:
```xml
    <application name="demo" namespace="http://xquerrail.com/demo" uri="/demo">
        <domain resource="/demo/domains/application-domain.xml" />
        <script-directory value="/demo/resources/js/"/>
        <stylesheet-directory value="/demo/resources/css/"/>
        <default-template value="main"/>
    </application>
```

<table border="1" cellpadding="1" cell-spacing="1">
  <tr>
    <th width="300">Option</td>
    <th>Description</th>
  </tr>
  <tr>
    <td>`@name`</td>
    <td> defines your application name.  This will be used to express any context information and how XQuerrail calls into your application.</td>
  </tr>
  <tr>
 <tr>
   <td>`@namespace`</td>
   <td>Establishes the default namespace that will be used across your application code.  The namespace should be meaningful to your application</td>
</tr>
<tr>    
<td>`@uri`</td>
<td>directory where the source code for your application will reside.  XQuerrail will use this to establish calls to your application controllers/views and other features exposed from your application.</td>
</tr>
<tr>
  <td>`<domain @resource="..."/>`
  <td> - Is the default entry domain used by your application.  This must be present to use any dynamic scaffolding (see Domain Models).
  </td>
</tr>
<tr>
<td>`<script-directory value="..."/>`</td>
<td>Configures the location of your application specific javascript resources.</td>    
</tr>
<tr>
<td>`<stylesheet-directory value="..."/>`</td>
<td> - Configures the location of your application specific css files.</td>
</tr>
<tr><td>`<default-template value="..."/>`</td><td> - Configures the default template used to when a template is not specified by your controllers or the `<default-template>` in the /config/default-template</td>
</td>
</table>

##Structuring your Application Directory

It is important to establish a proper application directory structure in order for XQuerrail to route calls appropriately to your application.  Remember XQuerrail uses conventions to call into your application so following the default conventions will ensure proper routing to your application.  The following outlines the directory conventions used in xquerrail applicaton.

```
 /src/
   /_config/
   /_framework/
   /{application-name}/
     + /controllers/
     +  /domains/
     +  /models/
     + /resources/
     + /tags/
     + /templates/ 
     + /views/
  /resources/
 
```

###XQuerrail Directory Requirements


<table cellpadding="1" cellspacing="1">
<tr>
  <th>Directory</th>
  <th>Required</th>
  <th>Description</th>
</tr>
<tr><td colspan="2">`/{application-name}/`</td><td>Should map to the @uri specified in config.xml</td></tr>
</td></tr>
<tr><td>`/controllers/`</td><td>Required</td><td>Contains all controllers for your application.  XQuerrail will look into this directory when routing calls to your application.
</td></tr>
<tr><td>`/domains/`</td><td>Optional</td><td>Contains all domain configuration. The `application-domain.xml` is required if using any dynamic scaffolding features in XQuerrail.
</tr></tr>
<tr><td> `/resources/`</td><td>Optional</td><td>While note specifically required ,the resource directory should match your naming conventions for your public /resources/ directory.  
</td></tr>
<tr><td>  `/tags/`</td><td>Optional</td><td>Contains all the custom tags for your application.  Tags provides a mechanism to create your own custom tab libraries used in your templates and views.
</td></tr>
<tr><td>  `/templates/`</td><td>Optional</td><td>Contains all the templates specified for your applications.
</td></tr>
<tr><td>  `/views/`</td><td>Optional</td><td>Is the directory where your application views will be maintained. The convention for creating views are based on the names of your controllers.  So if you defined a controller named foo then you will create a folder called `/your-application/views/foo/`.  
</td></tr> 
 </table>
