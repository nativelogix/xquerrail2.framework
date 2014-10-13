var gulp = require('gulp');
var gutil = require('gulp-util');

var fs = require('fs');
var pkg = require('./package.json');
var rename = require('gulp-rename');
var clean = require('gulp-clean');
var bump = require('gulp-bump');
var template = require('gulp-template');
var header = require('gulp-header');
var git = require('gulp-git');
var gitinfo = require('gulp-gitinfo')
var es   = require('event-stream')
var xray = require('gulp-xray-runner')
var argv = require('yargs').argv;
var mocha = require('gulp-mocha');
var watch = require('gulp-watch');
var plumber = require('gulp-plumber');
var runSequence = require('run-sequence');

var ml;
try {
  ml = require('./ml.json')
} catch (e) {
  ml = argv.ml;
}
var version = pkg.version;
var lastCommit;

module.exports.ml = ml;
gulp.task('update-xqy', ['copy-no-xqy', 'copy-xqy', 'last-git-commit'], function () {
  gutil.log('version: ' + version + ' - lastcommit: ' + lastCommit);
  return gulp.src(['dist/**/config.xqy'])
    .pipe(template({version: version, lastcommit: lastCommit}))
    .pipe(gulp.dest('./dist'));
});

gulp.task('copy-xqy', function () {
  return gulp.src(['src/main/**/*.xqy'])
    .pipe(header(fs.readFileSync('license.txt', 'utf8')))
    .pipe(gulp.dest('./dist'));
});

gulp.task('copy-no-xqy', function () {
  return gulp.src(['src/main/**/*.xsd', 'src/main/**/*.xsl'])
    .pipe(gulp.dest('./dist'));
});

gulp.task('last-git-commit', function() {
  return gitinfo()
    .pipe(es.map(function(data, cb) {
      lastCommit = data['\'local.branch.current.SHA,\' '];
      cb();
    }))
})

gulp.task('coverage', function () {
});

gulp.task('lint', function () {
});

gulp.task('xray', function (cb) {
  var options = {
    /* https://github.com/mikeal/request#http-authentication */
    auth: {
      username: ml.user,
      password: ml.password,
      sendImmediately: false
    },
    url: 'http://' + ml.host + ':' + ml.port + '/xray',//'/main/_framework/lib/xray',
    testDir: 'test',
    files: ['test/**/*.xqy']
  };
  xray(options, cb);
});

gulp.task('mocha', function () {
  var mochaOptions = {reporter: 'dot'};
  gulp.src('src/test/mocha/test/*.js')
    .pipe(mocha(mochaOptions));
});

gulp.task('clean', function () {
  return gulp.src('./dist', { read: false })
    .pipe(clean());
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
    .pipe(header(fs.readFileSync('license.txt', 'utf8')))
    .pipe(gulp.dest('./dist'));
});

// gulp.task('npm', function (done) {
//   require('child_process').spawn('npm', ['publish'], { stdio: 'inherit' })
//     .on('close', done);
// });

gulp.task('build', ['update-xqy'], function (cb) {
  cb();
  // return gulp.src('./src/contra.js')
  //   .pipe(gulp.dest('./dist'))
  //   .pipe(rename('contra.min.js'))
  //   .pipe(uglify())
  //   // .pipe(size())
  //   .pipe(gulp.dest('./dist'));
});

gulp.task('release', ['build'], function () {
  // build is complete, release the kraken!
});

gulp.task('test', ['coverage', 'lint', 'mocha', 'xray']);
// gulp.task('default', ['test', 'clean', 'build']);
gulp.task('default', function() {
    runSequence('test', 'clean', 'build', function() {
        console.log('Build completed.');
    });
});
