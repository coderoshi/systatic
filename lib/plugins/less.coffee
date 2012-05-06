util   = require('../utils')
{join} = require('path')
less   = require('less')

module.exports =
  name: 'less'
  defaultEvent: 'styles'
  build: (config, phaseData)->
    parser = new less.Parser
      paths: [config.stylesheets.sourceDir]

    util.compileOut config.stylesheets.sourceDir, /\.less$/, config.stylesheets.ignore, (filename, filedata, cb)->
      parser.parse filedata, (e, tree)->
        css = tree.toCSS(compress: true)
        cb join(config.stylesheets.buildDir, "#{filename}.css"), css
