xquery version "1.0-ml";
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
