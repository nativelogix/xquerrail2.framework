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

module namespace test = "http://xquerrail.com/unit-test";

import module namespace xray = "http://github.com/robwhitby/xray" at "./lib/xray/src/xray.xqy";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "./lib/xray/src/assertions.xqy";

declare variable $ANNOTATIONS = (
  xs:QName("test:case"),
  xs:QName("test:setup"),
  xs:QName("test:teardown")
);

declare function test:directories() {
	"/test/"
};
(:~
 : 	
~:)
declare function test:run-tests() {

};


