'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');
var parser = new xml2js.Parser({explicitArray: false, explicitRoot: true});

describe('Initialize actions', function() {

  before(function(done) {
    xquerrailCommon.initialize(done);
  });

  describe('initialize-database', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it ('should return the list of index definition', function(done) {
      xquerrailCommon.httpMethod('GET', 'initialize-database', undefined, undefined, undefined, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);

        parser.parseString(entity, function (err, result) {
          if (err === null) {
            expect(result).to.have.property('initialize-database');
            expect(result['initialize-database']).to.have.property('range-element-index');
            expect(result['initialize-database']['range-element-index']).to.not.be.empty;
            done();
          } else {
            new Error('Xml parsing error: [' + err + ']');
          }
        });
      }, '', undefined);
    });

  });

});
