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
<div >
 <div class="inner-page-title ">
        <div class="toolbar">
          <h2>Import </h2>
        </div>
    </div>
    <form>
     <div id="import-view" class="import-view content-box">    
             <label for="import-file">File Upload:
               <input type="file" name="import-file" id="import-file" class="field file medium" />
             </label><br/>
             <label for="import-format">File Upload Format:
                 <select id="import-format" name="format" class="field select medium">
                     <option value="xml">Xml Format (.xml)</option>
                     <option value="csv">Comma Seperated Values Format (*.csv)</option>
                     <option value="tab">Tab Delimited Format (*.txt|*.tab)</option>
                     <option value="excel">Excel 2007+ Format (*.xslx)</option>
                 </select>
             </label>
             <div class="buttonset">
                <input type="submit" value="upload"></input>
             </div>
        </div>
  </form>      
  <script type="text/javascript">
     initializeForm();
  </script>  
</div> 