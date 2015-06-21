keycode   = require 'keycode'

keyname = (event) ->
    key = keycode event
    if event.metaKey and key != 'command' then key = 'command-' + key
    if event.altKey  and key != 'alt'     then key = 'alt-'     + key
    if event.ctrlKey and key != 'ctrl'    then key = 'ctrl-'    + key
    key

module.exports = keyname
