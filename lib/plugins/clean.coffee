{rmdirSyncRecursive} = require('wrench')
{existsSync} = require('path')

module.exports =
  name: 'clean'
  phase: 'clean'
  build: (config, phaseData, next)->
    builddir = config.buildDir

    if builddir == '.' || builddir.match(/^\/$/) || builddir == '~' || builddir == ''
      return console.log "Nope. Won't delete '#{builddir}'. Please fix your config"

    if existsSync(builddir)
      rmdirSyncRecursive(builddir)
    
    next()
