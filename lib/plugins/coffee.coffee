util   = require('../utils')
{join} = require('path')
coffee = require('coffee-script')

module.exports =
  name: 'coffeescript'
  defaultEvent: 'scripts'
  build: (config, phaseData)->
    util.compileOut config.javascripts.sourceDir, /\.coffee$/, config.javascripts.ignore, (filename, filedata, cb)->
      js = coffee.compile(filedata)
      cb join(config.javascripts.buildDir, "#{filename}.js"), js
