###
000   000  000   000  000  000   000
000  000   0000  000  000   000 000 
0000000    000 0 000  000    00000  
000  000   000  0000  000   000 000 
000   000  000   000  000  000   000
###

capitalize  = require 'lodash.capitalize'
isEmpty     = require 'lodash.isempty'
StyleSwitch = require './styleswitch'
About       = require './about'
Console     = require './console'
Widget      = require './widget'
Stage       = require './stage'
Menu        = require './menu'
tools       = require './tools'
str         = require './str'
log         = require './log'
dbg         = require './log'
def         = require './def'

class knix

    @version = '::package.json:version::'

    @init: (config) =>

        if config.console?
            c = new Console()
            c.shade() if config.console == 'shade'

        StyleSwitch.init()
                
        @initMenu()
        @initAnim()
        @initTools()
        Stage.init()
    
        c?.raise()
        c?.maximize() if config.console == 'maximized'
                
        @
    
    ###
    00     00  00000000  000   000  000   000   0000000
    000   000  000       0000  000  000   000  000     
    000000000  0000000   000 0 000  000   000  0000000 
    000 0 000  000       000  0000  000   000       000
    000   000  00000000  000   000   0000000   0000000 
    ###
        
    @initMenu: =>
        
        mainMenu = new Menu
            id:     'menu'
            parent: 'stage'
            style:  
                top: '0px'
            
        toolMenu = new Menu
            id:     'tool'
            parent: 'stage'
            style:  
                top:   '0px'
                right: '0px'
        
    @initTools: =>

        btn = 
            menu: 'tool'

        Menu.addButton btn,
            tooltip: 'console'
            icon:    'octicon-terminal'
            action:  -> new Console()

        Menu.addButton btn,
            tooltip: 'style'
            keys:    ['i']
            icon:    'octicon-color-mode'
            action:  StyleSwitch.toggle

        Menu.addButton btn,
            tooltip: 'about'
            icon:    'octicon-info'
            action:  About.show

        Menu.addButton btn,
            tooltip: 'shade all'
            icon:    'octicon-dash'
            action:  knix.shadeWindows

        Menu.addButton btn,
            tooltip: 'close windows'
            icon:    'octicon-x'
            keys:    ['⇧⌥„']
            action:  knix.closeAllWindows            

    ###
     0000000  00000000   00000000   0000000   000000000  00000000
    000       000   000  000       000   000     000     000     
    000       0000000    0000000   000000000     000     0000000 
    000       000   000  000       000   000     000     000     
     0000000  000   000  00000000  000   000     000     00000000
    ###

    @create: (cfg, defs) =>

        cfg = def cfg, defs
        # dbg cfg
        if cfg.type? 
            try
                cls = require './'+cfg.type
                # dbg cls
                return new cls cfg
            catch err
                # log cfg.type, err
                0

        # log 'plain'
        new Widget cfg, { type: 'widget' }

    # ________________________________________________________________________________ get

    # shortcut to call @create with default type window and stage_content as parent

    @get: (cfg, defs) =>
        cfg = def cfg, defs
        w = @create def cfg,
            type:   'window'
            parent: 'stage_content'
        Stage.positionWindow(w) if w.isWindow?()
        w
        
    ###
    000   000  000  000   000  0000000     0000000   000   000   0000000
    000 0 000  000  0000  000  000   000  000   000  000 0 000  000     
    000000000  000  000 0 000  000   000  000   000  000000000  0000000 
    000   000  000  000  0000  000   000  000   000  000   000       000
    00     00  000  000   000  0000000     0000000   00     00  0000000 
    ###

    @isSelectableWindow:   (w) => not w.hasClassName('tooltip')
    @allWindows:           => w.widget for w in $$('.window') when @isSelectableWindow(w)
    @selectedWindows:      => w.widget for w in $$('.window.selected') when @isSelectableWindow(w)
    @selectedOrAllWindows: => 
        w = @selectedWindows()
        w = @allWindows() if isEmpty w
        w
    @selectedWidgets:  => w.widget for w in $$('.selected') when @isSelectableWindow(w)
    @delSelection:     => @selectedWidgets().each (w) -> w.del?() unless w?.isWindow?()
    @deselectAll:      => @selectedWidgets().each (w) -> w.elem.removeClassName 'selected'
    @selectAll:        => @allWindows().each (w) -> w.elem.addClassName 'selected'

    @shadeWindows:    => @selectedOrAllWindows().each (w) -> w.shade()
    @closeWindows:    => @selectedWindows().each (w) -> w.close()
    @closeAllWindows: => @allWindows().each (w) -> w.close()
                    
    ###
    000000000   0000000    0000000   000      000000000  000  00000000    0000000
       000     000   000  000   000  000         000     000  000   000  000     
       000     000   000  000   000  000         000     000  00000000   0000000 
       000     000   000  000   000  000         000     000  000             000
       000      0000000    0000000   0000000     000     000  000        0000000 
    ###

    @addPopup: (p) =>
        @popups = [] if not @popups?
        @popups.push p
        if not @popupHandler?
            @popupHandler = document.addEventListener 'mousedown', @closePopups
            
    @delPopup: (p) =>
        @popups = @popups.without p

    @closePopups: (event) =>
        e = event?.target
        if @popups?
            for p in @popups
                p.close() for p in @popups when e not in p.elem.descendants()
        if @popupHandler?
            @popupHandler.stop()
            delete @popupHandler
                        
    ###
     0000000   000   000  000  00     00   0000000   000000000  000   0000000   000   000
    000   000  0000  000  000  000   000  000   000     000     000  000   000  0000  000
    000000000  000 0 000  000  000000000  000000000     000     000  000   000  000 0 000
    000   000  000  0000  000  000 0 000  000   000     000     000  000   000  000  0000
    000   000  000   000  000  000   000  000   000     000     000   0000000   000   000
    ###

    @initAnim: => 
        @animTimeStamp = 0
        window.requestAnimationFrame @anim

    @animObjects = []
    @animate: (o) => @animObjects.push o
    @deanimate: (o) => 
        # log @animObjects.length
        tools.del @animObjects, o
        # log @animObjects.length
    
    @anim: (timestamp) =>
        step = 
            stamp: timestamp 
            delta: timestamp-@animTimeStamp
            dsecs: (timestamp-@animTimeStamp)*0.001
        for animObject in @animObjects
            animObject?.anim? step
        @animTimeStamp = timestamp
        window.requestAnimationFrame @anim

module.exports = knix
