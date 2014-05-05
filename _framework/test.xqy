xquery version "1.0-ml";

module namespace test = "http://xquerrail.com/unit-test";

import module namespace xray = "http://github.com/robwhitby/xray"
	at "./lib/xray/src/xray.xqy";

import module namespace assert = "http://github.com/robwhitby/xray/assertions"
	at "./lib/xray/src/assertions.xqy";

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


