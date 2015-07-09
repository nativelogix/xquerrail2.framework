var gulp = require('gulp');
var gutil = require('gulp-util');

var del = require('del');
var fs = require('fs');
var pkg = require('./package.json');
var bump = require('gulp-bump');
var template = require('gulp-template');
var git = require('gulp-git');
var gitinfo = require('gulp-gitinfo')
var es   = require('event-stream')
var xray = require('gulp-xray-runner')
var mocha = require('gulp-mocha');
var watch = require('gulp-watch');
var plumber = require('gulp-plumber');
var runSequence = require('run-sequence');
var inject = require('gulp-inject-string');
var nconf = require('nconf');
// var run = require('gulp-run');
// var map = require('vinyl-map');
var exec = require('gulp-exec');
// var data = require('gulp-data');
var install = require('gulp-install');

nconf
  .argv()
  .env()
  .file({ file: './ml.json' });

var ml = nconf.get('ml');
var roxy = nconf.get('roxy');

var getRoxyProperties = function() {
  var options = {
    'cwd': roxy.path || 'roxy'
  }
  var exec = require('child_process').execSync;
  var roxyCommand = 'ruby -Ideploy -Ideploy/lib deploy/lib/ml.rb ' + roxy.env;
  var stdout = exec(roxyCommand + ' info --format=json', options)
  return JSON.parse(stdout).properties;
};

var roxySettings = function() {
  return {
    'properties': getRoxyProperties()
  };
};

var validateMlSettings = function () {
  if (!ml) {
    throw new gutil.PluginError('xquerrail', 'ml settings are required. They can be defined as arguments, environment variables, ml.json or from Roxy properties.')
  }
  if (!ml.port) {
   throw new gutil.PluginError('xquerrail', 'ml.port is required.')
  }
  if (!ml.host) {
   throw new gutil.PluginError('xquerrail', 'ml.host is required.')
  }
  if (!ml.user) {
   throw new gutil.PluginError('xquerrail', 'ml.user is required.')
  }
  if (!ml.password) {
   throw new gutil.PluginError('xquerrail', 'ml.password is required.')
  }
};

if (!roxy) {
  roxy = {};
} else {
  if (!ml) {
    ml = {};
  }
  var properties = roxySettings().properties;
  for (var key in properties) {
    if (key.indexOf('ml.') == 0) {
      if (!ml[key.substring(3)]) {
        ml[key.substring(3)] = properties[key];
      }
    }
  };
  if (!ml.port) {
    ml.port = ml['app-port'];
  }
  if (!ml.host) {
    ml.host = ml['server'];
  }
}

var version = pkg.version;
var lastCommit;

gulp.task('update-xqy', ['copy-no-xqy', 'copy-xqy', 'last-git-commit'], function () {
  gutil.log('version: ' + version + ' - lastcommit: ' + lastCommit);
  return gulp.src(['dist/**/config.xqy'])
    .pipe(template({version: version, lastcommit: lastCommit}))
    .pipe(gulp.dest('./dist'));
});

gulp.task('copy-xqy', function () {
  return gulp.src(['src/main/**/*.xqy'])
    .pipe(inject.after('xquery version "1.0-ml";', '\n(:~ ' + fs.readFileSync('license.txt', 'utf8') + ' :)'))
    .pipe(gulp.dest('./dist'));
});

gulp.task('copy-no-xqy', function() {
  return gulp.src(['src/main/**/*.xsd', 'src/main/**/*.xsl'])
    .pipe(inject.after('<?xml version="1.0" encoding="UTF-8"?>', '\n<!-- ' + fs.readFileSync('license.txt', 'utf8') + ' -->'))
    .pipe(gulp.dest('./dist'));
});

gulp.task('last-git-commit', function(cb) {
  return gitinfo()
    .pipe(es.map(function(data) {
      lastCommit = data['local.branch.current.SHA'];
      gutil.log('data: ', data, '\nlastCommit: ', lastCommit);
      cb();
    }))
})

gulp.task('roxy:watch', function() {
  var modulesDB = roxySettings().properties['ml.modules-db'];
  var environment = roxy.env;
  var path = require('path');
  var options = {
    'cwd': 'roxy',
    pipeStdout: true,
    roxy : {
      'modulesDB': modulesDB,
      'environment': environment
    },
    'normalize': function(s) {
      s = s.replace(/\\/g,'/');
      if (s.substring(s.length-1) === '/') {
        s = s.substring(0, s.length-1)
      }
      return s;
    },
    'join': function(f) {
      return path.join(f.cwd, f.base);
    }
  };
  var reportOptions = {
    err: true, // default = true, false means don't write err
    stderr: true, // default = true, false means don't write stderr
    stdout: true // default = true, false means don't write stdout
  }

  watch(['src/**/*.xqy'], {read: false})
    .pipe(plumber())
    // .pipe(exec('echo <%= options.normalize(file.path) %>', options))
    .pipe(exec('ml <%= options.roxy.environment %> load <%= options.normalize(file.path) %> --db=<%= options.roxy.modulesDB %> --remove-prefix=<%= options.normalize(options.join(file)) %> -v', options))
    .pipe(exec.reporter(reportOptions));
});

gulp.task('coverage', function () {
});

gulp.task('lint', function () {
});

gulp.task('xray', function (cb) {
  validateMlSettings();
  var options = {
    /* https://github.com/mikeal/request#http-authentication */
    auth: {
      username: ml.user,
      password: ml.password,
      sendImmediately: false
    },
    url: 'http://' + ml.host + ':' + ml.port + '/xray',
    testDir: 'test',
    files: ['test/**/*.xqy']
  };
  xray(options, cb);
});

gulp.task('mocha', function (cb) {
  validateMlSettings();
  var mochaOptions = {
    timeout: 15000,
    reporter: 'spec'
  };
  gulp.src('src/test/mocha/test/*.js')
    .pipe(mocha(mochaOptions))
    .on('end', cb);
});

gulp.task('install', function (cb) {
  gulp.src('src/test/mocha/package.json')
    .pipe(install())
    .on('end', cb);
});

gulp.task('clean', function (cb) {
  del(['./dist'], cb);
});

gulp.task('tag', ['build'], function (/*cb*/) {
  var options = {
    args: '-v'
  };
  var pkg = require('./package.json');
  var v = 'v' + pkg.version;
  var message = 'Release ' + v;

  return gulp.src(['./*', '!node_modules/'])
    .pipe(git.commit(message, options))
    .pipe(git.tag(v, message,
      git.push('origin', 'master', {args: '--tags'})
      .end()
    ));
});

gulp.task('bump', function () {
  return gulp.src(['./package.json'])
    .pipe(bump())
    .pipe(gulp.dest('./'));
});

gulp.task('watch-update-xqy', function()  {
  gulp.src(['src/main/**/*.xqy'])
    .pipe(watch())
    .pipe(plumber()) // This will keeps pipes working after error event
    .pipe(inject.after('xquery version "1.0-ml";', '\n(:~ ' + fs.readFileSync('license.txt', 'utf8') + ' :)'))
    .pipe(gulp.dest('./dist'));
});

gulp.task('build', ['update-xqy'], function (cb) {
  cb();
});

gulp.task('release', ['build'], function () {
  // build is complete, release the kraken!
});

gulp.task('test', function(cb) {
    runSequence('coverage', 'lint', 'xray', 'mocha', function() {
        console.log('Test completed.');
        cb();
    });
});

gulp.task('default', function() {
    runSequence('test', 'clean', 'build', function() {
        console.log('Build completed.');
    });
});

module.exports.ml = ml;
