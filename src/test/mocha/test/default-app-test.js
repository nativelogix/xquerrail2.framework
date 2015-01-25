'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var configurationPath = '/test/mocha/test/app1/_config';
var configuration = '<application xmlns="http://xquerrail.com/config"><base>/main</base><config>'+configurationPath+'</config></application>';

function random(prefix) {
  return ((prefix)? prefix + '-': '') + Math.floor((Math.random() * 1000000) + 1)
};

function httpGet(model, action, data, callback) {
  var options = {
    json: true,
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.json',
    qs: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseResponse(model, error, response, callback);
  });
};

function httpPost(model, action, data, callback) {
  var options = {
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.json',
    json: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseResponse(model, error, response, callback);
  });
};

function parseResponse(model, error, response, callback) {
  if (response.statusCode === 500) {
    error = parseError(response);
  }
  var entity = response.body;
  callback(error, response, entity);
};

function parseError(response) {
  return {
    code: response.body.error.code,
    message: response.body.error.message,
    description: response.body.error['format_string'],
    data: response.body.error.data,
    stack: response.body.error.stack
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

describe('Custom app1 features', function() {

  this.timeout(10000);
  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    }, configuration);
  });

  describe('model1', function() {

    it('should create and get new entity', function(done) {
      xquerrailCommon.login(function(error, response, body) {
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

  });

});
