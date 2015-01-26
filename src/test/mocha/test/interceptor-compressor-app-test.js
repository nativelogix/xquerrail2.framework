'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var configurationPath = '/test/mocha/test/interceptor-compressor-app-test/_config';
var configuration = '<application xmlns="http://xquerrail.com/config"><base>/main</base><config>'+configurationPath+'</config></application>';

function random(prefix) {
  return ((prefix)? prefix + '-': '') + Math.floor((Math.random() * 1000000) + 1)
};

function httpGet(model, action, format, data, callback) {
  var options = {
    json: true,
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format,
    qs: data,
    followRedirect: true,
    gzip: true
  };
  request(options, function(error, response) {
    return parseResponse(model, format, error, response, callback);
  });
};

function httpPost(model, action, format, data, callback) {
  var options = {
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format,
    followRedirect: true,
    gzip: true
  };
  if (format === 'json') {
    options.json = data;
  } else if (format === 'xml') {
    options.form = data;
  } else {
    options.form = data;
  }
  request(options, function(error, response, body) {
    return parseResponse(model, format, error, response, callback);
  });
};

function parseResponse(model, format, error, response, callback) {
  if (response.statusCode === 500) {
    error = parseError(response);
  }
  var entity = response.body;
  if (format === 'json') {
    callback(error, response, entity);
  } else if (format === 'xml') {
    parser.parseString(entity, function (err, result) {
      entity = (result !== null && result !== undefined)?result[model]: undefined;
      callback(error, response, entity);
    });
  } else {
    callback(error, response, entity);
  }
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

function create(model, format, data, callback) {
  if (format === 'html') {
    httpPost(model, 'save', format, data, callback);
  } else {
    httpPost(model, 'create', format, data, callback);
  }
};

function update(model, format, data, callback) {
  httpPost(model, 'update', format, data, callback);
};

function get(model, format, data, callback) {
  httpGet(model, 'get', format, data, callback);
};

function remove(model, format, data, callback) {
  if (format === 'html') {
    httpPost(model, 'remove', format, data, callback);
  } else {
    httpPost(model, 'delete', format, data, callback);
  }
};

describe('Compress feature', function() {

  this.timeout(10000);
  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    }, module.filename);
  });

  describe('model1', function() {

    it('should create and remove entity in json format', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        var id = random('json-model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', 'json', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(response.headers['content-encoding']).to.equal('gzip');
          expect(entity.id).to.equal(id);
          remove('model1', 'json', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            done();
          });
        });
      });
    });

    it('should create and remove entity in xml format', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        var id = random('xml-model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', 'xml', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(response.headers['content-encoding']).to.equal('gzip');
          expect(entity.id).to.equal(id);
          remove('model1', 'xml', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            done();
          });
        });
      });
    });

    it('should create and remove entity in html format', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        var id = random('html-model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', 'json', data, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(response.headers['content-encoding']).to.equal('gzip');
          expect(entity.id).to.equal(id);
          remove('model1', 'html', data, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            done();
          });
        });
      });
    });

  });

});
