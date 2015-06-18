###
 0000000   00000000   00000000 
000   000  000   000  000   000
000000000  00000000   00000000 
000   000  000        000      
000   000  000        000      
###

clipboard = require 'clipboard'
random    = require 'lodash.random'
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

mstr        = undefined
stashFile   = process.env.HOME+'/Library/Preferences/sheepword.stash'
stash       = undefined
stashExists = false
stashLoaded = false

log   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0
dbg   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0
error = () -> ipc.send 'knixerror', [].slice.call arguments, 0

resetStash = ->
    stashLoaded = false
    clearInput 'pattern'
    showDirty()
    stash =     
        pattern: ''
        configs: {}                

masterConfirmed = ->
    if mstr?.length
        if stashExists
            readStash () -> 
                if stashLoaded
                    say()
                    showSitePassword()
                    masterSitePassword()
                else
                    say 'can\'t open stash file:', stashFile 
        else
            say ['Well chosen!', 'Nice one!', 'Good choice!', 'I didn\'t expect that :)', 'I never would have guessed that!'][random 5], 
                'And your <span class="open" onclick="openUrl(\'http://github.com\');">password pattern?</span>'
            showSettings()

patternConfirmed = ->
    if $("pattern").value.length
        if stash.pattern == ''
            say ['Also nice!', 'What a beautiful pattern!', 'Not bad either!', 'Congratulations!'][random 4], 
                'Have fun generating passwords!'
            setTimeout 5000, -> say()
        else
            say()
        stash.pattern = $("pattern").value
        writeStash()

openUrl = (url) -> (require 'opener') url

masterChanged = ->
    mstr = $("master").value
    hideSitePassword()
    hideSettings()
    stashLoaded = false
    greet()
    masterSitePassword()
    
patternChanged = ->
    if stash.pattern != $("pattern").value
        showDirty()
    else
        showSaved()
    masterSitePassword()
    
masterBlurred = ->
    if stashLoaded or not stashExists
        if $("master").value.length
            while $("master").value.length < 23
                $("master").value += 'x'
            
siteConfirmed = -> 
    pw = $("password").value
    if pw.length
        clipboard.writeText pw
        $("password").focus()
    
setSite = (site) ->
    setInput 'site',  site
    siteChanged()
    
siteChanged = ->
    if $("site").value.length == 0
        hideLock()
    masterSitePassword()
    
###
000       0000000    0000000   0000000    00000000  0000000  
000      000   000  000   000  000   000  000       000   000
000      000   000  000000000  000   000  0000000   000   000
000      000   000  000   000  000   000  000       000   000
0000000   0000000   000   000  0000000    00000000  0000000  
###

document.observe 'dom:loaded', ->
        
    for input in $$('input')
        input.on 'focus', (e) -> 
            $(e.target.name+'-border').addClassName 'focus'
        input.on 'blur',  (e) -> 
            $(e.target.name+'-border').removeClassName 'focus'
        input.on 'input', (e) ->
            $(e.target.name+'-ghost').setStyle opacity: if e.target.value.length then 0 else 1
        
    $("master" ).on 'blur' , masterBlurred
    $("master" ).on 'input', masterChanged
    $("site"   ).on 'input', siteChanged
    $("pattern").on 'input', patternChanged
    $("sheep"  ).on 'click', toggleSettings
    $("master" ).focus()
    if domain = extractDomain clipboard.readText()
        setSite domain 

    hideSitePassword()
    hideSettings()
    resetStash()
    stashExists = fs.existsSync stashFile
    if stashExists
        log 'found stash file', stashFile
    else
        log 'no stash file!'
    greet()

win.on 'focus', (event) -> 
    if stashLoaded
        if domain = extractDomain clipboard.readText()
            setSite domain
            clipboard.writeText $("password").value
            $("password").focus()
        else
            $("site").focus()
            $("site").setSelectionRange 0, $("site").value.length
    else
        $("master").focus()
        
###
000   000  00000000  000   000  0000000     0000000   000   000  000   000
000  000   000        000 000   000   000  000   000  000 0 000  0000  000
0000000    0000000     00000    000   000  000   000  000000000  000 0 000
000  000   000          000     000   000  000   000  000   000  000  0000
000   000  00000000     000     0000000     0000000   00     00  000   000
###
        
document.on 'keydown', (event) ->
    key  = event.which
    site = $('site').value
    hash = genHash(site+mstr)
    e    = document.activeElement
    
    if e == $('password')
        switch key
            when 8 # delete / backspace?
                if stash.configs[hash]?
                    delete stash.configs[hash]
                    writeStash()
                    masterSitePassword()
                return
            when 37, 38, 39, 40 # cursor keys
                $('site').focus()
                $('site').setSelectionRange 0, $('site').value.length
                event.preventDefault()
                return
            when 13 # enter
                if not stash.configs[hash]?
                    stash.configs[hash] = 
                        url: encrypt site, mstr
                stash.configs[hash].pattern = $('pattern').value
                writeStash()
                masterSitePassword()
                return
    
    switch key
        when 188 # comma
            if event.getModifierState 'Meta'
                toggleSettings()
        when 27 # escape
            if e == $('pattern')
                toggleSettings()
            else
                win.hide() 
        when 13 # enter
            switch e
                when $("master")  then masterConfirmed()
                when $("site")    then siteConfirmed()
                when $("pattern") then patternConfirmed()
        else
            dbg key

###
 0000000  000000000   0000000    0000000  000   000
000          000     000   000  000       000   000
0000000      000     000000000  0000000   000000000
     000     000     000   000       000  000   000
0000000      000     000   000  0000000   000   000
###
    
writeStash = () ->
    stashString = JSON.stringify(stash)
    buf = new Buffer(stashString, "utf8")
    log 'write stash', buf.length, stashFile, mstr, JSON.stringify(stash)
    cryptools.encryptFile stashFile, buf, mstr
    if $('pattern').value == stash.pattern then showSaved()
    if not stashLoaded
        readStash () -> 
            # log 'stash loaded', stashLoaded
            if stashLoaded and JSON.stringify(stash) == stashString
                # log 'stash confirmed'
                toggleSettings()

readStash = (cb) ->
    if fs.existsSync stashFile
        log 'stash exists' + stashFile + ' ' + mstr
        decryptFile stashFile, mstr, (err, json) -> 
            if err?
                error err
                resetStash()
            else
                stashLoaded = true
                stash = JSON.parse(json)
                setInput 'pattern', stash.pattern
                showSaved()
            cb()
    else
        log 'stash doesn\'t exists' + stashFile
        resetStash()
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
    # log "hash:" + hash + "config:" + jsonStr(config)
    password.make hash, config.pattern
        
showPassword = (config) ->
    url    = decrypt config.url, mstr
    pass   = makePassword genHash(url+mstr), config
    # dbg pass
    setInput 'password', pass
    pass
    
masterSitePassword = () ->
    site = trim $("site").value
    if not site?.length or not mstr?.length
        clearInput 'password'
        hideLock()
        return ""
    
    hash = genHash site+mstr    
        
    if stash.configs?[hash]?
        config = stash.configs[hash]
        log "cfgpattern", jsonStr config
        log "patterlval", $('pattern').value
        if config.pattern == $('pattern').value
            showLockClosed()
        else 
            showLockOpen()
    else        
        config = {}
        config.url = encrypt site, mstr
        config.pattern = $('pattern').value
        hideLock()
        
    pass = showPassword config
    
###
 0000000  00000000  000000000  000000000  000  000   000   0000000    0000000
000       000          000        000     000  0000  000  000        000     
0000000   0000000      000        000     000  000 0 000  000  0000  0000000 
     000  000          000        000     000  000  0000  000   000       000
0000000   00000000     000        000     000  000   000   0000000   0000000 
###

toggleSettings = ->
    if stashLoaded
        if  $("settings").visible()
            hideSettings()
            showSitePassword()
        else
            if $('site').value.length and not stash.configs?[genHash $('site').value+mstr]?
                $('site-border').setStyle opacity: 0
            else
                hideSitePassword()
            showSettings()

showSettings = ->
    $('settings').show()
    $('pattern').focus()
    
hideSettings = ->
    $('settings').hide()
    if $('pattern').value.length == 0 and stash?.pattern
        setInput 'pattern', stash.pattern
        patternChanged()

hideSitePassword = ->
    $('site-border').setStyle opacity: 0
    $('password-border').setStyle opacity: 0

showSitePassword = ->
    $('site-border').setStyle opacity: 1
    $('password-border').setStyle opacity: 1
    $('site').focus()

clearInput = (input) ->
    setInput input, ''
    
setInput = (input, value) ->
    $(input).value = value
    $(input+'-ghost').setStyle opacity: (value.length == 0 and 1 or 0)
    
showLockClosed = ->
    $('lock').innerHTML = '<span><i class="fa fa-lock fa-lg"></i></span>'
    $('lock').setStyle opacity: 1
    $('lock').addClassName 'closed'

showLockOpen = ->
    $('lock').innerHTML = '<span><i class="fa fa-unlock fa-lg"></i></span>'
    $('lock').setStyle opacity: 1
    $('lock').removeClassName 'closed'
    
showDirty = -> $('floppy').removeClassName 'saved'
showSaved = -> $('floppy').addClassName 'saved'

hideLock = ->
    $('lock').setStyle opacity: 0

greet = ->
    if stashExists
        say()
    else
        say 'Welcome to <b>sheepword</b>.', 
            'What will be your <span class="open" onclick="openUrl(\'http://github.com\');">master key?</span>'

say = -> 
    if arguments.length == 0
        $('bubble').setStyle opacity: 0
    else
        $('bubble').setStyle opacity: 1
        args = [].slice.call arguments, 0
        # log args.join "<p>"
        $('say').innerHTML = args.join "<p>"
