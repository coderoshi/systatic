{walkSync} = require('../utils')
{join}     = require('path')
jade       = require('./jade_template')
nfs        = require('node-fs')

# TODO: what about binding to phases? eg:
# documents: (...)->
# merge:     (...)->

module.exports =
  name: 'jade'
  phase: 'documents'
  build: (config, phaseData, next)->
    assets = phaseData.assets = {css: {}, js: {}}

    # TODO: when compiling, use new compiled assets, not the source file types

    # only merge assets if merge phase is called (and has a merge plugin attached)
    merged = phaseData.upToPhase('merge')

    # IDEA! Can merge plugin be responsible to defining document merge functions?
    # then only if it's involved will merge ever happen!!

    walkSync config.sourceDir, /\.jade$/, config.ignore, (fullname)->
      filename = fullname.replace(config.sourceDir, '').replace(/\//, '')
      outputfile = join(config.buildDir, filename.replace(/\.jade$/, '.html'))
      randomname = (Math.random() * 0x100000000 + 1).toString(36)
      nfs.mkdirSync(outputfile.replace(/\/[^/]+$/, ''), 0x0777, true)
      jade.compile(randomname, fullname, outputfile, assets, merged, true)
    next()
