###
 0000000   00000000   00000000 
000   000  000   000  000   000
000000000  00000000   00000000 
000   000  000        000      
000   000  000        000      
###

clipboard = require 'clipboard'
values    = require 'lodash.values'
random    = require 'lodash.random'
trim      = require 'lodash.trim'
pad       = require 'lodash.pad'
fs        = require 'fs'
_url      = require './js/tools/urltools'
password  = require './js/tools/password' 
cryptools = require './js/tools/cryptools'
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
                $("sheep").removeClassName 'no-pointer'
            
masterFade = ->
    if win.getSize()[1] > 355
        win.setSize win.getSize()[0], win.getSize()[1]-12
        setTimeout masterFade, 0

masterConfirmed = ->
    if mstr?.length
        if stashExists
            readStash () -> 
                if stashLoaded
                    $("sheep").removeClassName 'no-pointer'
                    say()
                    masterAnimDir = 1
                    masterAnim()
                else
                    whisper ['oops?', 'what?', 'again?', '...?', 'nope!'][random 4], 2000
        else
            say ['Well chosen!', 'Nice one!', 'Good choice!', 'I didn\'t expect that :)', 'Amazing!'][random 4], 
                'And your <span class="open" onclick="openUrl(\'http://github.com\');">password pattern?</span>'
            masterAnimDir = 1
            masterAnim()                

patternConfirmed = ->
    if $("pattern").value.length and stash.pattern != $("pattern").value
        if stash.pattern == ''
            say ['Also nice!', 'What a beautiful pattern!', 'Not bad either!', 'Congratulations!', 'The setup is done!'][random 4], 
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
                    
siteConfirmed = -> 
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
000  000   000  000  000000000  00000000  000   000  00000000  000   000  000000000   0000000
000  0000  000  000     000     000       000   000  000       0000  000     000     000     
000  000 0 000  000     000     0000000    000 000   0000000   000 0 000     000     0000000 
000  000  0000  000     000     000          000     000       000  0000     000          000
000  000   000  000     000     00000000      0      00000000  000   000     000     0000000 
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
                
    $("master" ).on 'input', masterChanged
    $("site"   ).on 'input', siteChanged
    $("pattern").on 'input', patternChanged
    $("sheep"  ).on 'click', toggleSettings
    $("sheep"  ).addClassName 'no-pointer'
    $("sheep"  ).on 'mouseenter', (e) -> $('sheep').focus()
    $("delete" ).on 'click', deleteStash
    $("list"   ).on 'click', listStash
    
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
            
onDocumentKeyDown = (event) ->
    key  = event.which
    e    = document.activeElement
    # log 'key', key, e.name, e.id, e.className
    
    if $('stashlist')?
        onListKey event
        return
    
    if key == 76 and event.getModifierState 'Meta' # Command-l
        listStash()
        return
    
    site = $('site').value
    hash = genHash(site+mstr)
    
    if e == $('password')
        switch key
            when 8 # delete / backspace?
                if stash.configs[hash]?
                    if ask 'Forget <i>'+stash.configs[hash].pattern+'</i>', 'for <b>'+site+'</b>?'
                        delete stash.configs[hash]
                        say 'The <b>' + site + '</b>', '<i>pattern</i> is forgotten.', 2000
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
        when 13 # enter
            switch e
                when $("master")  then masterConfirmed()
                when $("site")    then siteConfirmed()
                when $("pattern") then patternConfirmed()

document.on 'keydown', onDocumentKeyDown

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

numConfigs = () ->
    keysIn(stash.configs).length

onListKey = (event) ->
    e   = document.activeElement
    key = event.which
    # dbg key, e.name, e.id, e.className
    if key == 27 or key == 76 and event.getModifierState 'Meta' # escape or Command-l
        $('stashlist').closeList()
    if key == 39 or key == 40 # right or down
        if e? then e.parentElement?.nextSibling?.firstElementChild?.focus()
    if key == 37 or key == 38 # left or up
        if e? then e.parentElement?.previousSibling?.firstElementChild?.focus()
    

listStash = () ->
    savedBody = document.body.innerHTML
    document.body.innerHTML = '<div id="stashlist"></div>'
    $('stashlist').closeList = ->
        document.body.innerHTML = savedBody
        initEvents()
        setInput 'pattern', stash.pattern
        setInput 'master', mstr[0]
        updateFloppy()
        $('list').focus()
        
    for config in values(stash.configs)
        site = decrypt config.url, mstr
        item = new Element 'div',
            class: 'stash-item-border border'
        item.insert (new Element 'input',
            type:  'button',
            class: 'stash-item')
        item.insert (new Element 'span',
            class: 'site').update site
        lock = new Element 'span', class: 'lock'
        item.insert lock
        if config.pattern == stash.pattern
            lockClosed lock
        else
            lockOpen lock
            item.insert (new Element 'span', 
                class: 'pattern').update config.pattern
            
        item.on 'mouseenter', (e) -> e.target.childElements[0].focus()
    
        $('stashlist').insert item

    checkFocus = () ->
        if document.activeElement.className.length == 0
            $('stashlist').firstElementChild.firstElementChild.focus()

    for input in $$('input')
        input.on 'focus',      (e) -> $(e.target.parentElement).addClassName 'focus'
        input.on 'mouseenter', (e) -> $(e.target).focus()
        input.on 'blur',       (e) -> 
            $(e.target.parentElement).removeClassName 'focus'
            setTimeout checkFocus, 0
            
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
    $('site').addClassName 'no-pointer'
    $('password-border').setStyle opacity: 0
    $('password-border').addClassName 'no-pointer'

showSitePassword = ->
    $('site-border').setStyle  opacity: 1
    $('site-border').removeClassName 'no-pointer'
    $('site').removeClassName 'no-pointer'
    $('password-border').setStyle opacity: 1
    $('password-border').removeClassName 'no-pointer'
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
