
# simply echos out the steps
exports.defaultEvent = 'all'

exports.build = (config, phaseData)->
  console.log "Event: #{phaseData.event}"
