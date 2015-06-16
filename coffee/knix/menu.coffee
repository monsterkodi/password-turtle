###
00     00  00000000  000   000  000   000
000   000  000       0000  000  000   000
000000000  0000000   000 0 000  000   000
000 0 000  000       000  0000  000   000
000   000  00000000  000   000   0000000 
###

Widget = require './widget'
def    = require './def'

class Menu extends Widget

    init: (cfg, defs) =>
    
        cfg = def cfg, defs
        
        super cfg,
            type: 'menu'
        @
        
    isSubmenu: => @elem.hasClassName 'submenu'
        
    show: =>
        if @isSubmenu()
            $('stage_content').appendChild @elem
            parent = $(@config.parentID).widget
            @setPos parent.absPos().plus pos 0, parent.getHeight()
        @elem.addEventListener 'click', @hide
        @elem.addEventListener 'mouseleave', @hide
        super
        
    hide: =>
        if @isSubmenu()
            @elem.removeEventListener 'mousedown', @hide
            @elem.removeEventListener 'mouseleave', @hide
        super
        
    ###
     0000000  000000000   0000000   000000000  000   0000000
    000          000     000   000     000     000  000     
    0000000      000     000000000     000     000  000     
         000     000     000   000     000     000  000     
    0000000      000     000   000     000     000   0000000
    ###
        
    @menu: (id) => $(id)?.getWidget()
        
    @addButton: (cfg, defs) => 
        cfg = def cfg, defs
        @menu(cfg.menu).insertChild cfg,
            type:    'button'
            class:   'tool-button'
            id:      cfg.menu+'_button_'+cfg.text
            tooltip: cfg.text
                                            
module.exports = Menu
