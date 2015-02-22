xquery version "1.0-ml";

import module namespace request = "http://xquerrail.com/request" at "../../request.xqy";
import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";
import module namespace model-helper = "http://xquerrail.com/helper/model" at "../../helpers/model-helper.xqy";
import module namespace domain = "http://xquerrail.com/domain" at "../../domain.xqy";
import module namespace js = "http://xquerrail.com/helper/javascript" at "../../helpers/javascript-helper.xqy";

declare namespace search = "http://marklogic.com/appservices/search";

declare variable $response as map:map external;

response:initialize($response),
let $node := response:body()
let $model := domain:get-domain-model($node/@type)
return
  if($model) then
    <x>{
      js:object((
        js:entry("response",js:object((
          js:keyvalue("_type",$node/@type cast as xs:string),
          js:keyvalue("page",$node/@page),
          js:keyvalue("snippet_format",$node/@snippet-format),
          js:keyvalue("total",$node/@total),
          js:keyvalue("start",$node/@start),
          js:keyvalue("page_length",$node/@page-length),
          js:entry("results",
            js:array(
              for $result in $node/search:result
              return
                js:object((
                  js:keyvalue("index",$result/@index),
                  js:keyvalue("uri",$result/@uri),
                  js:keyvalue("path",$result/@start),
                  js:keyvalue("score",$result/@score),
                  js:keyvalue("confidence",$result/@confidence),
                  js:keyvalue("fitness",$result/@fitness),
                  js:entry("metadata",js:object(
                    for $meta in $result/search:metadata/*
                    return js:keyvalue(fn:local-name($meta),fn:data($meta))
                  )),
                  js:entry("snippets",
                    js:array(
                      for $snippet in $result/search:snippet
                      return
                        js:entry("matches",js:array(
                          for $match in $snippet/node()
                          return
                            typeswitch($match)
                            case element(search:match) return
                              js:object((
                                js:keyvalue("path",$match/@path),
                                js:keyvalue("text",$match/text())
                              ))
                            case text() return $match
                            default return ()
                        ))
                    )
                  )
                ))
            )
          ),
          (:Facets:)
          js:entry("facets",js:array(
            for $facet in $node/search:facet
            return
              js:entry("facet",
                js:object((
                  js:keyvalue("name",$facet/@name),
                  js:keyvalue("type",$facet/@type),
                  js:entry("values",js:array(
                    for $value in $facet/search:facet-value
                    return js:object((
                      js:keyvalue("name",$value/@name),
                      js:keyvalue("count",$value/@count cast as xs:integer)
                    ))
                  ))
                ))
              )
          )),
          (:QText:)
          js:entry("qtext",js:array(
            for $qtext in $node/search:qtext
            return fn:string($qtext)
          )),
          (:QText:)
          js:entry("query",js:array(
            cts:query($node/search:query/node())
          )),
          (:Metrics:)
          js:entry("metrics",js:object(
            $node/search:metrics ! (
              js:keyvalue("query_time",./search:query-resolution-time),
              js:keyvalue("facet_time",./search:facet-resolution-time),
              js:keyvalue("snippet_time",./search:snippet-resolution-time),
              js:keyvalue("metadata_time",./search:metadata-resolution-time),
              js:keyvalue("total_time",./search:total_time)
            )
          ))
        )))
      ))
    }</x>/*
  else
    ()
