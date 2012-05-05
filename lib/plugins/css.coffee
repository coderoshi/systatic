util   = require('../utils')
{join} = require('path')

module.exports =
  name: 'css'
  defaultEvent: 'styles'
  build: (config, phaseData)->
    util.compileOut config.stylesheets.sourceDir, /\.css$/, config.stylesheets.ignore, (filename, filedata, cb)->
      cb join(config.stylesheets.buildDir, filename), filedata
