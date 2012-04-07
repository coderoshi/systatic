log       = console.log
fs        = require('fs')
path      = require('path')
jade      = require(path.join(__dirname, 'plugins', 'jade_template'))
servitude = require('servitude')
bricks    = require('bricks')
exec      = require('child_process').exec

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
  appserver.addRoute(".+", appserver.plugins.fourohfour)

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


# Compiles and compacts all assets into a minimal set of files
exports.build = ()->
  c = config()
  basedir = c.sourceDir || 'src'
  basedir = path.resolve(basedir)

  builddir = c.buildDir || 'build'

  try
    fs.mkdirSync(builddir)
    fs.mkdirSync("#{builddir}/derp")
  catch e

  builddir = path.resolve(builddir)

  ignores = c.ignore || []


  assets = {css: {}, js: {}}
  walkSync basedir, /\.jade$/, (filenames)->
    return if filenames.length == 0
    filenames.forEach (fullname)->
      filename = fullname.replace(basedir, '').replace(/\//, '')
      for ignore in ignores
        return if filename.match(ignore)
      outputfile = path.join(builddir, filename.replace(/\.jade$/, '.html'))
      jade.compile(filename.replace(/.jade$/, ''), fullname, outputfile, assets) #, true)

  # now we have all the assets and how to group them together
  console.log assets


# Copies all built files to a remote source, like S3
exports.deploy = ()->
  log "== Not yet implemented"

exports.clean = ()->
  c = config()
  builddir = c.buildDir || 'build'
  if builddir == '.' || builddir.match(/^\//) || builddir == '~' || builddir == ''
    return log('No.')
  exec "rm -rf #{builddir}", (error, stdout, stderr)->
    log error


# Walks directories and finds files matching the given filter
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
    cb(collection.names)
    for dir in collection.dirs
      walkSync(path.join(start, dir), filter, cb)
  else
    throw new Error("#{start} is not a directory")
