'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});
var xml2js = require('xml2js');

var parser = new xml2js.Parser({explicitArray: false});

var parents = [
  {
    'name': xquerrailCommon.random('parent-model-1')
  },
  {
    'name': xquerrailCommon.random('parent-model-2')
  },
  {
    'name': xquerrailCommon.random('parent-model-3')
  }
];

var children = [
  {
    'name': xquerrailCommon.random('child-model-1'),
    'parent': [parents[0].name]
  },
  {
    'name': xquerrailCommon.random('child-model-2'),
    'parent': [parents[0].name, parents[1].name]
  },
  {
    'name': xquerrailCommon.random('child-model-3'),
    'parent': [parents[1].name, parents[2].name]
  },
  {
    'name': xquerrailCommon.random('child-model-4'),
    'parent': [parents[1].name]
  }
];

function httpGet(model, action, data, callback) {
  var options = {
    json: true,
    method: 'GET',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.json',
    qs: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseResponse(model, error, response, callback);
  });
};

function httpPost(model, action, data, callback) {
  var options = {
    method: 'POST',
    url: xquerrailCommon.urlBase + '/' + model + '/' + action + '.json',
    json: data,
    followRedirect: true
  };
  request(options, function(error, response) {
    return parseResponse(model, error, response, callback);
  });
};

function parseResponse(model, error, response, callback) {
  if (callback === undefined) {
    return;
  }
  if (response.statusCode === 500) {
    error = parseError(response);
  }
  var entity = response.body;
  callback(error, response, entity);
};

function parseError(response) {
  return {
    code: response.body.error.name,
    message: response.body.error.message,
    description: response.body.error['format_string'],
    data: response.body.error.data,
    stack: response.body.error.stack
  }
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
  httpGet(model, 'delete', data, callback);
};

function search(model, data, callback) {
  httpGet(model, 'search', data, callback);
};

var searchFetch = function (model, data, callback) {
  search(model, data, function(error, response, entity) {
    expect(response.statusCode).to.equal(200);
    var total = entity.response.total;
    var pageSize = entity.response['page_length'];
    var items = [];
    _.each(entity.response.results, function(item, index) {
      get(model, {'uri': item.uri}, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        items.push(entity);
        if (Math.min(total, pageSize) === index + 1) {
          callback(items);
        }
      });
    });
  });
};

var deleteAll = function(model, done) {
  var pageSize = 20;
  search(model, {'ps': pageSize}, function(error, response, entity) {
    expect(response.statusCode).to.equal(200);
    var total = entity.response.total;
    console.log('\nDelete [%s] - total: %s', model, total);
    if (total === 0) {
      done();
      return;
    }
    _.each(entity.response.results, function(item, index) {
      remove(model, {'uri': item.uri}, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        if (Math.min(total, pageSize) === index + 1) {
          deleteAll(model, done);
        }
      });
    });
  });
};

describe('Cascade delete features', function() {

  this.timeout(10000);
  before(function(done) {
    xquerrailCommon.initialize(function(error, response, body) {
      expect(response.statusCode).to.equal(200);
      xquerrailCommon.login(function(error, response, body) {
        _.each(parents, function(parent) {
          create('parent-model', parent, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            expect(entity.name).to.equal(parent.name);
          });
        });
        _.each(children, function(child) {
          create('child-model', child, function(error, response, entity) {
            expect(response.statusCode).to.equal(200);
            expect(entity.name).to.equal(child.name);
          });
        });
        done();
      });
    }, module.filename);
  });

  describe('all children', function() {
    it('should exist', function(done) {
      _.each(children, function(child) {
        get('child-model', child, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.name).to.equal(child.name);
        });
      });
      done();
    });
  });

  describe('all parents', function() {
    it('should exist', function(done) {
      _.each(parents, function(parent) {
        get('parent-model', parent, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.name).to.equal(parent.name);
        });
      });
      done();
    });
  });

  describe('cascade - remove', function() {
    it('should delete parent and referenced child', function(done) {
      var parentName = parents[0].name;
      remove('parent-model', {'_cascade': 'remove', 'name': parentName}, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity.name).to.equal(parentName);
        var referencedChildren = _.filter(
          children,
          function(child) { return (child.parent === parentName || child.parent.indexOf(parentName) > -1); }
        );
        _.each(referencedChildren, function (child, index) {
          get('child-model', child, function(error, response, entity) {
            expect(response.statusCode).to.equal(404);
            if (referencedChildren.length === index + 1) {
              done();
            }
          });
        });
      });
    });
  });

  describe('cascade - detach', function() {
    it('should delete parent and referenced child', function(done) {
      var parentName = parents[1].name;
      searchFetch('child-model', {'parent.text': parentName}, function(referencedChildren) {
        remove('parent-model', {'_cascade': 'detach', 'name': parentName}, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity.name).to.equal(parentName);
          _.each(referencedChildren, function (child, index) {
            get('child-model', child, function(error, response, entity) {
              expect(response.statusCode).to.equal(200);
              _.each(child.parent, function(parent) {
                expect(parent.text).not.to.equal(parentName);
              });
              if (referencedChildren.length === index + 1) {
                done();
              }
            });
          });
        });
      });
    });
  });

  describe('no cascade', function() {
    it('should not delete parent', function(done) {
      var parentName = parents[2].name;
      searchFetch('child-model', {'parent.text': parentName}, function(referencedChildren) {
        remove('parent-model', {'name': parentName}, function(error, response, entity) {
          expect(response.statusCode).to.equal(500);
          expect(error.code).to.equal('REFERENCE-CONSTRAINT-ERROR');
          _.each(referencedChildren, function (child, index) {
            get('child-model', child, function(error, response, entity) {
              expect(response.statusCode).to.equal(200);
              if (referencedChildren.length === index + 1) {
                get('parent-model', {'name': parentName}, function(error, response, entity) {
                  expect(response.statusCode).to.equal(200);
                  done();
                });
              }
            });
          });
        });
      });
    });
  });

  after(function(done) {
    deleteAll('child-model', done);
  });

  after(function(done) {
    deleteAll('parent-model', done);
  });

});
