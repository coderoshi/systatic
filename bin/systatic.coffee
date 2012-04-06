#!/usr/bin/env coffee

log      = console.log
argv     = require('optimist').argv
systatic = require('../lib/systatic')


logUsage = ()->
  log 'Usage:'
  log '  systatic [build | new APP_PATH]\n'
  log 'Options:'
  log '    --port port     [default 3000]'
  log '    --ipaddr ipaddr [default 0.0.0.0]'
  log '    --log log       [default none]'

  # if already created
  # log '  systatic [options]'

if argv._.length > 0
  
  # Create a new project from template
  if argv._[0] == 'new'
    if argv._.length == 1
      logUsage()
    else
      systatic.clone(argv._[1], 'basic')
    process.exit(0)

  # Generate static files
  if argv._[0] == 'build'
    systatic.build()
    process.exit(0)
  
  # Deploy static files
  if argv._[0] == 'deploy'
    systatic.deploy()
    process.exit(0)

if argv.help || argv.h
  logUsage()
  process.exit(0)


unless systatic.inProject('.')
  logUsage()
  #log "== Error: Could not find a Systatic project config, perhaps you are in the wrong folder?"  
  process.exit(0)


port    = argv.port || 3000
ipaddr  = argv.ipaddr || '0.0.0.0'
logfile = argv.log

systatic.startServer(port, ipaddr, logfile)
