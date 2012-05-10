
# simply echos out the steps
module.exports =
  name: 'echo'
  phase: require('../build_manager').phases.map((x)-> "#{x}:pre")
  label: false
  build: (config, phaseData, next)->
    console.log "Phase: #{phaseData.phase.replace(/:.*$/, '')}"
    next()
