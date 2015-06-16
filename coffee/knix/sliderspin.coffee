###
 0000000  000      000  0000000    00000000  00000000    0000000  00000000   000  000   000
000       000      000  000   000  000       000   000  000       000   000  000  0000  000
0000000   000      000  000   000  0000000   0000000    0000000   00000000   000  000 0 000
     000  000      000  000   000  000       000   000       000  000        000  000  0000
0000000   0000000  000  0000000    00000000  000   000  0000000   000        000  000   000
###

Hbox = require './hbox'
def  = require './def'

class Sliderspin extends Hbox
    
    init: (cfg, defs) =>

        cfg = def cfg, defs
        
        children = []
        if cfg.hasInput != false
            children.push
                type : 'connector'
                slot : cfg.class+':setValue'

        children.push
            type      : 'slider'
            value     : cfg.value
            minValue  : cfg.minValue
            maxValue  : cfg.maxValue
            valueStep : cfg.sliderStep
            hasKnob   : cfg.sliderKnob
            style     :
                width : '90%'
                
        children.push
            type      : 'spin'
            value     : cfg.value
            recKey    : cfg.recKey
            minValue  : cfg.minValue
            maxValue  : cfg.maxValue
            valueStep : cfg.spinStep
            minWidth  : 100
            format    : cfg.spinFormat or "%3.2f"
            style     :
                width : '10%'

        if cfg.hasOutput != false
            children.push
                type   : 'connector'
                signal : cfg.class+':onValue'

        super cfg, children : children

        @connect 'slider:onValue', 'spin:setValue'
        @connect 'spin:onValue', 'slider:setValue'
        @connect 'spin:onValue', @onSpinValue
        @

    onSpinValue: (v) => @emitValue _.value v
    
    setValue: (v) =>
        @config.value = _.value v
        @getChild('slider').setValue @config.value
        
module.exports = Sliderspin