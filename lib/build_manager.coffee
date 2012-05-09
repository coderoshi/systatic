_               = require('underscore')
{join, resolve} = require('path')

# Running this emits all steps in order
class BuildManager
  # TODO: remove scripts/style/merge and replace with 'assets'?
  #events: ['clean', 'documents', 'scripts', 'styles', 'merge', 'test', 'compress', 'publish']
  events: ['setup', 'documents', 'scripts', 'styles', 'merge', 'test', 'compress', 'publish']

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

  # loop through event list and emits
  # each step must fully execute before completion
  # registered events manage their own execution
  start: (toEvent)->
    return false unless _.include(@events, toEvent)

    phaseData =
      lastEvent     : toEvent
      pluginManager : @pluginManager
      upToPhase : (phaseName)=>
        for e in @events
          return true if e == phaseName
          break if e == toEvent
        false

    for event in @events
      #process.nextTick ()=> @emit(event, @config)
      @emit(event, ':pre', phaseData)
      @emit(event, '', phaseData)
      @emit(event, ':post', phaseData)

      return true if toEvent == event
    
    return true

  emit: (phase, suffix, phaseData)->
    phaseData.event = "#{phase}#{suffix}"
    if suffix == ':pre' || suffix == ''
      for plugin in @pluginManager.getPlugins("all#{suffix}")
        plugin.build(@config, phaseData)
    for plugin in @pluginManager.getPlugins("#{phase}#{suffix}")
      console.log "  [#{plugin.name}]"
      plugin.build(@config, phaseData)
    if suffix == ':post'
      for plugin in @pluginManager.getPlugins("all#{suffix}")
        plugin.build(@config, phaseData)


module.exports = BuildManager
