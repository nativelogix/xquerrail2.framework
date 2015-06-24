'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
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

describe('Same action different methods', function() {

  before(function(done) {
    xquerrailCommon.initialize(done/*function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    }*/);
  });

  describe('model1', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it('should invoke HTTP methods for xml format', function(done) {
      invokeMethod('GET', 'xml', function() {
        invokeMethod('POST', 'xml', function() {
          invokeMethod('PUT', 'xml', function() {
            invokeMethod('PATCH', 'xml', function() {
              invokeMethod('HEAD', 'xml', function() {
                invokeMethod('OPTIONS', 'xml', function() {
                invokeMethod('DELETE', 'xml', done);
                });
              });
            });
          });
        });
      });
    });

    it('should invoke HTTP methods for json format', function(done) {
      invokeMethod('GET', 'json', function() {
        invokeMethod('POST', 'json', function() {
          invokeMethod('PUT', 'json', function() {
            invokeMethod('PATCH', 'json', function() {
              invokeMethod('HEAD', 'json', function() {
                invokeMethod('OPTIONS', 'json', function() {
                invokeMethod('DELETE', 'json', done);
                });
              });
            });
          });
        });
      });
    });

  });

});
