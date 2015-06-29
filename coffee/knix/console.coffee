###
 0000000   0000000   000   000   0000000   0000000   000      00000000
000       000   000  0000  000  000       000   000  000      000     
000       000   000  000 0 000  0000000   000   000  000      0000000 
000       000   000  000  0000       000  000   000  000      000     
 0000000   0000000   000   000  0000000    0000000   0000000  00000000
###

Window   = require './window'
Settings = require './settings'
Stage    = require './stage'
tools    = require './tools'
str      = require './str'
def      = require './def'
win      = tools.win
wid      = tools.wid

class Console extends Window

    @scopeTags = []
        
    init: (cfg, defs) =>

        cfg = def cfg, defs
        
        @logTags = Settings.get 'logTags', {}

        cfg = def cfg,
            x:       0
            y:       0
            width:   500
            height:  500

        super cfg,
            title       : 'console'
            class       : 'console-window'
            content     : 'scroll'
            showMethods : Settings.get 'logMethods', true
            showClasses : Settings.get 'logClasses', false
            buttons     : \
            [
                action  : @maximize
                icon    : 'octicon-diff-added'
            ,
                action  : @scrollToTop
                icon    : 'fa-arrow-circle-o-up'
            ,
                action  : @scrollToBottom
                icon    : 'fa-arrow-circle-o-down'
            ,
                align   : 'right'
                action  : @clear
                keys    : ['⌥˚', '˚']
                icon    : 'fa-trash-o'
            ]
            child:
                class  : 'console'
                text   : '<span class="tiny-text" style="vertical-align:top">password-turtle version '+knix.version+'</span>'
                noMove : true

        @elem.addEventListener 'contextmenu', @onContextMenu
        @

    ###
    00     00  00000000  000   000  000   000
    000   000  000       0000  000  000   000
    000000000  0000000   000 0 000  000   000
    000 0 000  000       000  0000  000   000
    000   000  00000000  000   000   0000000 
    ###
    
    onContextMenu: (event) =>

        children = []
        for tag of @logTags
            if not tag.startsWith('@') and not tag.startsWith('.')
                children.push
                    type    : 'toggle'
                    text    : tag
                    states  : ['on', 'unset', 'off']
                    icons   : ['octicon-check', 'octicon-dash', 'octicon-x']
                    state   : @logTags[tag]
                    onState : @onTagState

        children.push
            type   : 'button'
            text   : 'ok'
            action : -> win().close()

        knix.get
            hasClose : true
            hasMaxi  : false
            title    : ' '
            resize   : false
            hasShade : false
            popup    : true
            pos      : Stage.absPos(event)
            console  : @
            children : children
            buttons  : \
            [
                icon    : 'octicon-check'
                action  : ->
                    for t in win().elem.select('.toggle')
                        t.widget.setState('on')
            ,
                icon    : 'octicon-dash'
                action  : ->
                    for t in win().elem.select('.toggle')
                        t.widget.setState('unset')
            ,
                icon    : 'octicon-x'
                action  : ->
                    for t in win().elem.select('.toggle')
                        t.widget.setState('off')
            ,
                action  : @trashSettings
                align   : 'right'
                icon    : 'fa-trash-o'
            ,
                action  : @toggleMethods
                align   : 'right'
                icon    : 'octicon-list-unordered'
            ,
                action  : @toggleClasses
                align   : 'right'
                icon    : 'octicon-three-bars'
            ]

        event.preventDefault()
        event.stop()

    ###
    000       0000000    0000000 
    000      000   000  000      
    000      000   000  000  0000
    000      000   000  000   000
    0000000   0000000    0000000 
    ###

    trashSettings: =>
        Settings.set 'logTags', {}
        Settings.set 'logMethods', undefined
        Settings.set 'logClasses', undefined

    onTagState: (event) =>
        tag = wid().config.text
        @logTags[tag] = event.detail.state
        Settings.set 'logTags', @logTags
        @updateTags()

    insert: (s) =>
        @getChild('console').elem.insert s
        @scrollToBottom()

    logInfo: (info,url,s) =>
        @addLogTag info.class
        if info.class? and info.type? and info.method?
            infoStr = info.class + info.type + info.method
        else
            infoStr = ''
        tags = [info.class].concat(Console.scopeTags)
        styles = ("log_"+t.replace(/[\/@]/g, '_') for t in tags when t?).join(' ')
        @insert '<pre class="'+styles+'">'+
            '<a onClick=\''+url+'\' class="console-link" title="'+infoStr+' '+tags.join(' ')+'">'+
            '<span class="console-class" '+      (not @config.showClasses and 'style="display:none;"' or '')+'>'+ (info.class? and info.class or '')+   '</span>'+
            '<span class="console-method-type" '+(not @config.showMethods and 'style="display:none;"' or '')+'>'+ (info.type? and info.type or '')+     '</span>'+
            '<span class="console-method" '+     (not @config.showMethods and 'style="display:none;"' or '')+'>'+ (info.method? and info.method or '')+ '</span>'+
            '<span class="octicon octicon-playback-play"></span>'+
            '</a> '+s+
            '</pre>'
        @updateTags()

    updateTags: () =>
        tagElems = @elem.select('pre')
        # enabledTags = ( t for t,v of @logTags when v == true or v == 'on' )
        for tagElem in tagElems
            show = -1
            for tag, v of @logTags
                tclass = 'log_'+tag.replace(/[\/@]/g, '_')  # replace / and @ with _
                if tclass in tagElem.classList
                    if v == 'off'
                        show = 0
                    else if v == 'on' and show != 0
                        show = 1
            
            tagElem.style.display = (show == 0 and 'none' or '')
            
    addLogTag: (tag) => @logTags[tag] = 'unset' if not @logTags[tag]?

    toggleClasses: =>
        @config.showClasses = not @config.showClasses
        Settings.set 'logClasses', @config.showClasses
        for t in @elem.select('.console-class')
            if @config.showClasses then t.show() else t.hide()

    toggleMethods: =>
        @config.showMethods = not @config.showMethods
        Settings.set 'logMethods', @config.showMethods
        for t in @elem.select('.console-method', '.console-method-type')
            if @config.showMethods then t.show() else t.hide()

    clear: => @getChild('console').clear()
        
    ###
     0000000  000000000   0000000   000000000  000   0000000
    000          000     000   000     000     000  000     
    0000000      000     000000000     000     000  000     
         000     000     000   000     000     000  000     
    0000000      000     000   000     000     000   0000000
    ###

    @setScopeTags: =>
        @scopeTags = Array.prototype.slice.call(arguments, 0)
        for t in @scopeTags
            @allConsoles().each (c) -> c.addLogTag(t)

    @logInfo: (info) =>
        args = Array.prototype.slice.call arguments, 1

        if 'error' in @scopeTags
            s = '<span class="console-error">%s</span> '.fmt(str(args[0])) + @toHtml.apply(Console, args.slice(1))
        else if 'warning' in @scopeTags
            s = '<span class="console-warning">%s</span> '.fmt(str(args[0])) + @toHtml.apply(Console, args.slice(1))
        else
            s = @toHtml.apply(Console, args)

        if info?.file? and info?.line?
            url = '::.info.json:source-url::'.fmt info.file, info.line
            info.file = info.file.slice 9, -7 # remove 'coffee/' prefix and '.coffee' suffix

        @allConsoles().each (c) -> c.logInfo info, url, s
        @scopeTags = []

    @allConsoles: => (e.getWindow() for e in $$(".console"))

    @log: => @allConsoles().each (c) ->
        c.insert Console.toHtml.apply(Console, Array.prototype.slice.call(arguments, 0))

    @toHtml: =>

        html = (str(arg) for arg in arguments).join(" ")
        html.replace(/([\'\"])(\w+)([\'\"]:)/g, '<span class="console-quote">$1</span><span class="console-string">$2</span><span class="console-quote">$3</span>')
            .replace(/([:\s\"\.])([-]?[\d]+)(?=[,\.]|px)?/g, '$1<span class="console-number">$2</span>')
            .replace(/([:,\.\{\}\(\)\[\]]+|px)/g, '<span class="console-punct">$1</span>')
            .replace(/->/g, '<span class="octicon octicon-arrow-small-right"></span>')

    @tag: Console.setScopeTags

module.exports = Console
