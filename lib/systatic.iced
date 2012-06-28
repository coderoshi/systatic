log        = console.log
{join}     = require('path')
path       = require('path')
jade       = require(path.join(__dirname, 'plugins', 'jade_template'))
servitude  = require('servitude')
bricks     = require('bricks')
exec       = require('child_process').exec
{walkSync} = require('./utils')

# iced       = require('iced-coffee-script')
# iced.catchExceptions()

## A TREE DIED FOR ME (book)

exports.config = config = ()->
  return @configData if @configData?
  @configData = require(path.resolve(join('.', 'config.json')))

exports.inProject = (dirname)->
  return true if path.existsSync(join(dirname, 'config.json'))
  false

exports.clone = (dirname, template)->
  templatePath = join(__dirname, '..', 'templates', template)
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
  appserver.addRoute(c[asset].route, getPlugin(c[asset].plugin, appserver), basedir: join(basedir, c[asset].baseDir))

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
  buildManager().start('compress')
  log "Built"

# Copies all built files to a remote source, like S3
exports.publish = ()->
  buildManager().start('publish')
  log "Published"

# Deletes the build directory
exports.clean = ()->
  buildManager().start('clean')
  log "Cleaned"

buildManager = ()->
  BuildManager  = require('./build_manager').BuildManager
  PluginManager = require('./plugin_manager').PluginManager
  configData    = require(path.resolve(path.join('.', 'config.json')))
  plugins       = new PluginManager(configData)
  events        = new BuildManager(configData, plugins)
  events
