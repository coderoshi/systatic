exec = require('child_process').exec

module.exports =
  name: 'clean'
  defaultEvent: 'clean'
  build: (config, phaseData)->
    builddir = config.buildDir
    if builddir == '.' || builddir.match(/^\/$/) || builddir == '~' || builddir == ''
      console.log builddir
      return console.log 'No.'
    exec "rm -rf #{builddir}", (error, stdout, stderr)->
      console.log error
