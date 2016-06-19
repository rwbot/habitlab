require! {
  'livescript'
  'livescript-loader'
  'gulp'
  'gulp-changed'
  'gulp-util'
  'gulp-print'
  'gulp-livescript'
  'gulp-yaml'
  'gulp-eslint'
  'browserify'
  'browserify-livescript'
  'through2'
  'path'
  'exorcist'
  'fs'
  'mkdirp'
  'webpack-stream'
  'vinyl-named'
}

webpack_config = require('./webpack.config.ls')

tspattern = [
  'src/interventions/**/*.ts'
]

es6pattern = [
  'src/interventions/**/*.es6'
]

lspattern = [
  'src/*.ls'
  'src/fields/*.ls'
  'src/libs_frontend/**/*.ls'
]

lspattern_srcgen = [
  'src/**/*.ls'
]

yamlpattern = [
  'src/manifest.yaml'
  'src/interventions/**/*.yaml'
]

eslintpattern_frontend = [
  'src/libs_frontend/**/*.js'
  'src/interventions/**/*.js'
]

jspattern_srcgen = [
  'src/**/*.js'
]

copypattern = [
  'src/**/*.html'
  'src/**/*.png'
  'src/*.js'
  'src/bower_components/**/*'
]

webpack_pattern = [
  'src/interventions/**/*.js'
  'src/interventions/**/*.ls'
]

browserify_js_pattern = [
  'src/interventions/**/*.js'
]

browserify_ls_pattern = [
  'src/interventions/**/*.ls'
]

gulp.task 'eslint_frontend', ->
  gulp.src(eslintpattern_frontend, {base: 'src'})
  #.pipe(gulp-print( -> "eslint_frontend: #{it}" ))
  .pipe(gulp-eslint({
    #parser: 'babel-eslint'
    parserOptions: {
      sourceType: 'script'
      ecmaVersion: 6
      ecmaFeatures: {
        'impliedStrict': true
      }
    }
    extends: 'eslint:recommended'
    envs: [
      'es6'
      'browser'
      'webextensions'
      #'node'
    ]
    globals: {
      #'$': true
      'require': true
      'env': true
      'exports': true
    }
    rules: {
      'no-console': 'off'
      'no-unused-vars': 'off'
      #'no-unused-vars': ['warn', {args: 'none', vars: 'local'}]
      'comma-dangle': ['warn', 'only-multiline']
      #'strict': 2
    }
  }))
  .pipe(gulp-eslint.formatEach('compact', process.stderr))

/*
gulp.task 'es6', ->
  gulp.src(es6pattern, {base: './'})
  .pipe(gulp-changed('.', {extension: '.js'}))
  .pipe(gulp-babel({
    #presets: ['es2015']
    plugins: [
      # this set of plugins will require chrome 51 or higher
      # https://github.com/askmatey/babel-preset-modern

      # the below are required by nodejs 6
      'transform-es2015-modules-commonjs'

      # the below are supported in chrome 52 and higher
      'transform-es2015-destructuring'
      'transform-es2015-function-name'

      # the below are not supported in chrome
      #'transform-exponentiation-operator'
      #'transform-async-to-generator'

      # the below are misc plugins
      #'undeclared-variables-check'
      'transform-strict-mode'
    ]
  }))
  .on('error', gulp-util.log)
  .pipe(gulp-print({colors: false}))
  .pipe(gulp.dest('.'))
  return
*/

/*
gulp.task 'typescript', ->
  gulp.src(tspattern, {base: './'})
  .pipe(gulp-changed('.', {extension: '.js'}))
  .pipe(gulp-typescript({noImplicitAny: true}))
  .on('error', gulp-util.log)
  .pipe(gulp-print({colors: false}))
  .pipe(gulp.dest('.'))
  return
*/

gulp.task 'livescript', ->
  gulp.src(lspattern, {base: 'src'})
  .pipe(gulp-changed('dist', {extension: '.js'}))
  .pipe(gulp-print( -> "livescript: #{it}" ))
  .pipe(gulp-livescript({bare: false}))
  .on('error', gulp-util.log)
  .pipe(gulp.dest('dist'))
  return

gulp.task 'livescript_srcgen', ->
  gulp.src(lspattern_srcgen, {base: 'src'})
  .pipe(gulp-changed('src_gen', {extension: '.js'}))
  #.pipe(gulp-print( -> "livescript_srcgen: #{it}" ))
  .pipe(gulp-livescript({bare: false}))
  .on('error', gulp-util.log)
  .pipe(gulp.dest('src_gen'))
  return

# TODO sourcemaps
# https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-multiple-destination.md
/*
gulp.task 'livescript_browserify', ->
  gulp.src(lspattern, {base: './'})
  .pipe(gulp-changed('.', {extension: '.js'}))
  .pipe(gulp-livescript({bare: false}))
  .on('error', gulp-util.log)
  .pipe(gulp-print({colors: false}))
  .pipe(gulp.dest('.'))
  return
*/

empty_or_updated = (stream, cb, sourceFile, targetPath) ->
  if not fs.existsSync(targetPath)
    stream.push sourceFile
    return cb!
  if fs.statSync(targetPath).size == 0
    stream.push sourceFile
    return cb!
  return gulp-changed.compareLastModifiedTime(stream, cb, sourceFile, targetPath)

gulp.task 'browserify_ls', ->
  # from
  # http://stackoverflow.com/questions/28441000/chain-gulp-glob-to-browserify-transform
  current_dir = process.cwd()
  browserified = ->
    return through2.obj (chunk, enc, callback) ->
      if chunk.isBuffer()
        relative_path = path.relative(current_dir, chunk.path)
        srcmap_path_relative = relative_path.replace(/^src\//, 'dist/').replace(/\.ls$/, '.js.map')
        srcmap_path = path.join(current_dir, srcmap_path_relative)
        outfile_path_relative = relative_path.replace(/^src\//, 'dist/').replace(/\.ls$/, '.js')
        outfile_path = path.join(current_dir, outfile_path_relative)
        outdir = path.dirname(outfile_path)
        mkdirp.sync outdir

        b = browserify(chunk.path, {
          #transform: ['browserify-livescript']
          extensions: ['.js', '.ls']
          debug: true
        })
        bundle = b.bundle()
        .pipe(exorcist(srcmap_path))
        .pipe(fs.createWriteStream(outfile_path), 'utf8')
        #chunk.contents = bundle
        #this.push(chunk)
      callback()
  return gulp.src(browserify_ls_pattern, {base: 'src'})
  .pipe(gulp-changed('dist', {extension: '.js', hasChanged: empty_or_updated}))
  .pipe(gulp-print( -> "browserify_ls: #{it}" ))
  .pipe(browserified())
  .on('error', gulp-util.log)
  #.pipe(gulp.dest('dist'))

# based on
# https://github.com/webpack/webpack-with-common-libs/blob/master/gulpfile.js
# https://github.com/shama/webpack-stream
gulp.task 'webpack', ->
  current_dir = process.cwd()
  myconfig = Object.create webpack_config
  return gulp.src(webpack_pattern, {base: 'src'})
  #.pipe(gulp-changed('dist', {extension: '.js', hasChanged: empty_or_updated}))
  .pipe(gulp-print( -> "webpack: #{it}" ))
  .pipe(vinyl-named( (file) ->
    relative_path = path.relative(path.join(current_dir, 'src'), file.path)
    relative_path_noext = relative_path.replace(/\.js$/, '').replace(/\.ls$/, '')
    return relative_path_noext
  ))
  .pipe(webpack-stream(myconfig))
  .on('error', gulp-util.log)
  .pipe(gulp.dest('dist'))

gulp.task 'browserify_js', ->
  # from
  # http://stackoverflow.com/questions/28441000/chain-gulp-glob-to-browserify-transform
  current_dir = process.cwd()
  browserified = ->
    return through2.obj (chunk, enc, callback) ->
      if chunk.isBuffer()
        relative_path = path.relative(current_dir, chunk.path)
        srcmap_path_relative = relative_path.replace(/^src\//, 'dist/').replace(/\.js$/, '.js.map')
        srcmap_path = path.join(current_dir, srcmap_path_relative)
        outfile_path_relative = relative_path.replace(/^src\//, 'dist/')
        outfile_path = path.join(current_dir, outfile_path_relative)
        outdir = path.dirname(outfile_path)
        mkdirp.sync outdir

        b = browserify(chunk.path, {
          #transform: ['browserify-livescript']
          extensions: ['.js', '.ls']
          debug: true
        })
        bundle = b.bundle()
        .pipe(exorcist(srcmap_path))
        .pipe(fs.createWriteStream(outfile_path), 'utf8')
        #chunk.contents = bundle
        #this.push(chunk)
      callback()
  return gulp.src(browserify_js_pattern, {base: 'src'})
  .pipe(gulp-changed('dist', {extension: '.js', hasChanged: empty_or_updated}))
  .pipe(gulp-print( -> "browserify_js: #{it}" ))
  .pipe(browserified())
  .on('error', gulp-util.log)
  #.pipe(gulp.dest('dist'))

/*
# based on
# https://github.com/gulpjs/gulp/blob/master/docs/recipes/fast-browserify-builds-with-watchify.md
gulp.task 'livescript_browserify', ->
  return browserify({
    entries: ['./browserify_test/test.ls']
    transform: ['browserify-livescript']
    debug: true
  })
  .bundle()
  .on('error', gulp-util.log.bind(gulp-util, 'Browserify Error'))
  .pipe(vinyl-source-stream('./browserify_test/test.js'))
  .pipe(vinyl-buffer()) # optional, remove if you don't need to buffer file contents
  .pipe(gulp-sourcemaps.init({loadMaps: true})) # optional, remove if you don't want sourcemaps
  .pipe(gulp-sourcemaps.write('.'))
  .pipe(gulp.dest('.'))

gulp.task 'typescript_browserify', ->
  return browserify({
    entries: ['./browserify_test/test.ts']
    debug: true
  })
  .plugin(tsify, {noImplicitAny: false})
  .bundle()
  .on('error', gulp-util.log.bind(gulp-util, 'Browserify Error'))
  .pipe(vinyl-source-stream('./browserify_test/test.js'))
  .pipe(vinyl-buffer()) # optional, remove if you don't need to buffer file contents
  .pipe(gulp-sourcemaps.init({loadMaps: true})) # optional, remove if you don't want sourcemaps
  .pipe(gulp-sourcemaps.write('.'))
  .pipe(gulp.dest('.'))
*/

gulp.task 'yaml', ->
  gulp.src(yamlpattern, {base: 'src'})
  .pipe(gulp-changed('dist', {extension: '.json'}))
  .pipe(gulp-print( -> "yaml: #{it}" ))
  .pipe(gulp-yaml({space: 2}))
  .on('error', gulp-util.log)
  .pipe(gulp.dest('dist'))
  return

gulp.task 'copy', ->
  gulp.src(copypattern, {base: 'src'})
  .pipe(gulp-changed('dist'))
  #.pipe(gulp-print( -> "copy: #{it}" ))
  .pipe(gulp.dest('dist'))
  return

gulp.task 'js_srcgen', ->
  gulp.src(jspattern_srcgen, {base: 'src'})
  .pipe(gulp-changed('src_gen'))
  #.pipe(gulp-print( -> "js_srcgen: #{it}" ))
  .pipe(gulp.dest('src_gen'))
  return


tasks_and_patterns = [
  ['livescript', lspattern]
  #['livescript_srcgen', lspattern_srcgen]
  #['js_srcgen', jspattern_srcgen]
  #['typescript', tspattern]
  #['es6', es6pattern]
  ['yaml', yamlpattern]
  #['browserify_js', browserify_js_pattern]
  #['browserify_ls', browserify_ls_pattern]
  ['copy', copypattern]
  ['eslint_frontend', eslintpattern_frontend]
  #['livescript_browserify', lspattern_browserify]
]

gulp.task 'build', tasks_and_patterns.map((.0))

# TODO we can speed up the watch speed for browserify by using watchify
# https://github.com/marcello3d/gulp-watchify/blob/master/examples/simple/gulpfile.js
# https://github.com/gulpjs/gulp/blob/master/docs/recipes/fast-browserify-builds-with-watchify.md
gulp.task 'watch' ->
  for [task,pattern] in tasks_and_patterns
    gulp.watch pattern, [task]
  return

gulp.task 'default', ['build', 'watch', 'webpack']
