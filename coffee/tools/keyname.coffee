keycode = require 'keycode'

modifierNames = ['shift', 'ctrl', 'alt', 'command']

keyname = (eventOrQuestion) ->
    if arguments.length > 1
        switch eventOrQuestion
            when 'isModifier?'
                return arguments[1] in modifierNames
        return false
    event = eventOrQuestion
    key = keycode event
    if key not in modifierNames
        if event.metaKey  then key = 'command+' + key
        if event.altKey   then key = 'alt+'     + key
        if event.ctrlKey  then key = 'ctrl+'    + key
        if event.shiftKey then key = 'shift+'   + key
    else
        key = ""
    key

module.exports = keyname
