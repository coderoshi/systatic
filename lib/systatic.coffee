log       = console.log
fs        = require('fs')
path      = require('path')
jade      = require(path.join(__dirname, 'plugins', 'jade_template'))
servitude = require('servitude')
bricks    = require('bricks')
exec      = require('child_process').exec
u         = require('underscore')

# hopefully use servitude
less      = require('less')
coffee    = require('coffee-script')
uglifyjs  = require('uglify-js')
cleancss  = require('clean-css')
compress  = require('compress-buffer')

exports.config = config = ()->
  return @configData if @configData?
  @configData = require(path.resolve(path.join('.', 'config.json')))

exports.inProject = (dirname)->
  return true if path.existsSync(path.join(dirname, 'config.json'))
  false

exports.clone = (dirname, template)->
  templatePath = path.join(__dirname, '..', 'templates', template)
  log "Generating project #{dirname}"
  exec "cp -R #{templatePath} #{dirname}", (error, stdout, stderr)->
    log error

getPlugin = (value, appserver)->
  switch value
    when "servitude" then servitude
    when "filehandler" then appserver.plugins.filehandler
    else appserver.plugins.filehandler

assetRoute = (appserver, asset)->
  c = config()
  basedir = c.sourceDir || 'src'
  appserver.addRoute(c[asset].route, getPlugin(c[asset].plugin, appserver), basedir: path.join(basedir, c[asset].baseDir))

exports.startServer = (port, ipaddr, logfile)->
  c = config()
  basedir = c.sourceDir || 'src'

  appserver = new bricks.appserver()
  appserver.addRoute("/$", jade, basedir: basedir, name: 'index')
  assetRoute(appserver, 'stylesheets')
  assetRoute(appserver, 'javascripts')
  assetRoute(appserver, 'images')
  # TODO: crap. cannot extract directories from regexp.
  appserver.addRoute(".+", jade, basedir: basedir, stylesheetspath: '/stylesheets/', javascriptspath: '/javascripts/')

  fourohfour = (request, response, options) ->
    request.url = "/404"
    response.statusCode 404
    jade.plugin request, response, options

  appserver.addRoute(".+", fourohfour)

  if logfile
    try
      appserver.addRoute(".+", appserver.plugins.loghandler, section: 'final', filename: logfile)
    catch error
      log "Error opening logfile, continuing without logfile"

  server = appserver.createServer()

  try
    server.listen(port, ipaddr)
  catch error
    log "Error starting server, unable to bind to #{ipaddr}:#{port}"


exports.test = (port, ipaddr, logfile)->
  c = config()
  builddir = c.buildDir || 'build'
  
  appserver = new bricks.appserver()
  appserver.addRoute("/$", appserver.plugins.redirect, routes: [{ path: "/$", url: "/index.html" }])
  appserver.addRoute(".+", appserver.plugins.filehandler, basedir: builddir)

  fourohfour = (request, response, options) ->
    request.url = "/404.html"
    appserver.plugins.filehandler.plugin request, response, options

  appserver.addRoute(".+", fourohfour, basedir: builddir)

  server = appserver.createServer()

  try
    server.listen(port, ipaddr)
  catch error
    log "Error starting server, unable to bind to #{ipaddr}:#{port}"


# Compiles and compacts all assets into a minimal set of files
exports.build = ()->
  c = config()
  basedir = c.sourceDir || 'src'
  basedir = path.resolve(basedir)

  builddir = c.buildDir || 'build'

  try
    fs.mkdirSync(builddir)
    #fs.mkdirSync("#{builddir}/derp")
    fs.mkdirSync("#{builddir}/stylesheets")
    fs.mkdirSync("#{builddir}/javascripts")
  catch e

  builddir = path.resolve(builddir)


  BuildEventManager = require('./build_event_manager').BuildEventManager
  events = new BuildEventManager()

  # load plugins
  events.register( require('./plugins/echo') )
  events.register( require('./plugins/jade') )


  events.start('compress')

  ###
  log "Building HTML"
  assets = renderHTML(c, basedir, builddir)
  log "Building CSS"
  renderCSS(c, basedir, builddir, assets.css)
  log "Building JS"
  renderJS(c, basedir, builddir, assets.js)

  compressBuildFiles(/\.(html|css|js)$/)
  ###

  log "Done"

compressBuildFiles = (c, pattern)->
  log "Compressing Assets"
  #inline = dc.compress == "inline"
  walkSync builddir, pattern, (fullname)->
    zipFile(fullname, false) #inline)


# Copies all built files to a remote source, like S3
exports.deploy = ()->
  c = config()
  builddir = c.buildDir || 'build'
  builddir = path.resolve(builddir)
  dcs = c.deploy || []

  u.forEach dcs, (dc)->
    # TODO: compress in seperate phase, always append .gz
    # If a deployment wants inline, change file names on transfer
    ###
    if dc.compress? && dc.compress.toString() != "false"
      log "Compressing Assets"
      inline = dc.compress == "inline"
      walkSync builddir, /\.(html|css|js)$/, (fullname)->
        zipFile(fullname, inline)
    ###

    s3 = require('noxmox').nox.createClient
      key: dc.access_key_id
      secret: dc.secret_access_key
      bucket: dc.bucket

    walkSync builddir, null, (fullname)->
      filename = fullname.replace(builddir, '').replace(/\//, '')
      data = fs.readFileSync(fullname)
      headers = { 'Content-Length': data.length, 'x-amz-acl':'public' }
      headers['Content-Encoding'] = 'gzip' if filename.match(/.gz$/)
      req = s3.put(filename, headers)
      log filename
      req.on 'continue', ()->
        log "pushing #{filename}"
        req.end(data)
      req.on 'response', (res)->
        log "responding #{filename}"
        res.on 'data', (chunk)-> log chunk
        res.on 'end', ()-> log 'File is now stored on S3' if res.statusCode == 200


  log "Deployed"


exports.clean = ()->
  c = config()
  builddir = c.buildDir || 'build'
  if builddir == '.' || builddir.match(/^\//) || builddir == '~' || builddir == ''
    return log('No.')
  exec "rm -rf #{builddir}", (error, stdout, stderr)->
    log error


## Helper functions

###
renderHTML = (c, basedir, builddir)->
  assets = {css: {}, js: {}}

  ignores = c.ignore || []

  walkSync basedir, /\.jade$/, (fullname)->
    filename = fullname.replace(basedir, '').replace(/\//, '')
    for ignore in ignores
      return if filename.match(ignore)
    outputfile = path.join(builddir, filename.replace(/\.jade$/, '.html'))
    randomname = (Math.random() * 0x100000000 + 1).toString(36)
    jade.compile(randomname, fullname, outputfile, assets, true)

  assets
###


## A TREE DIED FOR ME (book)

renderJS = (c, basedir, builddir, jsassets)->
  # Do all the same things for javascript
  jsbasedir = c.javascripts.baseDir || 'javascripts'
  jsbuilddir = path.resolve(path.join(builddir, jsbasedir))
  jsbasedir = path.resolve(path.join(basedir, jsbasedir))

  jsdata = {}

  # first compile up all coffee files
  walkSync jsbasedir, /\.coffee$/, (fullname)->
    filename = fullname.replace(jsbasedir, '').replace(/\//, '')
    filedata = fs.readFileSync(fullname, 'utf8')
    jsdata[filename] = coffee.compile(filedata)

  # get all of the regular js files
  walkSync jsbasedir, /\.js$/, (fullname)->
    filename = fullname.replace(jsbasedir, '').replace(/\//, '')
    jsdata[filename] = fs.readFileSync(fullname, 'utf8')
  
  jsp = uglifyjs.parser
  pro = uglifyjs.uglify

  # output to merged JS files
  u.forEach jsassets, (files, outputname)->
    outputname = path.join(jsbuilddir, "#{outputname}.js")
    buffer = ''
    u.forEach files, (i, assetkey)->
      unless jsdata[assetkey]?
        log "Unknown asset #{assetkey}"
        return
      buffer += jsdata[assetkey]
    # write buffer to outputname
    ast = jsp.parse(buffer)    # parse code and get the initial AST
    ast = pro.ast_mangle(ast)  # get a new AST with mangled names
    ast = pro.ast_squeeze(ast) # get an AST with compression optimizations
    finalCode = pro.gen_code(ast)
    fs.writeFileSync(outputname, finalCode, 'utf8')


renderCSS = (c, basedir, builddir, cssassets)->
  cssbasedir = c.stylesheets.baseDir || 'stylesheets'
  cssbuilddir = path.resolve(path.join(builddir, cssbasedir))
  cssbasedir = path.resolve(path.join(basedir, cssbasedir))

  parser = new less.Parser
    paths: [cssbasedir], # Specify search paths for @import directives
    #filename: 'style.less' # Specify a filename, for better error messages

  cssdata = {}

  # first compile up all less files
  walkSync cssbasedir, /\.less$/, (fullname)->
    filename = fullname.replace(cssbasedir, '').replace(/\//, '')
    filedata = fs.readFileSync(fullname, 'utf8')
    parser.parse filedata, (e, tree)->
      cssdata[filename] = tree.toCSS(compress: true)

  # get all of the regular css files
  walkSync cssbasedir, /\.css$/, (fullname)->
    filename = fullname.replace(cssbasedir, '').replace(/\//, '')
    cssdata[filename] = fs.readFileSync(fullname, 'utf8')
  
  # output to merged CSS files
  u.forEach cssassets, (files, outputname)->
    outputname = path.join(cssbuilddir, "#{outputname}.css")
    buffer = ''
    u.forEach files, (i, assetkey)->
      unless cssdata[assetkey]?
        log "Unknown asset #{assetkey}"
        return
      buffer += cssdata[assetkey]
    # write buffer to outputname
    finalCode = cleancss.process(buffer)
    fs.writeFileSync(outputname, finalCode, 'utf8')


# compress asset files
zipFile = (filename, inline)->
  data = fs.readFileSync(filename, 'utf8')
  compressedData = compress.compress(new Buffer(data))
  outputname = if inline then filename else "#{filename}.gz"
  fs.writeFileSync(outputname, compressedData, 'utf8')



# Walks directories and finds files matching the given filter
# TODO: make this more systatic-centric. pass in where you wish
# to walk: source, build, javascripts, stylesheets, images.
# Optionally show ignored files (false by default)
walkSync = (start, filter, cb)->
  filter = /./ unless filter?
  if fs.statSync(start).isDirectory()
    collection = fs.readdirSync(start).reduce((acc, name)->
      if fs.statSync(path.join(start, name)).isDirectory()
        acc.dirs.push(name)
      else
        if name.match(filter)
          acc.names.push(path.join(start, name))
      acc
    names: []
    dirs: []
    )
    if collection.names.length > 0
      collection.names.forEach (fullname)-> cb(fullname)
    for dir in collection.dirs
      walkSync(path.join(start, dir), filter, cb)
  else
    throw new Error("#{start} is not a directory")
