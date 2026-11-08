###
 0000000  00000000   000   000  00000000   000000000   0000000    0000000   000       0000000
000       000   000   000 000   000   000     000     000   000  000   000  000      000     
000       0000000      00000    00000000      000     000   000  000   000  000      0000000 
000       000   000     000     000           000     000   000  000   000  000           000
 0000000  000   000     000     000           000      0000000    0000000   0000000  0000000 
###

fs     = require 'fs'
crypto = require 'crypto'
bcrypt = require 'bcryptjs'

ipc = require("electron").ipcRenderer
# log = () -> ipc.send 'console.log',   [].slice.call arguments, 0

cipherType   = 'aes-256-cbc'
fileEncoding = encoding:'utf8'

# node's legacy crypto.createCipher()/createDecipher() derived key and iv from
# the password with openssl's EVP_BytesToKey (md5, no salt). those functions are
# gone from current node versions, so we do the same derivation by hand and
# stay compatible with stash files written by older versions of this app.
keyAndIv = (password) ->
    data = Buffer.from password, 'utf8'
    derived = Buffer.alloc 0
    chunks = []
    while Buffer.concat(chunks).length < 48
        derived = crypto.createHash('md5').update(Buffer.concat [derived, data]).digest()
        chunks.push derived
    keyIv = Buffer.concat chunks
    key: keyIv.slice 0, 32
    iv:  keyIv.slice 32, 48

encrypt = (data, key) ->
    { key: aesKey, iv } = keyAndIv genHash(key)
    cipher = crypto.createCipheriv cipherType, aesKey, iv
    enc =  cipher.update data, 'utf8', 'hex'
    enc += cipher.final 'hex'
    
decrypt = (data, key) ->
    # log 'decrypt...' + key + ':' + data
    # log 'decrypt...' + key + ':' + genHash(key)
    { key: aesKey, iv } = keyAndIv genHash(key)
    cipher = crypto.createDecipheriv cipherType, aesKey, iv
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
            # log 'decrypting...' + key + ':' + encrypted
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

module.exports = 
    encrypt:     encrypt
    decrypt:     decrypt
    encryptFile: encryptFile
    decryptFile: decryptFile
    genHash:     genHash
    genSalt:     genSalt
