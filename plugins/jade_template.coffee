fs   = require('fs')
path = require('path')
jade = require('jade')

basedir  = null
basepath = '/'
uglify   = false

exports.init = (options)->
  options  = options || {}
  basepath = options.basepath if options.basepath
  basedir  = options.basedir
  uglify   = options.uglify if options.uglify

 # accepts 'data' object
exports.plugin = (req, res, options)->
  data = options.data || {}
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