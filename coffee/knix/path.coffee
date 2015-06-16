###
00000000    0000000   000000000  000   000
000   000  000   000     000     000   000
00000000   000000000     000     000000000
000        000   000     000     000   000
000        000   000     000     000   000
###

Widget = require './widget'
def    = require './def'

class Path extends Widget

    init: (cfg, defs) =>
        
        @config = def cfg, _.def defs,
            type     : 'path'
            start    : pos(0,0)
            startDir : pos(0,0)
            end      : pos(0,0)
            endDir   : pos(0,0)
            svg      : knix.svg
            noMove   : true

        @path = @config.svg.path()
        @path .M 0,0
            .Q 0,0,0,0
            .Q 0,0,0,0

        @path.attr('stroke-linecap': 'round', 'stroke-linejoin': 'round')
        @path.style(cursor: 'grabbing')
        @path.stroke(width: 4)
        @path.addClass('path')
        @path.addClass(clss) for clss in @config.class.split(' ') if @config.class?
        @path.fill('none')
        @elem = @path.node
        @elem.getWidget = @returnThis
        
        if @config.startHandle?
            @config.startHandle.elem.addEventListener 'onpos', @setStart
        if @config.endHandle?
            @config.endHandle.elem.addEventListener 'onpos', @setEnd

        @config.endHead   = @config.end.plus @config.endDir
        @config.startHead = @config.start.plus @config.startDir
        @setStart @config.start
        @setEnd   @config.end
        @initEvents()
        @

    close: =>
        if @config.startHandle? then @config.startHandle.elem.removeEventListener 'onpos', @setStart
        if @config.endHandle?   then @config.endHandle.elem.removeEventListener 'onpos', @setEnd
        @path?.remove()
        @path = undefined
        super()

    setVisible:   (v) => if v then @path.show() else @path.hide()

    setEndDir:    (p) => @config.endDir = p; @setEnd @config.end
    setStartDir:  (p) => @config.startDir = p; @setStart @config.start
    setEndHead:   (p) => @setEndDir p.minus(@config.end)
    setStartHead: (p) => @setStartDir p.minus(@config.start)
    
    swapStartHandle: (h) => 
        @config.startHandle.elem.removeEventListener 'onpos', @setStart
        @config.startHandle = h
        @config.startHandle.elem.addEventListener 'onpos', @setStart

    setStart: =>
        p = _.arg()
        @config.start = pos p.x, p.y
        @config.startHead = @config.start.plus(@config.startDir)
        @config.mid = @config.startHead.mid(@config.endHead)
        @setCtrl 0, @config.start
        @setCtrl 1, @config.startHead
        @setCtrl 2, @config.mid

    setEnd: =>
        p = _.arg()
        @config.end = pos p.x, p.y
        @config.endHead = @config.end.plus(@config.endDir)
        @config.mid = @config.startHead.mid(@config.endHead)
        @setCtrl 2, @config.mid
        @setCtrl 3, @config.endHead
        @setCtrl 4, @config.end

    setCtrl: (c, p) =>
        si = [0,1,1,2,2][c]
        o  = [0,0,2,0,2][c]
        s  = @path.getSegment(si)
        s.coords[0+o] = p.x
        s.coords[1+o] = p.y
        @path.replaceSegment si, s

module.exports = Path