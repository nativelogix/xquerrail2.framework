##Configuring XQuerrail

The following documentation provides all the configuration options defined in the `/_config.xqy`
The `<config>` element must conform to the definition in the `/_framework/schemas/config.xsd` and be in the namespace `http://xquerrail.com/config`.

```xml
<config xmlns="http://xquerrail.com/config" xsi:schemaLocation="http://xquerrail.com/config ../_framework/schemas/config.xsd">
  ...
</config>
```

`<routes-config resource="..."/>` - Determines the configuration xml file that will be used to evaluate the incoming request url against.

`<routes-module resource="..."/>` - Defines the module that will generate the routing URL from the request. This allows a custom implementation routing module.

`<interceptor-config resource="">` - Defines the configuration that will be used to configure interceptors.

`<interceptor-module resource="..."/>` - Defines the module that will manage the interception calls.  This allows user to create a custom interception module.
