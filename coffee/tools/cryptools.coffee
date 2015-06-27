###
 0000000  00000000   000   000  00000000   000000000   0000000    0000000   000       0000000
000       000   000   000 000   000   000     000     000   000  000   000  000      000     
000       0000000      00000    00000000      000     000   000  000   000  000      0000000 
000       000   000     000     000           000     000   000  000   000  000           000
 0000000  000   000     000     000           000      0000000    0000000   0000000  0000000 
###

fs        = require 'fs'
crypto    = require 'crypto'
bcrypt    = require 'bcryptjs'
zipObject = require 'lodash.zipobject'
log       = require '../knix/log'

cipherType   = 'aes-256-cbc'
fileEncoding = encoding:'utf8'

encrypt = (data, key) ->
    cipher = crypto.createCipher cipherType, genHash(key)
    enc =  cipher.update data, 'utf8', 'hex'
    enc += cipher.final 'hex'
    
decrypt = (data, key) ->
    log 'decrypt...' + key + ':' + data
    log 'decrypt...' + key + ':' + genHash(key)
    cipher = crypto.createDecipher cipherType, genHash(key)
    dec  = cipher.update data, 'hex', 'utf8'
    dec += cipher.final 'utf8'
    
encryptFile = (file, buffer, key) ->
    encrypted = encrypt buffer, key
    fs.writeFileSync file, encrypted, fileEncoding
    
decryptFile = (file, key, cb) ->
    if fs.existsSync file
        try
            encrypted = fs.readFileSync(file, fileEncoding)
        catch
            cb ['can\'t read file at', file]
            return
        try
            log 'decrypting...' + key + ':' + encrypted
            cb null, decrypt(encrypted, key)
        catch
            cb ['can\'t decrypt file', file]
    else
        cb ['no file at', file]
    
genHash = (value) -> crypto.createHash('sha512').update(value).digest('hex')
genSalt = (length) -> 
    salt = ""
    while salt.length < length
        salt += bcrypt.genSaltSync(12).substr(10)
    salt.substr 0, length

exp = 
    [
        'encrypt', 'decrypt', 'decryptFile', 'encryptFile', 'genHash', 'genSalt'
    ]
module.exports = zipObject(exp.map((e) -> [e, eval(e)]))
