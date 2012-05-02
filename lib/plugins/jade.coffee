util = require('../utils')
jade = require('./jade_template')
path = require('path')


exports.defaultEvent = 'resources'

exports.build = (config, phaseData)->
  basedir = config.sourceDir || 'src'
  basedir = path.resolve(basedir)

  builddir = config.buildDir || 'build'
  builddir = path.resolve(builddir)

  assets = phaseData.assets = {css: {}, js: {}}

  ignores = config.ignore || []

  util.walkSync basedir, /\.jade$/, (fullname)->
    filename = fullname.replace(basedir, '').replace(/\//, '')
    for ignore in ignores
      return if filename.match(ignore)
    outputfile = path.join(builddir, filename.replace(/\.jade$/, '.html'))
    randomname = (Math.random() * 0x100000000 + 1).toString(36)
    jade.compile(randomname, fullname, outputfile, assets, true)

  #assets
