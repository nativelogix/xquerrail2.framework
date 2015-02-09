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

<div id="login">
  <?if response:has-flash("login")?>
    <div class="response-msg error ui-corner-all">
      <span>Login Error <?flash-message name="login"?></span>
    </div>
  <?endif?>
  <form method="post" class="form-horizontal">
    <input type="hidden" name="returnUrl" value="{xdmp:get-request-field("returnUrl")}"/>
    <ul>
      <li>
        <label for="username" class="desc">         
          User Name:
        </label>
        <div>
          <input type="text" tabindex="1" maxlength="255" value="" class="field text full" name="username" id="username" required="required" />
        </div>
      </li>
      <li>
        <label for="password" class="desc">
          Password:
        </label>
        <div>
          <input type="password" tabindex="1" maxlength="255" value="" class="field text full" name="password" id="password" required="required" />
        </div>
      </li>
      <li class="buttons">
        <div>
          <button class="btn btn-primary" type="submit" value="login">Login</button>
        </div>
      </li>
    </ul>
   </form>
</div>
