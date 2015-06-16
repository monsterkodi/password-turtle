###
00000000    0000000   000   000   0000000   00000000
000   000  000   000  0000  000  000        000     
0000000    000000000  000 0 000  000  0000  0000000 
000   000  000   000  000  0000  000   000  000     
000   000  000   000  000   000   0000000   00000000
###

Window = require './window'
def    = require './def'

class Range extends Window

    init: (cfg, defs) =>
    
        cfg = def cfg, defs

        cfg = def cfg,
            low         : 0.0
            minLow      : -10000
            maxLow      : 10000
            lowStep     : 0.1
            high        : 1.0
            width       : 300
            minWidth    : 240
            minHigh     : -10000
            maxHigh     : 10000
            highStep    : 0.1
            valueFormat : "%1.3f"
            resize      : 'horizontal'

        super cfg,
            type     : 'range'
            title    : 'range'
            children : \
            [
                type     : 'sliderspin'
                class    : 'range_low'
                recKey   : 'low'
                tooltip  : 'minimum' 
                value    : cfg.low
                minValue : cfg.minLow
                maxValue : cfg.maxLow
                spinStep : cfg.lowStep
            ,
                type     : 'sliderspin'
                class    : 'range_high'
                tooltip  : 'maximum' 
                recKey   : 'high'
                value    : cfg.high
                minValue : cfg.minHigh
                maxValue : cfg.maxHigh
                spinStep : cfg.highStep
            ,
                type     : 'hbox'
                children : \
                [
                    type      : 'connector'
                    slot      : 'range_in:setValue'
                ,
                    type      : 'spin'
                    class     : 'range_in'
                    tooltip   : 'input'
                    valueStep : 0.001
                    minWidth  : 100
                    maxWidth  : 10000
                    format    : cfg.valueFormat
                    style     :
                        width : '50%'
                ,
                    type      : 'spin'
                    class     : 'range_out'
                    tooltip   : 'output'
                    valueStep : 0.001
                    minWidth  : 100
                    maxWidth  : 10000
                    format    : cfg.valueFormat
                    style     :
                        width : '50%'
                ,
                    type      : 'connector'
                    signal    : 'range_out:onValue'
                ]
            ]
            
        @connect 'range_in:onValue',   @setValue
        @connect 'range_low:onValue',  @setLow
        @connect 'range_high:onValue', @setHigh
        @
    
    paramValuesAtConnector: (paramValues, connector) =>
        if connector.config.slot == 'range_in:setValue'
            paramValues.offset = @config.low
            paramValues.range  = @config.high - @config.low
            Audio.sendParamValuesFromConnector paramValues, @connector "range_out:onValue"
            
    setHigh: (v) => 
        @config.high = Math.max(@config.low, _.value v)
        @getChild('range_high').setValue Math.max(@config.low, @config.high)
        
    setLow: (v) => 
        @config.low = _.value v
        @getChild('range_low').setValue Math.min(@config.low, @config.high)
        
    range: => @config.high - @config.low
    
    setValue: (v) =>
        @config.value = @config.low + _.clamp(0.0, 1.0, _.value(v)) * @range()
        @getChild('range_out').setValue @config.value

    @menu: =>

        @menuButton
            text    : 'range'
            icon    : 'fa-sliders'
            action  : -> new Range
                            center: true
module.exports = Range