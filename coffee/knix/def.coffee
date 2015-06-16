###
0000000    00000000  00000000
000   000  000       000     
000   000  0000000   000000  
000   000  000       000     
0000000    00000000  000     
###

defaults  = require 'lodash.defaults'
clone     = require 'lodash.clone'

def = (c,d) ->
    if c?
        defaults(clone(c), d)
    else if d?
        clone(d)
    else
        {}

module.exports = def