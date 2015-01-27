'use strict';

var path = require('path');
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

  function random(prefix) {
    return ((prefix)? prefix + '-': '') + Math.floor((Math.random() * 1000000) + 1)
  };

  function getApplicationConfig(filename) {
    var configurationPath;
    if (filename === undefined) {
      configurationPath = '/test/mocha/test/common-app-test/_config';
    } else {
      configurationPath = getApplicationConfigPath(filename)
    }
    return '<application xmlns="http://xquerrail.com/config"><base>/main</base><config>'+configurationPath+'</config></application>'
  }

  function getApplicationConfigPath(filename) {
    var configurationPath = filename.substring(0, filename.length - path.extname(filename).length);
    configurationPath = configurationPath.replace(/\\/g, '/');
    configurationPath = configurationPath.substring(configurationPath.indexOf('xquerrail2.framework/src') + 'xquerrail2.framework/src'.length);
    return configurationPath += '/_config';
  }

  function initialize(callback, configuration) {
    var options = {
      method: 'POST',
      url: settings.urlBase + '/initialize',
      followRedirect: true,
      headers: {'Content-Type': 'text/xml'},
      body: getApplicationConfig(configuration)
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
      url: settings.urlBase + '/logout',
      followRedirect: true
    };

    request(options, callback);
  };

  return {
    urlBase: settings.urlBase,
    username: settings.username,
    password: settings.password,
    initialize: initialize,
    login: login,
    logout: logout,
    random: random
  };
})();

module.exports = xquerrailCommon;
