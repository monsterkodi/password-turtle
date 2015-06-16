###
 0000000  00000000   000  000   000  000   000  00000000  00000000 
000       000   000  000  0000  000  0000  000  000       000   000
0000000   00000000   000  000 0 000  000 0 000  0000000   0000000  
     000  000        000  000  0000  000  0000  000       000   000
0000000   000        000  000   000  000   000  00000000  000   000
###

Spin = require './spin'
def  = require './def'

class Spinner extends Spin
    
    init: (cfg, defs) =>

        cfg = _.def cfg, defs

        super cfg,
            tooltip   : false
            valueStep : 1
            minValue  : 0
            maxValue  : cfg.values.length-1

        new Drag
            cursor    : 'ew-resize'
            target    : @getChild('spin-content').elem
            doMove    : false
            onMove    : @sliderFunc
            onStart   : @sliderFunc

        delete @input
        @
        
    sliderFunc: (drag, event) =>
        oldValue = @config.value
        pos      = @getChild('spin-content').absPos()
        width    = event.clientX-pos.x
        v        = @size2value width
        
        d = v - @range()/2
        i = @range()/2 + d * @config.valueStep  * @steps() / @range()
        i = @clamp @round(i)

        @setValue @config.values[i]
        if oldValue != @config.value
            @emit 'valueInput', value: @config.value

    setValue: (a) =>
        v = _.arg a
        i = @config.values.indexOf v
        c = @getChild 'spin-content'
        c.clear()
        w = Math.max(3, c.getWidth()/@steps())
        offset = i * @getChild('spin-content').getWidth() / @config.values.length
        c.elem.insert '<div class="spinner-knob" style="width:%dpx; left:%dpx"/>'.fmt(w, offset)
        @config.value = @config.values[i]
        c.elem.insert String @config.value
        @emitValue @config.value

    index: => @config.values.indexOf @config.value

    incr: (d=1) =>
        oldValue = @config.value
        if d in ['+', '++'] then d = 1
        else if d in ['-', '--'] then d = -1
        i = @clamp(@index() + d)
        @setValue @config.values[i]
        if oldValue != @config.value
            @emit 'valueInput', @config.value

    size2value: (s) => @config.minValue + @range() * s / @getChild('spin-content').getWidth()

module.exports = Spinner