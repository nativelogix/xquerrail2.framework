##Helper Libraries

XQuerrail provides many helper libraries to perform various functions such as building html forms, creating json or basic utilities bundled with the core framework. There are 3 primary helpers defined in XQuerrail.

###"form" helper
```xquery
import module namespace form = "http://xquerrail.com/helper/form"  at "/_framework/helpers/form-helper.xqy";
```

The form-helper provides features for building html forms from existing domain models or grid models to use with Javascript Grid libraries.  XQuerrail uses the form-helper to generate all dynamic html forms and index grids defined in `/_framework/base/views/`.  The notable uses are in the `base.new.html.xqy` and the `base.edit.html.xqy`.  The form-helper defines functions that accept a `<domain:field>` definition from the domain-model and builds the appropriate html output necessary to create/edit/update new model instances.  There are many functions but the following outline the core functions and their usage:

<table cellpadding="1" cellspan="1" border="1">
  <tr>
    <th width="200">Function</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>**form:build-form**</td>
    <td>Creates a HTML from a defined domain model.  The form helper uses the XQuerrail Type System to render various html components defined by your model. 
    </td>
  </tr>
  <tr>
    <td>**form:form-field**</td>
    <td>Creates the html representation of model field.</td>
  <tr>
  <tr>
    <td>**form:field-grid**</td>
    <td>Creates the html representation of model field.</td>
  <tr>
  <tr>
    <td>**form:form-field**</td>
    <td>Creates the html representation of model field.</td>
  <tr>
</table>

##"javascript" helper
```xquery
import module namespace js = "http://xquerrail.com/helper/javascript"  at "/_framework/helpers/javascript-helper.xqy";
```

The `javascript-helper` is provides a functional way to compose json objects. THe helper provides functions to create json representations.  There is a common need to expressively render json using a functional syntax that emits json using functions.  For example lets compose a json object using the helper functions. 

```javascript
 import module namespace helper = "http://xquerrail.com/helper/javascript" at "/_framework/helper/javascript.xqy";
 
  js:o((
    js:e("hello-world","Bob"),
    js:a((1,2,3,4,5))
  ))
 [Returns]
 {
   "hello-world" : "Bob",
   [1,2,3,4,5]
 }
```

###"json" helper


```xquery
import module namespace js = "http://xquerrail.com/helper/javascript"  at "/_framework/helpers/javascript-helper.xqy";
```

The `json-helper` library is an automated way of creating json from xml and vice versa.  Its purpose is to try to create json to xml and xml to json mapping without any user directives.  This is helpful if the output you are creating is custom xml output, but require some simple json rendering.