knix = require './js/coffee/knix/knix'
ipc  = require 'ipc'
log  = require './js/coffee/knix/log'

document.observe 'dom:loaded', ->
    
    knix.init
        console: 'maximized'
    
    ipc.on 'logknix', (args) -> 
        # console.log 'lognix' + args;
        log.apply log, args
