'use strict';

var xquerrailCommon = require('./xquerrailCommon');

var _ = require('lodash');
var fs = require('fs');
var assert = require('chai').assert;
var expect = require('chai').expect;

var xquerrail = {};

describe('Authentication features', function() {

  before(function(done) {
    xquerrailCommon.initialize(done);
  });

  describe('login', function() {
    it('should be successful', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        expect(response.statusCode).to.equal(302);
        expect(response.headers).to.include.keys('set-cookie');
        done();
      });
    });
  });

  describe('logout', function() {
    it('should be successful', function(done) {
      xquerrailCommon.login(function(error, response, body) {
        expect(response.headers).to.include.keys('set-cookie');
        xquerrailCommon.logout(function(error, response, body) {
          expect(response.url).to.be.empty;
          done();
        });
      });
    });
  })

});
