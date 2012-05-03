_               = require('underscore')
{join, resolve} = require('path')
EventEmitter2   = require('eventemitter2').EventEmitter2

# Running this emits all steps in order
class BuildEventManager extends EventEmitter2
  
  constructor: ()->
    @events = ['clean', 'documents', 'scripts', 'styles', 'compress', 'publish']
    @userConfig = require(resolve(join('.', 'config.json')))
    @sanitizeConfig @userConfig

  sanitizeConfig: (config)->
    sourceDir = config.sourceDir || 'src'
    sourceDir = resolve(sourceDir)
    config.sourceDir = sourceDir
    
    buildDir = config.buildDir || 'build'
    buildDir = resolve(buildDir)
    config.buildDir = buildDir

    config.stylesheets ||= {}
    stylesSourceDir = config.stylesheets.sourceDir || 'stylesheets'
    config.stylesheets['sourceDir'] = resolve(join(sourceDir, stylesSourceDir))
    config.stylesheets['buildDir'] = resolve(join(buildDir, stylesSourceDir))

    config.javascripts ||= {}
    scriptsSourceDir = config.javascripts.sourceDir || 'javascripts'
    config.javascripts.sourceDir = resolve(join(sourceDir, scriptsSourceDir))
    config.javascripts.buildDir = resolve(join(buildDir, scriptsSourceDir))

  register: (plugin)->
    if plugin.defaultEvent == 'all'
      # register for every event
      @on event, plugin.build for event in @events
    else if plugin.defaultEvent == 'all:pre'
      @on "#{event}:pre", plugin.build for event in @events
    else if plugin.defaultEvent == 'all:pre'
      @on "#{event}:post", plugin.build for event in @events
    else
      @on plugin.defaultEvent, ()->
        console.log "  [#{plugin.name}]"
        plugin.build(arguments...)


  # loop through event list and emits
  # each step must fully execute before completion
  # registered events manage their own execution
  start: (toEvent)->
    return false unless _.include(@events, toEvent)

    phaseData = {}

    #process.nextTick ()=> @emit('setup', @userConfig)
    phaseData.event = 'setup'
    @emit('setup', @userConfig, phaseData)

    for event in @events
      #process.nextTick ()=> @emit(event, @userConfig)
      # phaseData.event = event
      phaseData.event = "#{event}:pre"
      @emit(phaseData.event, @userConfig, phaseData)
      phaseData.event = event
      @emit(phaseData.event, @userConfig, phaseData)
      phaseData.event = "#{event}:post"
      @emit(phaseData.event, @userConfig, phaseData)
      return true if toEvent == event
    
    return true


module.exports = BuildEventManager
