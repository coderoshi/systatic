fs        = require('fs')
path      = require('path')
jade      = require(path.join(__dirname, '..', 'plugins', 'jade_template'))
servitude = require('servitude')
bricks    = require('bricks')
exec      = require('child_process').exec

exports.inProject = (dirname)->
  return true if path.existsSync(dirname)
  false


exports.clone = (dirname, template)->
  templatePath = path.join(__dirname, '..', 'templates', template)
  console.log "Generating project #{dirname}"
  exec "cp -R #{templatePath} #{dirname}", (error, stdout, stderr)->
    console.log error


exports.startServer = (basedir, port, ipaddr, log)->
  appserver = new bricks.appserver()

  appserver.addRoute("/$", jade, basedir: basedir, name: 'index')
  appserver.addRoute("/stylesheets/(.+)", servitude, basedir: path.join(basedir, 'stylesheets'))
  appserver.addRoute("/javascripts/(.+)", servitude, basedir: path.join(basedir, 'javascripts'))
  appserver.addRoute("/images/(.+)", appserver.plugins.filehandler, basedir: basedir)
  appserver.addRoute(".+", jade, basedir: basedir)
  appserver.addRoute(".+", appserver.plugins.fourohfour)

  if log
    try
      appserver.addRoute(".+", appserver.plugins.loghandler, section: 'final', filename: log)
    catch error
      console.log "Error opening logfile, continuing without logfile"

  server = appserver.createServer()

  try
    server.listen(port, ipaddr)
  catch error
    console.log "Error starting server, unable to bind to #{ipaddr}:#{port}"


#sys       = require('sys')

###
copyFile = (source, dest, callback)->
  read = fs.createReadStream(source)
  write = fs.createWriteStream(dest)
  read.on('end', callback)
  sys.pump(read, write)

mkdir_p = (path, mode, callback, position)->
  parts = require('path').normalize(path).split(osSep)

  mode = mode || process.umask()
  position = position || 0

  return callback() if position >= parts.length

  directory = parts.slice(0, position + 1).join(osSep) || osSep
  fs.stat directory, (err)->
    if err === null
      mkdir_p(path, mode, callback, position + 1)
    else
      fs.mkdir directory, mode, (err)->
        if err && err.errno != 17
          return callback(err)
        else
          mkdir_p(path, mode, callback, position + 1)

mkdir = (path, mode, recursive, callback)->
  if typeof(recursive) !== 'boolean'
    callback = recursive
    recursive = false

  if typeof(callback) !== 'function'
    callback = ()->

  unless recursive
    fs.mkdir(path, mode, callback)
  else
    mkdir_p(path, mode, callback)
###