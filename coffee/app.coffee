###
 0000000   00000000   00000000 
000   000  000   000  000   000
000000000  00000000   00000000 
000   000  000        000      
000   000  000        000      
###

clipboard = require 'clipboard'
isempty   = require 'lodash.isempty'
values    = require 'lodash.values'
random    = require 'lodash.random'
trim      = require 'lodash.trim'
pad       = require 'lodash.pad'
fs        = require 'fs'
_url      = require './js/tools/urltools'
password  = require './js/tools/password' 
cryptools = require './js/tools/cryptools'
keyname   = require './js/tools/keyname'
remote    = require 'remote'
sleep     = require 'sleep'
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

resetStash = ->
    stashLoaded = false
    clearInput 'site'
    clearInput 'password'
    clearInput 'pattern'
    updateFloppy()
    stash =     
        pattern: ''
        configs: {}                

###
 0000000   000   000  000  00     00
000   000  0000  000  000  000   000
000000000  000 0 000  000  000000000
000   000  000  0000  000  000 0 000
000   000  000   000  000  000   000
###

masterAnimDir = 0
masterAnim = ->
    if masterAnimDir == 1
        if $("master").value.length < 24
            $("master").value += 'x'        
            setTimeout masterAnim, 24-$("master").value.length
            return
        else 
            masterAnimDir = -1
    if masterAnimDir == -1
        if $("master").value.length > 1
            $("master").value = $("master").value.substr(0, Math.max(1, $("master").value.length-2))
            win.setSize win.getSize()[0], Math.max(win.getSize()[1], 492-$("master").value.length*6)
            masterAnim()
        else
            masterAnimDir = 0
            if stashExists
                showSitePassword()
                masterSitePassword()
            else
                showSettings()
                $('button-list').hide()
                $('sheep').disabled = false
            
masterFade = ->
    $('sheep').disabled = true
    if win.getSize()[1] > 355
        win.setSize win.getSize()[0], win.getSize()[1]-12
        setTimeout masterFade, 0

masterConfirmed = ->
    if mstr?.length
        if stashExists
            readStash () -> 
                if stashLoaded
                    $('sheep').disabled = false
                    say()
                    masterAnimDir = 1
                    masterAnim()
                else
                    whisper ['oops?', 'what?', '...?', 'nope!'][random 3], 2000
        else
            say ['Well chosen!', 'Nice one!', 'Good choice!'][random 2], 
                'And your <span class="open" onclick="openUrl(\'http://github.com\');">password pattern?</span>'
            masterAnimDir = 1
            masterAnim()

patternConfirmed = ->
    if $("pattern").value.length and stash.pattern != $("pattern").value
        if stash.pattern == ''
            say ['Also nice!', 'What a beautiful pattern!', 'The setup is done!'][random 2], 
                'Have fun generating passwords!', 5000
            $('button-list').show()
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
    if stashExists
        say()
    else
        say 'Welcome to <b>sheepword</b>.', 
            'What will be your <span class="open" onclick="openUrl(\'http://github.com\');">master key?</span>'
    masterFade()
    
patternChanged = ->
    updateFloppy()
    masterSitePassword()
                    
copyPassword = -> 
    pw = $("password").value
    if pw.length
        clipboard.writeText pw
        $("password").focus()
        whisper '<u>password</u> copied', 2000
    
setSite = (site) ->
    setInput 'site',  site
    siteChanged()
    
siteChanged = ->
    if $("site").value.length == 0
        hideLock()
    masterSitePassword()
    
###
00000000  000   000  00000000  000   000  000000000   0000000
000       000   000  000       0000  000     000     000     
0000000    000 000   0000000   000 0 000     000     0000000 
000          000     000       000  0000     000          000
00000000      0      00000000  000   000     000     0000000 
###
    
initEvents = () ->
    for input in $$('input')
        input.on 'focus', (e) -> 
            $(e.target.id+'-border').addClassName 'focus'
        input.on 'blur',  (e) -> 
            $(e.target.id+'-border').removeClassName 'focus'
        input.on 'input', (e) ->
            $(e.target.id+'-ghost').setStyle opacity: if e.target.value.length then 0 else 1
        if input.id != 'master'
            input.on 'mouseenter', (e) ->
                $(e.target).focus()
            
    for border in $$('.border')
        if border.id != 'master-border'
            border.on 'mouseenter', (e) ->
                $(e.target.id.substr(0,e.target.id.length-7)).focus()
                
    $('master'  ).on 'input', masterChanged
    $('site'    ).on 'input', siteChanged
    $('password').on 'click', copyPassword
    $('pattern' ).on 'input', patternChanged
    $('sheep'   ).on 'click', toggleSettings
    $('delete'  ).on 'click', deleteStash
    $('list'    ).on 'click', listStash
    $('sheep'   ).on 'mouseenter', (e) -> $('sheep').focus()
    # $('sheep'   ).disabled = true
    
###
000       0000000    0000000   0000000    00000000  0000000  
000      000   000  000   000  000   000  000       000   000
000      000   000  000000000  000   000  0000000   000   000
000      000   000  000   000  000   000  000       000   000
0000000   0000000   000   000  0000000    00000000  0000000  
###

document.observe 'dom:loaded', ->
        
    initEvents()
    
    $("master").focus()
    if domain = extractDomain clipboard.readText()
        setSite domain 

    hideSitePassword()
    hideSettings()
    resetStash()
    stashExists = fs.existsSync stashFile
    if not stashExists
        masterChanged()

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
            
onKeyDown = (event) ->
    key = keyname event
    e    = document.activeElement
    dbg key
    
    if $('stashlist')?
        onListKey event
        return
    
    if key == 'command-l' or key == 'ctrl-l'
        listStash()
        return
    
    site = $('site').value
    hash = genHash(site+mstr)
    
    if e == $('password')
        switch key
            when 'delete'
                if stash.configs[hash]?
                    if ask 'Forget <i>'+stash.configs[hash].pattern+'</i>', 'for <b>'+site+'</b>?'
                        delete stash.configs[hash]
                        say 'The <b>' + site + '</b>', '<i>pattern</i> is forgotten.', 2000
                        writeStash()
                        masterSitePassword()
                return
            when 'left', 'right', 'up', 'down'
                $('site').focus()
                $('site').setSelectionRange 0, $('site').value.length
                event.preventDefault()
                return
            when 'enter'
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
        when 'command-,', 'ctrl-,' then toggleSettings()
        when 'esc'
            if e == $('pattern') or $('settings').visible()
                if $('pattern').value != stash.pattern
                    setInput 'pattern', stash.pattern
                    patternChanged()
                    say()
                else
                    toggleSettings()
            else
                $('pattern').value = stash.pattern
                patternChanged()
                win.hide() 
        when 'enter'
            switch e
                when $("master")  then masterConfirmed()
                when $("site")    then copyPassword()
                when $("pattern") then patternConfirmed()

document.on 'keydown', onKeyDown

###
 0000000  000000000   0000000    0000000  000   000
000          000     000   000  000       000   000
0000000      000     000000000  0000000   000000000
     000     000     000   000       000  000   000
0000000      000     000   000  0000000   000   000
###

deleteStash = () ->
    if ask 'delete all remembered <i>patterns</i>?', 'if yes, confirm again.'
        fs.unlink stashFile, (err) ->
            if err
                say 'woops!', 'can\'t remove file!'
            else
                resetStash()
                stashExists = false
                $('master').value = ''
                $('master').focus()
                masterChanged()
    
writeStash = () ->
    stashString = JSON.stringify(stash)
    buf = new Buffer(stashString, "utf8")
    cryptools.encryptFile stashFile, buf, mstr
    updateFloppy()
    if not stashLoaded
        readStash () -> 
            if stashLoaded and JSON.stringify(stash) == stashString
                toggleSettings()

readStash = (cb) ->
    if fs.existsSync stashFile
        decryptFile stashFile, mstr, (err, json) -> 
            if err?
                resetStash()
            else
                stashLoaded = true
                stash = JSON.parse(json)
                setInput 'pattern', stash.pattern
                updateFloppy()
            cb()
    else
        resetStash()
        cb()

###
000      000   0000000  000000000
000      000  000          000   
000      000  0000000      000   
000      000       000     000   
0000000  000  0000000      000   
###

numConfigs = () -> Object.keys(stash.configs).length

onListKey = (event) ->
    key = keyname event
    e   = document.activeElement
    dbg key
    switch key 
        when 'esc', 'command-l', 'ctrl-l'
            $('stashlist').closeList()
        when 'right', 'down'
            if e? then e.parentElement?.nextSibling?.firstElementChild?.focus()
        when 'left', 'up'
            if e? then e.parentElement?.previousSibling?.firstElementChild?.focus()
        when 'delete'
            if e.parentElement.nextSibling?
                e.parentElement.nextSibling.firstElementChild.focus()
            else
                e.parentElement.previousSibling?.firstElementChild?.focus()
            delete stash.configs[e.id]
            e.parentElement.remove()
            writeStash()
        when 'enter'
            $('stashlist').closeList e.nextSibling.innerHTML
        when 'command-,', 'ctrl-,' # comma
            $('stashlist').closeList()
            hideSitePassword()
            showSettings()
        else
            log key

listStash = () ->
    
    if isempty stash.configs then return
    savedFocus = document.activeElement.id
    savedSite  = $('site').value
    savedBody  = document.body.innerHTML
    document.body.innerHTML = '<div id="stashlist"></div>'    
    
    $('stashlist').closeList = (site) ->
        document.body.innerHTML = savedBody
        initEvents()
        setInput 'pattern', stash.pattern
        setInput 'master',  mstr[0]
        if site?
            hideSettings()
            showSitePassword()
            setInput 'site', site
            masterSitePassword()            
            copyPassword()
        else
            setInput 'site', savedSite
            $(savedFocus)?.focus()
            masterSitePassword()
            updateFloppy()
        
    for hash in Object.keys stash.configs
        config = stash.configs[hash]
        site = decrypt config.url, mstr
        item =       new Element 'div', class: 'stash-item-border border'
        item.insert  new Element 'input', id: hash, type: 'button', class: 'stash-item'
        item.insert (new Element 'span', class: 'site').update site
        lock =       new Element 'span', class: 'lock'
        item.insert lock
        if config.pattern == stash.pattern
            lockClosed lock
        else
            lockOpen lock
            item.insert (new Element 'span', 
                class: 'pattern').update config.pattern
            
        $('stashlist').insert item
            
        item.on 'mouseenter', (e) -> e.target.childElements[0].focus()    
        $(hash).on 'click',   (e) -> $('stashlist').closeList e.target.nextSibling.innerHTML

    for input in $$('input')
        input.on 'focus',      (e) -> $(e.target.parentElement).addClassName 'focus'
        input.on 'blur',       (e) -> $(e.target.parentElement).removeClassName 'focus'
        input.on 'mouseenter', (e) -> $(e.target).focus()
            
    $('stashlist').firstElementChild.firstElementChild.focus()
    
###
 0000000  000  000000000  00000000
000       000     000     000     
0000000   000     000     0000000 
     000  000     000     000     
0000000   000     000     00000000
###
    
makePassword = (hash, config) -> password.make hash, config.pattern
        
showPassword = (config) ->
    url    = decrypt config.url, mstr
    pass   = makePassword genHash(url+mstr), config
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
        if config.pattern == stash.pattern
            lockClosed $('lock')
        else 
            lockOpen $('lock')
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
            hideSitePassword()
            showSettings()

showSettings = ->
    updateFloppy()
    $('settings').show()
    $('pattern').focus()
    if isEmpty stash.configs
        $('list').disabled = true
        $('list-border').addClassName 'disabled'
    else 
        $('list').disabled = false
        $('list-border').removeClassName 'disabled'
    
hideSettings = ->
    $('settings').hide()
    say() if stashExists
    stashExists = fs.existsSync stashFile
    if $('pattern').value.length == 0 and stash?.pattern
        setInput 'pattern', stash.pattern
        patternChanged()

hideSitePassword = ->
    $('site-border').setStyle opacity: 0
    $('site-border').addClassName 'no-pointer'
    $('site').disabled = true
    $('password-border').setStyle opacity: 0
    $('password-border').addClassName 'no-pointer'
    $('password').disabled = true

showSitePassword = ->
    $('site-border').setStyle  opacity: 1
    $('site-border').removeClassName 'no-pointer'
    $('site').disabled = false    
    $('password-border').setStyle opacity: 1
    $('password-border').removeClassName 'no-pointer'
    $('password').disabled = false
    $('site').focus()

clearInput = (input) -> setInput input, ''
    
setInput = (input, value) ->
    $(input).value = value
    $(input+'-ghost').setStyle opacity: (value.length == 0 and 1 or 0)
    
lockClosed = (e) -> 
    e.innerHTML = '<span><i class="fa fa-lock fa-lg"></i></span>'
    e.removeClassName 'open'
    e.addClassName 'closed'

lockOpen = (e) ->        
    e.innerHTML = '<span><i class="fa fa-unlock fa-lg"></i></span>'
    e.removeClassName 'closed'
    e.addClassName 'open'    

hideLock = -> 
    $('lock').removeClassName 'open'
    $('lock').removeClassName 'closed'
            
updateFloppy = ->
    if stash?.pattern != $("pattern").value or stash?.pattern == ''
        $('floppy').removeClassName 'saved'
    else
        $('floppy').addClassName 'saved'
        
###
000000000   0000000   000      000   000
   000     000   000  000      000  000 
   000     000000000  000      0000000  
   000     000   000  000      000  000 
   000     000   000  0000000  000   000
###

unsay = undefined

whisper = (boo) -> 
    clearTimeout(unsay) if unsay?
    unsay = undefined
    if arguments.length > 1
        unsay = setTimeout say, arguments[1]
    $('bubble').className = 'whisper'
    $('say').innerHTML = boo

say = -> 
    clearTimeout(unsay) if unsay?
    unsay = undefined
    if arguments.length == 0
        $('say').innerHTML += ' '
        $('bubble').className = 'silent'
    else
        args = [].slice.call arguments, 0
        if args.length == 3
            delay = args.pop()
            unsay = setTimeout say, delay
        $('bubble').className = "say"
        $('say').innerHTML = args.join "<p>"

ask = ->
    if not $('say').innerHTML.endsWith(arguments[arguments.length-1]+'</p>')
        say.apply say, arguments
        $('bubble').className = "ask"
        return false
    true
