util   = require('../utils')
{join} = require('path')

# simply copies over javascript files to build directory
module.exports =
  name: 'javascript'
  defaultEvent: 'scripts'
  build: (config, phaseData)->
    util.compileOut config.javascripts.sourceDir, /\.js$/, config.javascripts.ignore, (filename, filedata, cb)->
      cb join(config.javascripts.buildDir, filename), filedata
