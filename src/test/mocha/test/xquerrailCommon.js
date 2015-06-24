'use strict';

var fs = require('fs');
var path = require('path');
var request = require('request').defaults({jar: true});
var assert = require('chai').assert;
var expect = require('chai').expect;
var xml2js = require('xml2js');
var parser = new xml2js.Parser({explicitArray: false, explicitRoot: true});
var builder = new xml2js.Builder();

var xquerrailCommon = (function(){
  var settings = {};
  var ml;
  try {
    ml = require('../../../../gulpfile.js').ml;
    if(ml === undefined) {
      throw new Error();
    }
  } catch(e) {
    console.error(e);
    console.log('Could find global ml try different location ./ml.json');
    ml = require('./ml.json');
  }
  settings.urlBase = 'http://' + ml.host + ":" + ml.port;
  settings.username = ml.user;
  settings.password = ml.password;
  console.log('Using XQuerrail: [%s] - [%s]', settings.urlBase, settings.username);

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

    request(options, function(error, response, body) {setTimeout(function(){callback(error, response, body)}, 300)});
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

  function httpMethod(method, model, action, data, qs, callback, format, opt) {
    format = getFormat(format);
    var options = opt || {};
    if (!options.method) {
      options.method = method;
    }
    if (!options.url) {
      options.url = xquerrailCommon.urlBase + '/' + model + '/' + action + '.' + format;
    }
    if (!options.qs) {
      options.qs = qs;
    }
    if (!options.headers) {
      options.headers = {};
    }
    options.followRedirect = true;

      if (format === 'json') {
        options.headers['content-type'] = 'application/json';
        options.json = data;
      } else if (format === 'xml') {
        options.headers['content-type'] = 'text/xml';
        if (data) {
          options.body = new xml2js.Builder({'rootName': model, 'headless': true, 'renderOpts': {}}).buildObject(data);
        }
      } else {
        options.form = data;
    }

    request(options, function(error, response) {
      return parseResponse(model, format, error, response, callback);
    });
  };

  function parseResponse(model, format, error, response, callback) {
    var entity = response.body;
    if (format === 'xml') {
      parseXml(model, error, response, callback);
    } else if (format === 'json') {
      parseJson(model, error, response, callback);
    } else {
      callback(error, response, entity);
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
    if (body.error) {
      return {
        name: body.error.name,
        code: body.error.code,
        message: body.error.message,
        description: body.error['format_string'],
        data: body.error.data,
        stack: body.error.stack
      }
    } else {
      throw new Error({
        'name': 'parseErrorException',
        'message': 'parseError failed body does not content error property',
        'value': body
      });
    }
  };

  var schema = function (model, callback, format, options) {
    httpMethod('GET', model, 'schema', undefined, undefined, callback, format, options);
  };

  var create = function(model, data, callback, format, options) {
    httpMethod('POST', model, 'create', data, undefined, callback, format, options);
  };

  var update = function(model, data, callback, format, options) {
    httpMethod('POST', model, 'update', data, undefined, callback, format, options);
  };

  var get = function (model, data, callback, format, options) {
    httpMethod('GET', model, 'get', undefined, data, callback, format, options);
  };

  var remove = function(model, data, callback, format, options) {
    httpMethod('POST', model, 'delete', data, undefined, callback, format, options);
  };

  var list = function(model, data, callback, format, options) {
    httpMethod('GET', model, 'list', undefined, data, callback, format, options);
  };

  var lookup = function(model, data, callback, format, options) {
    httpMethod('GET', model, 'lookup', undefined, data, callback, format, options);
  };

  var suggest = function(model, data, callback, format, options) {
    httpMethod('GET', model, 'suggest', undefined, data, callback, format, options);
  };

  var search = function(model, data, callback, format, options) {
    httpMethod('GET', model, 'search', undefined, data, callback, format, options);
  };

  var removeAll = function(model, callback, format, options) {
    httpMethod('DELETE', model, 'delete-all', undefined, undefined, callback, format, options);
  };

  var stripRoot = function(model, error, response, entity, callback) {
    entity = entity[model] || entity;
    callback(error, response, entity);
  };


  var model = {
    create: create,
    update: update,
    get: get,
    remove: remove,
    removeAll: removeAll,
    list: list,
    lookup: lookup,
    suggest: suggest,
    search: search,
    schema: schema,
    stripRoot: stripRoot
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
