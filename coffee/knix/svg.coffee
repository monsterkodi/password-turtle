###
 0000000  000   000   0000000 
000       000   000  000      
0000000    000 000   000  0000
     000     000     000   000
0000000       0       0000000 
###

Widget = require './widget'
def    = require './def'

class Svg extends Widget
    
    init: (cfg, defs) =>
    
        cfg = def cfg, defs
        
        super cfg,
            type : 'svg'
            
        @svg = SVG @elem
        @svg.node.getWidget = @returnThis
        @

module.exports = Svg