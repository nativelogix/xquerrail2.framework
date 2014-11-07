'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

function random(prefix) {
  return ((prefix)? prefix + '-': '') + Math.floor((Math.random() * 1000000) + 1)
};

function httpGet(model, action, data, callback) {
  var options = {
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.xml',
    qs: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseXml(model, error, response, callback);
  });
};

function httpPost(model, action, data, callback) {
  var options = {
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.xml',
    form: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseXml(model, error, response, callback);
  });
};

function parseXml(model, error, response, callback) {
  if (response.body != undefined) {
    var entity = response.body;
    parser.parseString(entity, function (err, result) {
      entity = (result !== null && result !== undefined)?result[model]: undefined;
      callback(error, response, entity);
    });
  } else {
    callback(error, response, undefined);
  }
};

function create(model, data, callback) {
  httpPost(model, 'create', data, callback);
};

function update(model, data, callback) {
  httpPost(model, 'update', data, callback);
};

function get(model, data, callback) {
  httpGet(model, 'get', data, callback);
};

function remove(model, data, callback) {
  httpPost(model, 'delete', data, callback);
};

describe('XML CRUD features', function() {

  before(function(done) {
    this.timeout(5000);
    // xquerrailCommon.initialize(function(error, response, body) {
      // expect(response.statusCode).to.equal(200);
      done();
    // });
  });

  describe('model1', function() {
    it('user not authenticated should return 401', function(done) {
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
        return parseXml(model, error, response, function(error, response, entity) {
          expect(response.statusCode).to.equal(401);
          done();
        });
      });
    });

    it('should create and get new entity', function(done) {
      xquerrailCommon.login(function() {
        var id = random('model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.id).to.equal(id);
          get('model1', {'id': id}, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            expect(entity.id).to.equal(id);
            done();
          });
        });
      });
    });

    it('should create and update new entity', function(done) {
      xquerrailCommon.login(function() {
        var id = random('model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          var name = random('model1-name-update');
          var data = {
            'id': id,
            'name': name
          };
          update('model1', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            expect(entity.id).to.equal(id);
            expect(entity.name).to.equal(name);
            done()
          });
        });
      });
    });

    it('should create, delete and get entity', function(done) {
      xquerrailCommon.login(function() {
        var id = random('model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.id).to.equal(id);
          remove('model1', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            expect(entity.id).to.equal(id);
            get('model1', {'id': id}, function(error, response, entity) {
              expect(response.statusCode).to.equal(404);
              done();
            });
          });
        });
      });
    });
  });

});
