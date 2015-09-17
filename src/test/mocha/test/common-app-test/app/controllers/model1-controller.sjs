'use strict';

var baseController = require('/main/_framework/base/base-controller.xqy');
var request = require('/main/_framework/request.xqy');
var response = require('/main/_framework/response.xqy');

var infoJs = function () {
  xdmp.log('infoJs')
  return xdmp.unquote('<response>' + fn.currentDateTime() + '</response>');
};

var testNodeBuilder = function () {
  xdmp.log('test')
  var nb = new NodeBuilder();
  nb
    .startDocument()
      .startElement("response")
        .addText("test")
      .endElement()
    .endDocument();
  return nb.toNode();
};

var modelName = function() {
  var model = baseController.model();
  return {"model": model.xpath("@name")};
};

var customResponse = function() {
  var model = baseController.model();
  response.initialize({});
  response.setBody({"response": "customResponse"})
  return response.response()
};

module.exports = {
  'infoJS': infoJs,
  'modelName': modelName,
  'testNodeBuilder': testNodeBuilder,
  'customResponse': customResponse
}
