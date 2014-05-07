(:
Copyright 2014 MarkLogic Corporation

XQuerrail - blabla
:)

xquery version "1.0-ml";

module namespace generator = "http://xquerrail.com/generator/xray";

import module namespace base = "http://xquerrail.com/generator" at "generator.base.xqy";

declare function generator:default-template() {
  <base:template>
     import module namespace xray = "http://marklogic.com/unittest/";
     
     declare function xray:setup() {{
        ()
     }};
     declare function xray:teardown() {{
        ()
     }};
     <?functions?>
     declare function %test xray:<?function-name?>-test() {{
        assert:notImplemented()
     }};
     <?_function?>
     <?_functions?>
  </base:template>
};

declare function base-options() {
    <options>
        <location>/_framework/base/base-model.xqy</location>
        <namespace>http://xquerrail.com/model/base</namespace>
        <target>/tests/_framework/base/base-model.test.xqy</target>
    </options>
};

declare function generate-library-tests(
$template as element(base:template)
$configuration as element(base:options)
)  {
  () 
};