(:@GENERATED@:)
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
declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace response = "http://xquerrail.com/response" at "../../response.xqy";

import module namespace domain = "http://xquerrail.com/domain" at "../../domain.xqy";

import module namespace js = "http://xquerrail.com/helper/javascript" at "../../helpers/javascript-helper.xqy";
import module namespace form = "http://xquerrail.com/helper/form" at "../../helpers/form-helper.xqy";


declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

declare variable $default-col-width := 40;
declare variable $default-resizable := fn:true();
declare variable $default-sortable  := fn:false();
declare variable $default-pagesize  := 100;

let $init := response:initialize($response)
let $domain-model := response:model()
let $model := $domain-model
let $model-editable := fn:not($domain-model/domain:navigation/@newable eq "false")
let $modelName := fn:data($domain-model/@name)
let $modelLabel := (fn:data($domain-model/@label),$modelName)[1]
let $gridCols := 
    js:json(js:array(
      for $item in $domain-model//(domain:element|domain:attribute)
      return form:field-grid-column($item)))
let $editButtons := 
     js:json(
       js:o((
         js:kv("search",xs:boolean(($model/domain:navigation/@searchable,"true")[1])),
         js:kv("new",   xs:boolean(($model/domain:navigation/@newable,"true")[1])),
         js:kv("edit",  xs:boolean(($model/domain:navigation/@editable,"true")[1])),
         js:kv("delete",xs:boolean(($model/domain:navigation/@removable,"true")[1])),
         js:kv("show",  xs:boolean(($model/domain:navigation/@showable,"false")[1])),
         js:kv("import",xs:boolean(($model/domain:navigation/@importable,"false")[1])),
         js:kv("export",xs:boolean(($model/domain:navigation/@exportable,"false")[1]))
     )))
(:let $uuidMap :=  fn:string(<stmt>{{ name:'uuid', label:'UUID', index:'uuid',hidden:true }}</stmt>):)
let $uuidMap := js:json(js:o((
                     js:kv("name","uuid"),
                     js:kv("label","UUID"),
                     js:kv("index","uuid"),
                     js:kv("hidden",fn:true())
                )))
let $uuidKey := domain:get-field-id($domain-model/domain:element[@name = "uuid"])

let $model-sort-field  := domain:get-field-name-key(domain:get-model-field($model, $model/domain:navigation/@sortField/fn:data(.)))
let $model-order       := ($model/domain:navigation/@sortOrder/fn:data(.),"asc")[1]
let $model-order := 
  if ($model-order eq "ascending") then
    "asc"
  else if ($model-order eq "descending") then
    "desc"
  else
    $model-order

(:Editable:)
let $editAction := 
    if($model-editable) 
    then <node>window.location.href = "/{response:controller()}/edit.html?" + context.modelId +  '=' + rowid;</node>/text()
    else <node>window.location.href = "/{response:controller()}/details.html?" + context.modelId +  '=' + rowid;</node>/text()
return
<div class="box">
<div class="box-header">
  <span class="title"><?title?></span>
     <div class="btn-toolbar">
      <div id="toolbar" class="btn-group"></div>
    </div>
</div>
<div  class="box-content">
   <?if response:has-flash("save")?>
   <?flash-message name="save"?>
   <?endif?>
   <?if response:has-flash("error")?>
   <?flash-message name="save"?>
   <?endif?>
   <div class="row-fluid">
      <div id="list-wrapper" class="span12">
           <table id="{response:controller()}_table" class="index-grid"></table>
           <div id="{response:controller()}_table_pager"> </div>
        </div>           
        <div class="clearfix"> </div> 
    </div>
</div>
    <script type="text/javascript">
            {form:context($response)}
            var _id = null;
            var toolbarMode = {$editButtons};
            /*initialize your grid model*/
            var gridModel = {{
                url: '/{response:controller()}/list.xml',
                pager: '#{response:controller()}_table_pager',
                id : "{domain:get-model-identity-field-name(response:model())}",
                colModel: eval(decodeURIComponent('{fn:encode-for-uri($gridCols)}')),
                sortname: '{$model-sort-field}',
                sortorder: '{$model-order}',
                emptyrecords: "No {$modelLabel}s Found",
                loadtext: "Loading {$modelLabel}s",
                editAction: function(rowid) {{
                    {$editAction}
                }}
            }};

        </script>
        <?resource-include "js/vendor/jqgrid/jquery.jqGrid.src.js"?>
        <?resource-include "js/vendor/jqgrid/i18n/grid.locale-en.js"?>
        <?resource-include "js/vendor/jqgrid/ui.jqgrid.css"?>
        <?resource-include "js/vendor/jqgrid/ui.jqgrid.bootstrap.css"?>
 
</div>