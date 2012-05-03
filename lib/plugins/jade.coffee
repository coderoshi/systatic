util   = require('../utils')
jade   = require('./jade_template')
{join} = require('path')

exports.name = 'jade'
exports.defaultEvent = 'documents'
exports.build = (config, phaseData)->
  assets = phaseData.assets = {css: {}, js: {}}
  ignores = config.ignore || []

  util.walkSync config.sourceDir, /\.jade$/, (fullname)->
    filename = fullname.replace(config.sourceDir, '').replace(/\//, '')
    for ignore in ignores
      return if filename.match(ignore)
    outputfile = join(config.buildDir, filename.replace(/\.jade$/, '.html'))
    randomname = (Math.random() * 0x100000000 + 1).toString(36)
    jade.compile(randomname, fullname, outputfile, assets, true)
