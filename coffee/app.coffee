###
 0000000   00000000   00000000 
000   000  000   000  000   000
000000000  00000000   00000000 
000   000  000        000      
000   000  000        000      
###

clipboard = require 'clipboard'
trim      = require 'lodash.trim'
pad       = require 'lodash.pad'
fs        = require 'fs'
_url      = require './js/tools/urltools'
password  = require './js/tools/password' 
cryptools = require './js/tools/cryptools'
remote    = require 'remote'
ipc       = require 'ipc'

win = remote.getCurrentWindow()

genHash       = cryptools.genHash
encrypt       = cryptools.encrypt
decrypt       = cryptools.decrypt
decryptFile   = cryptools.decryptFile
extractSite   = _url.extractSite
extractDomain = _url.extractDomain
containsLink  = _url.containsLink
jsonStr       = (a) -> JSON.stringify a, null, " "

mstr      = undefined
stashFile = process.env.HOME+'/.config/sheepword.stash'
stash     = undefined

log   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0
dbg   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0
error = () -> ipc.send 'knixerror', [].slice.call arguments, 0

resetStash = ->
    stash =     
        pattern: 'sh33p-w0rd'
        configs: {}

masterConfirmed = -> 
    log 'master confirm'
    $("site").focus()

masterChanged = -> 
    mstr = $("master").value 
    $("master-ghost").setStyle opacity: if mstr?.length then 0 else 1
    masterSitePassword()
    
masterFocus = -> $("master-border").addClassName 'focus'
    
masterBlurred = ->
    $("master-border").removeClassName 'focus'
    if $("master").value.length
        while $("master").value.length < 18
            $("master").value += 'x'
            
siteFocus       = -> $("site-border").addClassName 'focus'
siteBlurred     = -> $("site-border").removeClassName 'focus'
passwordFocus   = -> $("password-border").addClassName 'focus'
passwordBlurred = -> $("password-border").removeClassName 'focus'

siteConfirmed   = -> 
    log 'site confirm'
    pw = $("password").value
    if pw.length
        clipboard.writeText pw
        $("password").focus()
    
setSite = (site) ->
    $("site").value = site
    siteChanged()
    
siteChanged = -> 
    $("site-ghost").setStyle opacity: if $("site").value.length then 0 else 1
    masterSitePassword()
    
openPrefs = ->
    log 'openPrefs'

document.observe 'dom:loaded', ->
    
    resetStash()
    
    for inputName in ['master', 'site', 'password']
        $(inputName).on 'focus', eval inputName+'Focus'
        $(inputName).on 'blur', eval inputName+'Blurred'
    
    $("master").on 'input',  masterChanged
    $("site"  ).on 'input',  siteChanged
    $("sheep" ).on 'click',  openPrefs
    $("master").focus()
    if domain = extractDomain clipboard.readText()
        setSite domain 

win.on 'focus', (event) -> 
    if mstr? and mstr.length
        if domain = extractDomain clipboard.readText()
            setSite domain
            clipboard.writeText $("password").value
            $("password").focus()
        else
            $("site").focus()
            $("site").setSelectionRange 0, $("site").value.length
    else
        $("master").focus()
        
document.on 'keydown', (event) ->
    if event.which == 27 # escape
        win.hide()
    if event.which == 13 # enter
        log 'enter'
        if document.activeElement == $("master")
            log 'master enter'
            masterConfirmed()
        else if document.activeElement == $("site")
            log 'site enter'
            siteConfirmed()

undirty = -> log 'undirty'
dirty   = -> log 'dirty'

###
 0000000  000000000   0000000    0000000  000   000
000          000     000   000  000       000   000
0000000      000     000000000  0000000   000000000
     000     000     000   000       000  000   000
0000000      000     000   000  0000000   000   000
###
    
writeStash = () ->
    buf = new Buffer(JSON.stringify(stash), "utf8")
    cryptools.encryptFile stashFile, buf, mstr
    undirty()

readStash = (cb) ->
    if fs.existsSync stashFile
        log 'stash exists' + stashFile + ' ' + mstr
        decryptFile stashFile, mstr, (err, json) -> 
            if err?
                if err[0] == 'can\'t decrypt file'
                    error err
                    stash = undefined
                    cb()
                else
                    error err
            else
                stash = JSON.parse(json)
                undirty()
                cb()
    else
        resetStash()
        undirty()
        cb()

numConfigs = () ->
    keysIn(stash.configs).length

###
 0000000  000  000000000  00000000
000       000     000     000     
0000000   000     000     0000000 
     000  000     000     000     
0000000   000     000     00000000
###
    
makePassword = (hash, config) ->
    log "hash:" + hash + "config:" + jsonStr(config)
    password.make hash, config.pattern
        
showPassword = (config) ->
    url    = decrypt config.url, mstr
    pass   = makePassword genHash(url+mstr), config
    dbg pass
    $("password").value = pass
    $("password-ghost").setStyle opacity: 0
    pass
    
masterSitePassword = () ->
    site = trim $("site").value
    if not site?.length or not mstr?.length
        $("password").value = ""
        $("password-ghost").setStyle opacity: 1
        return ""
    
    hash = genHash site+mstr    
        
    if stash.configs?[hash]?
        config = stash.configs[hash]
    else        
        config = {}
        config.url = encrypt site, mstr
        config.pattern = stash.pattern
        stash.configs[hash] = config
        
    pass = showPassword config
    
###
00     00   0000000   000  000   000
000   000  000   000  000  0000  000
000000000  000000000  000  000 0 000
000 0 000  000   000  000  000  0000
000   000  000   000  000  000   000
###

