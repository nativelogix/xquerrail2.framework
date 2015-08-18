xquery version "1.0-ml";

module namespace extension = "http://xquerrail.com/domain/extension";

import module namespace config = "http://xquerrail.com/config"  at "/main/_framework/config.xqy";
import module namespace domain = "http://xquerrail.com/domain"  at "/main/_framework/domain.xqy";

declare option xdmp:mapping "false";

(:~
 : Here is the initialize function invoked by dispatcher before any other custom functions
~:)
declare function extension:initialize(
  $request as map:map?
) as empty-sequence() {
  ()
};

(:~
 : Provide a domain extension
~:)
declare function extension:build-domain-extension(
  $application-name as xs:string,
  $domain as element(domain:domain)
) as element(domain:domain) {
  <domain xmlns="http://xquerrail.com/domain">
    <model name="dynamic-model1" persistence="directory" label="Dnyamic Model #1" extends="base" namespace-uri="http://marklogic.com/model/model1" key="uuid" keyLabel="id">
      <directory>/test/dynamic-model1/</directory>
      <element name="id" type="string" label="Id"/>
      <element name="name" type="string" label="Name"/>
    </model>
    <controller name="dynamic-model1" model="dynamic-model1"/>
    <model name="dynamic-model2" persistence="directory" label="Dynamic Model #2" extends="base" namespace-uri="http://marklogic.com/model/model2" key="uuid" keyLabel="id">
      <directory>/test/dynamic-model1/</directory>
      <element name="id" type="string" label="Id"/>
      <element name="name" type="string" label="Name"/>
    </model>
    <controller name="dynamic-model2" model="dynamic-model2"/>
  </domain>
};
