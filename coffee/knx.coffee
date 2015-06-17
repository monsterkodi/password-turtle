knix    = require './js/knix/knix'
log     = require './js/knix/log'
error   = require './js/knix/error'
warning = require './js/knix/warning'
ipc     = require 'ipc'

document.observe 'dom:loaded', ->
    
    knix.init
        console: 'maximized'
    
    ipc.on 'knix_log', (args) ->  log.apply log, args
    ipc.on 'knix_error', (args) ->  error.apply error, args
    ipc.on 'knix_warning', (args) ->  warning.apply warning, args
