_          = require('underscore')
fs         = require('fs')
{walkSync} = require('../utils')
{join}     = require('path')
cleancss   = require('clean-css')
uglifyjs   = require('uglify-js')

# IDEA! Can merge plugin be responsible to defining document merge functions?
# then only if it's involved will merge ever happen!!

# merges css and javascript files into single files
module.exports =
  name: 'assetmerger'
  phase: 'merge'
  publics: {
    # a hash of public functions meant for other plugins to use
  }
  build: (config, phaseData, next)->

    # phaseData.phase
    # phaseData.lastPhase

    # read all css asset files
    mergeCSS config.stylesheets.buildDir, phaseData.assets?.css
    mergeJS  config.javascripts.buildDir, phaseData.assets?.js

    next()


mergeCSS = (buildDir, assets)->
  return false unless assets?

  cssdata = {}

  # get all of the regular css files
  walkSync buildDir, /\.css$/, null, (filename)->
    name = filename.replace(buildDir, '').replace(/\//, '')
    # TODO: this sucks. converts from site.less.css to site.less
    # how does it know about this conversion? not generic enough!!
    name = name.replace(/(\.\w+)\.css/, '$1')
    cssdata[name] = fs.readFileSync(filename, 'utf8')

  # output to merged CSS files
  _.forEach assets, (files, outputname)->
    outputname = join(buildDir, "#{outputname}.css")
    buffer = ''
    _.forEach files, (i, assetkey)->
      unless cssdata[assetkey]?
        console.log "Unknown asset #{assetkey}"
        return
      buffer += cssdata[assetkey]
    # write buffer to outputname
    finalCode = cleancss.process(buffer)
    fs.writeFileSync(outputname, finalCode, 'utf8')

mergeJS = (buildDir, assets)->
  return false unless assets?

  jsdata = {}

  jsp = uglifyjs.parser
  pro = uglifyjs.uglify

  # get all of the regular css files
  walkSync buildDir, /\.js$/, null, (filename)->
    name = filename.replace(buildDir, '').replace(/\//, '')
    # TODO: this sucks. converts from site.less.css to site.less
    # how does it know about this conversion? not generic enough!!
    name = name.replace(/(\.\w+)\.js/, '$1')
    jsdata[name] = fs.readFileSync(filename, 'utf8')

  # output to merged JS files
  _.forEach assets, (files, outputname)->
    outputname = join(buildDir, "#{outputname}.js")
    buffer = ''
    _.forEach files, (i, assetkey)->
      unless jsdata[assetkey]?
        console.log "Unknown asset #{assetkey}"
        return
      buffer += jsdata[assetkey]
    # write buffer to outputname
    ast = jsp.parse(buffer)    # parse code and get the initial AST
    ast = pro.ast_mangle(ast)  # get a new AST with mangled names
    ast = pro.ast_squeeze(ast) # get an AST with compression optimizations
    finalCode = pro.gen_code(ast)
    fs.writeFileSync(outputname, finalCode, 'utf8')

