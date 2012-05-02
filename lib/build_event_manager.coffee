u             = require('underscore')
path          = require('path')
EventEmitter2 = require('eventemitter2').EventEmitter2

# Running this emits all steps in order
class BuildEventManager extends EventEmitter2
  
  constructor: ()->
    # 'assets' => 'javascript', 'css'
    #@events = ['clean', 'resources', 'assets', 'compress', 'publish']
    @events = ['clean', 'resources', 'scripts', 'styles', 'compress', 'publish']
    @userConfig = require(path.resolve(path.join('.', 'config.json')))

  register: (plugin)->
    if plugin.defaultEvent == 'all'
      # register for every event
      for event in @events
        @on event, plugin.build
    else
      @on plugin.defaultEvent, plugin.build


  # loop through event list and emits
  # each step must fully execute before completion
  # registered events manage their own execution
  start: (toEvent)->
    return false unless u.include(@events, toEvent)
    
    phaseData = {}

    #process.nextTick ()=> @emit('setup', @userConfig)
    phaseData.event = 'setup'
    @emit('setup', @userConfig, phaseData)

    for event in @events
      #process.nextTick ()=> @emit(event, @userConfig)
      phaseData.event = event
      @emit(event, @userConfig, phaseData)
      return true if toEvent == event
    
    return true

exports.BuildEventManager = BuildEventManager
