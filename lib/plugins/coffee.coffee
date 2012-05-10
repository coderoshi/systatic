util   = require('../utils')
{join} = require('path')
coffee = require('coffee-script')

module.exports =
  name: 'coffeescript'
  phase: 'scripts'
  build: (config, phaseData, next)->
    util.compileOut config.javascripts.sourceDir, /\.coffee$/, config.javascripts.ignore, (filename, filedata, cb)->
      js = coffee.compile(filedata)
      cb join(config.javascripts.buildDir, "#{filename}.js"), js
    next()
