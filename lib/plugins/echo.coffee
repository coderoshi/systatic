
# simply echos out the steps
module.exports =
  name: 'echo'
  defaultEvent: 'all:pre'
  build: (config, phaseData)->
    console.log "Event: #{phaseData.event.replace(/:.*$/, '')}"
