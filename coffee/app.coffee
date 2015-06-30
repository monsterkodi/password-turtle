###
 0000000   00000000   00000000 
000   000  000   000  000   000
000000000  00000000   00000000 
000   000  000        000      
000   000  000        000      
###

clipboard = require 'clipboard'
isEmpty   = require 'lodash.isempty'
values    = require 'lodash.values'
random    = require 'lodash.random'
trim      = require 'lodash.trim'
pad       = require 'lodash.pad'
isNaN     = require 'lodash.isnan'
uuid      = require 'node-uuid'
fs        = require 'fs'
_url      = require './js/tools/urltools'
password  = require './js/tools/password' 
cryptools = require './js/tools/cryptools'
keyname   = require './js/tools/keyname'
remote    = require 'remote'
open      = require 'opener'
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

mstr          = undefined
stashFile     = process.env.HOME+'/Library/Preferences/password-turtle.stash'
stash         = undefined
stashExists   = false
stashLoaded   = false
currentPassword = undefined
stash_key     = ''
prefs_key     = ''
vault_key     = ''
settings_key  = ''

log   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0
dbg   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0

console.log   = () -> ipc.send 'console.log',   [].slice.call arguments, 0
console.error = () -> ipc.send 'console.error', [].slice.call arguments, 0

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
        if $("master").value.length > 0
            $("master").value = $("master").value.substr(0, Math.max(0, $("master").value.length-2))
            win.setSize win.getSize()[0], Math.max(win.getSize()[1], 491-$("master").value.length*6)
            masterAnim()
        else
            win.setSize win.getSize()[0], 491
            startTimeout getPref 'timeout'
            masterAnimDir = 0
            if stashExists
                $('turtle').disabled = false
                updateSiteFromClipboard()
                showSitePassword()
                masterSitePassword()
            else
                showSettings()
                $('buttons').hide()
            
masterFade = ->
    $('turtle').disabled = true
    if win.getSize()[1] > 355
        win.setSize win.getSize()[0], Math.max 355, win.getSize()[1]-12
        setTimeout masterFade, 0

###
000  000   000  00000000   000   000  000000000
000  0000  000  000   000  000   000     000   
000  000 0 000  00000000   000   000     000   
000  000  0000  000        000   000     000   
000  000   000  000         0000000      000   
###

masterConfirmed = ->
    if mstr?.length
        if stashExists
            readStash () -> 
                if stashLoaded
                    $('turtle').disabled = false
                    say()
                    masterAnimDir = 1
                    masterAnim()
                    $('master-timeout')?.setStyle
                        width: '100%'
                        left: '0%'            
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
            $('turtle').disabled = false    
        else
            if not ask 'change the default <i>pattern</i>?', 'if yes, press return again.'
                return
            say 'the new default pattern is', '<i>'+$("pattern").value+'</i>', 6000
        stash.pattern = $("pattern").value
        writeStash()
    else if stash.pattern == $("pattern").value
        toggleSettings()

masterChanged = ->
    if stashExists
        say()
    else
        say 'Welcome to <b>password-turtle</b>.', 
            'What will be your <span class="open" onclick="openUrl(\'http://github.com\');">master key?</span>'
    logOut()
    
patternChanged = ->
    updateFloppy()
    masterSitePassword()
        
savePattern = ->
    site = $('site').value
    hash = genHash(site+mstr)
    stash.configs[hash].pattern = $('pattern').value
    writeStash()
    masterSitePassword()        
                    
copyAndSavePattern = ->
    copyPassword()
    
    site = $('site').value
    hash = genHash(site+mstr)

    if not stash.configs[hash]?
        stash.configs[hash] = 
            url: encrypt site, mstr
        whisper '<u>password</u> copied and<br></i>pattern</i> remembered', 2000
        savePattern()
    else if stash.configs[hash].pattern != $('pattern').value
        if not ask 'Replace <i>'+stash.configs[hash].pattern+'</i>', 'with <i>'+$('pattern').value+'</i>?'
            return
        say 'Using <i>'+$('pattern').value+'</i>', 'for <b>'+site+'</b>', 2000
        savePattern()
                    
copyPassword = -> 
    resetTimeout()
    pw = currentPassword
    if pw?.length
        clipboard.writeText pw
        $("password").focus()
        whisper '<u>password</u> copied', 2000
        
###
00000000  000   000  00000000  000   000  000000000   0000000
000       000   000  000       0000  000     000     000     
0000000    000 000   0000000   000 0 000     000     0000000 
000          000     000       000  0000     000          000
00000000      0      00000000  000   000     000     0000000 
###
    
initEvents = () ->
    for input in $$('input')
        input.on 'focus', (e) -> $(e.target.id+'-border')?.addClassName 'focus'
        input.on 'blur',  (e) -> $(e.target.id+'-border')?.removeClassName 'focus'
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
    $('pattern' ).on 'input', patternChanged
    $('turtle'  ).on 'click', toggleSettings
    $('password').on 'mousedown', copyPassword
    $('turtle'  ).on 'mouseenter', (e) -> $('turtle').focus()
            
###
000       0000000    0000000   0000000    00000000  0000000  
000      000   000  000   000  000   000  000       000   000
000      000   000  000000000  000   000  0000000   000   000
000      000   000  000   000  000   000  000       000   000
0000000   0000000   000   000  0000000    00000000  0000000  
###

document.observe 'dom:loaded', ->
        
    initEvents()
    prefs = loadPrefs()
    
    toggleStyle() if not prefs.dark
    
    $("master").focus()
    
    hideSitePassword()
    hideSettings()
    resetStash()
    stashExists = fs.existsSync stashFile
    if not stashExists
        masterChanged()
        
win.on 'close', (event) ->
    values = loadPrefs()
    values.winpos = win.getPosition()
    savePrefs values
    
win.on 'focus', (event) -> 
    resetTimeout()
    if stashLoaded
        updateSiteFromClipboard()
        $("site").focus()
        $("site").select()
        # $("site").setSelectionRange 0, $("site").value.length
    else
        $("master").focus()
    
###
000000000  000  00     00  00000000   0000000   000   000  000000000
   000     000  000   000  000       000   000  000   000     000   
   000     000  000000000  0000000   000   000  000   000     000   
   000     000  000 0 000  000       000   000  000   000     000   
   000     000  000   000  00000000   0000000    0000000      000   
###

timeoutInterval = undefined
timeoutInSeconds = 0
timeoutDelay = 0
timeoutLast = undefined

timeoutPercent = (pct) -> $('master-timeout')?.setStyle { width: pct+'%', left: (50-pct/2)+'%'}

timeoutTick = () ->
    now = Date.now()
    delta = (now - timeoutLast)/1000
    timeoutLast = now
    timeoutInSeconds -= delta
    pct = 100 * timeoutInSeconds / timeoutDelay
    timeoutPercent pct
    if timeoutInSeconds <= 0
        logOut()

startTimeout = (mins) ->
    timeoutDelay = mins*60
    stopTimeout()
    resetTimeout()
    if mins
        timeoutLast = Date.now()
        timeoutInterval = setInterval timeoutTick, 1000
    timeoutPercent mins and 100 or 0
    
stopTimeout = () ->
    if timeoutInterval
        clearInterval timeoutInterval
        timeoutInterval = undefined        
    timeoutPercent 0
    
resetTimeout = () ->
    timeoutInSeconds = timeoutDelay
    if timeoutInterval 
        timeoutPercent 100
    
logOut = ->
    stopTimeout()
    if not $('bubble')? then restoreBody()
    mstr = $('master').value
    setInput 'master', mstr
    $('master').focus()
    timeoutPercent 0
    hideSitePassword()
    hideSettings()
    stashLoaded = false
    masterFade()    
        
###
000   000  00000000  000   000  0000000     0000000   000   000  000   000
000  000   000        000 000   000   000  000   000  000 0 000  0000  000
0000000    0000000     00000    000   000  000   000  000000000  000 0 000
000  000   000          000     000   000  000   000  000   000  000  0000
000   000  00000000     000     0000000     0000000   00     00  000   000
###
            
onKeyDown = (event) ->
    key = keyname.ofEvent event
    e   = document.activeElement

    resetTimeout()
    
    switch key
        when stash_key    then return toggleStash()    
        when settings_key then return toggleSettings() 
        when prefs_key    then return togglePrefs()    
        when vault_key    then return toggleVault()   
        when 'command+w'  then event.preventDefault(); event.stopPropagation(); return 
        when 'command+t'  then return toggleStyle()
        when 'command+i'  then return toggleAbout()
        when 'esc' 
            if not $('bubble')?        then return restoreBody()
            if $('settings').visible() then return toggleSettings()

    if $('stashlist')? then return onStashKey event
    if $('vaultlist')? then return onVaultKey event
    if $('prefslist')? then return onPrefsKey event
            
    if not $('site')?
        # log 'no site?'
        return
        
    site = $('site').value
    hash = genHash(site+mstr)
    
    if e == $('password')
        switch key
            when 'command+backspace'
                if stash.configs[hash]?
                    if ask 'Forget <i>'+stash.configs[hash].pattern+'</i>', 'for <b>'+site+'</b>?'
                        delete stash.configs[hash]
                        say 'The <b>' + site + '</b>', '<i>pattern</i> is forgotten', 2000
                        writeStash()
                        masterSitePassword()
                return
            when 'left', 'right', 'up', 'down'
                $('site').focus()
                $('site').setSelectionRange 0, $('site').value.length
                event.preventDefault()
                return
                
    if e == $('master') and not $('master').value.length
        if key in ['backspace', 'enter']
            logOut()
            return
    
    btnames = ['stash', 'vault', 'prefs', 'about', 'help']
    if e.id in btnames
        switch key
            when 'left', 'up'
                $(btnames[btnames.indexOf(e.id)-1]).focus()
            when 'right', 'down'
                $(btnames[btnames.indexOf(e.id)+1]).focus()
        
    switch key
        when 'esc'
            if e == $('pattern') or $('settings').visible()
                if $('pattern').value != stash.pattern
                    setInput 'pattern', stash.pattern
                    patternChanged()
                    say()
            else
                $('pattern').value = stash.pattern
                patternChanged()
                win.hide() 
        when 'enter'
            switch e
                when $("master")   then masterConfirmed()
                when $("site")     then copyPassword()
                when $("password") then copyAndSavePattern()
                when $("pattern")  then patternConfirmed()

document.on 'keydown', onKeyDown

###
0000000     0000000   0000000    000   000
000   000  000   000  000   000   000 000 
0000000    000   000  000   000    00000  
000   000  000   000  000   000     000   
0000000     0000000   0000000       000   
###

saveBody = () ->
    resetTimeout()
    if not $('bubble')? then return
    savedFocus = document.activeElement.id
    savedSite  = $('site')?.value
    savedBody  = document.body.innerHTML
    
    window.restoreBody = (site) ->
        resetTimeout()
        document.body.innerHTML = savedBody
        initEvents()
        setInput 'pattern', stash.pattern
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
            if $('settings').visible()
                showSettings()
            if isEmpty(stash.configs) and savedFocus == 'stash'
                $('prefs').focus()

initBody = (name) ->
    saveBody()    
    lst = new Element 'div', class: 'list', id: name+'list'
    scroll = new Element 'div', class: 'scroll', id: name+'scroll'
    lst.insert scroll            
    lst.insert initButtons()
    document.body.update lst

###
0000000    000   000  000000000  000000000   0000000   000   000   0000000
000   000  000   000     000        000     000   000  0000  000  000     
0000000    000   000     000        000     000   000  000 0 000  0000000 
000   000  000   000     000        000     000   000  000  0000       000
0000000     0000000      000        000      0000000   000   000  0000000 
###

initInputBorder = (inp) ->
    inp.on 'focus',      (e) -> $(e.target.parentElement).addClassName 'focus'
    inp.on 'blur',       (e) -> $(e.target.parentElement).removeClassName 'focus'
    inp.on 'mouseenter', (e) -> $(e.target).focus()

initButtons = () ->

    buttons  = new Element 'div', class: 'buttons', id: 'buttons'
    
    for btn in [
        ['stash', 'database']         , 
        ['vault', 'archive']          , 
        ['prefs', 'cog']              , 
        ['about', 'info-circle']      , 
        ['help' , 'question-circle'] ]
        spn = new Element 'span'
        brd = new Element 'div', class: 'button-border border', id: btn[0]+'-border'
        inp = new Element 'input', type: 'button', class: 'button', id: btn[0]
        icn = new Element 'i', class: 'button-icon fa fa-'+btn[1]
        spn.insert brd
        brd.insert inp
        brd.insert icn
        buttons.insert spn
        initInputBorder inp
        inp.on 'click', onButton
        
    buttons    

onButton = (e) ->
    switch e.target.id
        when 'stash' then toggleStash()
        when 'vault' then toggleVault()
        when 'prefs' then togglePrefs()
        when 'about' then showAbout()
        when 'help'  then showHelp()

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
                # log jsonStr stash
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

onStashKey = (event) ->
    key = keyname.ofEvent event
    e   = document.activeElement
    switch key 
        when 'right', 'down' then e?.parentElement?.nextSibling?.firstElementChild?.focus()
        when 'left', 'up'    then e?.parentElement?.previousSibling?.firstElementChild?.focus()
        when 'command+backspace'
            if e?.id?.length
                if e.parentElement.nextSibling?
                    e.parentElement.nextSibling.firstElementChild.focus()
                else
                    e.parentElement.previousSibling?.firstElementChild?.focus()
                delete stash.configs[e.id]
                e.parentElement.remove()
                writeStash()
                if isEmpty stash.configs
                    restoreBody()
        when 'enter'
            restoreBody e?.nextSibling?.innerHTML

toggleStash = ->
    if $('stashlist')?
        restoreBody()
    else
        showStash()

showStash = () ->
    return if not stashLoaded
    return if isEmpty stash.configs
    
    initBody 'stash'    
        
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
            
        $('stashscroll').insert item
            
        item.on 'mouseenter', (e) -> e.target.childElements[0]?.focus()
        $(hash).on 'click',   (e) -> restoreBody e.target.nextSibling.innerHTML

        initInputBorder $(hash)
                    
    $('stashscroll').firstElementChild.firstElementChild.focus()
    
###
000   000   0000000   000   000  000      000000000
000   000  000   000  000   000  000         000   
 000 000   000000000  000   000  000         000   
   000     000   000  000   000  000         000   
    0      000   000   0000000   0000000     000   
###

onVaultKey = (event) ->
    key = keyname.ofEvent event
    e   = document.activeElement
    switch key 
        when 'command+n', 'control+n'  
            hash = uuid.v4()
            stash.vault[hash] = key: ""
            addVaultItem hash, stash.vault[hash].key
            $(hash).focus()
            toggleVaultItem hash
            editVaultKey hash
        when 'down'  then e?.parentElement?.nextSibling?.nextSibling?.firstElementChild?.focus()
        when 'up'    then e?.parentElement?.previousSibling?.previousSibling?.firstElementChild?.focus()
        when 'left'  then closeVaultItem  e?.id
        when 'right' then openVaultItem   e?.id
        when 'space' 
            if e?.id?
                toggleVaultItem e.id
                event.preventDefault()
        when 'command+backspace'
            if e?.id?.length
                if e.parentElement.nextSibling?.nextSibling?
                    e.parentElement.nextSibling.nextSibling.firstElementChild.focus()
                else
                    e.parentElement.previousSibling?.previousSibling?.firstElementChild?.focus()
                delete stash.vault[e.id]
                e.parentElement.nextSibling.remove()
                e.parentElement.remove()
                writeStash()

toggleVault = -> if $('vaultlist')? then restoreBody() else showVault()

adjustValue = (value) ->
    value.style.height = 'auto'
    value.style.height = value.scrollHeight+'px'
    if value.scrollHeight < 46
        value.style.height = '28px'

vaultValue     = (hash) -> $(hash).parentElement.nextSibling
vaultArrow     = (hash) -> $(hash).nextSibling
openVaultItem  = (hash) -> 
    vaultValue(hash).setStyle display: 'block'
    vaultArrow(hash).update '▼'
    vaultArrow(hash).addClassName 'open'
closeVaultItem = (hash) -> 
    vaultValue(hash).setStyle display: 'none'
    vaultArrow(hash).update '►'
    vaultArrow(hash).removeClassName 'open'
toggleVaultItem = (hash) ->
    if vaultValue(hash).getStyle('display') == 'none' then openVaultItem hash else closeVaultItem hash

saveVaultKey = (e) ->
    input = e.parentElement.select('.vault-key')[0]
    stash.vault[input.id].key = e.value
    input.value = stash.vault[input.id].key
    writeStash()

editVaultKey = (hash) ->
    border = $(hash).parentElement
    inp = new Element 'input', 
        class: 'vault-overlay vault-key'
        type:  'input'
        value: border.select('.vault-key')[0].value
    ipc.send 'disableToggle'
    
    inp.on 'keydown', (e) ->
        key = keyname.ofEvent e
        switch key
            when 'esc'
                input = e.target.parentElement.select('.vault-key')[0]
                e.target.value = input.value
                e.stopPropagation()
                input.focus()
            when 'enter'
                input = e.target.parentElement.select('.vault-key')[0]
                saveVaultKey e.target
                input.focus()
                e.stopPropagation()
                e.preventDefault()
            
    inp.on 'change', (e) -> saveVaultKey e.target
        
    inp.on 'blur', (e) -> 
        ipc.send 'enableToggle'
        e.target.remove()
        
    border.insert inp
    inp.focus()
    inp.setSelectionRange inp.value.length, inp.value.length

addVaultItem = (hash, vaultKey, vaultValue) ->
    item  = new Element 'div', 
        class: 'vault-item-border border'
    input = new Element 'input', 
        class: 'vault-item vault-key'
        type:  'button'
        id:    hash
        value: vaultKey
    arrow = new Element('div', class:'vault-arrow').update '►'
    item.insert input
    item.insert arrow
    $('vaultscroll').insert item
    value = new Element 'textarea',
        class: 'vault-value'
        wrap:  'off'
        rows:   1
    value.update vaultValue or ''
    $('vaultscroll').insert value
    adjustValue value
    value.setStyle display: 'none'

    initInputBorder input
    item.on  'mouseenter', (e) -> e.target.childElements[0]?.focus()
    arrow.on 'click',      (e) -> toggleVaultItem $(e.target).parentElement.firstElementChild.id
    input.on 'click',      (e) -> toggleVaultItem $(e.target).id
    input.on 'keydown',    (e) -> if keyname.ofEvent(e) == 'enter' then editVaultKey $(e.target).id
    value.on 'focus',      (e) -> 
        selToEnd = -> @selectionStart = @selectionEnd = @value.length
        setTimeout selToEnd.bind(e.target), 1
    value.on 'input',      (e) -> adjustValue e.target
    value.on 'change',     (e) -> 
        input = e.target.previousSibling.select('.vault-key')[0]
        stash.vault[input.id].value = e.target.value
        writeStash()

showVault = () ->
    return if not stashLoaded
    
    initBody 'vault'
    
    if not stash.vault? or isEmpty Object.keys(stash.vault)
        stash.vault = {} 
        stash.vault[uuid.v4()] = 
            key:   "title"
            value: "some secret"
        
    for vaultHash in Object.keys stash.vault
        addVaultItem vaultHash, stash.vault[vaultHash].key, stash.vault[vaultHash].value
            
    $('vaultscroll').firstElementChild.firstElementChild.focus()    
    
###
00000000   00000000   00000000  00000000   0000000
000   000  000   000  000       000       000     
00000000   0000000    0000000   000000    0000000 
000        000   000  000       000            000
000        000   000  00000000  000       0000000 
###

prefsFile = process.env.HOME+'/Library/Preferences/password-turtle.json'
prefs = 
    shortcut: { default: 'ctrl+`',    type: 'shortcut', text: 'global shortcut'         }
    timeout:  { default: 5,           type: 'int',      text: 'autoclose delay', min: 0 }
    mask:     { default: true,        type: 'bool',     text: 'mask locked passwords'   }
    confirm:  { default: true,        type: 'bool' ,    text: 'confirm changes'         }
    dark:     { default: true,        type: 'bool',     text: 'dark theme'              }
    sttgskey: { default: 'command+p', type: 'shortcut', text: 'pattern shortcut'        }
    stashkey: { default: 'command+l', type: 'shortcut', text: 'sites shortcut'          }
    vaultkey: { default: 'command+o', type: 'shortcut', text: 'vault shortcut'          }
    prefskey: { default: 'command+,', type: 'shortcut', text: 'preferences shortcut'    }

getPref = (key) -> loadPrefs()[key]
setPref = (key, value) -> 
    values = loadPrefs()
    values[key] = value
    savePrefs values

loadPrefs = () ->
    values = {}
    try
        values = JSON.parse fs.readFileSync(prefsFile, encoding:'utf8')
    catch        
        log 'can\'t load prefs file', prefsFile
    for key in Object.keys prefs
        if not values[key]?
            values[key] = prefs[key].default
    # log jsonStr values
    stash_key     = values['stashkey']
    prefs_key     = values['prefskey']
    vault_key     = values['vaultkey']
    settings_key  = values['sttgskey']
    values

savePrefs = (values) ->
    fs.writeFileSync prefsFile, jsonStr(values), encoding:'utf8'

togglePrefs = ->
    if $('prefslist')?
        restoreBody()
    else
        showPrefs()

showPrefs = () ->
    return if not stashLoaded
    
    initBody 'prefs'
    
    values = loadPrefs()
    for key in Object.keys prefs
        pref = prefs[key]
        value = values[key]
        item  = new Element 'div', class: 'pref-item-border border'
        input = new Element 'input', id: key, type: 'button', class: 'pref-item'
        item.insert input
        item.insert (new Element 'span', class: 'pref').update pref.text
        switch pref.type
            when 'bool'
                bool = new Element 'span', class: 'bool'
                item.insert bool
                setBool bool, value
            when 'int'
                item.insert (new Element 'span', class: 'int').update value and value+' min' or 'never'
            when 'shortcut'
                item.insert (new Element 'span', class: 'shortcut').update value
            
        $('prefsscroll').insert item

        initInputBorder input
        input.on 'click',      (e) -> 
            key = e.target.id
            pref = prefs[key]
            switch pref?.type
                when 'bool'
                    values[key] = not values[key]
                    bool = e.target.parentElement.select('.bool')[0]
                    setBool bool, values[key]
                    savePrefs values
                    if key == 'dark'
                        toggleStyle()
                when 'int'
                    
                    # 000  000   000  000000000
                    # 000  0000  000     000   
                    # 000  000 0 000     000   
                    # 000  000  0000     000   
                    # 000  000   000     000   
                    
                    inputChanged = (e) -> 
                        input    = e.target.parentElement.select('input.pref-item')[0]
                        prefKey  = input.id                        
                        intValue = parseInt e.target.value
                        intValue = 0 if isNaN intValue
                        intValue = Math.max(prefs[prefKey].min, intValue) if prefs[prefKey].min? and intValue
                        e.target.parentElement.select('.int')[0].update(intValue and intValue+' min' or 'never')
                        setPref prefKey, intValue
                        if prefKey == 'timeout'
                            startTimeout intValue
                        e.preventDefault()
                        input.focus()

                    border = e.target.parentElement
                    intValue = parseInt e.target.parentElement.select('.int')[0].innerHTML
                    intValue = 0 if isNaN intValue
                    inp = new Element 'input', 
                        class: 'pref-overlay int'
                        type:  'input'
                        value: intValue
                    ipc.send 'disableToggle'                        
                    inp.on 'blur', (e) -> 
                        ipc.send 'enableToggle'
                        e.target.remove()
                    inp.on 'change', inputChanged
                    inp.on 'keydown', (e) ->
                        key = keyname.ofEvent e
                        e.stopPropagation()
                        if '+' not in key
                            switch key
                                when 'esc'
                                    e.target.value = e.target.parentElement.select('.int')[0]
                                    e.preventDefault()
                                    e.target.parentElement.select('input')[0].focus()
                                when 'up', 'down'
                                    prefKey = e.target.parentElement.select('input')[0].id
                                    inc = prefs[prefKey].inc or 1
                                    newValue = parseInt(e.target.value) + (key == 'up' and inc or -inc)
                                    newValue = Math.max(newValue, prefs[prefKey].min) if prefs[prefKey].min?
                                    e.target.value = newValue
                                    e.preventDefault()
                                when 'enter'
                                    inputChanged e
                                when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'enter', 'backspace', 'left', 'right', 'tab'
                                    1
                                else
                                    e.preventDefault()
                                
                    border.insert inp
                    inp.focus()
                when 'shortcut'
                    
                    #  0000000  000   000   0000000   00000000   000000000   0000000  000   000  000000000
                    # 000       000   000  000   000  000   000     000     000       000   000     000   
                    # 0000000   000000000  000   000  0000000       000     000       000   000     000   
                    #      000  000   000  000   000  000   000     000     000       000   000     000   
                    # 0000000   000   000   0000000   000   000     000      0000000   0000000      000   
                    
                    border = e.target.parentElement
                    msg = new Element 'input', 
                        class: 'pref-overlay shortcut'
                        type:  'button'
                        value: 'press the shortcut'
                    ipc.send 'disableToggle'
                    msg.on 'keydown', (e) ->
                        key = keyname.ofEvent e
                        input = e.target.parentElement.select('input')[0]
                        if (e.metaKey or e.ctrlKey or e.altKey) and key.indexOf('+')>=0
                            e.preventDefault()
                            e.stopPropagation()
                            e.target.parentElement.select('.shortcut')[0].update key
                            prefKey = input.id
                            setPref prefKey, key
                            switch prefKey
                                when 'shortcut'
                                    ipc.send 'globalShortcut', key
                                when 'stashkey' then stash_key = key
                                when 'vaultkey' then vault_key = key
                                when 'prefskey' then prefs_key = key
                                when 'sttgskey' then settings_key = key
                            
                            input.focus()
                        else if not keyname.isModifier(key) and key != ''
                            switch key
                                when 'esc', 'enter', 'tab'
                                    e.preventDefault()
                                    e.stopPropagation()
                                    input.focus()
                                when 'backspace'
                                    e.target.parentElement.select('.shortcut')[0].update ''
                                    setPref prefKey, ''
                                    input.focus()                                
                                else
                                    e.target.value = 'no modifier'
                                    event.stopPropagation()
                        else
                            e.target.value = keyname.modifiersOfEvent e
                    msg.on 'blur', (e) -> 
                        ipc.send 'enableToggle'
                        e.target.remove()
                    border.insert msg
                    msg.focus()
            
    $('prefsscroll').firstElementChild.firstElementChild.focus()
    
onPrefsKey = (e) ->
    key  = keyname.ofEvent e
    elem = document.activeElement
    if elem?
        switch key 
            when 'right', 'down'
                ($(elem.parentElement?.nextSibling?.firstElementChild.id).select('input')?[0] or 
                elem.parentElement?.nextSibling?.firstElementChild).focus()
            when 'left', 'up'
                if elem.id == 'ok'
                    elem.parentElement.parentElement.previousSibling.select('input')[0].focus()
                else
                    elem.parentElement?.previousSibling?.firstElementChild?.focus()
                    
###
 0000000   0000000     0000000   000   000  000000000
000   000  000   000  000   000  000   000     000   
000000000  0000000    000   000  000   000     000   
000   000  000   000  000   000  000   000     000   
000   000  0000000     0000000    0000000      000   
###

toggleAbout = () ->
    if $('about-github')
        restoreBody()
    else
        showAbout()
    
showAbout = () ->
    saveBody()
    version = '::package.json:version::'
    document.body.innerHTML = '<div id="about"><h1 id="title">password-turtle</h1><sub>version %s</sub>'.fmt version
    githubIcon = new Element 'div', { id: 'about-github' }
    githubIcon.insert '<svg viewbox="0 0 16 16" width="80px" height="80px" class="kitty-svg"><path class="github-svg" d="M7.999,0.431c-4.285,0-7.76,3.474-7.76,7.761 c0,3.428,2.223,6.337,5.307,7.363c0.388,0.071,0.53-0.168,0.53-0.374c0-0.184-0.007-0.672-0.01-1.32 c-2.159,0.469-2.614-1.04-2.614-1.04c-0.353-0.896-0.862-1.135-0.862-1.135c-0.705-0.481,0.053-0.472,0.053-0.472 c0.779,0.055,1.189,0.8,1.189,0.8c0.692,1.186,1.816,0.843,2.258,0.645c0.071-0.502,0.271-0.843,0.493-1.037 C4.86,11.425,3.049,10.76,3.049,7.786c0-0.847,0.302-1.54,0.799-2.082C3.768,5.507,3.501,4.718,3.924,3.65 c0,0,0.652-0.209,2.134,0.796C6.677,4.273,7.34,4.187,8,4.184c0.659,0.003,1.323,0.089,1.943,0.261 c1.482-1.004,2.132-0.796,2.132-0.796c0.423,1.068,0.157,1.857,0.077,2.054c0.497,0.542,0.798,1.235,0.798,2.082 c0,2.981-1.814,3.637-3.543,3.829c0.279,0.24,0.527,0.713,0.527,1.437c0,1.037-0.01,1.874-0.01,2.129 c0,0.208,0.14,0.449,0.534,0.373c3.081-1.028,5.302-3.935,5.302-7.362C15.76,3.906,12.285,0.431,7.999,0.431z"/></svg>'
    $('about').insert githubIcon
    $('about-github').on 'click', () -> open "https://github.com/monsterkodi/password-turtle"
    $('title').on 'click', () -> restoreBody()
    $('about').insert '<h2>credits</h2>'
    addLink = (text, url) ->
        link = new Element 'div', { class: 'link', id: text } 
        link.url = url
        link.insert text
        $('about').insert link
        link.on 'click', (e) ->open e.target.url
        
    addLink 'electron',     'http://electron.atom.io/'
    addLink 'coffeescript', 'http://coffeescript.org/'
    addLink 'stylus',       'http://learnboost.github.io/stylus/'
    addLink 'atom',         'https://atom.io/'
    addLink 'node',         'http://nodejs.org/'
    addLink 'grunt',        'http://gruntjs.com/'
    addLink 'lodash',       'https://lodash.com/'
    addLink 'fontawesome',  'https://fortawesome.github.io/Font-Awesome/'

###
000   000  00000000  000      00000000 
000   000  000       000      000   000
000000000  0000000   000      00000000 
000   000  000       000      000      
000   000  00000000  0000000  000      
###

openUrl  = (url) -> open url
showHelp = ()    -> open "https://github.com/monsterkodi/password-turtle"
    
###
 0000000  000  000000000  00000000
000       000     000     000     
0000000   000     000     0000000 
     000  000     000     000     
0000000   000     000     00000000
###

setSite = (site) ->
    setInput 'site', site
    siteChanged()
    
siteChanged = ->
    if $("site").value.length == 0
        hideLock()
    masterSitePassword()

updateSiteFromClipboard = () ->    
    if domain = extractDomain clipboard.readText()
        setSite domain 

makePassword = (hash, config) -> password.make hash, config.pattern
            
showPassword = (config) ->
    url  = decrypt config.url, mstr
    pass = currentPassword = makePassword genHash(url+mstr), config
    if hasLock() and getPref 'mask'
        pass = pad '', currentPassword.length, '●'
    setInput 'password', pass 
    
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
        
    showPassword config
    
###
 0000000  00000000  000000000  000000000  000  000   000   0000000    0000000
000       000          000        000     000  0000  000  000        000     
0000000   0000000      000        000     000  000 0 000  000  0000  0000000 
     000  000          000        000     000  000  0000  000   000       000
0000000   00000000     000        000     000  000   000   0000000   0000000 
###

toggleSettings = ->
    resetTimeout()
    if not $('bubble')?
        restoreBody()
        if not $('settings').visible()
            hideSitePassword()
            showSettings()
    else if stashLoaded
        if  $('settings').visible()
            hideSettings()
            showSitePassword()
        else
            hideSitePassword()
            showSettings()

showSettings = ->
    $('buttons')?.remove()
    updateFloppy()
    $('settings').insert initButtons()
    $('settings').show()    
    $('pattern').focus()
    updateStashButton()    
    
hideSettings = ->
    $('settings').hide()
    $('buttons')?.remove()
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
    return if not $('site-border')?
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

hasLock = ->
    $('lock').hasClassName('open') or $('lock').hasClassName('closed')

hideLock = -> 
    $('lock').removeClassName 'open'
    $('lock').removeClassName 'closed'
    
lockClosed = (e) -> 
    e.innerHTML = '<span><i class="fa fa-lock fa-lg"></i></span>'
    e.removeClassName 'open'
    e.addClassName 'closed'

lockOpen = (e) ->        
    e.innerHTML = '<span><i class="fa fa-unlock fa-lg"></i></span>'
    e.removeClassName 'closed'
    e.addClassName 'open'    

setBool = (e, b) -> 
    e.innerHTML = b and '<i class="fa fa-check fa-lg"></i>' or '<i class="fa fa-times fa-lg"></i>'
    e.removeClassName b and 'bool-false' or 'bool-true'
    e.addClassName b and 'bool-true' or 'bool-false'
            
updateFloppy = ->
    if floppy = $('floppy')
        if stash?.pattern != $("pattern").value or stash?.pattern == ''
            floppy.removeClassName 'saved'
        else
            floppy.addClassName 'saved'

updateStashButton = ->        
    if isEmpty stash.configs
        $('stash')?.disabled = true
        $('stash-border')?.addClassName 'disabled'
    else 
        $('stash')?.disabled = false
        $('stash-border')?.removeClassName 'disabled'
        
###
 0000000  000000000  000   000  000      00000000
000          000      000 000   000      000     
0000000      000       00000    000      0000000 
     000     000        000     000      000     
0000000      000        000     0000000  00000000
###

toggleStyle = ->
    link = $('style-link')
    currentScheme = link.href.split('/').last()
    schemes = ['turtle-dark.css', 'turtle-bright.css']
    nextSchemeIndex = ( schemes.indexOf(currentScheme) + 1) % schemes.length
    newlink = new Element 'link', 
        rel:  'stylesheet'
        type: 'text/css'
        href: 'style/'+schemes[nextSchemeIndex]
        id:   'style-link'

    link.parentNode.replaceChild newlink, link
        
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

say = () -> 
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
        $('say').innerHTML = args.join "<br>"

ask = ->
    if getPref('confirm')
        if not $('say').innerHTML.endsWith(arguments[arguments.length-1])
            say.apply say, arguments
            $('bubble').className = "ask"
            return false
    true

module.exports = true
