###
0000000    00000000    0000000    0000000 
000   000  000   000  000   000  000      
000   000  0000000    000000000  000  0000
000   000  000   000  000   000  000   000
0000000    000   000  000   000   0000000 
###

assign = require 'lodash.assign'
Stage  = require './stage'
error  = require './error'
log    = require './log'
def    = require './def'

class Drag

    constructor: (cfg) ->
        
        assign @, def cfg,
                target  : null
                handle  : null
                minPos  : null
                maxPos  : null
                onStart : null
                onMove  : null
                onStop  : null
                doMove  : true
                active  : true
                cursor  : 'move'

        if typeof @target is 'string'
            t = document.getElementById @target
            if not t?
                error 'cant find drag target with id', @target
                return
            @target = t
        if not @target?
            error 'cant find drag target', @target
            return
        if @minPos? and @maxPos?
            [@minPos, @maxPos] = [@minPos.min(@maxPos), @minPos.max(@maxPos)]
        @dragging  = false
        @listening = false
        @handle    = document.getElementById(@handle) if typeof (@handle) is 'string'
        @handle    = @target unless @handle?
        @handle.style.cursor = @cursor
        @activate() if @active
        return

    absPos: (event) => Stage.absPos event
    relPos: (event) => Stage.relPos event

    dragStart: (event) =>
        
        return if @dragging or not @listening
        # log 'start', @target.id
        @dragging = true
        @startPos = @absPos event
        @pos     = @absPos event
        @onStart @, event if @onStart?
        @lastPos = @absPos event
        
        if @doMove
            @startPos = @target.relPos()
            @startPos = @startPos.check()

        document.addEventListener 'mousemove', @dragMove
        document.addEventListener 'mouseup',   @dragUp

    dragMove: (event) =>

        return if not @dragging

        @pos   = @absPos event
        @delta = @lastPos.to @pos
        @deltaSum = @startPos.to @pos
        
        if @doMove
            newPos = @startPos.add(@delta).clamp @minPos, @maxPos
            @target.getWidget().setPos newPos
            
        if @onMove?
            @onMove this, event

        @lastPos = @pos

    constrain: (minX, minY, maxX, maxY) =>
        
        wp = @target.getWidget().relPos()

        @minPos = pos minX, minY
        @maxPos = pos maxX, maxY
        
        cp = wp.clamped @minPos, @maxPos

        if wp.notSame cp
            
            if @doMove
                @target.getWidget().setPos cp
                
    dragUp: (event) => @dragStop event

    dragStop: (event) =>

        return if not @dragging
        document.removeEventListener 'mousemove', @dragMove
        document.removeEventListener 'mouseup',   @dragUp
        delete @lastPos
        delete @startPos
        @onStop this, event if @onStop? and event?
        @dragging = false
        return

    activate: =>
        
        return if @listening
        @listening = true
        @handle.addEventListener 'mousedown', @dragStart
        return

    deactivate: =>

        return if not @listening
        @handle.removeEventListener 'mousedown', @dragStart
        @listening = false
        @dragStop() if @dragging
        return

module.exports = Drag
