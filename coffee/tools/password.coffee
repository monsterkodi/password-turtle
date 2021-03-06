###
00000000    0000000    0000000   0000000  000   000   0000000   00000000   0000000  
000   000  000   000  000       000       000 0 000  000   000  000   000  000   000
00000000   000000000  0000000   0000000   000000000  000   000  0000000    000   000
000        000   000       000       000  000   000  000   000  000   000  000   000
000        000   000  0000000   0000000   00     00   0000000   000   000  0000000  
###

{ _ } = require 'kxk'

charsets = [
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVXYZ'
    '0123456789'
    '-'
    '.'
    '+=<>~'
    '!|@#$%^&*(){}[];:?,/_\'\"\`\\'
    ]

setWithChar = (char) ->
    for set in charsets
        if _.indexOf(set, char) >= 0
            return set
            
isValidPattern = (pattern) ->
    for c in pattern
        return false if not setWithChar(c)?
    true

make = (hash, pattern) ->
    pw = ""
    ss = Math.floor(hash.length / pattern.length)
    for i in [0...pattern.length]        
        sum = 0
        for s in [0...ss]
            sum += parseInt(hash[i*ss+s], 16)
        sum += pattern.charCodeAt i
        cs  = setWithChar pattern[i]
        pw += cs[sum%cs.length]
    pw
    
module.exports = 
    make:           make
    isValidPattern: isValidPattern
