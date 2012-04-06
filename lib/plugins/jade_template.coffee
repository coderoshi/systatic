fs   = require('fs')
path = require('path')
jade = require('jade')

basedir  = null
basepath = '/'
uglify   = false
stylesheetspath = '/stylesheets/'
javascriptspath = '/javascripts/'
compiled = false

exports.init = (options)->
  options  = options || {}
  basepath = options.basepath if options.basepath
  basedir  = options.basedir
  uglify   = options.uglify if options.uglify
  stylesheetspath = options.stylesheetspath
  javascriptspath = options.javascriptspath
  compiled = options.compiled

stylesheets = (files)->
  if typeof(files) == 'string'
    "<script src='#{stylesheetspath}#{files}'></script>\n"
  else if typeof(files) == 'object'
    "<script src='#{stylesheetspath}#{files.join(',')}'></script>\n"

javacripts = (files)->
  if typeof(files) == 'string'
    "<script src='#{javascriptspath}#{files}'></script>\n"
  else if typeof(files) == 'object'
    "<script src='#{javascriptspath}#{files.join(',')}'></script>\n"

 # accepts 'data' object
exports.plugin = (req, res, options)->
  data = options.data || {}
  # these only use servitude if compiled is false
  data['stylesheets'] = stylesheets
  data['javascripts'] = javacripts
  
  name = options.name
  name = req.url.replace(basepath, '').replace(/\?.*/, '') unless name
  filePath = options.file || path.join basedir, "#{name}.jade"
  fileData = fs.readFileSync(filePath, 'utf8')
  try
    template = jade.compile(fileData, filename: filePath, pretty: !uglify)
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