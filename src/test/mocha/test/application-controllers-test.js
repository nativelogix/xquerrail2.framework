'use strict';

var xquerrailCommon = require('./xquerrailCommon');
var _ = require('lodash');
var assert = require('chai').assert;
var expect = require('chai').expect;
var request = require('request').defaults({jar: true});

describe('Application controllers (applications, domains)', function() {

  before(function(done) {
    xquerrailCommon.initialize(done);
  });

  describe('applications', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it ('should return the list of applications in json format', function(done) {
      xquerrailCommon.httpMethod('GET', 'applications', 'get', undefined, undefined, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity).to.have.property('applications');
        expect(entity.applications).to.be.instanceof(Array);
        expect(entity.applications).to.not.be.empty;
        expect(entity.applications.length).to.equal(2);
        done();
      }, 'json', undefined);
    });

    it ('should return the list of applications in xml format', function(done) {
      xquerrailCommon.httpMethod('GET', 'applications', 'get', undefined, undefined, function(error, response, entity) {
        expect(response.statusCode).to.equal(200);
        expect(entity).to.have.property('applications');
        expect(entity.applications).to.not.be.empty;
        expect(entity.applications).to.have.property('application');
        expect(entity.applications.application.length).to.equal(2);
        done();
      }, 'xml', undefined);
    });

  });

  describe('domains', function() {

    before(function(done) {
      xquerrailCommon.login(function() {
        done();
      });
    });

    it ('should return domain for the first application in json format', function(done) {
      xquerrailCommon.httpMethod('GET', 'applications', 'get', undefined, undefined, function(error, response, entity) {
        var application = entity.applications[0];
        expect(application).to.have.property('name');
        expect(application).to.have.property('domain');
        expect(application.domain).to.have.property('link');
        expect(application.domain.link).to.equal('/applications/' + application.name + '/domain/get.json');
        xquerrailCommon.httpMethod('GET', 'applications/' + application.name + '/domain', 'get', undefined, undefined, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          // Add swagger validation
          expect(entity).to.have.property('$schema');
          expect(entity['$schema']).to.not.be.empty;
          expect(entity).to.have.property('definitions');
          expect(entity).to.have.property('properties');
          done();
        }, 'json', undefined);
      }, 'json', undefined);
    });

    it ('should return domain for the first application in xml format', function(done) {
      xquerrailCommon.httpMethod('GET', 'applications', 'get', undefined, undefined, function(error, response, entity) {
        var application = entity.applications.application[0];
        expect(application).to.have.property('name');
        expect(application).to.have.property('domain');
        expect(application.domain).to.have.property('link');
        expect(application.domain.link).to.equal('/applications/' + application.name + '/domain/get.xml');
        xquerrailCommon.httpMethod('GET', 'applications/' + application.name + '/domain', 'get', undefined, undefined, function(error, response, entity) {
          expect(response.statusCode).to.equal(200);
          expect(entity).to.have.property('domain');
          expect(entity.domain).to.not.be.empty;
          expect(entity.domain).to.have.property('model');
          expect(entity.domain.model).to.be.instanceof(Array);
          expect(entity.domain.model).to.not.be.empty;
          done();
        }, 'xml', undefined);
      }, 'xml', undefined);
    });

  });

});
