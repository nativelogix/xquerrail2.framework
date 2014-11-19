import module namespace domain = "http://xquerrail.com/domain" at "../../domain.xqy";

import module namespace response  ="http://xquerrail.com/response" at "../../response.xqy";

import module namespace model-helper = "http://xquerrail.com/helper/model" at "../../helpers/model-helper.xqy";
    
declare variable $response as map:map external;

response:initialize($response),()
