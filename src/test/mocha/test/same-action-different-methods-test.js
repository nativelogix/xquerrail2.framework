'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var invokeMethod = function(method, format, callback) {
  xquerrailCommon.httpMethod(method, 'model1', 'method', undefined, undefined, function(error, response, entity) {
    expect(response.statusCode).to.equal(200);
    if (entity) {
      expect(entity).to.have.property('method');
      expect(entity.method).to.equal(method);
    } else {
      expect(response.headers).to.have.property('xq-method');
      expect(response.headers['xq-method']).to.equal(method);
    }
    if (callback !== undefined) {
      callback();
    }
  }, format);
};

describe('Custom app1 features', function() {

  this.timeout(10000);
  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    });
  });

  describe('model1', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it('should invoke HTTP methods for xml format', function(done) {
      invokeMethod('GET', 'xml');
      invokeMethod('POST', 'xml');
      invokeMethod('PUT', 'xml');
      invokeMethod('PATCH', 'xml');
      invokeMethod('HEAD', 'xml');
      invokeMethod('OPTIONS', 'xml');
      invokeMethod('DELETE', 'xml', done);
    });

    it('should invoke HTTP methods for json format', function(done) {
      invokeMethod('GET', 'json');
      invokeMethod('POST', 'json');
      invokeMethod('PUT', 'json');
      invokeMethod('PATCH', 'json');
      invokeMethod('HEAD', 'json');
      invokeMethod('OPTIONS', 'json');
      invokeMethod('DELETE', 'json', done);
    });

  });

});
