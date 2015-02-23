'use strict';

var path = require('path');
var request = require('request').defaults({jar: true});
var assert = require('chai').assert;
var expect = require('chai').expect;
var xml2js = require('xml2js');
var parser = new xml2js.Parser({explicitArray: false});

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

  function getFormat(format) {
    if(format === undefined) {
      format = 'json';
    }
    if (format.substring(0, 1) === '.') {
      format = format.substring(1);
    }
    return format;
  };

  function httpMethod(method, model, action, data, qs, callback, format) {
    format = getFormat(format);
    var options = {
      method: method,
      url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format,
      json: data,
      qs: qs,
      followRedirect: true
    };
    request(options, function(error, response) {
      return parseResponse(model, format, error, response, callback);
    });
  };

  function parseResponse(model, format, error, response, callback) {
    if (format === 'xml') {
      parseXml(model, error, response, callback);
    } else {
      parseJson(model, error, response, callback);
    }
  };

  function parseJson(model, error, response, callback) {
    var body;
    try {
      body = JSON.parse(response.body);
    } catch(e) {
      body = response.body;
    }
    if (response.statusCode === 500) {
      console.dir(body)
      error = parseError(body);
    }
    if (callback !== undefined) {
      callback(error, response, body);
    }
  };

  function parseXml(model, error, response, callback) {
    if (response.body !== undefined) {
      var entity = response.body;
      parser.parseString(entity, function (err, result) {
        if (err === null) {
          callback(error, response, result);
        } else {
          new Error('Xml parsing error: [' + err + ']');
        }
      });
    } else {
      callback(error, response, undefined);
    }
  };

  function parseError(body) {
    return {
      code: body.error.code,
      message: body.error.message,
      description: body.error['format_string'],
      data: body.error.data,
      stack: body.error.stack
    }
  };

  var create = function(model, data, callback) {
    httpMethod('POST', model, 'create', data, undefined, callback);
  };

  var update = function(model, data, callback) {
    httpMethod('POST', model, 'update', data, undefined, callback);
  };

  var get = function (model, data, callback) {
    httpMethod('GET', model, 'get', undefined, data, callback);
  };

  var remove = function(model, data, callback) {
    httpMethod('POST', model, 'delete', data, undefined, callback);
  };

  var list = function(model, data, callback) {
    httpMethod('GET', model, 'list', undefined, data, callback);
  };

  var lookup = function(model, data, callback) {
    httpMethod('GET', model, 'lookup', undefined, data, callback);
  };

  var suggest = function(model, data, callback) {
    httpMethod('GET', model, 'suggest', undefined, data, callback);
  };

  var search = function(model, data, callback) {
    httpMethod('GET', model, 'search', undefined, data, callback);
  };

  var model = {
    create: create,
    update: update,
    get: get,
    remove: remove,
    list: list,
    lookup: lookup,
    suggest: suggest,
    search: search
  };

  return {
    urlBase: settings.urlBase,
    username: settings.username,
    password: settings.password,
    initialize: initialize,
    login: login,
    logout: logout,
    random: random,
    model: model,
    httpMethod: httpMethod,
    parseResponse: parseResponse
  };
})();

module.exports = xquerrailCommon;
