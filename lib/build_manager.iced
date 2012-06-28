_               = require('underscore')
{join, resolve} = require('path')

# TODO: remove scripts/style/merge and replace with 'assets'?
# exports.phases = phases = ['setup', 'clean', 'documents', 'scripts', 'styles', 'merge', 'test', 'compress', 'publish']
exports.phases = phases = ['setup', 'documents'] #, 'scripts', 'styles', 'merge', 'test', 'compress', 'publish']


# Running this emits all steps in order
class BuildManager
  phases: phases

  constructor: (config, pluginManager)->
    @pluginManager = pluginManager
    @sanitizeConfig(@config = config)

  sanitizeConfig: (config)->
    sourceDir = config.sourceDir || 'src'
    sourceDir = resolve(sourceDir)
    config.sourceDir = sourceDir
    
    buildDir = config.buildDir || 'build'
    buildDir = resolve(buildDir)
    config.buildDir = buildDir

    config.stylesheets ||= {}
    stylesSourceDir = config.stylesheets.sourceDir || 'stylesheets'
    config.stylesheets.sourceDir = resolve(join(sourceDir, stylesSourceDir))
    config.stylesheets.buildDir = resolve(join(buildDir, stylesSourceDir))

    config.javascripts ||= {}
    scriptsSourceDir = config.javascripts.sourceDir || 'javascripts'
    config.javascripts.sourceDir = resolve(join(sourceDir, scriptsSourceDir))
    config.javascripts.buildDir = resolve(join(buildDir, scriptsSourceDir))

  # loop through phase list and emits
  # each step must fully execute before completion
  # registered phases manage their own execution
  start: (toPhase)->
    return false unless _.include(@phases, toPhase)

    @phaseSequence = @buildPhaseSequence(toPhase)
    @pluginCounts = 0
    @phaseData =
      lastPhase     : toPhase
      pluginManager : @pluginManager
      upToPhase : (phaseName)=>
        for e in @phases
          return true if e == phaseName
          break if e == toPhase
        false

    @serialPhase()

    true

  buildPhaseSequence: (toPhase)->
    sequence = []
    for phase in @phases
      sequence.push "#{phase}:pre"
      sequence.push phase
      sequence.push "#{phase}:post"
      break if phase == toPhase
    sequence


  serialPhase: ()->
    @currentPhase = @phaseSequence.shift()
    return true unless @currentPhase?
    @exec(@currentPhase, @phaseData)

  # TODO: create two kinds of plugins: standard (sync) and async
  # sync are not responsible for calling referenceContinue

  # each of these calls are performed serially, and
  # do not return until all attached phases return
  exec: (phase, phaseData)->
    # the results of this 
    phaseData.phase = phase

    # console.log "Phase: #{phase}"

    plugins = @pluginManager.getPlugins(phase)
    if plugins.length == 0
      @serialPhase()
      return

    # first push them all onto the stack...
    @pluginCallPush(plugin) for plugin in plugins

    # now run them, and let them pop themselves off...
    for plugin in plugins
      console.log "  [#{plugin.name}]" unless plugin.label == false
      plugin.build(@config, phaseData, @pluginCallPop)

    # TODO: we let these plugins be async, but they never return control. W.T.F!?

    # IDEA! multiple plugins fail because the first pushes on the stack, but after popping,
    # it returns control to this main code. but since the plugincount is still zero, it doesn't
    # call the serial phase, so there's nothing left to execute and it just ends.
    # BUT... why doesn't the second code keep running....???

  pluginCallPush: (plugin)=>
    @pluginCounts++

  pluginCallPop: ()=>
    @pluginCounts--
    @serialPhase() if @pluginCounts <= 0



exports.BuildManager = BuildManager
