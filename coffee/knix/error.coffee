###
00000000  00000000   00000000    0000000   00000000 
000       000   000  000   000  000   000  000   000
0000000   0000000    0000000    000   000  0000000  
000       000   000  000   000  000   000  000   000
00000000  000   000  000   000   0000000   000   000
###

module.exports = () ->
    Console = require './console'
    Console.tag 'error'
    Console.logInfo.apply Console, Array.prototype.slice.call(arguments, 0)
