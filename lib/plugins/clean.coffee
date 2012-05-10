{rmdirSyncRecursive} = require('wrench')

module.exports =
  name: 'clean'
  phase: 'clean'
  build: (config, phaseData, next)->
    builddir = config.buildDir

    if builddir == '.' || builddir.match(/^\/$/) || builddir == '~' || builddir == ''
      return console.log "Nope. Won't delete #{builddir}"

    rmdirSyncRecursive(builddir)
    next()
