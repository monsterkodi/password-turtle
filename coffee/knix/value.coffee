###
000   000   0000000   000      000   000  00000000
000   000  000   000  000      000   000  000     
 000 000   000000000  000      000   000  0000000 
   000     000   000  000      000   000  000     
    0      000   000  0000000   0000000   00000000
###

Widget = require './widget'
def    = require './def'

class Value extends Widget

    init: (cfg, def) => 
        
        cfg = _.def cfg, def
        
        super cfg,
            value    : 0
            minValue : -Number.MAX_VALUE/2
            maxValue : +Number.MAX_VALUE/2
            noMove   : true

    initEvents: =>
        if @config.onValue?
            if _.isString @config.onValue
                win = @getWindow()
                @elem.on "onValue", win[@config.onValue]
            else
                @elem.on "onValue", @config.onValue  
        super

    setValue: (v) =>
        oldValue = @config.value
        v = @clamp _.value v
        if v != oldValue
            @config.value = v
            @emitValue v
        @

    incr: (d=1) =>
        if d in ['+', '++'] then d = 1
        else if d in ['-', '--'] then d = -1
        step = @config.valueStep and @config.valueStep or 1
        @setValue @round(@config.value + step*d)

    decr: => @incr -1

    ###
    000000000   0000000    0000000   000       0000000
       000     000   000  000   000  000      000     
       000     000   000  000   000  000      0000000 
       000     000   000  000   000  000           000
       000      0000000    0000000   0000000  0000000 
    ###

    percentage: (v) => # returns the percentage of value v in the [minValue,maxValue] range
        pct = 100 * (v - @config.minValue) / @range()
        Math.max(0,Math.min(pct,100))

    size2value: (s) => # returns the value in the [minValue,maxValue] range that lies at point s
        @config.minValue + @range() * s / @innerWidth()

    range: => @config.maxValue - @config.minValue
    steps: => 1 + @range() / @config.valueStep
    clamp: (v) => _.clamp @config.minValue, @config.maxValue, v
    round: (v) => # rounds v to multiples of valueStep
        if @config.valueStep
            d = - v + Math.round(v/@config.valueStep)*@config.valueStep
            v += d
        v

module.exports = Value