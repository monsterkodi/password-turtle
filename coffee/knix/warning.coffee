###
000   000   0000000   00000000   000   000  000  000   000   0000000 
000 0 000  000   000  000   000  0000  000  000  0000  000  000      
000000000  000000000  0000000    000 0 000  000  000 0 000  000  0000
000   000  000   000  000   000  000  0000  000  000  0000  000   000
00     00  000   000  000   000  000   000  000  000   000   0000000 
###

module.exports = () ->
    Console = require './console'
    Console.tag 'warning'
    Console.logInfo.apply Console, Array.prototype.slice.call(arguments, 0)
