'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});

function validateList(model, list) {
  expect(list).to.be.defined;
  expect(list).to.have.property('_type');
  expect(list._type).to.equal(model);
  expect(list).to.have.property('currentpage');
  expect(list).to.have.property('pagesize');
  expect(list).to.have.property('totalpages');
  expect(list).to.have.property('totalrecords');
  expect(list).to.have.property(model);
};

function validateLookup(model, list) {
  expect(list).to.be.defined;
  expect(list).to.have.property('_type');
  expect(list._type).to.equal(model);
  expect(list).to.have.property('lookups');
  expect(list.lookups).to.be.instanceof(Array);
};

function validateSuggest(model, suggest) {
  expect(suggest).to.be.defined;
  expect(suggest).to.have.property('_type');
  expect(suggest._type).to.equal(model);
  expect(suggest).to.have.property('suggest');
  expect(suggest.suggest).to.be.instanceof(Array);
};

function validateSearch(model, response) {
  expect(response).to.be.defined;
  expect(response).to.have.property('response');
  expect(response.response).to.have.property('_type');
  expect(response.response._type).to.equal(model);
  expect(response.response).to.have.property('page');
  expect(response.response).to.have.property('snippet_format');
  expect(response.response).to.have.property('total');
  expect(response.response).to.have.property('start');
  expect(response.response).to.have.property('page_length');
  expect(response.response).to.have.property('results');
  expect(response.response.results).to.be.instanceof(Array);
};

describe('JSON CRUD features', function() {

  this.timeout(10000);
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
        url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.json',
        followRedirect: true
      };
      _request(options, function(error, response) {
        return xquerrailCommon.parseResponse(model, 'json', error, response, function(error, response, entity) {
          expect(response.statusCode).to.equal(401);
          done();
        });
      });
    });
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

    it('should create and update new entity', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.create('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        var name = xquerrailCommon.random('model1-name-update');
        var data = {
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
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.create('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
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

    it('should create, list and delete', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.create('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity.id).to.equal(id);
        var criteria = {
          "sidx": "name",
          "sord": "descending"
        };
        xquerrailCommon.model.list('model1', criteria, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          validateList('model1', entity);
          expect(entity.sort.field).to.equal(criteria.sidx);
          expect(entity.sort.order).to.equal(criteria.sord);
          xquerrailCommon.model.remove('model1', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            done();
          });
        });
      });
    });

    it('should create, lookup and delete', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.create('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity.id).to.equal(id);
        var criteria = {
          "q": data.name
        };
        xquerrailCommon.model.lookup('model1', criteria, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          validateLookup('model1', entity);
          xquerrailCommon.model.remove('model1', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            done();
          });
        });
      });
    });

    it('should create, suggest and delete', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.create('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity.id).to.equal(id);
        var criteria = {
          "query": "m"
        };
        xquerrailCommon.model.suggest('model1', criteria, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          validateSuggest('model1', entity);
          xquerrailCommon.model.remove('model1', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            done();
          });
        });
      });
    });

    it('should create, search and delete', function(done) {
      var id = xquerrailCommon.random('model1-id');
      var data = {
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.create('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity.id).to.equal(id);
        var criteria = {
          "query": "name:model1"
        };
        xquerrailCommon.model.search('model1', criteria, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          validateSearch('model1', entity);
          xquerrailCommon.model.remove('model1', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            done();
          });
        });
      });
    });

    it('should delete none existing resource return 404', function(done) {
      var id = xquerrailCommon.random('dummy-resource');
      var data = {
        'id': id,
        'name': 'model1-name'
      };
      xquerrailCommon.model.remove('model1', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(404);
        done();
      });
    });

  });

});
