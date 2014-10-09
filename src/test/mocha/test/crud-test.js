'use strict';

var _ = require('lodash');
var fs = require('fs');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var xquerrail = {};

function random(prefix) {
  return ((prefix)? prefix + '-': '') + Math.floor((Math.random() * 1000000) + 1)
};

function login(callback) {
  var options = {
    method: 'POST',
    url: xquerrail.url + '/login',
    form: {
      username: xquerrail.username,
      password: xquerrail.password
    },
    followRedirect: true
  };

  request(options, callback);
};

function initialize(callback) {
  var options = {
    method: 'GET',
    url: xquerrail.url + '/initialize',
    followRedirect: true
  };

  request(options, function(error, response, body) {setTimeout(function(){callback(error, response, body)}, 100)});
};

function httpGet(model, action, data, callback) {
  var options = {
    json: true,
    method: 'POST',
    url: xquerrail.url + '/' + model + '/' + action + '.json',
    qs: data,
    followRedirect: true
  };
  request(options, callback);
};

function httpPost(model, action, data, callback) {
  var options = {
    json: true,
    method: 'POST',
    url: xquerrail.url + '/' + model + '/' + action + '.json',
    form: data,
    followRedirect: true
  };
  request(options, callback);
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

describe('CRUD features', function() {

  before(function(done) {
    this.timeout(5000);
    var ml;
    try {
      ml = require('../../../../gulpfile.js').ml;
      if(ml === undefined) {
        throw new Error();
      }
    } catch(e) {
      console.log('Could find global ml try different location ./ml.json');
      ml = require('./ml.json');
    }
    xquerrail.url = 'http://' + ml.host + ":" + ml.port;
    xquerrail.username = ml.user;
    xquerrail.password = ml.password;
    initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    });
  });

  describe('model1', function() {
    it('should create and get new entity', function(done) {
      login(function(error, response, body) {
        var id = random('model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', data, function(error, response, boby) {
          expect(response.statusCode).to.equal(200);
          var entity = response.body;
          expect(entity.id).to.equal(id);
          get('model1', {'id': id}, function(error, response, boby) {
            expect(response.statusCode).to.equal(200);
            var entity = response.body;
            expect(entity.id).to.equal(id);
            done();
          });
        });
      });
    });

    it('should create and update new entity', function(done) {
      login(function(error, response, body) {
        var id = random('model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', data, function(error, response, boby) {
          expect(response.statusCode).to.equal(200);
          var name = random('model1-name-update');
          var data = {
            'id': id,
            'name': name
          };
          update('model1', data, function(error, response, boby) {
            expect(response.statusCode).to.equal(200);
            var entity = response.body;
            expect(entity.id).to.equal(id);
            expect(entity.name).to.equal(name);
            done()
          });
        });
      });
    });

    it('should create, delete and get entity', function(done) {
      login(function(error, response, body) {
        var id = random('model1-id');
        var data = {
          'id': id,
          'name': 'model1-name'
        };
        create('model1', data, function(error, response, boby) {
          expect(response.statusCode).to.equal(200);
          var entity = response.body;
          expect(entity.id).to.equal(id);
          remove('model1', data, function(error, response, boby) {
            expect(response.statusCode).to.equal(200);
            var entity = response.body;
            expect(entity.id).to.equal(id);
            get('model1', {'id': id}, function(error, response, boby) {
              expect(response.statusCode).to.equal(200);
              var entity = response.body;
              expect(entity).to.be.undefined;
              done();
            });
          });
        });
      });
    });
  });

});
