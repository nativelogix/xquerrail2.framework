'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

// function httpGet(model, action, data, format, callback) {
//   var format = format || 'xml';
//   var options = {
//     json: true,
//     method: 'GET',
//     url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format,
//     qs: data,
//     followRedirect: true
//   };
//   request(options, function(error, response) {
//     return parseResponse(model, error, response, format, callback);
//   });
// };

// function httpPost(model, action, data, format, callback) {
//   var format = format || 'xml';
//   var options = {
//     method: 'POST',
//     url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format,
//     form: data,
//     followRedirect: true
//   };
//   request(options, function(error, response) {
//     return parseResponse(model, error, response, format, callback);
//   });
// };

// function parseResponse(model, error, response, format, callback) {
//   if (format === 'json') {
//     if (response.statusCode === 500) {
//       error = parseError(response);
//     }
//     var entity = response.body;
//     callback(error, response, entity);
//   } else {
//     if (response.body !== undefined) {
//       var entity = response.body;
//       parser.parseString(entity, function (err, result) {
//         if (err !== null) {
//           callback(err, response, undefined);
//         } else {
//           entity = (result !== null && result !== undefined)?result[model]: undefined;
//           callback(error, response, entity);
//         }
//       });
//     } else {
//       callback(error, response, undefined);
//     }
//   }
// };

// function parseError(response) {
//   return {
//     code: response.body.error.code,
//     message: response.body.error.message,
//     description: response.body.error['format_string'],
//     data: response.body.error.data,
//     stack: response.body.error.stack
//   }
// };

function create(model, data, callback) {
  xquerrailCommon.httpMethod('POST', model, 'create', data, undefined, callback);
};

function update(model, data, callback) {
  xquerrailCommon.httpMethod('POST', model, 'update', data, undefined, callback);
};

function get(model, data, format, callback) {
  // httpGet(model, 'get', data, format, callback);
  xquerrailCommon.httpMethod('GET', model, 'get', undefined, data, callback, format);
};

function edit(model, data, format, callback) {
  // httpGet(model, 'edit', data, format, callback);
  xquerrailCommon.httpMethod('GET', model, 'edit', undefined, data, callback, format);
};

function remove(model, data, callback) {
  // httpPost(model, 'delete', data, 'xml', callback);
  xquerrailCommon.httpMethod('POST', model, 'delete', data, undefined, callback);
};

describe('Controller extension features', function() {

  this.timeout(10000);
  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      xquerrailCommon.login(function() {
        done();
      });
    });
  });

  describe('controller.extension-1.xqy', function() {
    it('should return response custom-action-1', function(done) {
      var model = 'model1';
      var data = {'name': 'richard'};
      xquerrailCommon.httpMethod('GET', model, 'custom-action-1', undefined, data, function(error, response, body) {
        expect(response.statusCode).to.equal(200);
        expect(body).to.have.property('response');
        expect(body.response).to.contain('Custom action #1');
        done();
      });
    });
  });

  describe('controller.extension-2.xqy', function() {
    it('should return response custom-action-2', function(done) {
      var model = 'model1';
      var data = {'name': 'richard'};
      xquerrailCommon.httpMethod('GET', model, 'custom-action-2', undefined, data, function(error, response, body) {
        expect(response.statusCode).to.equal(200);
        expect(body).to.have.property('response');
        expect(body.response).to.contain('Custom action #2');
        done();
      });
    });
  });

});
