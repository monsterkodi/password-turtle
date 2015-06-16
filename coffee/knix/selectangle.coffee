###
 0000000  00000000  000      00000000   0000000  000000000   0000000   000   000   0000000   000      00000000
000       000       000      000       000          000     000   000  0000  000  000        000      000     
0000000   0000000   000      0000000   000          000     000000000  000 0 000  000  0000  000      0000000 
     000  000       000      000       000          000     000   000  000  0000  000   000  000      000     
0000000   00000000  0000000  00000000   0000000     000     000   000  000   000   0000000   0000000  00000000
###

Widget = require './widget'
def    = require './def'

class Selectangle extends Widget

    @start  : (wid) => @selectangle = new Selectangle parent : wid
    @stop   : => @selectangle?.close()
    @toggle : => if @selectangle? then @stop() else @start()

    init: (cfg, defs) =>
        
        cfg = def cfg, defs
        window.document.documentElement.style.cursor = 'crosshair'
        Stage = require './stage'        
        pos = if cfg.parent?.absPos? then cfg.parent.absPos().to(Stage.mousePos) else Stage.mousePos

        @wid = cfg.parent         
        
        super cfg,
            type:   'selectangle'
            parent: 'stage_content'
            pos:    pos
            width:  0
            height: 0
            
        stage = $('stage_content')
        stage.addEventListener 'mousemove', @onMove
        stage.addEventListener 'mouseup',   @close
        stage.addEventListener 'mousedown', @close
        @
    
    close: (event) =>
        if @sizePos().square() == 0 and not event.shiftKey
            for wid in (@wid? and @wid.allChildren() or knix.allWindows())
                wid.elem.removeClassName 'selected'
        stage = $('stage_content')
        stage.removeEventListener 'mousemove', @onMove
        stage.removeEventListener 'mouseup',   @done
        stage.removeEventListener 'mousedown', @done     
        window.document.documentElement.style.cursor = 'auto'   
        super

    onMove: (event) =>
        Stage = require './stage'
        ep  = Stage.absPos event
        if @wid?.absPos? then ep = @wid.absPos().to(ep)
        tl  = ep.min @config.pos
        br  = ep.max @config.pos
        @setPos tl
        @resize br.x - tl.x, br.y - tl.y
        
        @wid?.scrollToPos? ep
        
        widgets = @wid? and @wid.allChildren() or knix.allWindows()
        window.document.documentElement.style.cursor = 'crosshair'        
        
        rect = @absRect()
        # log rect
        for wid in widgets
            if rect.contains wid.absCenter()
                if not wid.config.noSelect
                    wid.elem.addClassName 'selected'
            else if not event.shiftKey
                wid.elem.removeClassName 'selected'
            
module.exports = Selectangle
