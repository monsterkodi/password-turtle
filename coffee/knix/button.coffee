###
0000000    000   000  000000000  000000000   0000000   000   000
000   000  000   000     000        000     000   000  0000  000
0000000    000   000     000        000     000   000  000 0 000
000   000  000   000     000        000     000   000  000  0000
0000000     0000000      000        000      0000000   000   000
###

isString = require 'lodash.isstring'
Widget   = require './widget'
def      = require './def'

class Button extends Widget
    
    init: (cfg, defs) =>

        cfg = def cfg, defs
        
        children = []
                
        if cfg.icon?
            children.push
                type : 'icon'
                icon : cfg.icon
                
        super cfg,
            keys     : []
            type     : 'button'
            noMove   : true
            children : children
            
        @connect 'mousedown', @trigger
        @connect 'mouseup',   @release

    insertText: =>
        if @config.menu != 'menu'
            super

    trigger: (event) =>
        id = isString(event) and event or event?.target?.id or @config.recKey
        @config.action? event
        @emit 'trigger', id
        event?.stop?()
        @
        
    release: (event) =>
        id = isString(event) and event or event?.target?.id or @config.recKey
        @emit 'release', id
        @

module.exports = Button
