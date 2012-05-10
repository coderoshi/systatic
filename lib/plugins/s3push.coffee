_          = require('underscore')
{walkSync} = require('../utils')
{nox}      = require('noxmox')

module.exports =
  name: 's3push'
  phase: 'publish'
  build: (config, phaseData, next)->
    builddir = config.buildDir
    dcs = config.deploy || []

    _.forEach dcs, (dc)->
      s3 = nox.createClient
        key: dc.access_key_id
        secret: dc.secret_access_key
        bucket: dc.bucket

      walkSync builddir, null, null, (fullname)->
        filename = fullname.replace(builddir, '').replace(/\//, '')
        data = fs.readFileSync(fullname)
        headers = { 'Content-Length': data.length, 'x-amz-acl':'public' }
        headers['Content-Encoding'] = 'gzip' if filename.match(/.gz$/)
        req = s3.put(filename, headers)
        log filename
        req.on 'continue', ()->
          log "pushing #{filename}"
          req.end(data)
        req.on 'response', (res)->
          log "responding #{filename}"
          res.on 'data', (chunk)-> log chunk
          res.on 'end', ()-> log 'File is now stored on S3' if res.statusCode == 200

    next()
