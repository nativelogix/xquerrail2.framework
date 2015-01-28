xquery version "1.0-ml";
(:~ 

Copyright 2011 - NativeLogix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.




 :)

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