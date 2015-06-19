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
                    $("sheep"  ).removeClassName 'no-pointer'
                    say()
                    showSitePassword()
                    masterSitePassword()
                else
                    log 'can\'t open stash file:', stashFile 
                    whisper ['oops?', 'what?', 'again?', '...?', 'I didn\'t get that!'][random 4]
        else
            say ['Well chosen!', 'Nice one!', 'Good choice!', 'I didn\'t expect that :)', 'I never would have guessed that!'][random 4], 
                'And your <span class="open" onclick="openUrl(\'http://github.com\');">password pattern?</span>'
            showSettings()
            $("sheep"  ).removeClassName 'no-pointer'

patternConfirmed = ->
    if $("pattern").value.length and stash.pattern != $("pattern").value
        if stash.pattern == ''
            say ['Also nice!', 'What a beautiful pattern!', 'Not bad either!', 'Congratulations!', 'The setup is done!'][random 4], 
                'Have fun generating passwords!', 3000
        else
            if not ask 'change the default <i>pattern</i>?', 'if yes, press return again.'
                return
            say 'the new default pattern is', '<i>'+$("pattern").value+'</i>', 6000
        stash.pattern = $("pattern").value
        writeStash()
    else if stash.pattern == $("pattern").value
        toggleSettings()

openUrl = (url) -> (require 'opener') url

masterChanged = ->
    mstr = $("master").value
    hideSitePassword()
    hideSettings()
    stashLoaded = false
    greet()
    masterSitePassword()
    
patternChanged = ->
    updateFloppy()
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
        say '<u>' + pw + '</u>', 'on the clipboard', 5000
    
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
            $(e.target.id+'-border').addClassName 'focus'
        input.on 'blur',  (e) -> 
            say()
            $(e.target.id+'-border').removeClassName 'focus'
        input.on 'input', (e) ->
            $(e.target.id+'-ghost').setStyle opacity: if e.target.value.length then 0 else 1
        input.on 'mouseenter', (e) ->
            $(e.target).focus()
        
    $('bubble').opacity = 0
        
    $("master" ).on 'blur' , masterBlurred
    $("master" ).on 'input', masterChanged
    $("site"   ).on 'input', siteChanged
    $("pattern").on 'input', patternChanged
    $("sheep"  ).on 'click', toggleSettings
    $("sheep"  ).addClassName 'no-pointer'
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
                    if ask 'Forget <i>'+stash.configs[hash].pattern+'</i>', 'for <b>'+site+'</b>?'
                        delete stash.configs[hash]
                        say 'The <b>' + site + '</b>', '<i>pattern</i> is forgotten now.', 2000
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
                    say 'Remembering <i>' + $('pattern').value+'</i>', 'for <b>'+site+'</b>', 2000
                else if stash.configs[hash].pattern != $('pattern').value
                    if not ask 'Replace <i>'+stash.configs[hash].pattern+'</i>', 'with <i>'+$('pattern').value+'</i>?'
                        return
                    say 'Using <i>'+$('pattern').value+'</i>', 'for <b>'+site+'</b>', 2000
                stash.configs[hash].pattern = $('pattern').value
                writeStash()
                masterSitePassword()
                return
    
    switch key
        when 188 # comma
            if event.getModifierState 'Meta'
                toggleSettings()
        when 27 # escape
            $('pattern').value = stash.pattern
            masterSitePassword()
            if e == $('pattern')
                toggleSettings()
            else
                win.hide() 
        when 13 # enter
            switch e
                when $("master")  then masterConfirmed()
                when $("site")    then siteConfirmed()
                when $("pattern") then patternConfirmed()
        # else
        #     dbg key

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
        if config.pattern == stash.pattern
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
    updateFloppy()
    $('settings').show()
    $('pattern').focus()
    
hideSettings = ->
    $('settings').hide()
    say()
    if $('pattern').value.length == 0 and stash?.pattern
        setInput 'pattern', stash.pattern
        patternChanged()

hideSitePassword = ->
    $('site-border').setStyle opacity: 0
    $('site-border').addClassName 'no-pointer'
    $('password-border').setStyle opacity: 0
    $('password-border').addClassName 'no-pointer'

showSitePassword = ->
    $('site-border').setStyle  opacity: 1
    $('site-border').removeClassName 'no-pointer'
    $('password-border').setStyle opacity: 1
    $('password-border').removeClassName 'no-pointer'
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
updateFloppy = ->
    if stash.pattern != $("pattern").value
        showDirty()
    else
        say()
        showSaved()

hideLock = ->
    $('lock').setStyle opacity: 0

greet = ->
    if stashExists
        say()
    else
        say 'Welcome to <b>sheepword</b>.', 
            'What will be your <span class="open" onclick="openUrl(\'http://github.com\');">master key?</span>'

whisper = (boo) -> 
    $('bubble').setStyle opacity: 1
    $('bubble').addClassName 'whisper'
    $('say').innerHTML = boo

unsay = undefined
say = -> 
    # log [].slice.call arguments, 0
    clearTimeout(unsay) if unsay?
    unsay = undefined
    if arguments.length == 0
        $('say').innerHTML += ' '
        $('bubble').setStyle opacity: 0
    else
        args = [].slice.call arguments, 0
        if args.length == 3
            delay = args.pop()
            unsay = setTimeout say, delay
            
        $('bubble').removeClassName 'whisper'
        $('bubble').setStyle opacity: 1
        $('say').innerHTML = args.join "<p>"

ask = ->
    log arguments[arguments.length-1]
    if not $('say').innerHTML.endsWith(arguments[arguments.length-1]+'</p>')
        say.apply say, arguments
        return false
    true
