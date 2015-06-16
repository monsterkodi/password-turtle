###
000   000   0000000   000   000  0000000    000      00000000
000   000  000   000  0000  000  000   000  000      000     
000000000  000000000  000 0 000  000   000  000      0000000 
000   000  000   000  000  0000  000   000  000      000     
000   000  000   000  000   000  0000000    0000000  00000000
###

Widget = require './Widget'
tools  = require './tools'
pos    = require './pos'
def    = require './def'

class Handle extends Widget
        
    init: (cfg, defs) =>

        cfg = def cfg, defs

        @config = def cfg,
            radius: 16
            noMove: true
                        
        @circle         = @config.svg.circle @config.radius
        @circle.addClass @config.class
        @elem           = @circle.node
        @elem.getWidget = @returnThis
        @initElem()
        @initEvents()
        @elem.relPos    = @relPos
        
        @drag = new Drag
            target : @elem
            onStop : @config.onUp
        @
    
    initEvents: =>
        @elem.addEventListener 'onpos',   @config.onPos if @config.onPos?

    close: =>
        @circle?.remove()
        @circle = undefined
        super()
    
    constrain: (minX, minY, maxX, maxY) => @drag.constrain minX, minY, maxX, maxY
    
    relPos: => pos @circle.cx(), @circle.cy()
    absPos: => pos @circle.cx(), @circle.cy()
    
    move: (p) => @setPos @absPos().plus p
    setPos: =>
        p = tools.arg()
        o = @relPos()
        if o.notSame p
            @circle.center p.x, p.y
            @elem.dispatchEvent new CustomEvent 'onpos', { 'detail': p }

module.exports = Handle