fs = require('fs')

# seeks plugins to load
class PluginManager
  pluginDir: "#{__dirname}/plugins"

  constructor: (config)->
    @plugins = {}
    @loadPlugins()
    @config = config

  # currently only loads local plugins
  # TODO: load plugins based on config
  loadPlugins: ()->
    fs.readdirSync(@pluginDir).forEach (name)=>
      @addPlugin require("#{@pluginDir}/#{name}")

    # If logging is turned on?
    # console.log @plugins

  addPlugin: (plugin)->
    phases = plugin.phase
    if typeof(plugin.phase) == 'string'
      phases = [plugin.phase]
    return false unless phases?
    for phase in phases
      phasePlugins = (@plugins[phase] ||= [])
      phasePlugins.push plugin

  getPlugins: (phase)->
    @plugins[phase] || []

exports.PluginManager = PluginManager
