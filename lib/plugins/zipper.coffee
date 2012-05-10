fs         = require('fs')
compress   = require('compress-buffer')
{join}     = require('path')
{walkSync} = require('../utils')

module.exports =
  name: 'zipper'
  phase: 'compress'
  build: (config, phaseData, next)->
    walkSync config.buildDir, /\.(html|css|js)$/, null, (filename)->
      inline = false
      data = fs.readFileSync(filename, 'utf8')
      compressedData = compress.compress(new Buffer(data))
      outputname = if inline then filename else "#{filename}.gz"
      fs.writeFileSync(outputname, compressedData, 'utf8')
    next()
