'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

function random(prefix) {
  return ((prefix)? prefix + '-': '') + Math.floor((Math.random() * 1000000) + 1)
};

function httpGet(model, action, data, format, callback) {
  var format = format || 'xml';
  var options = {
    json: true,
    method: 'GET',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format,
    qs: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseResponse(model, error, response, format, callback);
  });
};

function httpPost(model, action, data, format, callback) {
  var format = format || 'xml';
  var options = {
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format,
    form: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseResponse(model, error, response, format, callback);
  });
};

function parseResponse(model, error, response, format, callback) {
  if (format === 'json') {
    if (response.statusCode === 500) {
      error = parseError(response);
    }
    var entity = response.body;
    callback(error, response, entity);
  } else {
    if (response.body !== undefined) {
      var entity = response.body;
      parser.parseString(entity, function (err, result) {
        if (err !== null) {
          callback(err, response, undefined);
        } else {
          entity = (result !== null && result !== undefined)?result[model]: undefined;
          callback(error, response, entity);
        }
      });
    } else {
      callback(error, response, undefined);
    }
  }
};

function parseError(response) {
  return {
    code: response.body.error.code,
    message: response.body.error.message,
    description: response.body.error['format_string'],
    data: response.body.error.data,
    stack: response.body.error.stack
  }
};

function create(model, data, callback) {
  httpPost(model, 'create', data, 'xml', callback);
};

function update(model, data, callback) {
  httpPost(model, 'update', data, 'xml', callback);
};

function get(model, data, format, callback) {
  httpGet(model, 'get', data, format, callback);
};

function edit(model, data, format, callback) {
  httpGet(model, 'edit', data, format, callback);
};

function remove(model, data, callback) {
  httpPost(model, 'delete', data, 'xml', callback);
};

describe('Custom Interceptor features', function() {

  // this.timeout(10000);
  before(function(done) {
    xquerrailCommon.initialize(done/*function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    }*/);
  });

  describe('custom-interceptor-2.xqy', function() {
    it('should return custom http header', function(done) {
      xquerrailCommon.login(function() {
        // Response header is set by customer-interceptor-2
        var headerValue = random('dummy-header');
        httpGet('model1', 'list', {'mocha-param-test': headerValue}, 'json', function(error, response) {
          expect(response.statusCode).to.equal(200);
          expect(response.headers['before-response-test'], headerValue);
          done();
        });
      });
    });
  });

  describe('engine.extension.xqy', function() {
    it('should return {"message": "Hello World"}', function(done) {
      xquerrailCommon.login(function() {
        // Response header is set by customer-interceptor-2
        var headerValue = random('dummy-header');
        httpGet('model1', 'info', {}, 'json', function(error, response) {
          expect(response.statusCode).to.equal(200);
          // expect(response.headers['before-response-test'], headerValue);
          expect(response.body.response).to.not.be.undefined();
          done();
        });
      });
    });
  });

  describe('custom-view interceptor', function() {
    it('should return {"message": "custom-view"}', function(done) {
      xquerrailCommon.login(function() {
        httpGet('model1', 'info', {'view': 'custom'}, 'json', function(error, response) {
          expect(response.statusCode).to.equal(200);
          expect(response.body.response).to.equal('custom-view');
          done();
        });
      });
    });
  });

  describe('missing-custom-view interceptor', function() {
    it('should return HTTP - 200', function(done) {
      xquerrailCommon.login(function() {
        httpGet('model1', 'info', {'view': 'custom1'}, 'json', function(error, response) {
          expect(response.statusCode).to.equal(200);
          done();
        });
      });
    });
  });

});
