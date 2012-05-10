util   = require('../utils')
{join} = require('path')
less   = require('less')

module.exports =
  name: 'less'
  phase: 'styles'
  build: (config, phaseData, next)->
    parser = new less.Parser
      paths: [config.stylesheets.sourceDir]

    util.compileOut config.stylesheets.sourceDir, /\.less$/, config.stylesheets.ignore, (filename, filedata, cb)->
      parser.parse filedata, (e, tree)->
        css = tree.toCSS(compress: true)
        cb join(config.stylesheets.buildDir, "#{filename}.css"), css
    next()
