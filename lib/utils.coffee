fs   = require('fs')
path = require('path')

# Walks directories and finds files matching the given filter
# TODO: make this more systatic-centric. pass in where you wish
# to walk: source, build, javascripts, stylesheets, images.
# Optionally show ignored files (false by default)
exports.walkSync = walkSync = (start, filter, cb)->
  filter = /./ unless filter?
  if fs.statSync(start).isDirectory()
    collection = fs.readdirSync(start).reduce((acc, name)->
      if fs.statSync(path.join(start, name)).isDirectory()
        acc.dirs.push(name)
      else
        if name.match(filter)
          acc.names.push(path.join(start, name))
      acc
    names: []
    dirs: []
    )
    if collection.names.length > 0
      collection.names.forEach (fullname)-> cb(fullname)
    for dir in collection.dirs
      walkSync(path.join(start, dir), filter, cb)
  else
    throw new Error("#{start} is not a directory")