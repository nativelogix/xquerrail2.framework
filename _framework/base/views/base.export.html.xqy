xquery version "1.0-ml";

import module namespace response = "http://xquerrail.com/response"
    at "/_framework/response.xqy";
    
import module namespace domain  = "http://xquerrail.com/domain"
    at "/_framework/domain.xqy";

import module namespace form  = "http://xquerrail.com/helper/form"
    at "/_framework/helpers/form-helper.xqy";

declare variable $response as map:map external;
response:initialize($response),
let  $repColumns := 
    for $item in response:model()//(domain:element|domain:attribute)
    return form:field-grid-column($item)
return 
<div xmlns="http://www.w3.org/1999/xhtml" id="report-wrapper" class="ui-layout">
    <div id="report-toolbar" class="ui-layout-north">
       <button id="run-report" class="ui-button">Run</button>
       <button id="save-report" class="ui-button">Save</button>
       <button id="export-report" class="ui-button">Export</button>
    </div>

    <div id="report-navigation" class="ui-layout-west">
        <form id="report-form" action="/reports/results.xml" method="get">
            <div id="report-tabs">
              <ul>
                  <li><a href="#report-criteria">Criteria</a></li>
                  <li><a href="#report-fields">Fields</a></li>
              </ul>
              <div id="report-tabs-container" style="height:100%;overflow:auto;display:block;">
                  <div id="report-criteria" >
                            <div class="formItem">
                                <label class="desc" for="site">Site:</label>
                                <input id="siteNumber-criteria" name="site" type="text" class="field small" multiple="true"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="site">Customer:</label>
                                <input id="customer-criteria" name="siteCustomer" type="text" class="field small" multiple="true"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="region">Region:</label>
                                <input id="region-criteria" name="siteRegion" type="text" class="field small" multiple="true"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="issue">Issue:</label>
                                <input id="issue-criteria" name="issue" type="text" class="field small"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="subissue">Sub-Issue:</label>
                                <input id="subissue-criteria" name="subissue" type="text" class="field small"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="subissue">Severity:</label>
                                <input id="severity-criteria" name="severity" type="text" class="field small"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="ticketstatus-criteria">Operational Status:</label>
                                <input id="ticketstatus-criteria" name="opStatus" type="text" class="field small"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="billingstatus">Billing Status:</label>
                                <input id="billingstatus-criteria" name="billingStatus" type="text" class="field small"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="assignedResource">Assigned Resource:</label>
                                <input id="assignedResource-criteria" name="assignedResource" type="text" class="field small"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="assignedSupervisor">Assigned Supervisor:</label>
                                <input id="assignedSupervisor-criteria" name="assignedSupervisor" type="text" class="field small"/>
                            </div>
                            <div class="formItem">
                                <label class="desc" for="assignedRepresentative">Assigned Representative:</label>
                                <input id="assignedRepresentative-criteria" name="assignedRepresentative" type="text" class="field small"/>
                            </div>
                    </div>
                    <div id="report-fields">
                           <table id="report-fields-table">
                            <thead>
                                <tr class="header-row">
                                  <th width="40">Select
                                   <input type="checkbox" id="check-all" checked="checked"/>
                                  </th>
                                  <th width="40">Order</th>
                                  <th>Name</th>
                                  <th width="200">Column</th>
                                  <th width="50">Width</th>
                                  <th width=""></th>
                                </tr>
                            </thead>
                            <tbody>
                            { for $field at $pos in response:model()//(domain:element|domain:attribute)
                              return  
                                <tr id="{$pos}" class="body-row">
                                  <td><input type="checkbox" checked="checked" name="field" value="{$field/@name}" class="field small select-field" /></td>
                                  <td>{<input type="text" name="{$field/@name}|order" value="{$pos}" class="field-order"/>}</td>
                                  <td>{fn:string($field/@name)}</td>
                                  
                                  <td><input type="text" name="{$field/@name}|label" value="{fn:data($field/@label)}" class="field-label"/></td>
                                  <td><input type="text" name="{$field/@name}|width" value="{($field/domain:ui/@gridWidth,100)[1]}" style="text-align:right;width:40px" class="field-width"/></td>                      
                                </tr>
                            }
                           </tbody>
                           </table>
                    </div>
                </div><!---/end-tab-container-->
            </div>
        </form>
    </div>
    <div id="report-results" class="ui-layout-center" style="">
        <table id="report-results-table"></table>
        <div id="report-results-pager"></div>
    </div>
     <script type="text/javascript" src="/resources/js/jquery.tablednd.js">//</script>
     <script type="text/javascript">
      var reportColModel = {xdmp:to-json($repColumns)};
      var reportModel = '{fn:data(response:model()/@name)}';
    </script>
    <div id="export-dialog" title="Export Report">
         <div class="formItem"> 
           <label class="desc">Format: </label>
           <select id="export-format" class="field small" style="text-align:left">
                <option value="excel">Microsoft Excel 2007 (xlsx)</option>
                <option value="xml">Extensible Markup Language (xml)</option>
                <option value="csv">Comma Seperated Values (csv)</option>
           </select>
        </div>
        <div class="formItem">
           <label class="desc">Report Name</label>
           <input id="export-name"  type="text" class="string field small" style="width:228px" value="{response:model()/@label} Report"/>
        </div>
    </div>
</div>
