'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});

describe('XML CRUD features', function() {

  var create = function(model, data, callback) {
    xquerrailCommon.model.create(
      model,
      data,
      function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        xquerrailCommon.model.stripRoot(model, error, response, entity, function(error, response,entity) {
          callback(entity);
        });
      },
      'xml'
    );
  };

  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    });
  });

  describe('user not authenticated', function() {
    it('should return 401', function(done) {
      var model = 'model1';
      var action = 'get';
      var j = request.jar()
      var _request = request.defaults({jar:j})
      var options = {
        method: 'GET',
        url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.xml',
        followRedirect: true
      };
      _request(options, function(error, response) {
        return xquerrailCommon.parseResponse(model, 'xml', error, response, function(error, response, entity) {
          expect(response.statusCode).to.equal(401);
          done();
        });
      });
    });
  });

  describe('model1', function() {
    var namespace;
    before(function(done) {
      xquerrailCommon.login(function() {
        xquerrailCommon.model.schema('model1', function(error, response, entity) {
          namespace = entity.model.namespace;
          done();
        });
      });
    });

    it('should create and get new entity', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        '$': {'xmlns': namespace},
        'id': id,
        'name': 'model1-name'
      };
      create('model1', data, function(entity) {
        expect(entity.id).to.equal(id);
        xquerrailCommon.model.get('model1', {'id': id}, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.id).to.equal(id);
          done();
        });
      });
    });

    it('should create and update new entity', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        '$': {'xmlns': namespace},
        'id': id,
        'name': 'model1-name'
      };
      create('model1', data, function(entity) {
        var name = xquerrailCommon.random('model1-name-update');
        var data = {
        '$': {'xmlns': namespace},
          'id': id,
          'name': name
        };
        xquerrailCommon.model.update('model1', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.id).to.equal(id);
          expect(entity.name).to.equal(name);
          done()
        });
      });
    });

    it('should create, delete and get entity', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        '$': {'xmlns': namespace},
        'id': id,
        'name': 'model1-name'
      };
      create('model1', data, function(entity) {
        expect(entity.id).to.equal(id);
        xquerrailCommon.model.remove('model1', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.id).to.equal(id);
          xquerrailCommon.model.get('model1', {'id': id}, function(error, response, entity) {
            expect(response.statusCode).to.equal(404);
            done();
          });
        });
      });
    });
  });

});
