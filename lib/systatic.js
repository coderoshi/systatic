(function() {
  var assetRoute, bricks, config, exec, fs, getPlugin, jade, path, servitude;

  fs = require('fs');

  path = require('path');

  jade = require(path.join(__dirname, 'plugins', 'jade_template'));

  servitude = require('servitude');

  bricks = require('bricks');

  exec = require('child_process').exec;

  exports.config = config = function() {
    if (this.configData != null) return this.configData;
    return this.configData = require(path.resolve(path.join('.', 'config.json')));
  };

  exports.inProject = function(dirname) {
    if (path.existsSync(path.join(dirname, 'config.json'))) return true;
    return false;
  };

  exports.clone = function(dirname, template) {
    var templatePath;
    templatePath = path.join(__dirname, '..', 'templates', template);
    console.log("Generating project " + dirname);
    return exec("cp -R " + templatePath + " " + dirname, function(error, stdout, stderr) {
      return console.log(error);
    });
  };

  getPlugin = function(value, appserver) {
    switch (value) {
      case "servitude":
        return servitude;
      case "filehandler":
        return appserver.plugins.filehandler;
      default:
        return appserver.plugins.filehandler;
    }
  };

  assetRoute = function(appserver, asset) {
    var basedir, c;
    c = config();
    basedir = c.sourceDir || 'src';
    return appserver.addRoute(c[asset].route, getPlugin(c[asset].plugin, appserver), {
      basedir: path.join(basedir, c[asset].baseDir)
    });
  };

  exports.startServer = function(port, ipaddr, logfile) {
    var appserver, basedir, c, server;
    c = config();
    basedir = c.sourceDir || 'src';
    appserver = new bricks.appserver();
    appserver.addRoute("/$", jade, {
      basedir: basedir,
      name: 'index'
    });
    assetRoute(appserver, 'stylesheets');
    assetRoute(appserver, 'javascripts');
    assetRoute(appserver, 'images');
    appserver.addRoute(".+", jade, {
      basedir: basedir,
      stylesheetspath: '/stylesheets/',
      javascriptspath: '/javascripts/'
    });
    appserver.addRoute(".+", appserver.plugins.fourohfour);
    if (logfile) {
      try {
        appserver.addRoute(".+", appserver.plugins.loghandler, {
          section: 'final',
          filename: logfile
        });
      } catch (error) {
        console.log("Error opening logfile, continuing without logfile");
      }
    }
    server = appserver.createServer();
    try {
      return server.listen(port, ipaddr);
    } catch (error) {
      return console.log("Error starting server, unable to bind to " + ipaddr + ":" + port);
    }
  };

  exports.build = function() {
    return log("== Not yet implemented");
  };

  exports.deploy = function() {
    return log("== Not yet implemented");
  };

}).call(this);
