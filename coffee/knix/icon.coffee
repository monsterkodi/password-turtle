###
000   0000000   0000000   000   000
000  000       000   000  0000  000
000  000       000   000  000 0 000
000  000       000   000  000  0000
000   0000000   0000000   000   000
###

Widget = require './widget'
dbg    = require './log'
def    = require './def'

class Icon extends Widget

    init: (cfg, defs) =>

        cfg = def cfg, defs
        
        cfg = def cfg, 
            type: 'icon'
            elem: 'span'

        super cfg,
            child:
                elem:  'i'
                class: (cfg.icon.startsWith('fa') and 'fa ' or 'octicon ') + cfg.icon
        
    setIcon: (icon) =>
        e = @elem.firstChild
        e.removeClassName @config.icon
        @config.icon = icon
        e.addClassName @config.icon

module.exports = Icon
