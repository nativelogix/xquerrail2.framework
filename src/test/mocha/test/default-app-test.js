'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});

describe('Custom app1 features', function() {

  before(function(done) {
    xquerrailCommon.initialize(done, module.filename);
  });

  describe('model1', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it('should create and get new entity', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.create('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity.id).to.equal(id);
        xquerrailCommon.model.get('model1', {'id': id}, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.id).to.equal(id);
          done();
        });
      });
    });

  });

});
