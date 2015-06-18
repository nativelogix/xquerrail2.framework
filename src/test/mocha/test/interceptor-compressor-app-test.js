'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;

function create(model, format, data, callback) {
  xquerrailCommon.model.create(
    model,
    data,
    function(error, response, entity) {
      expect(response.statusCode).to.equal(200);
      expect(response.headers['content-encoding']).to.equal('gzip');
      return xquerrailCommon.model.stripRoot(model, error, response, entity, callback);
    },
    format,
    {gzip: true}
  );
};

function remove(model, format, data, callback) {
  var done = function(error, response) {
    expect(response.statusCode).to.equal(200);
    if (callback) {
      callback();
    }
  }
  if (format === 'html') {
    xquerrailCommon.httpMethod(
      'POST',
      model,
      'remove',
      data,
      undefined,
      done,
      format,
      {gzip: true}
    );
  } else {
    xquerrailCommon.model.remove(
      model,
      data,
      done,
      format,
      {gzip: true}
    );
  }
};

// function stripModelRoot(model, error, response, entity, callback) {
//   entity = entity[model] || entity;
//   callback(error, response, entity);
// };

describe('Compress feature', function() {

  var namespace;

  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      xquerrailCommon.login(function() {
        xquerrailCommon.model.schema('model1', function(error, response, entity) {
          namespace = entity.model.namespace;
          done();
        });
      });
    }, module.filename);
  });

  describe('model1', function() {

    it('should create and remove entity in json format', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        var id = xquerrailCommon.random('json-model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', 'json', data, function(error, response, entity) {
          expect(entity.id).to.equal(id);
          remove('model1', 'json', data, done);
        });
      });
    });

    it('should create and remove entity in xml format', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        var id = xquerrailCommon.random('xml-model1-id');
        var data = {
          '$': {'xmlns': namespace},
          'id': id,
          'name': 'model1-name'
        };
        create('model1', 'xml', data, function(error, response, entity) {
          expect(entity.id).to.equal(id);
          remove('model1', 'xml', entity, done);
        });
      });
    });

    it('should create and remove entity in html format', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        var id = xquerrailCommon.random('html-model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', 'json', data, function(error, response, entity) {
          expect(entity.id).to.equal(id);
          remove('model1', 'html', data, done);
        });
      });
    });

  });

});
