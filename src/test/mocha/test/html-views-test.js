'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

function edit(model, data, callback) {
  xquerrailCommon.httpMethod('GET', model, 'edit', undefined, data, callback, 'html');
};

describe('HTML view features', function() {

  this.timeout(10000);
  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      done();
    });
  });

  describe('model3', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it('should create a new entity and validate custom field template CUSTOM-TEMPLATE-FOR-MODEL3-NAME', function(done) {
      var id = xquerrailCommon.random('model3-id');
      var data = {
        'id': id,
        'name': 'model3-name'
      };
      xquerrailCommon.model.create('model3', data, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity.id).to.equal(id);
        edit('model3', {'uuid': entity.uuid}, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(response.body).to.have.string('CUSTOM-TEMPLATE-FOR-MODEL3-NAME');
          done();
        });
      });
    });

  });

});
