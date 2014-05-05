import module namespace domain = "http://xquerrail.com/domain"
    at "/_framework/domain.xqy";

import module namespace response  ="http://xquerrail.com/response"
    at "/_framework/response.xqy";

import module namespace model-helper = "http://xquerrail.com/helper/model"
    at "/_framework/helpers/model-helper.xqy";
    
declare variable $response as map:map external;

response:initialize($response),()
