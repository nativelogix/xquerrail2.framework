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

import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare option xdmp:output "indent-untyped=yes";

declare variable $response as map:map external;

response:initialize($response),
<div id="search-wrapper" class="row-fluid">
<div>
    <div class="row-fluid spacer">
        <div class="span3">
          <h4>Search</h4>
        </div>
        <form class="form-search span9">
            <div class="input-append span12">
                <input class="search-query span11" id="appendedInputButton"  type="text" />
                <button class="btn btn-primary" type="submit">Search</button>
            </div>
        </form>
    </div>
    <div class="row-fluid">
    <div class="span3">
        <div class="well sidebar-nav">
            <ul class="nav nav-list">
                <li class="nav-header">{{ facetGroupName | facetGroupLabel }}</li>
                <li >{{ facetValue.name }} ({{ facetValue.count }})</li>
                <br />
            </ul>
        </div><!--/.well -->
    </div><!--/span-->
    <div class="span9">
        <div class="row-fluid">
            <div class="span4">
            
            </div>
        </div>
    </div><!--/span-->
</div><!--/row-->
</div>
</div>