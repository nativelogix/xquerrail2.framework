'use strict';

var globals = require('mocha');
var _ = require('lodash');
var fs = require('fs');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request');
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var xquerrail = {};

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

describe('Authentication features', function() {

  before(function() {
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
  });

  describe('login', function() {
    it('should be successful', function(done) {
      var options = {
        method: 'POST',
        url: xquerrail.url + '/login',
        form: {
          username: xquerrail.username,
          password: xquerrail.password
        },
        followRedirect: true
      };

      request(options, function(error, response, body) {
        expect(response.headers).to.include.keys('set-cookie');
        done();
      });
    });
  });

  describe('logout', function() {
    it('should be successful', function(done) {
      login(function(error, response, body) {
        expect(response.headers).to.include.keys('set-cookie');
        request.get( xquerrail.url + '/logout', function(error, response, body) {
          expect(response.url).to.be.empty;
          done();
        });
      });
    });
  })

});
