util   = require('../utils')
{join} = require('path')
less   = require('less')

exports.name = 'less'
exports.defaultEvent = 'styles'
exports.build = (config, phaseData)->
  # cssassets = phaseData.assets.css
  # ignores = config.ignore || []

  parser = new less.Parser
    paths: [config.stylesheets.sourceDir],   # Specify search paths for @import directives
    #filename: 'style.less' # Specify a filename, for better error messages

  util.compileOut config.stylesheets.sourceDir, /\.less$/, (filename, filedata, cb)->
    outputfile = join(config.stylesheets.buildDir, "#{filename}.css")
    parser.parse filedata, (e, tree)->
      css = tree.toCSS(compress: true)
      cb(outputfile, css)

  #assets
###
renderCSS = (c, basedir, builddir, cssassets)->
  cssbasedir = c.stylesheets.baseDir || 'stylesheets'
  cssbuilddir = resolve(path.join(builddir, cssbasedir))
  cssbasedir = resolve(path.join(basedir, cssbasedir))

  parser = new less.Parser
    paths: [cssbasedir], # Specify search paths for @import directives
    #filename: 'style.less' # Specify a filename, for better error messages

  cssdata = {}

  # first compile up all less files
  walkSync cssbasedir, /\.less$/, (fullname)->
    filename = fullname.replace(cssbasedir, '').replace(/\//, '')
    filedata = fs.readFileSync(fullname, 'utf8')
    parser.parse filedata, (e, tree)->
      cssdata[filename] = tree.toCSS(compress: true)

  # get all of the regular css files
  walkSync cssbasedir, /\.css$/, (fullname)->
    filename = fullname.replace(cssbasedir, '').replace(/\//, '')
    cssdata[filename] = fs.readFileSync(fullname, 'utf8')
  
  # output to merged CSS files
  _.forEach cssassets, (files, outputname)->
    outputname = path.join(cssbuilddir, "#{outputname}.css")
    buffer = ''
    _.forEach files, (i, assetkey)->
      unless cssdata[assetkey]?
        log "Unknown asset #{assetkey}"
        return
      buffer += cssdata[assetkey]
    # write buffer to outputname
    finalCode = cleancss.process(buffer)
    fs.writeFileSync(outputname, finalCode, 'utf8')
###
