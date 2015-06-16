###
 0000000  00000000   000  000   000
000       000   000  000  0000  000
0000000   00000000   000  000 0 000
     000  000        000  000  0000
0000000   000        000  000   000
###

Value = require './value'
def   = require './def'

class Spin extends Value
    
    init: (cfg, defs) =>

        cfg = def cfg, defs
        
        super cfg,
            type       : 'spin'
            horizontal : true
            child      :
                elem   : 'table'
                type   : 'spin-table'
                child  :
                    elem     : 'tr'
                    type     : 'spin-row'
                    children : \
                    [
                        class : 'decr spin-td'
                        elem  : 'td'
                        keys  : []
                        child :
                            type  : 'icon'
                            icon  : 'octicon-triangle-left'
                            style :
                                position: 'relative'
                                top: '-1px'
                    ,
                        class : 'spin-content'
                        elem  : 'td'
                        children : \
                        [
                            type  : 'input'
                            class : 'spin-input'
                        ,
                            type  : 'spin-knob'
                        ]
                    ,
                        class : 'incr spin-td'
                        elem  : 'td'
                        keys  : []
                        child :
                            type  : 'icon'
                            icon  : 'octicon-triangle-right'
                            style :
                                position: 'relative'
                                top: '-1px'
                    ]

        @connect 'decr:mousedown', @startDecr
        @connect 'decr:mouseup',   @stopTimer
        
        @connect 'incr:mousedown', @startIncr
        @connect 'incr:mouseup',   @stopTimer

        @connect 'input:mousedown', @onInputDown
        @connect 'input:click', @onInputDown

        if not @config.valueStep?
            @config.valueStep = @range() > 1 and 1 or @range()/100

        @elem.on 'keypress', @onKey

        @input = @getChild('spin-input').elem

        @input.addEventListener 'change', @onInputChange

        @input.value = @config.value
        @setValue @config.value
        @

    ###
    000   000  00000000  000   000
    000  000   000        000 000 
    0000000    0000000     00000  
    000  000   000          000   
    000   000  00000000     000   
    ###

    onKey: (event, e) =>
        if event.key in ['Esc']
            @setValue @config.value
            return
        if event.key in ['Up', 'Down']
            @setValue @input.value
            @incr event.key == 'Up' and '+' or '-'
            event.stop()
            return 
        if event.key in ['Left', 'Right', ' ', 'Tab']
            if event.key == ' '
                Keys.onKey event
                event.stop()
            else if event.key == 'Left'
                @config.knobIndex += 1
            else if event.key == 'Right'
                @config.knobIndex -= 1
            @onInputChange()
            @updateKnob()
            return
        if event.key not in '0123456789-.'
            if event.key.length == 1
                Keys.onKey event
                event.stop()
                return
        if event.key in '-.'
            if @input.value.indexOf(event.key) > -1
                s = @input.value.slice @input.selectionStart, @input.selectionEnd
                if s.indexOf(event.key) < 0
                    Keys.onKey event
                    event.stop()
                    return

    onInputChange: => 
        oldValue = @config.value
        @setValue @input.value
        if @config.value != oldValue
            @emit 'valueInput', value: @config.value

    onInputDown: (event) => 
        @config.knobIndex = -(@input.selectionStart-@input.value.length+1)
        @updateKnob()
        event.stopPropagation()

    setValue: (a) =>
        super _.value a
        [start, end] = [@input.selectionStart, @input.selectionEnd]
        @input.value = @format(@config.value) if @input?
        if not @config.knobIndex?
            @config.knobIndex = if @config.maxValue <= 1 then 1 else 3
        @updateKnob()        
        [@input.selectionStart, @input.selectionEnd] = [start, end]
        
    updateKnob: =>
        @config.knobIndex = _.clamp @config.knobIndex, 0, @format(@config.maxValue).length-1
        i = @config.knobIndex
        i = 3 if i == 2
        @getChild('spin-knob').moveTo @getChild('spin-content').getWidth() - ( 8 + i * 7.5 )

    incr: (d=1) =>
        oldValue = @config.value
        valueLength = @input.value.length

        start = @input.value.length - @config.knobIndex - 1
        dotindex = @input.value.indexOf '.'
        if dotindex >= 0 and start >= dotindex
            tempStep = 1.0 / (Math.pow 10, start - dotindex)
        else 
            if dotindex >= 0 
                valueLength = dotindex
            tempStep = Math.pow 10, valueLength - start - 1

        [saveStep, @config.valueStep] = [@config.valueStep, tempStep]
        super 
        @config.valueStep = saveStep
        
        if oldValue != @config.value
            @emit 'valueInput', value: @config.value
            
        @updateKnob()

    startIncr: => @incr(); @timer = setInterval(@incr, Math.max(80, 2000/@steps()))
    startDecr: => @decr(); @timer = setInterval(@decr, Math.max(80, 2000/@steps()))
    stopTimer: => clearInterval @timer

    onWindowSize: => @setValue @config.value

    format: (s) => return @config.format.fmt(s) if @config.format?; String(s)
    strip0: (s) => return s.replace(/(0+)$/,'').replace(/([\.]+)$/,'') if s.indexOf('.') > -1; String(s.strip())
    
module.exports = Spin