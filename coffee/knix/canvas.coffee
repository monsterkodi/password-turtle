###
 0000000   0000000   000   000  000   000   0000000    0000000
000       000   000  0000  000  000   000  000   000  000     
000       000000000  000 0 000   000 000   000000000  0000000 
000       000   000  000  0000     000     000   000       000
 0000000  000   000  000   000      0      000   000  0000000 
###

Widget = require './widget'
def    = require './def'

class Canvas extends Widget

    init: (cfg, defs) =>
            
        cfg = def cfg, defs

        cfg.width  = undefined
        cfg.height = undefined
        
        super cfg,
            elem   : 'canvas'
            noMove : true

    resize: (width, height) =>
        
        @setHeightNoEmit height
        @elem.width  = width
        @elem.height = height

module.exports = Canvas