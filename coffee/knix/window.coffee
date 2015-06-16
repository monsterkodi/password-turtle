###
000   000  000  000   000  0000000     0000000   000   000
000 0 000  000  0000  000  000   000  000   000  000 0 000
000000000  000  000 0 000  000   000  000   000  000000000
000   000  000  000  0000  000   000  000   000  000   000
00     00  000  000   000  0000000     0000000   00     00
###

Widget = require './widget'
Stage  = require './stage'
Drag   = require './drag'
pos    = require './pos'
str    = require './str'
log    = require './log'
def    = require './def'

class Window extends Widget

    constructor: (cfg, defs) -> super cfg, defs

    init: (cfg, defs) =>

        cfg = def cfg, defs
            
        children = cfg.children
        if cfg.child
            if not children? then children = []
            children.push cfg.child

        delete cfg.children
        delete cfg.child

        connect = cfg.connect
        delete cfg.connect

        super cfg,
            type      : 'window'
            class     : 'window' 
            parent    : 'stage_content'
            hasClose  : true
            hasShade  : true
            resize    : true
            # isMovable : true
            isShaded  : false
            onDown    : @raise

        @initWindow()
        @config.children = children
        @insertChildren()
        @config.connect = connect
        @layoutChildren()

        if @config.popup then knix.addPopup @

        if @config.center
            @moveTo Math.max(0, Stage.size().width/2 - @getWidth()/2), Math.max(0,Stage.size().height/2 - @getHeight()/2)
            @config.center = undefined
        @

    postInit: => @sizeWindow()
    
    ###
    000  000   000  000  000000000  000   000  000  000   000  0000000     0000000   000   000
    000  0000  000  000     000     000 0 000  000  0000  000  000   000  000   000  000 0 000
    000  000 0 000  000     000     000000000  000  000 0 000  000   000  000   000  000000000
    000  000  0000  000     000     000   000  000  000  0000  000   000  000   000  000   000
    000  000   000  000     000     00     00  000  000   000  0000000     0000000   00     00
    ###

    initWindow: =>

        @addCloseButton()  if @config.hasClose
        @addShadeButton()  if @config.hasShade
        @initButtons()     if @config.buttons?
                
        @addTitleBar() if @config.hasTitle or @config.title

        content = knix.create
            elem   : 'div',
            type   : 'content'
            parent : @elem.id

        @content = content

        if @config.content == 'scroll'

            content.elem.setStyle
                overflow : 'scroll'
                width    : '100%'
                height   : '100%'
                height   : "%dpx".fmt @contentHeight()

        @elem.on 'size', @sizeWindow
        @

    initButtons: =>

        align = 'left'
        lastRightButton = undefined
        for b in @config.buttons
            button = @insertChild b, 
                noMove : true
                type   : 'button'
                align  : align
            align = button.config.align
            if align == 'right'
                if lastRightButton?
                    lastRightButton.elem.insert before : button.elem
                lastRightButton = button
            button.elem.addClassName 'tool-button'
            button.elem.addClassName 'window-button-'+button.config.align
            
            if b.configKey?
                @config[b.configKey] = b.state
                @connect b.class+':onState', @onButtonState

    onButtonState: (event) =>
        button = event.target.widget
        key    = button.config.configKey
        state  = event.detail.state
        if key.indexOf('.') > 0
            path  = key.split '.'
            child = @
            while path.length > 1
                child = child[path.splice(0,1)]
            child[path[0]]? event.detail.state
            child['on'+_.capitalize(path[0])]? event
        else
            @[key]? event.detail.state
            @['on'+_.capitalize(key)]? event
            @config[key] = state

    ###
    000   000  00000000   0000000   0000000    00000000  00000000 
    000   000  000       000   000  000   000  000       000   000
    000000000  0000000   000000000  000   000  0000000   0000000  
    000   000  000       000   000  000   000  000       000   000
    000   000  00000000  000   000  0000000    00000000  000   000
    ###

    addTitleBar: =>
        t = knix.create
            type:   'title'
            text:   @config.title
            parent: this
        t.elem.ondblclick = @maximize
        t.elem.onmousedown  = @onTitleSelect

    onTitleSelect: (event) =>
        if event.shiftKey
            if @elem.hasClassName 'selected'
                @elem.removeClassName 'selected'
                return
            @elem.addClassName 'selected'
        
    addCloseButton: =>
        knix.create
            type:   'button'
            class:  'close tool-button'
            noMove: true
            parent: this
            child:  
                type: 'icon'
                icon: 'octicon-x'
            action: @close

    addShadeButton: =>
        knix.create
            type:   'button'
            class:  'shade tool-button'
            noMove: true
            parent: this
            child:  
                type: 'icon'
                icon: 'octicon-dash'
            action: @shade

    headerSize: (box="border-box-height") =>
        children = Selector.findChildElements(@elem, [ '*.title', '*.close', '*.shade' ])
        i = 0
        while i < children.length
            height = children[i].getLayout().get(box)
            return height if height
            i++
        0

    ###
     0000000  000  0000000  00000000
    000       000     000   000     
    0000000   000    000    0000000 
         000  000   000     000     
    0000000   000  0000000  00000000
    ###

    addMovement: =>
        if @config.resize or not @config.noMove
            @elem.on 'mousemove', @onHover
            @elem.on 'mouseleave', @onLeave
        else
            super

    onHover: (event, e) =>

        if @sizeMoveDrag?
            if @sizeMoveDrag.dragging then return
            @sizeMoveDrag.deactivate() 
            delete @sizeMoveDrag

        if e?.getWidget?()?
            m = @matchConfigValue 'noMove', true, e.getWidget().upWidgets()
            @elem.style.cursor = 'default'
            if m.length
                return
        
        # log 'hover', e.id
        
        eventPos = Stage.absPos event
        d1 = eventPos.minus @absPos()
        d2 = @absPos().plus(@sizePos()).minus eventPos

        md = 10
        action = 'move'
        border = ''
        if not @config.resize? or not (@config.resize == false)
            if d1.y < md
                action = 'size' if not (@config.resize == 'horizontal')
                border = 'top'
            else if d2.y < md
                action = 'size' if not (@config.resize == 'horizontal')
                border = 'bottom'
            if d1.x < md
                action = 'size' if not (@config.resize == 'vertical')
                border+= 'left'
            if d2.x < md
                action = 'size' if not (@config.resize == 'vertical')
                border+= 'right'

        if action == 'size' and not @config.isShaded

            if border == 'left' or border == 'right'
                cursor = 'ew-resize'
            else if border == 'top' or border == 'bottom'
                cursor = 'ns-resize'
            else if border == 'topleft' or border == 'bottomright'
                cursor = 'nwse-resize'
            else
                cursor = 'nesw-resize'

            @sizeMoveDrag = new Drag
                target:  @elem
                onStart: @sizeStart
                onMove:  @sizeMove
                doMove:  false
                cursor:  cursor

            @sizeMoveDrag.border = border
        else
            @sizeMoveDrag = new Drag
                target: @elem
                minPos: pos undefined, 0
                onMove: @dragMove
                cursor: 'grab'
        return

    dragMove: (drag) =>
        @emitMove()
        if @elem.hasClassName 'selected'
            for w in knix.selectedWindows()
                if w != @
                    w.move drag.delta

    onLeave: (event) =>
        if @sizeMoveDrag? and not @sizeMoveDrag.dragging
            @sizeMoveDrag.deactivate() if @sizeMoveDrag
            delete @sizeMoveDrag

    sizeStart: (drag, event) =>
        @config.isMaximized = false

    sizeMove: (drag, event) =>

        wpos = @absPos()
        spos = Stage.absPos(event)

        hdr = @headerSize()

        if drag.border in ['left', 'topleft', 'top']
            wdt = wpos.x - spos.x + @getWidth()
            hgt = wpos.y - spos.y + @getHeight()
            br  = wpos.plus(pos(@getWidth(), @getHeight()))
        else
            wdt = spos.x - wpos.x
            hgt = spos.y - wpos.y

        wdt = Math.max(hdr*2, wdt)
        wdt = Math.min(@maxWidth(), wdt)
        wdt = Math.max(@minWidth(), wdt)

        hgt = Math.max(hdr, hgt)
        hgt = Math.min(@maxHeight(), hgt)
        hgt = Math.max(@minHeight(), hgt)

        hgt = null if drag.border == 'left' or drag.border == 'right'
        wdt = null if drag.border == 'top' or drag.border == 'bottom'

        @resize wdt, hgt

        if drag.border in ['left', 'topleft', 'top']
            if not wdt? then dx = 0 else dx = br.x-@getWidth()-wpos.x
            if not hgt? then dy = 0 else dy = br.y-@getHeight()-wpos.y
            @moveBy dx, dy

    maximize: =>
        if @config.isMaximized
            @setPos @config.pos
            @setSize @config.size
            @config.isMaximized = false
        else
            @config.pos  = @absPos()
            @config.size = @getSize()
            menuHeight   = $('menu').getHeight()
            @moveTo 0, menuHeight+2
            @resize Stage.size().width, Stage.size().height-menuHeight-2
            @config.isMaximized = true

    ###
    000       0000000   000   000   0000000   000   000  000000000
    000      000   000   000 000   000   000  000   000     000   
    000      000000000    00000    000   000  000   000     000   
    000      000   000     000     000   000  000   000     000   
    0000000  000   000     000      0000000    0000000      000   
    ###

    stretchWidth: => @

    sizeWindow: =>
        if @config.content == 'scroll'
            @content.setWidth  @contentWidth()
            @content.setHeight @contentHeight()

        for w in @allChildren()
            w.onWindowSize?()

    layoutChildren: =>
        e = @config.content? and $(@config.content) or @elem
        if not @config.width?
            if e.widget.config.resize?
                if e.widget.config.resize == 'horizontal' or e.widget.config.resize == true
                    e.widget.stretchWidth()
            else
                @setWidth e.getWidth()
        if not @config.height?
            @setHeight e.getHeight()
        if @config.resize
            e.style.minWidth  = "%dpx".fmt(e.getWidth()) if not @config.minWidth?
            e.style.minHeight = "%dpx".fmt(e.getHeight()) if not @config.minHeight?
            if @config.resize == 'horizontal'
                e.style.maxHeight = "%dpx".fmt(e.getHeight()) if not @config.maxHeight?
            if @config.resize == 'vertical'
                e.style.maxWidth = "%dpx".fmt(e.getWidth()) if not @config.maxWidth?

    ###
    00     00  000   0000000   0000000
    000   000  000  000       000     
    000000000  000  0000000   000     
    000 0 000  000       000  000     
    000   000  000  0000000    0000000
    ###
    
    isWindow: => true

    raise: (event) =>
        e = @scrollElem? and @scrollElem or @content.elem
        scrollx = e.scrollLeft
        scrolly = e.scrollTop
        @elem.parentElement.appendChild @elem
        e.scrollLeft = scrollx
        e.scrollTop = scrolly
        event?.stopPropagation()

    popup: (event) =>
        log 'popup', Stage.absPos event
        if @elem?
            @elem.show()
            @setPos Stage.absPos event
            @elem.raise()
        else
            warning 'no elem!'

    scrollToBottom: => @content.elem.scrollTop = @content.elem.scrollHeight
    scrollToTop:    => @content.elem.scrollTop = 0

    contentWidth:  => @elem.getLayout().get('padding-box-width')
    contentHeight: => @elem.getLayout().get('padding-box-height') - @headerSize()

    shade: =>
        if @config.isShaded
            @config.isShaded = false
            @content.show()
            @setHeightNoEmit @config.height
            @elem.setStyle({'min-height': @minHeightShade})
        else
            @config.height = @getHeight()
            @minHeightShade = @elem.getStyle('min-height')
            @elem.setStyle({'min-height': '0px'})
            @setHeightNoEmit @headerSize()
            @config.isShaded = true
            @content.hide()

        @emit 'shade',
            shaded: @config.isShaded

        return

    del: => @close()
    close: =>
        if @config.popup?
            knix.delPopup @
        super

    @menuButton: (cfg) =>

        Menu.addButton _.def cfg,
            menu: 'audio'

module.exports = Window
