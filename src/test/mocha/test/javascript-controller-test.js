'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

describe('Javascript controller features', function() {

  before(function(done) {
    xquerrailCommon.initialize(done);
  });

  describe('invoke model1-controller.sjs', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it('infoJS should return HTTP - 200', function(done) {
      if (xquerrailCommon.isMl8()) {
        xquerrailCommon.httpMethod('GET', 'model1', 'infoJS', undefined, undefined, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          done();
        }, 'xml', undefined);
      } else {
        done();
      }
    });

    it('testNodeBuilder should return HTTP - 200', function(done) {
      if (xquerrailCommon.isMl8()) {
        xquerrailCommon.httpMethod('GET', 'model1', 'testNodeBuilder', undefined, undefined, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.response).to.equal("test");
          done();
        }, 'xml', undefined);
      } else {
        done();
      }
    });

    it('modelName should return HTTP - 200', function(done) {
      if (xquerrailCommon.isMl8()) {
        xquerrailCommon.httpMethod('GET', 'model1', 'modelName', undefined, undefined, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity).to.have.property("model");
          expect(entity.model).to.equal("model1");
          done();
        }, 'json', undefined);
      } else {
        done();
      }
    });

    it('customResponse should return HTTP - 200', function(done) {
      if (xquerrailCommon.isMl8()) {
        xquerrailCommon.httpMethod('GET', 'model1', 'customResponse', undefined, undefined, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity).to.have.property("response");
          expect(entity.response).to.equal("customResponse");
          done();
        }, 'json', undefined);
      } else {
        done();
      }
    });

  });

});
