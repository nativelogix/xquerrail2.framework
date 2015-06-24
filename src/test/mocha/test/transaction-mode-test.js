'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var invokeMethod = function(method, action, transactionMode, callback) {
  xquerrailCommon.httpMethod(method, 'model1', action, undefined, undefined, function(error, response, entity) {
    expect(response.statusCode).to.equal(200);
    expect(entity).to.have.property('transaction-mode');
    expect(entity['transaction-mode']).to.equal(transactionMode);
    if (callback !== undefined) {
      callback();
    }
  });
};

describe('Override transaction mode features', function() {

  // this.timeout(10000);

  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      // expect(response.statusCode).to.equal(200);
      xquerrailCommon.login(function() {
        done();
      });
    }, module.filename);
  });

  it('should invoke HTTP methods for xml format', function(done) {
    invokeMethod('DELETE', 'fake-delete', 'query', function() {
      invokeMethod('GET', 'fake-get', 'update', done);
    });
  });

});
