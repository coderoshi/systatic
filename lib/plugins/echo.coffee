
# simply echos out the steps
exports.defaultEvent = 'all:pre'

exports.build = (config, phaseData)->
  console.log "Event: #{phaseData.event.replace(/:.*$/, '')}"
