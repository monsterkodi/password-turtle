###
000   000  0000000     0000000   000   000
000   000  000   000  000   000   000 000 
000000000  0000000    000   000    00000  
000   000  000   000  000   000   000 000 
000   000  0000000     0000000   000   000
###

class Hbox extends Widget
    
    init: (cfg, defs) =>

        cfg = _.def cfg, defs
        
        cfg = _.def cfg, 
            valign  : 'middle'
            spacing : 5

        super cfg,
            type  : 'hbox'
            style :
                display       : 'table'
                borderSpacing : '%dpx 0px'.fmt cfg.spacing
                marginRight   : '-%dpx'.fmt cfg.spacing
                marginLeft    : '-%dpx'.fmt cfg.spacing
        @

    insertChild: (cfg) =>

        child = super cfg

        child.elem.style.display       = 'table-cell'
        child.elem.style.verticalAlign = cfg.valign? and cfg.valign or @config.valign

        child
