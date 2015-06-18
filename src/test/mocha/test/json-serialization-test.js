'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var find = function(model, data, callback) {
  xquerrailCommon.httpMethod('GET', model, 'find', undefined, data, callback);
};

var findEmpty = function(model, data, callback) {
  xquerrailCommon.httpMethod('GET', model, 'find-empty', undefined, data, callback);
};

var multi = function(model, data, callback) {
  xquerrailCommon.httpMethod('GET', model, 'multi-find', undefined, data, callback);
};

describe('Custom app1 features', function() {

  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    }, module.filename);
  });

  describe('model1', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        var data1 = {
          'id': xquerrailCommon.random('model1-id'),
          'name': 'model1-name',
          'tag': 'commontag'
        };
        var data2 = {
          'id': xquerrailCommon.random('model2-id'),
          'name': 'model2-name',
          'tag': 'commontag'
        };
        xquerrailCommon.model.create('model1', data1, function(error, response, entity) {
          xquerrailCommon.model.create('model2', data2, function(error, response, entity) {
            done();
          });
        });
      });
    });

    after(function(done) {
      xquerrailCommon.logout(function() {
        done();
      });
    });

    it('should create and find new entity', function(done) {
      find('model1', {'name': 'model1-name'}, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity).to.have.property('_type');
        expect(entity._type).to.equal('model1');
        expect(entity).to.have.property('model1');
        expect(entity.model1).to.be.instanceof(Array);
        done();
      });
    });

    it('should create and findEmpty new entity', function(done) {
      findEmpty('model1', {'name': 'model1-name'}, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity).to.have.property('_type');
        expect(entity._type).to.equal('model1');
        expect(entity).to.have.property('model1');
        expect(entity.model1).to.be.instanceof(Array);
        expect(entity.model1).to.be.empty;
        done();
      });
    });

    it('should create and multi new entity', function(done) {
      multi('model1', {'tag': 'commontag'}, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity).to.have.property('_type');
        expect(entity._type).to.be.instanceof(Array);
        expect(entity._type).to.contain('model1');
        expect(entity._type).to.contain('model2');
        expect(entity).to.have.property('model1');
        expect(entity).to.have.property('model2');
        expect(entity.model1).to.be.instanceof(Array);
        expect(entity.model2).to.be.instanceof(Array);
        done();
      });
    });

  });

});
