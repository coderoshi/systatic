util   = require('../utils')
{join} = require('path')
coffee = require('coffee-script')

module.exports =
  name: 'coffeescript'
  defaultEvent: 'scripts'
  build: (config, phaseData)->
    # jsassets = phaseData.assets.js
    # ignores = config.ignore || []

    util.compileOut config.javascripts.sourceDir, /\.coffee$/, (filename, filedata, cb)->
      outputfile = join(config.javascripts.buildDir, "#{filename}.js")
      js = coffee.compile(filedata)
      cb(outputfile, js)


###
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
  _.forEach jsassets, (files, outputname)->
    outputname = path.join(jsbuilddir, "#{outputname}.js")
    buffer = ''
    _.forEach files, (i, assetkey)->
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
###
