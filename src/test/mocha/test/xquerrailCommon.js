'use strict';

var request = require('request').defaults({jar: true});
var assert = require('chai').assert;
var expect = require('chai').expect;

var xquerrailCommon = (function(){
  var settings = {};
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
  settings.urlBase = 'http://' + ml.host + ":" + ml.port;
  settings.username = ml.user;
  settings.password = ml.password;
  console.log('Using XQuerrail: %j', settings)

  function initialize(callback) {
    var options = {
      method: 'GET',
      url: settings.urlBase + '/initialize',
      followRedirect: true
    };
    request(options, function(error, response, body) {setTimeout(function(){callback(error, response, body)}, 100)});
  };
  
  function login(callback) {
    var options = {
      method: 'POST',
      url: settings.urlBase + '/login',
      form: {
        username: settings.username,
        password: settings.password
      },
      followRedirect: true
    };

    request(options, callback);
  };

  function logout(callback) {
    var options = {
      method: 'GET',
      url: urlBase + '/logout',
      followRedirect: true
    };

    request(options, callback);
    // expect(response.url).to.be.empty;
  };

  return {
    urlBase: settings.urlBase,
    username: settings.username,
    password: settings.password,
    initialize: initialize,
    login: login
  };
})();

module.exports = xquerrailCommon;
