fs   = require('fs')
path = require('path')
jade = require('jade')
u    = require('underscore')

basedir  = null
basepath = '/'
uglify   = false
stylesheetspath = '/stylesheets/'
javascriptspath = '/javascripts/'
compiled = false


# TODO: move this out to utils
walkSync = (start, filter, cb)->
  filter = /./ unless filter?
  if fs.statSync(start).isDirectory()
    collection = fs.readdirSync(start).reduce((acc, name)->
      if fs.statSync(path.join(start, name)).isDirectory()
        acc.dirs.push(name)
      else
        name = path.join(start, name)
        if name.match(filter)
          acc.names.push(name)
      acc
    names: []
    dirs: []
    )
    cb(collection.names)
    for dir in collection.dirs
      walkSync(path.join(start, dir), filter, cb)
  else
    throw new Error("#{start} is not a directory")

inflateFiles = (sourceDir, pattern)->
  files = []
  walkSync sourceDir, pattern, (filenames)->
    filenames.forEach (fullname)->
      files.push fullname.replace("#{sourceDir}/", '')
  files


# force css sourceDir to be the same as the public path
stylesheets = ()->
  files = u.flatten(arguments)

  # TODO: BAD BAD BAD! Extract /src/ from sourceDir and javascript/baseDir
  sourceDir = 'src/stylesheets'

  if typeof(files) == 'undefined'
    files =[]
    walkSync sourceDir, null, (filenames)->
      filenames.forEach (fullname)->
        files.push fullname.replace("#{sourceDir}/", '')
  
  files[pos] = inflateFiles(sourceDir, file) for file, pos in files

  files = u.uniq(u.flatten(files))

  "<script src='#{stylesheetspath}#{files.join(',')}'></script>\n"


# TODO: Make "scriptserver" just execute any "javascript" registered renders
javascripts = ()->
  files = u.flatten(arguments)

  # TODO: BAD BAD BAD! Extract /src/ from sourceDir and javascript/baseDir
  sourceDir = 'src/javascripts'
  
  if typeof(files) == 'undefined'
    files =[]
    walkSync sourceDir, null, (filenames)->
      filenames.forEach (fullname)->
        files.push fullname.replace("#{sourceDir}/", '')
  
  files[pos] = inflateFiles(sourceDir, file) for file, pos in files

  files = u.uniq(u.flatten(files))

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
  filename = options.file || path.join basedir, "#{name}.jade"
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
  u.forEach squashedmap, (set, setname)->
    if u.isEqual(fileset, set)
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


exports.compile = (name, filename, outputfile, assets, uglify)->
  data =
    stylesheets: compiledstylesheets(name, assets.css)
    javascripts: compiledjavascripts(name, assets.js)
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
