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

  addPlugin: (plugin)->
    phase = (@plugins[plugin.defaultEvent] ||= [])
    phase.push plugin

  getPlugins: (phase)->
    @plugins[phase] || []

module.exports = PluginManager
