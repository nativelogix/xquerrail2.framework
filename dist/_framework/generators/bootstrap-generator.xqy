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

module namespace extension = "http://xquerrail.com/application/extension";

import module namespace config = "http://xquerrail.com/config" at "../config.xqy";
import module namespace cache = "http://xquerrail.com/cache" at "../cache.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../domain.xqy";
import module namespace generator = "http://xquerrail.com/generator/base" at "generator-base.xqy";

declare option xdmp:mapping "false";

declare variable $USE-MODULES-DB := (xdmp:modules-database() ne 0);

declare function extension:initialize(
) as empty-sequence() {
  xdmp:log("extension:initialize"),
  (for $model in domain:get-models()
    let $functor :=
      generator:generate-main-module($model,
        map:new((
          map:entry("output-directory","_generated_"),
          map:entry("format","map"),
          map:entry("build","inline"),
          map:entry("functions",("create","update"))
      ))
    )
    return generator:get-generator(
      xdmp:key-from-QName(domain:get-field-qname($model)),
      "build"
    )
  )[0],
  cache:set-domain-cache($cache:SERVER-FIELD-CACHE-LOCATION, $generator:ENABLE-GENERATOR-KEY, fn:true())
};

declare function extension:reset(
) as empty-sequence() {
  generator:reset()
};
