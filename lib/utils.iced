fs     = require('fs')
nfs    = require('node-fs')
{join} = require('path')

# TODO: DO NOT USE A CALLBACK IN compileOut... use return []
# TODO: Create a callback token so the plugin manager knows

# Walks directories and finds files matching the given filter
# TODO: make this more systatic-centric. pass in where you wish
# to walk: source, build, javascripts, stylesheets, images.
# Optionally show ignored files (false by default)
exports.walkSync = walkSync = (start, filter, ignores, cb)->
  filter = /./ unless filter?
  if fs.statSync(start).isDirectory()
    collection = fs.readdirSync(start).reduce((acc, name)->
      if fs.statSync(join(start, name)).isDirectory()
        acc.dirs.push(name)
      else
        if name.match(filter)
          ignored = false
          if ignores
            for ignore in ignores
              ignored ||= true if name.match(ignore)
          acc.names.push(join(start, name)) unless ignored
      acc
    names: []
    dirs: []
    )
    if collection.names.length > 0
      collection.names.forEach (fullname)-> cb(fullname)
    for dir in collection.dirs
      walkSync(join(start, dir), filter, ignores, cb)
  else
    throw new Error("#{start} is not a directory")


exports.compileOut = (basedir, filter, ignores, cb)->
  walkSync basedir, filter, ignores, (fullname)->
    filename = fullname.replace(basedir, '').replace(/\//, '')
    filedata = fs.readFileSync(fullname, 'utf8')
    cb filename, filedata, (outputfile, output)->
      nfs.mkdirSync(outputfile.replace(/\/[^/]+$/, ''), 0o777, true)
      fs.writeFileSync(outputfile, output, 'utf8')
