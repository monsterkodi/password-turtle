###
00000000    0000000   0000000  
000   000  000   000  000   000
00000000   000000000  000   000
000        000   000  000   000
000        000   000  0000000  
###

Widget = require './widget'
def    = require './def'

class Pad extends Widget
        
    init: (cfg, defs) =>
    
        cfg = def cfg, defs
        cfg = def cfg,
            minWidth   : 100
            minHeight  : 100
            numHandles : 1
            hasPaths   : true
        
        @o = 8 # offset from border
        
        super cfg,
            type       : 'pad'
            noMove     : true
            minWidth   : cfg.minWidth
            minHeight  : cfg.minHeight
            child      :
                type   : 'svg'
                noMove : true
        
        @svg = @getChild 'svg'
        
        if @config.vals?
            @config.vals = ( pos v.x, v.y for v in @config.vals )
            @config.numHandles = @config.vals.length
        else
            @config.vals = []
            for i in [0...@config.numHandles]
                hp = pos i.toFixed(3)/(@config.numHandles-1), i.toFixed(3)/(@config.numHandles-1)
                @config.vals.push hp
        
        @handles = []
        for i in [0...@config.numHandles]
            h = @createHandle()
            @handles.push h
            if i == @config.sustainIndex
                h.circle.addClass 'sustain'
            else if i == 0 or i == @config.numHandles-1
                h.circle.back()
            
        if @config.hasPaths
            @paths = []
            for i in [0...@config.numHandles-1]
                @createPathAtIndex i
             
        @setSVGSize cfg.minWidth, cfg.minHeight                    
        @updateHandles()
        @
    
    ###
    00000000    0000000   000000000  000   000
    000   000  000   000     000     000   000
    00000000   000000000     000     000000000
    000        000   000     000     000   000
    000        000   000     000     000   000
    ###
    
    createPathAtIndex: (i) =>
        p = new Path
            svg         : @svg.svg
            class       : 'pad-path'
            startHandle : @handles[i]
            endHandle   : @handles[i+1]
        p.path.node.addEventListener 'dblclick', @pathDoubleClick
        p.path.back()   
        new Drag
            target : p.path.node
            cursor : 'grab'
            doMove : false
            onMove : @pathDragMove
        @paths.splice i, 0, p 
    
    splitPathAtIndex: (i) =>
        if i < @config.sustainIndex then @config.sustainIndex += 1
        @config.vals.splice i+1, 0, @config.vals[i].mid(@config.vals[i+1])
        h = @createHandle()
        @handles.splice i+1, 0, h
        @handles[i].circle.center -1, -1
        @createPathAtIndex i
        @paths[i+1].swapStartHandle @handles[i+1]
        @updateHandles()
        @constrainHandles()
    
    pathDoubleClick: (event) =>
        sh = event.target.getWidget().config.startHandle
        eh = event.target.getWidget().config.endHandle
        i = @handles.indexOf sh
        @splitPathAtIndex i

    pathDragMove: (drag) =>
        sh = drag.target.getWidget().config.startHandle
        sh.move drag.delta
        eh = drag.target.getWidget().config.endHandle
        eh.move drag.delta
        @constrainHandles()
            
    ###
    000   000   0000000   000   000  0000000    000      00000000
    000   000  000   000  0000  000  000   000  000      000     
    000000000  000000000  000 0 000  000   000  000      0000000 
    000   000  000   000  000  0000  000   000  000      000     
    000   000  000   000  000   000  0000000    0000000  00000000
    ###
        
    createHandle: =>
        h = new Handle
            svg   : @svg.svg
            class : 'pad-handle'
            onPos : @onHandlePos
            onUp  : @onHandleUp
        h.elem.addEventListener 'dblclick', @handleDoubleClick
        h
    
    removeHandleAtIndex: (i) =>
        if i < @config.sustainIndex then @config.sustainIndex -= 1
        @paths[i].swapStartHandle @handles[i-1]
        @handles[i-1].circle.center -1, -1
        @config.vals.splice i, 1
        @paths.splice(i-1, 1)[0].close()
        @handles.splice(i, 1)[0].close()
        @updateHandles()
        @constrainHandles()
    
    handleDoubleClick: (event) =>
        h = event.target.getWidget()
        i = @handles.indexOf h
        if i > 0 and i < @handles.length-1 and i != @config.sustainIndex
            @removeHandleAtIndex i

    onHandlePos: (event) =>
        if not @config.vals? then return
        [w,h] = [@getWidth()-2*@o, @getHeight()-2*@o]
        if not w? or not h? then return
        p = _.arg()
        i = @handles.indexOf event.target.getWidget()
        x =       (p.x - @o) / w
        y = 1.0 - (p.y - @o) / h
        
        @config.vals[i].x = x
        @config.vals[i].y = y
    
    onHandleUp: => @constrainHandles()

    constrainHandles: =>
        [w,h] = [@getWidth()-2*@o, @getHeight()-2*@o]

        for i in [0...@config.vals.length]
            minY = @o
            if i == 0
                minY = @o+h
                [minX, maxX] = [@o, @o]
            else if i == @config.vals.length-1
                minY = @o+h
                [minX, maxX] = [@o+w, @o+w]
            else
                minX = @handles[i-1].relPos().x
                maxX = @handles[i+1].relPos().x
                
            @handles[i].constrain minX, minY, maxX, @o+h

    updateHandles: =>
        [w,h] = [@getWidth()-2*@o, @getHeight()-2*@o]
        for i in [0...@config.vals.length]
            hp = pos @o + @config.vals[i].x * w, h - @config.vals[i].y * h + @o
            @handles[i].setPos hp
        
    ###
    000   000   0000000   000    
    000   000  000   000  000    
     000 000   000000000  000    
       000     000   000  000    
        0      000   000  0000000
    ###
        
    valAtRel: (rel) =>
        if @config.numHandles < 2 or rel <= 0 then return @config.vals[0].y
        if rel >= 1 then return @config.vals[@config.vals.length-1].y
        si = 0
        ei = 1
        for i in [0...@config.vals.length]
            if @config.vals[i].x <= rel
                si = i
            else
                ei = i
                break
        
        [sp,ep] = [@config.vals[si],@config.vals[ei]]
        dp = sp.to ep
        dl = dp.length()
        if dl == 0 or dp.x == 0
            log 'null', rel, si, ei, dl, dp.x
            sp.y
        else
            p = sp.plus dp.times (rel - @config.vals[si].x) / dp.x
            p.y
    
    ###
    00000000   000   000  000      00000000  00000000 
    000   000  000   000  000      000       000   000
    0000000    000   000  000      0000000   0000000  
    000   000  000   000  000      000       000   000
    000   000   0000000   0000000  00000000  000   000
    ###
    
    showRuler: (x, y) =>
        [w,h] = [@getWidth()-2*@o, @getHeight()-2*@o]
        if x?
            if not @rulerx?
                @rulerx = new Path
                    svg   : @svg.svg
                    class : 'pad-ruler'
                @rulerx.path.back()
            @rulerx.setStart pos x*w+@o, 0
            @rulerx.setEnd   pos x*w+@o, h+2*@o
        if y?
            if not @rulery?
                @rulery = new Path
                    svg   : @svg.svg
                    class : 'pad-ruler'
                @rulery.path.back()
            @rulery.setStart pos      0, h-y*h+@o
            @rulery.setEnd   pos w+2*@o, h-y*h+@o
        
    hideRuler: =>
        if @rulerx
            @rulerx.close()
            delete @rulerx
        if @rulery
            @rulery.close()
            delete @rulery
        
    ###
     0000000  000  0000000  00000000
    000       000     000   000     
    0000000   000    000    0000000 
         000  000   000     000     
    0000000   000  0000000  00000000
    ###
    
    getWidth:  => @svg.elem.width    
    getHeight: => @svg.elem.height
                
    setSVGSize: (width, height) =>
        @svg.setWidth width
        @svg.setHeight height
        @svg.elem.width = width
        @svg.elem.height = height  
        
                
    setSize: (width, height) =>
        @setSVGSize width, height
        @updateHandles()
        @constrainHandles()

module.exports = Pad