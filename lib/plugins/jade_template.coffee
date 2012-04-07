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

stylesheets = (files, attrs)->
  if typeof(files) == 'string'
    "<script src='#{stylesheetspath}#{files}'></script>\n"
  else if typeof(files) == 'object'
    "<script src='#{stylesheetspath}#{files.join(',')}'></script>\n"

javascripts = (files)->
  if typeof(files) == 'string'
    "<script src='#{javascriptspath}#{files}'></script>\n"
  else if typeof(files) == 'object'
    "<script src='#{javascriptspath}#{files.join(',')}'></script>\n"

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

  filedata = fs.readFileSync(filename, 'utf8')

  try
    template = jade.compile(filedata, filename: filename, pretty: !uglify)
    html = template(data)
    fs.writeFileSync(outputfile, html, 'utf8')
  catch err
    console.log "Could not compile template #{filename} because:"
    console.log err
    return []
