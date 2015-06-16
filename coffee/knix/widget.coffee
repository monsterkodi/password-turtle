###
000   000  000  0000000     0000000   00000000  000000000
000 0 000  000  000   000  000        000          000   
000000000  000  000   000  000  0000  0000000      000   
000   000  000  000   000  000   000  000          000   
00     00  000  0000000     0000000   00000000     000   
###

uuid    = require 'node-uuid'
unique  = require 'lodash.uniq'
filter  = require 'lodash.filter'
find    = require 'lodash.find'
warning = require './warning'
log     = require './log'
dbg     = require './log'
str     = require './str'
pos     = require './pos'
def     = require './def'

class Widget

    constructor: (cfg, defs) -> @init cfg, defs; @postInit()

    postInit: => @

    init: (cfg, defs) =>

        cfg = def cfg, defs
        
        # dbg cfg

        if not cfg.type?
            warning "NO TYPE?"
            cfg.type = 'unknown'

        if not cfg.elem?
            cfg.elem = (cfg.attr?.href? or cfg.href? or null) and 'a'
            cfg.elem ?= 'div'                               # div is default element

        @elem = Widget.elem cfg.elem, cfg.type              # create element
        if cfg.id?
            @elem.id = cfg.id
            # log cfg.id
        @elem.widget = @                                    # let this be the elements widget
        @config = cfg                                       # set config
        @config.id = @elem.id                               # store id in config

        @initElem()
        
        @elem.relPos = -> o = @positionedOffset(); pos o.left, o.top

        @elem.writeAttribute('id', @config.id) if @config.id? # set element id

        for a,v of @config.attr                             # set element attributes
            @elem.writeAttribute(a, v)

        for k in ['href']
            @elem.writeAttribute(k, @config[k]) if @config[k]?

        if @config.class                                    # add class names
            for clss in @config.class.split(' ')
                @elem.addClassName clss

        #__________________________________________________ CSS setup

        if @config.style
            @elem.setStyle @config.style

        style = $H()
        for s in ['minWidth', 'minHeight', 'maxWidth', 'maxHeight'] when @config[s]?
            style.set(s, @config[s]+'px')
        @elem.setStyle style.toObject() if style.keys().length

        #__________________________________________________ DOM setup

        if @config.parent?
            @addToParent(@config.parent) 
            delete @config.parent
        
        @insertChildren()
        @insertText()

        #__________________________________________________ position and size

        if @config.pos?
            @config.x = @config.pos.x if @config.pos.x?
            @config.y = @config.pos.y if @config.pos.y?

        if @config.x? or @config.y?
            @elem.style.position = 'absolute'
            @moveTo @config.x, @config.y

        @resize @config.width, @config.height if @config.width? or @config.height?
        
        if @config.tooltip
            Tooltip = require './tooltip'
            Tooltip.create
               target: @
               onTooltip: @onTooltip 

        #__________________________________________________ event setup

        @addMovement()
        @initEvents()
        @

    ###
    00000000  000   000  00000000  000   000  000000000   0000000
    000       000   000  000       0000  000     000     000     
    0000000    000 000   0000000   000 0 000     000     0000000 
    000          000     000       000  0000     000          000
    00000000      0      00000000  000   000     000     0000000 
    ###

    initEvents: =>
        @elem.addEventListener "click",      @config.onClick  if @config.onClick?
        @elem.addEventListener "mousedown",  @config.onDown   if @config.onDown?
        @elem.addEventListener "mouseup",    @config.onUp     if @config.onUp?
        @elem.addEventListener "mouseover",  @config.onOver   if @config.onOver?
        @elem.addEventListener "mousemove",  @config.onMove   if @config.onMove?
        @elem.addEventListener "mouseout",   @config.onOut    if @config.onOut?
        @elem.addEventListener "ondblclick", @config.onDouble if @config.onDouble?
        @

    ###
     0000000   0000000   000   000  000   000  00000000   0000000  000000000  000   0000000   000   000
    000       000   000  0000  000  0000  000  000       000          000     000  000   000  0000  000
    000       000   000  000 0 000  000 0 000  0000000   000          000     000  000   000  000 0 000
    000       000   000  000  0000  000  0000  000       000          000     000  000   000  000  0000
     0000000   0000000   000   000  000   000  00000000   0000000     000     000   0000000   000   000
    ###

    initConnections: =>
        connections = @config.connect
        return if not connections?
        for connection in connections
            @connect connection.signal, connection.slot
        @

    connect: (signal, slot) =>
        # tag 'Connection'
        # log @elem.id, signal, slot
        [signalSender, signalEvent] = @resolveSignal signal
        slotFunction = @resolveSlot slot
        if not signalSender?
            error "sender not found!"
        if not signalEvent?
            error "event not found!"
        if not slotFunction?
            error "slot not found!"
        # log signalSender.elem.id
        signalSender.elem.addEventListener signalEvent, slotFunction
        @

    disconnect: (signal, slot) =>
        [signalSender, signalEvent] = @resolveSignal signal
        slotFunction = @resolveSlot slot
        if not signalSender?
            error "sender not found!"
        if not signalEvent?
            error "event not found!"
        if not slotFunction?
            error "slot not found!"
        # log 'disconnect', signalSender.elem.id, signalEvent
        signalSender.elem.removeEventListener signalEvent, slotFunction
        @

    connector: (name) =>
        # tag 'Connection'
        # log name
        for t in ['slot', 'signal', 'in', 'out']
            for e in @elem.select('.'+t)
                if e.hasClassName 'connector'
                    # tag 'Connection'
                    # log 'found connector element', t, e.widget.config[t]
                    if e.widget.config[t] == name or e.widget.config[t]+':'+t == name
                        return e.widget
            # warning 'no elem with class', name
        error 'connector not found!', name
        undefined

    resolveSignal: (signal) =>
        [event, sender] = signal.split(':').reverse()
        if sender?
            sdr = @getChild sender
            sdr = @getWindow()?.getChild(sender) unless sdr?
            sender = sdr
        sender = @ unless sender?
        [sender, event]

    resolveSlot: (slot) =>
        if typeof slot == 'function'
            return slot
        if typeof slot == 'string'
            [func, receiver] = slot.split(':').reverse()
            if receiver?
                # log 'receiver', receiver
                rec = @getChild(receiver)
                # log 'receiver', rec, 'child', @getWindow()
                rec = @getWindow()?.getChild(receiver) unless rec?
                # log 'receiver', rec, 'window child'
                receiver = rec
            receiver = @ unless receiver?
            # log 'receiver', receiver, 'this'
            if receiver[func]?
                if typeof receiver[func] == 'function'
                    return receiver[func] #.bind(receiver)
                else
                    error 'not a function'
            # log 'no func', func, 'in receiver', receiver
        error 'cant resolve slot:', slot, typeof slot
        null

    ###
     0000000  000   0000000   000   000   0000000   000    
    000       000  000        0000  000  000   000  000    
    0000000   000  000  0000  000 0 000  000000000  000    
         000  000  000   000  000  0000  000   000  000    
    0000000   000   0000000   000   000  000   000  0000000
    ###

    emit: (signal, args) =>
        event = new CustomEvent signal,
            bubbles    : false,
            cancelable : true,
            detail     : args
        @elem?.dispatchEvent event
        @

    emitSize: =>
        @emit 'size',
            width  : @config.width
            height : @config.height

    emitMove: =>
        p = pos @config.x, @config.y
        @emit 'move',
            pos: p

    emitValue: (v) => 
        @emit 'onValue',
            value: v
        
    emitClose: => @emit 'close'

    ###
    00000000  000      00000000  00     00
    000       000      000       000   000
    0000000   000      0000000   000000000
    000       000      000       000 0 000
    00000000  0000000  00000000  000   000
    ###

    @elem: (type, clss) => # create element of <type> add class <clss> and assign a unique id
        e = new Element type
        e.id = Widget.newID clss
        e.addClassName clss
        e

    @newID: (clss) => "%s-%s".fmt clss, uuid.v4()    
        
    initElem: =>
        @elem.getWindow     = @getWindow
        @elem.getChild      = @getChild
        @elem.getParent     = @getParent
        @elem.toggleDisplay = @toggleDisplay        
                
    ###
    000   000  000  00000000  00000000    0000000   00000000    0000000  000   000  000   000
    000   000  000  000       000   000  000   000  000   000  000       000   000   000 000 
    000000000  000  0000000   0000000    000000000  0000000    000       000000000    00000  
    000   000  000  000       000   000  000   000  000   000  000       000   000     000   
    000   000  000  00000000  000   000  000   000  000   000   0000000  000   000     000   
    ###

    returnThis: => @

    addToParent: (p) =>
        if not @elem?
            error 'no @elem?'
            return this
        if not p?
            error 'no p?'
            return this
        parentElement = p.content?.elem
        parentElement = p.elem unless parentElement
        parentElement = $(p) unless parentElement
        if not parentElement?
            error 'no element?', p
            return this
        parentElement.insert @elem
        @config.parentID = parentElement.id
        @

    insertChild: (config, defaults) =>
        child = knix.create config, defaults
        child.addToParent @
        child

    insertChildren: =>
        if @config.child
            c = @insertChild(@config.child)
            @config.child = c.config
        if @config.children
            c = []
            for cfg in @config.children
                c.push @insertChild(cfg).config
            @config.children = c
        @

    insertText: => @elem?.insert(@config.text) if @config.text?
    setText: (t) => @elem.textContent=''; @config.text = t; @insertText()
        
    # returns first ancestor element that matches class or id of argument
    # with no argument: the element with config.parentID or the parent element

    getParent: =>
        args = $A(arguments)
        if args.length
            anc = @elem.ancestors()
            for a in anc
                if a.match("#"+args[0]) or a.match("."+args[0])
                    return a.widget
            return
        return $(@config.parentID).widget if @config.parentID
        return $(@parentElement.id).widget if @parentElement?
        return @getWidget().getParent() if @getWidget?()?.getParent?
        return undefined
        
    getUp: => 
        args = $A(arguments)
        if args.length
            if @elem.match("#"+args[0]) or @elem.match("."+args[0]) then return @
        @getParent.apply @, arguments
            
    getAncestors: => filter [@getParent(), @getParent()?.getAncestors()].flatten()
    upWidgets:    => filter [@, @getAncestors()].flatten()
    upWidgetWithConfigValue: (key) => find @upWidgets(), (w) -> w?.config?[key]? 
    matchConfigValue: (key, value, list) => filter ( w for w in list when w?.config?[key] == value )
        
    getWindow: => # without argument: returns this or first ancestor element with class 'window'
                  # with argument: returns the window with id 
        if arguments.length
            return $($A(arguments)[0]).widget
        if @elem.hasClassName 'window'
            return this
        @getParent 'window'

    getChild: (classOrID) => # returns first child element that matches class or element id
        c = @elem.select('#'+classOrID, '.'+classOrID)
        return c[0].widget if c.length
        undefined
        
    children:    => filter ( c.getWidget?() for c in @elem.childNodes )
    allChildren: => unique filter ( c.getWidget?() for c in $(@elem.id).descendants() )
    
    prepareState: => @
    getState: => 
        for c in @allChildren() 
            c.prepareState()
        clone @config
        
    ###
    00     00  000   0000000   0000000
    000   000  000  000       000     
    000000000  000  0000000   000     
    000 0 000  000       000  000     
    000   000  000  0000000    0000000
    ###
    
    close: =>
        # log 'close', @elem.id
        @emitClose()
        @elem?.remove()
        delete @elem
        delete @config
        undefined

    onTooltip: => @config.tooltip
        
    dump: => @config
    isWindow: => false

    clear: =>
        while @elem.hasChildNodes()
            @elem.removeChild @elem.lastChild
        @

    show: =>
        @elem.show()
        @elem.raise()
        @
        
    hide: =>
        @elem.hide()
        @

    toggleDisplay: =>
        if @elem.visible()
            @elem.hide()
        else
            @elem.show()

    ###
     0000000   00000000   0000000   00     00  00000000  000000000  00000000   000   000
    000        000       000   000  000   000  000          000     000   000   000 000 
    000  0000  0000000   000   000  000000000  0000000      000     0000000      00000  
    000   000  000       000   000  000 0 000  000          000     000   000     000   
     0000000   00000000   0000000   000   000  00000000     000     000   000     000   
    ###

    setPos: (p) => @moveTo p.x, p.y
    move:   (p) => @moveBy p.x, p.y
    moveBy: (dx, dy) => @setPos @relPos().plus pos(dx, dy)
    moveTo: (x, y) =>
        @config.x = x if x?
        @config.y = y if y?
        @elem.style.left = "%dpx".fmt(x) if x?
        @elem.style.top  = "%dpx".fmt(y) if y?
        # log @elem.style.left, @elem.style.top
        @emitMove()
        @

    setWidth: (w) =>
        if w?
            @config.width = w
            if @getWidth() != w
                ow = @elem.style.width
                @elem.style.width = "%dpx".fmt(w)

                if newWidth = @getWidth() and diff = newWidth - w
                    @elem.style.width = "%dpx".fmt(w - diff)
                    log 'adjusted', diff, @elem.id, @elem.style.width, w

                @emitSize() if ow != @elem.style.width
        @

    setHeight: (h) =>
        if h?
            oh = @elem.style.height
            @setHeightNoEmit h
            # log @elem.id, @elem.style.height, h
            @emitSize() if oh != @elem.style.height
        @

    setHeightNoEmit: (h) =>
        if h? 
            @config.height = h
            if @getHeight() != h
                # log @elem.id, @getHeight(), h
                @elem.style.height = "%dpx".fmt(h)
                # log @elem.id, @elem.style.height, h
                if newHeight = @getHeight() and diff = newHeight - h
                    @elem.style.height = "%dpx".fmt(h - diff)
                    log 'adjusted', diff, @elem.id, @elem.style.height, h

    resize: (w, h) =>
        @setWidth w
        @setHeight h
        @

    setSize:   (s) => @resize s.width, s.height
    getSize:   => return { width : @getWidth(), height : @getHeight() }
    sizePos:   => return pos @getWidth(), @getHeight()
    getWidth:  => @elem?.getWidth()
    getHeight: => @elem?.getHeight()
    absRect:   => Rect = require './rect'; new Rect @absPos().x, @absPos().y, @getWidth(), @getHeight()

    innerWidth:   => @elem.getLayout().get("padding-box-width")
    innerHeight:  => @elem.getLayout().get("padding-box-height")
    minWidth:     => w = parseInt @elem.getStyle('min-width' ); if w then w else 0
    minHeight:    => h = parseInt @elem.getStyle('min-height'); if h then h else 0
    maxWidth:     => w = parseInt @elem.getStyle('max-width' ); if w then w else Number.MAX_VALUE
    maxHeight:    => h = parseInt @elem.getStyle('max-height'); if h then h else Number.MAX_VALUE
    relPos:       => o = @elem.positionedOffset(); pos o.left, o.top
    absPos:       => o = @elem.cumulativeOffset(); s = @elem.cumulativeScrollOffset(); pos o.left - s.left, o.top - s.top
    scrollPos:    => pos @elem.scrollLeft, @elem.scrollTop
    absCenter:    => @absPos().plus(pos(@elem.getWidth(),@elem.getHeight()).scale(0.5))
    stretchWidth: => @elem.style.width = '50%'

    ###
    00     00   0000000   000   000  00000000
    000   000  000   000  000   000  000     
    000000000  000   000   000 000   0000000 
    000 0 000  000   000     000     000     
    000   000   0000000       0      00000000
    ###

    addMovement: =>        
        if @config.isMovable
            new Drag
                target:  @elem
                minPos:  pos(undefined,0)
                onMove:  @onMove
                onStart: @moveStart
                onStop:  @moveStop
                cursor: null

    onMove: (drag, event) =>
        log 'move', @elem?.id
        @emitMove()
        
    moveStart: (drag, event) =>
        tag 'Drag'
        log 'start', event.target?.id
        StyleSwitch.togglePathFilter()

    moveStop: (drag, event) =>
        tag 'Drag'
        log 'stop', event.target?.id
        StyleSwitch.togglePathFilter()

module.exports = Widget
