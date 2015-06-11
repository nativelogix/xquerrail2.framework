'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;

describe('Controller extension features', function() {

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
