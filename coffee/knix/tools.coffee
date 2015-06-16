###
000000000   0000000    0000000   000       0000000
   000     000   000  000   000  000      000     
   000     000   000  000   000  000      0000000 
   000     000   000  000   000  000           000
   000      0000000    0000000   0000000  0000000 
###

zipObject = require 'lodash.zipobject'
remove    = require 'lodash.remove'

Element.addMethods 
    raise: (element) ->
        if not (element = $(element))
            return
        element.parentElement.appendChild element
        return
    getWidget: (element) ->
        return element.widget if element?.widget?
        return element?.parentElement?.getWidget()

SVGAnimatedLength.prototype._str = -> "<%0.2f>".fmt @baseVal.value

clamp = (r1, r2, v) ->
    if r1 > r2
        [r1,r2] = [r2,r1]
    v = Math.max(v, r1) if r1?
    v = Math.min(v, r2) if r2?
    v

round = (value, stepSize=1) -> Math.round(value/stepSize)*stepSize
floor = (value, stepSize=1) -> Math.floor(value/stepSize)*stepSize

arg = (arg, argname='') ->
    arg = arg.caller.arguments[0] if not arg?
    if typeof arg == 'object'
        if arg.detail?
            if arg.detail[argname]?
                return arg.detail[argname]
            return arg.detail
            
    if argname == 'value'
        if typeof arg == 'string'
            return parseFloat arg
    arg

value = (arg) -> arg arg, 'value'
win   =       -> win.caller.arguments[0].target.getWidget().getWindow()
wid   =       -> wid.caller.arguments[0].target.getWidget()
del   = (l,e) -> remove l, (n) -> n == e

exp = 
    [
        'clamp', 'round', 'floor', 'arg', 'value', 'win', 'wid', 'del'
    ]
module.exports = zipObject(exp.map((e) -> [e, eval(e)]))
