_          = require('underscore')
log        = console.log
fs         = require('fs')
path       = require('path')
jade       = require(path.join(__dirname, 'plugins', 'jade_template'))
servitude  = require('servitude')
bricks     = require('bricks')
exec       = require('child_process').exec
{walkSync} = require('./utils')

## A TREE DIED FOR ME (book)

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

  # TODO: this should be part of utils.compileOut
  try
    fs.mkdirSync(builddir)
    #fs.mkdirSync("#{builddir}/derp")
    fs.mkdirSync("#{builddir}/stylesheets")
    fs.mkdirSync("#{builddir}/javascripts")
  catch e

  events = buildEventManager()

  # load plugins
  # TODO: eventually pull these all from config.json

  events.start('compress')

  log "Done"


# Copies all built files to a remote source, like S3
exports.deploy = ()->
  c = config()
  builddir = c.buildDir || 'build'
  builddir = path.resolve(builddir)
  dcs = c.deploy || []

  _.forEach dcs, (dc)->
    s3 = require('noxmox').nox.createClient
      key: dc.access_key_id
      secret: dc.secret_access_key
      bucket: dc.bucket

    walkSync builddir, null, null, (fullname)->
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
  events = buildEventManager()

  #events.start('clean')

buildEventManager = ()->
  BuildEventManager = require('./build_event_manager')
  PluginManager     = require('./plugin_manager')
  plugins = new PluginManager()
  events  = new BuildEventManager(plugins)
  events
