_          = require 'underscore'
fs         = require 'fs'
{join}     = require 'path'
jade       = require 'jade'
{walkSync} = require '../utils'

basedir  = null
basepath = '/'
uglify   = false
stylesheetspath = '/stylesheets/'
javascriptspath = '/javascripts/'
compiled = false


inflateFiles = (sourceDir, pattern)->
  files = []
  walkSync sourceDir, pattern, null, (filename)->
    files.push filename.replace("#{sourceDir}/", '')
  files


# force css sourceDir to be the same as the public path
stylesheets = ()->
  files = _.flatten(arguments)

  # TODO: BAD BAD BAD! Extract /src/ from sourceDir and javascript/baseDir
  sourceDir = 'src/stylesheets'

  if typeof(files) == 'undefined'
    files =[]
    walkSync sourceDir, null, null, (filename)->
      files.push filename.replace("#{sourceDir}/", '')
  
  files[pos] = inflateFiles(sourceDir, file) for file, pos in files

  files = _.uniq(_.flatten(files))

  scripts = ""
  for file in files
    if file.match(/.less$/)
      scripts += "<link href='#{stylesheetspath}#{file}' rel='stylesheet/less' type='text/css' />\n"
    else
      scripts += "<link href='#{stylesheetspath}#{file}' type='text/css' />\n"
  scripts
  scripts += "<script src='http://lesscss.googlecode.com/files/less-1.3.0.min.js'></script>\n"



# TODO: Make "scriptserver" just execute any "javascript" registered renders
javascripts = ()->
  files = _.flatten(arguments)

  # TODO: BAD BAD BAD! Extract /src/ from sourceDir and javascript/baseDir
  sourceDir = 'src/javascripts'
  
  if typeof(files) == 'undefined'
    files =[]
    walkSync sourceDir, null, null, (filename)->
      files.push filename.replace("#{sourceDir}/", '')
  
  files[pos] = inflateFiles(sourceDir, file) for file, pos in files

  files = _.uniq(_.flatten(files))

  scripts = ""
  scripts += "<script src='http://coffeescript.org/extras/coffee-script.js'></script>\n"
  for file in files
    if file.match(/.coffee$/)
      scripts += "<script src='#{javascriptspath}#{file}' type='text/coffeescript'></script>\n"
    else
      scripts += "<script src='#{javascriptspath}#{file}'></script>\n"
  scripts


envvar = (data)->
  env = 'dev'
  data[env]

exports.init = (options)->
  options  = options || {}
  basepath = options.basepath if options.basepath
  basedir  = options.basedir
  uglify   = options.uglify if options.uglify
  stylesheetspath = options.stylesheetspath
  javascriptspath = options.javascriptspath

 # accepts 'data' object
exports.plugin = (req, res, options)->
  data = options.data || {}
  data['stylesheets'] = stylesheets
  data['javascripts'] = javascripts
  data['env'] = envvar
  name = options.name
  name = req.url.replace(basepath, '').replace(/\?.*/, '') unless name
  filename = options.file || join(basedir, "#{name}.jade")
  filedata = fs.readFileSync(filename, 'utf8')
  try
    template = jade.compile(filedata, filename: filename, pretty: !uglify)
    res.setHeader('Content-Type', 'text/html')
    res.write(template(data))
    return res.end()
  catch err
    console.log err
    res.setHeader('Content-Type', 'text/html')
    res.write('<html><body><pre>')
    res.write(err.message)
    res.write('</pre></body></html>')
    return res.end()
  
  res.next()


filewrangler = (name, files, squashedmap)->
  squashedname = null
  fileset = {}
  fileset[file] = 1 for file in [].concat(files)
  # find if we already have a script that matches this whole set.
  _.forEach squashedmap, (set, setname)->
    if _.isEqual(fileset, set)
      squashedname = setname
      return
  # if no match was found, create a new batch using the name
  squashedmap[name] = fileset unless squashedname
  squashedname || name

compiledstylesheets = (name, squashedmap)->
  return (files, attrs)->
    squashedname = filewrangler(name, files, squashedmap)
    "<link href=\"#{stylesheetspath}#{squashedname}.css\" rel=\"stylesheet\" type=\"text/css\" />"

compiledjavascripts = (name, squashedmap)->
  return (files)->
    squashedname = filewrangler(name, files, squashedmap)
    "<script src=\"#{javascriptspath}#{squashedname}.js\"></script>"


exports.compile = (name, filename, outputfile, assets, merged, uglify)->
  if merged
    data =
      stylesheets: compiledstylesheets(name, assets.css)
      javascripts: compiledjavascripts(name, assets.js)
      env: envvar
  else
    data =
      stylesheets: stylesheets
      javascripts: javascripts
      env: envvar

  filedata = fs.readFileSync(filename, 'utf8')

  try
    template = jade.compile(filedata, filename: filename, pretty: !uglify)
    html = template(data)
    fs.writeFileSync(outputfile, html, 'utf8')
  catch err
    console.log "Could not compile template #{filename} because:"
    console.log err
    return []
