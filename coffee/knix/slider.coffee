###
 0000000  000      000  0000000    00000000  00000000 
000       000      000  000   000  000       000   000
0000000   000      000  000   000  0000000   0000000  
     000  000      000  000   000  000       000   000
0000000   0000000  000  0000000    00000000  000   000
###

Value = require './value'
def   = require './def'

class Slider extends Value
    
    init: (cfg, defs) =>

        super cfg,
            type     : 'slider'
            minWidth : 50
            child    :
                type  : 'slider-bar'
                child :
                    type : 'slider-knob'

        if not @config.hasKnob
            @getChild('slider-knob').elem.hide()

        @setBarValue @config.value

        new Drag
            cursor  : 'ew-resize'
            target  : @elem
            doMove  : false
            onMove  : @onDrag
            onStart : @onDrag
        @

    onDrag: (drag) => 
        oldValue = @config.value
        @setValue @size2value drag.pos.x-@absPos().x
        if oldValue != @config.value
            @emit 'valueInput', value: @config.value
        
    onWindowSize: => @setValue @config.value

    valueToPercentOfWidth: (value) => # returns the percentage of value v in the [minValue,maxValue] range
        cfg = @config
        knobWidth = @config.hasKnob and @getChild('slider-knob').getWidth() or 0
        borderWidth = @getChild('slider-bar').getHeight() - @getChild('slider-bar').innerHeight()
        knobMinPercent = 100 * (knobWidth+borderWidth) / Math.max(1, @getWidth())
        barFactor = (value - cfg.minValue) / (cfg.maxValue - cfg.minValue)
        barPercent = knobMinPercent + ( (100-knobMinPercent) * barFactor )
        barPercent

    setValue: (v) =>
        super
        @setBarValue(@config.value)

    setBarValue: (barValue) =>
        pct = @valueToPercentOfWidth(barValue)
        @getChild('slider-bar').elem.style.width = "%.2f%%".fmt pct

module.exports = Slider