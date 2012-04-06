(function() {
  var basedir, basepath, compiled, fs, jade, javacripts, javascriptspath, path, stylesheets, stylesheetspath, uglify;

  fs = require('fs');

  path = require('path');

  jade = require('jade');

  basedir = null;

  basepath = '/';

  uglify = false;

  stylesheetspath = '/stylesheets/';

  javascriptspath = '/javascripts/';

  compiled = false;

  exports.init = function(options) {
    options = options || {};
    if (options.basepath) basepath = options.basepath;
    basedir = options.basedir;
    if (options.uglify) uglify = options.uglify;
    stylesheetspath = options.stylesheetspath;
    javascriptspath = options.javascriptspath;
    return compiled = options.compiled;
  };

  stylesheets = function(files) {
    if (typeof files === 'string') {
      return "<script src='" + stylesheetspath + files + "'></script>\n";
    } else if (typeof files === 'object') {
      return "<script src='" + stylesheetspath + (files.join(',')) + "'></script>\n";
    }
  };

  javacripts = function(files) {
    if (typeof files === 'string') {
      return "<script src='" + javascriptspath + files + "'></script>\n";
    } else if (typeof files === 'object') {
      return "<script src='" + javascriptspath + (files.join(',')) + "'></script>\n";
    }
  };

  exports.plugin = function(req, res, options) {
    var data, fileData, filePath, name, template;
    data = options.data || {};
    data['stylesheets'] = stylesheets;
    data['javascripts'] = javacripts;
    name = options.name;
    if (!name) name = req.url.replace(basepath, '').replace(/\?.*/, '');
    filePath = options.file || path.join(basedir, "" + name + ".jade");
    fileData = fs.readFileSync(filePath, 'utf8');
    try {
      template = jade.compile(fileData, {
        filename: filePath,
        pretty: !uglify
      });
      res.setHeader('Content-Type', 'text/html');
      res.write(template(data));
      return res.end();
    } catch (err) {
      console.log(err);
      res.setHeader('Content-Type', 'text/html');
      res.write('<html><body><pre>');
      res.write(err.message);
      res.write('</pre></body></html>');
      return res.end();
    }
    return res.next();
  };

}).call(this);
