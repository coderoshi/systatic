fs = require('fs')

# seeks plugins to load
class PluginManager

  constructor: ()->
    @plugins = []
    @loadPlugins()

  # currently only loads local plugins
  loadPlugins: ()->
    pluginDir = "#{__dirname}/plugins"
    fs.readdirSync(pluginDir).forEach (name)=>
      @addPlugin require("#{pluginDir}/#{name}")

  addPlugin: (plugin)->
    @plugins.push plugin

  getPlugins: ()-> @plugins

module.exports = PluginManager
