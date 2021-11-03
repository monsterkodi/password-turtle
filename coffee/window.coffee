###
000   000  000  000   000  0000000     0000000   000   000
000 0 000  000  0000  000  000   000  000   000  000 0 000
000000000  000  000 0 000  000   000  000   000  000000000
000   000  000  000  0000  000   000  000   000  000   000
00     00  000  000   000  0000000     0000000   00     00
###

{ $, _, about, elem, empty, fs, keyinfo, last, open, post, prefs, slash, stash, stopEvent } = require 'kxk'

_url      = require './js/tools/urltools'
password  = require './js/tools/password'
cryptools = require './js/tools/cryptools'
uuid      = require 'uuid'
electron  = require 'electron'

ipc       = electron.ipcRenderer
clipboard = electron.clipboard

random    = _.random
trim      = _.trim
pad       = _.pad
isNaN     = _.isNaN

genHash       = cryptools.genHash
encrypt       = cryptools.encrypt
decrypt       = cryptools.decrypt
decryptFile   = cryptools.decryptFile
extractSite   = _url.extractSite
extractDomain = _url.extractDomain
containsLink  = _url.containsLink
jsonStr       = (a) -> JSON.stringify a, null, " "

mstr          = undefined
stashFile     = slash.join post.get('userData'), "password-turtle.stash"
stash         = undefined
stashExists   = false
stashLoaded   = false
currentPassword = undefined

prefs.init()

resetStash = ->
    stashLoaded = false
    clearInput 'site'
    clearInput 'password'
    clearInput 'pattern'
    updateFloppy()
    stash =
        pattern: ''
        configs: {}

setWinSize = (w,h) -> electron.ipcRenderer.send 'setWinSize' w, h
getWinSize =       -> electron.ipcRenderer.sendSync 'getWinSize'
        
###
 0000000   000   000  000  00     00
000   000  0000  000  000  000   000
000000000  000 0 000  000  000000000
000   000  000  0000  000  000 0 000
000   000  000   000  000  000   000
###

masterStart = ->

    startTimeout prefs.get 'timeout' 5    
    if stashExists
        $('turtle').disabled = false
        updateSiteFromClipboard()
        showSitePassword()
        masterSitePassword()
    else
        showSettings()
        $('buttons').style.display = 'none'

masterAnim = ->
    master =$ 'master'
    master.value = ''
    setWinSize 364 491
    setTimeout masterStart, 10
    
masterFade = ->
    $('turtle').disabled = true
    setWinSize 364 360

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
                    masterAnim()
                    $('master-timeout')?.style.width = '100%'
                    $('master-timeout')?.style.left = '0%'
                else
                    whisper ['oops?', 'what?', '...?', 'nope!'][random 3], 2000
        else
            say ['Well chosen!', 'Nice one!', 'Good choice!'][random 2],
                'And your <span class="open" onclick="openUrl(\'http://github.com\');">password pattern?</span>'
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
    for input in document.querySelectorAll('input')
        input.addEventListener 'focus', (e) -> $(e.target.id+'-border')?.classList.add 'focus'
        input.addEventListener 'blur',  (e) -> $(e.target.id+'-border')?.classList.remove 'focus'
        input.addEventListener 'input', (e) ->
            $(e.target.id+'-ghost').style.opacity = if e.target.value.length then 0 else 1
        if input.id != 'master'
            input.addEventListener 'mouseenter', (e) ->
                $(e.target).focus()

    for border in document.querySelectorAll('.border')
        if border.id != 'master-border'
            border.addEventListener 'mouseenter', (e) ->
                $(e.target.id.substr(0,e.target.id.length-7)).focus()

    $('master'  ).addEventListener 'input', masterChanged
    $('site'    ).addEventListener 'input', siteChanged
    $('pattern' ).addEventListener 'input', patternChanged
    $('turtle'  ).addEventListener 'click', toggleSettings
    $('password').addEventListener 'mousedown', copyPassword
    $('turtle'  ).addEventListener 'mouseenter', (e) -> $('turtle').focus()

###
000       0000000    0000000   0000000    00000000  0000000
000      000   000  000   000  000   000  000       000   000
000      000   000  000000000  000   000  0000000   000   000
000      000   000  000   000  000   000  000       000   000
0000000   0000000   000   000  0000000    00000000  0000000
###

window.onload = ->

    initEvents()
    toggleStyle() if not prefs.get 'dark', true

    $("master").blur()
    $("master").focus()
    
    hideSitePassword()
    hideSettings()
    resetStash()
    stashExists = fs.existsSync stashFile
    if not stashExists
        masterChanged()
        
window.onclose = (event) ->

    prefs.save()

window.onfocus = (event) ->

    resetTimeout()
    if stashLoaded
        updateSiteFromClipboard()
        $("site")?.focus()
        $("site")?.select()
    else
        $("master")?.focus()

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

timeoutPercent = (pct) ->
    if mto = $('master-timeout')
        mto.style.width = pct+'%'
        mto.style.left = (50-pct/2)+'%'

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

    { mod, key, combo, char } = keyinfo.forEvent event

    resetTimeout()

    switch combo
        when 'command+w' 'ctrl+w' 'command+h', 'ctrl+h' then return electron.ipcRenderer.send 'hide'
        when 'command+q' 'ctrl+q'  then return electron.ipcRenderer.send 'quit'
        when 'command+.' 'ctrl+.'  then return toggleAbout()
        when 'alt+i' 'ctrl+i'      then return toggleStyle()
        when 'esc'
            if not $('bubble')? then return restoreBody()
            else if $('settings').style.display != 'none' then return toggleSettings()
            else return electron.ipcRenderer.send 'hide'

    if $('stashlist')? then return onStashKey event
    if $('vaultlist')? then return onVaultKey event
    if $('prefslist')? then return onPrefsKey event
    if not $('site')?  then return

    site = $('site').value
    hash = genHash(site+mstr)

    e = document.activeElement
    if e == $('password')
        switch combo
            when 'command+backspace' 'ctrl+backspace'
                if stash.configs[hash]?
                    if ask 'Forget <i>'+stash.configs[hash].pattern+'</i>', 'for <b>'+site+'</b>?'
                        delete stash.configs[hash]
                        say 'The <b>' + site + '</b>', '<i>pattern</i> is forgotten', 2000
                        writeStash()
                        masterSitePassword()
                return
            when 'left' 'right' 'up' 'down'
                $('site').focus()
                $('site').setSelectionRange 0, $('site').value.length
                event.preventDefault()
                return

    if e == $('master') and not $('master').value.length
        if key in ['backspace' 'enter']
            logOut()
            return

    btnames = ['stash' 'vault' 'prefs' 'about' 'help']
    if e.id in btnames
        switch key
            when 'left' 'up'    then $(btnames[btnames.indexOf(e.id)-1]).focus()
            when 'right' 'down' then $(btnames[btnames.indexOf(e.id)+1]).focus()

    switch key
        # when 'esc'
            # if e == $('pattern') or $('settings').style.display != 'none'
                # if $('pattern').value != stash.pattern
                    # setInput 'pattern', stash.pattern
                    # patternChanged()
                    # say()
            # else
                # $('pattern').value = stash.pattern
                # patternChanged()
                # win.hide()
        when 'enter'
            switch e
                when $("master")   then masterConfirmed()
                when $("site")     then copyPassword()
                when $("password") then copyAndSavePattern()
                when $("pattern")  then patternConfirmed()

document.addEventListener 'keydown', onKeyDown

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
            if $('settings').style.display != 'none'
                showSettings()
            if empty(stash.configs) and savedFocus == 'stash'
                $('prefs').focus()

initBody = (name) ->

    saveBody()
    lst = elem class: 'list', id: name+'list'
    scroll = elem class: 'scroll', id: name+'scroll'
    lst.appendChild scroll
    lst.appendChild initButtons()
    document.body.innerHTML = ''
    document.body.appendChild lst

###
0000000    000   000  000000000  000000000   0000000   000   000   0000000
000   000  000   000     000        000     000   000  0000  000  000
0000000    000   000     000        000     000   000  000 0 000  0000000
000   000  000   000     000        000     000   000  000  0000       000
0000000     0000000      000        000      0000000   000   000  0000000
###

initInputBorder = (inp) ->
    inp.addEventListener 'focus',      (e) -> $(e.target.parentElement).classList.add 'focus'
    inp.addEventListener 'blur',       (e) -> $(e.target.parentElement).classList.remove 'focus'
    inp.addEventListener 'mouseenter', (e) -> $(e.target).focus()

initButtons = () ->

    buttons  = elem class: 'buttons', id: 'buttons'

    for btn in [
        ['stash', 'database']         ,
        ['vault', 'archive']          ,
        ['prefs', 'cog']              ,
        ['about', 'info-circle']      ,
        ['help' , 'question-circle'] ]
        spn = elem 'span'
        brd = elem class: 'button-border border', id: btn[0]+'-border'
        inp = elem 'input', type: 'button', class: 'button', id: btn[0]
        icn = elem 'i', class: 'button-icon fa fa-'+btn[1]
        spn.appendChild brd
        brd.appendChild inp
        brd.appendChild icn
        buttons.appendChild spn
        initInputBorder inp
        inp.addEventListener 'click', onButton

    buttons

onButton = (event) ->
    switch event.target.id
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

    { mod, key, combo, char} = keyinfo.forEvent event

    e = document.activeElement
    switch combo
        when 'right', 'down' then e?.parentElement?.nextSibling?.firstChild?.focus()
        when 'left', 'up'    then e?.parentElement?.previousSibling?.firstChild?.focus()
        when 'command+backspace', 'ctrl+backspace'
            if e?.id?.length
                if e.parentElement.nextSibling?
                    e.parentElement.nextSibling.firstChild.focus()
                else
                    e.parentElement.previousSibling?.firstChild?.focus()
                delete stash.configs[e.id]
                e.parentElement.remove()
                writeStash()
                if empty stash.configs
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
    return if empty stash.configs

    initBody 'stash'

    for hash in Object.keys stash.configs
        config = stash.configs[hash]
        site = decrypt config.url, mstr
        item =            elem class: 'stash-item-border border'
        item.appendChild  elem 'input', id: hash, type: 'button', class: 'stash-item'
        siteSpan = item.appendChild elem 'span', class: 'site', text:site
        lock = elem 'span', class: 'lock'
        item.appendChild lock
        if config.pattern == stash.pattern
            lockClosed lock
        else
            lockOpen lock
            item.appendChild elem 'span', class:'pattern', text:config.pattern

        $('stashscroll').appendChild item

        item.addEventListener 'mouseenter', (event) -> event.target.firstChild?.focus()
        $(hash).addEventListener 'click',   (event) -> restoreBody event.target.nextSibling.innerHTML

        initInputBorder $(hash)

    $('stashscroll').firstChild.firstChild.focus()

###
000   000   0000000   000   000  000      000000000
000   000  000   000  000   000  000         000
 000 000   000000000  000   000  000         000
   000     000   000  000   000  000         000
    0      000   000   0000000   0000000     000
###

onVaultKey = (event) ->

    { mod, key, combo, char } = keyinfo.forEvent event

    e = document.activeElement

    switch combo
        when 'command+n', 'ctrl+n'
            hash = uuid.v4()
            stash.vault[hash] = key: ""
            addVaultItem hash, stash.vault[hash].key
            $(hash).focus()
            toggleVaultItem hash
            editVaultKey hash
        when 'down'  then e?.parentElement?.nextSibling?.nextSibling?.firstChild?.focus()
        when 'up'    then e?.parentElement?.previousSibling?.previousSibling?.firstChild?.focus()
        when 'left'  then closeVaultItem  e?.id
        when 'right' then openVaultItem   e?.id
        when 'space'
            if e?.id?
                toggleVaultItem e.id
                event.preventDefault()
        when 'command+backspace', 'ctrl+backspace'
            if e?.id?.length
                if e.parentElement.nextSibling?.nextSibling?
                    e.parentElement.nextSibling.nextSibling.firstChild.focus()
                else
                    e.parentElement.previousSibling?.previousSibling?.firstChild?.focus()
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
    vaultValue(hash).style.display = 'block'
    vaultArrow(hash).innerHTML = '▼'
    vaultArrow(hash).classList.add 'open'
closeVaultItem = (hash) ->
    vaultValue(hash).style.display = 'none'
    vaultArrow(hash).innerHTML = '►'
    vaultArrow(hash).classList.remove 'open'
toggleVaultItem = (hash) ->
    if vaultValue(hash).style.display == 'none' then openVaultItem hash else closeVaultItem hash

saveVaultKey = (event) ->
    input = $('.vault-key', event.parentElement)
    stash.vault[input.id].key = event.value
    input.value = stash.vault[input.id].key
    writeStash()

editVaultKey = (hash) ->
    border = $(hash).parentElement
    inp = elem 'input',
        class: 'vault-overlay vault-key'
        type:  'input'
        value: $('.vault-key', border).value
    ipc.send 'disableToggle'

    inp.addEventListener 'keydown', (event) ->
        key = keyinfo.keynameForEvent event
        switch key
            when 'esc'
                input = $('.vault-key', event.target.parentElement)
                event.target.value = input.value
                event.stopPropagation()
                input.focus()
            when 'enter'
                input = $('.vault-key', event.target.parentElement)
                saveVaultKey event.target
                input.focus()
                stopEvent event

    inp.addEventListener 'change', (event) -> saveVaultKey event.target

    inp.addEventListener 'blur', (event) ->
        ipc.send 'enableToggle'
        event.target.remove()

    border.appendChild inp
    inp.focus()
    inp.setSelectionRange inp.value.length, inp.value.length

addVaultItem = (hash, vaultKey, vaultValue) ->
    item  = elem class: 'vault-item-border border'
    input = elem 'input',
        class: 'vault-item vault-key'
        type:  'button'
        id:    hash
        value: vaultKey
    arrow = elem class:'vault-arrow', text:'►'
    item.appendChild input
    item.appendChild arrow
    $('vaultscroll').appendChild item
    value = elem 'textarea',
        class: 'vault-value'
        wrap:  'off'
        rows:   1
    value.innerHTML = vaultValue or ''
    $('vaultscroll').appendChild value
    adjustValue value
    value.style.display = 'none'

    initInputBorder input
    item.addEventListener  'mouseenter', (e) -> e.target.firstChild?.focus()
    arrow.addEventListener 'click',      (e) -> toggleVaultItem $(e.target).parentElement.firstChild.id
    input.addEventListener 'click',      (e) -> toggleVaultItem $(e.target).id
    input.addEventListener 'keydown',    (e) -> if keyinfo.keynameForEvent(e) == 'enter' then editVaultKey $(e.target).id
    value.addEventListener 'focus',      (e) ->
        selToEnd = -> @selectionStart = @selectionEnd = @value.length
        setTimeout selToEnd.bind(e.target), 1
    value.addEventListener 'input',      (e) -> adjustValue e.target
    value.addEventListener 'change',     (e) ->
        input = $('.vault-key', e.target.previousSibling)
        stash.vault[input.id].value = e.target.value
        writeStash()

showVault = () ->
    return if not stashLoaded

    initBody 'vault'

    if not stash.vault? or empty Object.keys(stash.vault)
        stash.vault = {}
        stash.vault[uuid.v4()] =
            key:   "title"
            value: "some secret"

    for vaultHash in Object.keys stash.vault
        addVaultItem vaultHash, stash.vault[vaultHash].key, stash.vault[vaultHash].value

    $('vaultscroll').firstChild.firstChild.focus()

###
00000000   00000000   00000000  00000000   0000000
000   000  000   000  000       000       000
00000000   0000000    0000000   000000    0000000
000        000   000  000       000            000
000        000   000  00000000  000       0000000
###

prefInfo =
    shortcut: { type: 'shortcut', text: 'global shortcut'         }
    timeout:  { type: 'int',      text: 'autoclose delay', min: 0 }
    mask:     { type: 'bool',     text: 'mask locked passwords'   }
    confirm:  { type: 'bool' ,    text: 'confirm changes'         }
    dark:     { type: 'bool',     text: 'dark theme'              }

togglePrefs = ->
    if $('prefslist')?
        restoreBody()
    else
        showPrefs()

showPrefs = () ->
    return if not stashLoaded

    initBody 'prefs'

    for key, pref of prefInfo
        value = prefs.get key
        item  = elem class: 'pref-item-border border'
        input = elem 'input', id: key, type: 'button', class: 'pref-item'
        item.appendChild input
        item.appendChild elem 'span', class: 'pref', text: pref.text
        switch pref.type
            when 'bool'
                bool = elem 'span', class: 'bool'
                item.appendChild bool
                setBool bool, value
            when 'int'
                item.appendChild elem 'span', class: 'int', text: value and value+' min' or 'never'
            when 'shortcut'
                item.appendChild elem 'span', class: 'shortcut', text: value

        $('prefsscroll').appendChild item

        initInputBorder input
        input.addEventListener 'click', (event) ->
            key = event.target.id
            pref = prefInfo[key]
            switch pref?.type
                when 'bool'
                    prefs.set key, not prefs.get key
                    bool = $('.bool', event.target.parentElement)
                    setBool bool, prefs.get key
                    if key == 'dark'
                        toggleStyle()
                when 'int'

                    # 000  000   000  000000000
                    # 000  0000  000     000
                    # 000  000 0 000     000
                    # 000  000  0000     000
                    # 000  000   000     000

                    inputChanged = (event) ->
                        input    = $('input.pref-item', event.target.parentElement)
                        prefKey  = input.id
                        intValue = parseInt event.target.value
                        intValue = 0 if isNaN intValue
                        intValue = Math.max(prefInfo[prefKey].min, intValue) if prefInfo[prefKey].min? and intValue
                        $('.int', event.target.parentElement).innerHTML = intValue and intValue+' min' or 'never'
                        prefs.set prefKey, intValue
                        if prefKey == 'timeout'
                            startTimeout intValue
                        event.preventDefault()
                        input.focus()

                    border = event.target.parentElement
                    intValue = parseInt $('.int', event.target.parentElement).innerHTML
                    intValue = 0 if isNaN intValue
                    inp = elem 'input', class: 'pref-overlay int', value: intValue
                    ipc.send 'disableToggle'
                    inp.addEventListener 'blur', (event) ->
                        ipc.send 'enableToggle'
                        event.target.remove()
                    inp.addEventListener 'change', inputChanged
                    inp.addEventListener 'keydown', (event) ->
                        key = keyinfo.keynameForEvent event
                        event.stopPropagation()
                        if '+' not in key
                            switch key
                                when 'esc'
                                    event.target.value = $('.int', event.target.parentElement)
                                    event.preventDefault()
                                    $('input', event.target.parentElement).focus()
                                when 'up', 'down'
                                    prefKey = $('input', event.target.parentElement).id
                                    inc = prefInfo[prefKey].inc or 1
                                    newValue = parseInt(event.target.value) + (key == 'up' and inc or -inc)
                                    newValue = Math.max(newValue, prefInfo[prefKey].min) if prefInfo[prefKey].min?
                                    event.target.value = newValue
                                    event.preventDefault()
                                when 'enter'
                                    inputChanged event
                                when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'enter', 'backspace', 'left', 'right', 'tab'
                                    1
                                else
                                    event.preventDefault()

                    border.appendChild inp
                    inp.focus()

                when 'shortcut'

                    #  0000000  000   000   0000000   00000000   000000000   0000000  000   000  000000000
                    # 000       000   000  000   000  000   000     000     000       000   000     000
                    # 0000000   000000000  000   000  0000000       000     000       000   000     000
                    #      000  000   000  000   000  000   000     000     000       000   000     000
                    # 0000000   000   000   0000000   000   000     000      0000000   0000000      000

                    border = event.target.parentElement
                    msg = elem 'input',
                        class: 'pref-overlay shortcut'
                        type:  'button'
                        value: 'press the shortcut'
                    ipc.send 'disableToggle'

                    msg.addEventListener 'keydown', (event) ->

                        { mod, key, combo } = keyinfo.forEvent event
                        
                        input = $('input', event.target.parentElement)
                        
                        if combo.indexOf('+') >= 0 and key != ''
                            stopEvent event
                            $('.shortcut', event.target.parentElement).innerHTML = combo
                            prefKey = input.id
                            prefs.set prefKey, combo
                            if prefKey == 'shortcut'
                                ipc.send 'globalShortcut', combo
                            input.focus()
                        else if not keyinfo.isModifier(key) and key != ''
                            switch key
                                when 'esc', 'enter', 'tab'
                                    stopEvent event
                                    input.focus()
                                when 'backspace'
                                    $('.shortcut', event.target.parentElement).innerHTML = ''
                                    prefs.set prefKey, ''
                                    input.focus()
                                else
                                    event.target.value = 'no modifier'
                                    event.stopPropagation()
                        else
                            event.target.value = keyinfo.modifiersForEvent event
                            
                    msg.addEventListener 'blur', (event) ->
                        ipc.send 'enableToggle'
                        event.target.remove()
                        
                    border.appendChild msg
                    msg.focus()

    $('prefsscroll').firstChild.firstChild.focus()

onPrefsKey = (event) ->

    key  = keyinfo.keynameForEvent event
    if active = document.activeElement
        switch key
            when 'right', 'down'
                ($('input', $(active.parentElement?.nextSibling?.firstChild.id))? or
                active.parentElement?.nextSibling?.firstChild).focus()
            when 'left', 'up'
                if active.id == 'ok'
                    $('input', active.parentElement.parentElement.previousSibling).focus()
                else
                    active.parentElement?.previousSibling?.firstChild?.focus()

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
    version = require(__dirname+'/package.json').version
    
    document.body.innerHTML = ""
    about = elem id:'info'
    about.innerHTML = "<h1 id=\"title\">password-turtle</h1><sub>version #{version}</sub>"
    document.body.appendChild about
    githubIcon = elem id:'aboutGithub'
    githubLink = elem id:'githubLink'
    about.appendChild githubLink
    githubLink.appendChild githubIcon
    githubIcon.innerHTML = '<svg viewbox="0 0 16 16" width="80px" height="80px" class="kitty-svg"><path class="github-svg" d="M7.999,0.431c-4.285,0-7.76,3.474-7.76,7.761 c0,3.428,2.223,6.337,5.307,7.363c0.388,0.071,0.53-0.168,0.53-0.374c0-0.184-0.007-0.672-0.01-1.32 c-2.159,0.469-2.614-1.04-2.614-1.04c-0.353-0.896-0.862-1.135-0.862-1.135c-0.705-0.481,0.053-0.472,0.053-0.472 c0.779,0.055,1.189,0.8,1.189,0.8c0.692,1.186,1.816,0.843,2.258,0.645c0.071-0.502,0.271-0.843,0.493-1.037 C4.86,11.425,3.049,10.76,3.049,7.786c0-0.847,0.302-1.54,0.799-2.082C3.768,5.507,3.501,4.718,3.924,3.65 c0,0,0.652-0.209,2.134,0.796C6.677,4.273,7.34,4.187,8,4.184c0.659,0.003,1.323,0.089,1.943,0.261 c1.482-1.004,2.132-0.796,2.132-0.796c0.423,1.068,0.157,1.857,0.077,2.054c0.497,0.542,0.798,1.235,0.798,2.082 c0,2.981-1.814,3.637-3.543,3.829c0.279,0.24,0.527,0.713,0.527,1.437c0,1.037-0.01,1.874-0.01,2.129 c0,0.208,0.14,0.449,0.534,0.373c3.081-1.028,5.302-3.935,5.302-7.362C15.76,3.906,12.285,0.431,7.999,0.431z"/></svg>'
    $('title').addEventListener 'click', () -> restoreBody()
    $('githubLink').onmousedown = ->
        log 'open', "https://github.com/monsterkodi/password-turtle"
        open "https://github.com/monsterkodi/password-turtle"

###
000   000  00000000  000      00000000
000   000  000       000      000   000
000000000  0000000   000      00000000
000   000  000       000      000
000   000  00000000  0000000  000
###

openUrl  = (url) -> open url
showHelp = ()    -> open "https://monsterkodi.github.io/password-turtle/manual.html"

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
    if hasLock() and prefs.get 'mask'
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
        if $('settings').style.display == 'none'
            hideSitePassword()
            showSettings()
    else if stashLoaded
        if $('settings').style.display != 'none'
            hideSettings()
            showSitePassword()
        else
            hideSitePassword()
            showSettings()

showSettings = ->
    $('buttons')?.remove()
    updateFloppy()
    $('settings').appendChild initButtons()
    $('settings').style.display = 'initial'
    $('pattern').focus()
    updateStashButton()

hideSettings = ->
    $('settings').style.display = 'none'
    $('buttons')?.remove()
    say() if stashExists
    stashExists = fs.existsSync stashFile
    if $('pattern').value.length == 0 and stash?.pattern
        setInput 'pattern', stash.pattern
        patternChanged()

hideSitePassword = ->
    $('site-border').style.opacity = 0
    $('site-border').classList.add 'no-pointer'
    $('site').disabled = true
    $('password-border').style.opacity = 0
    $('password-border').classList.add 'no-pointer'
    $('password').disabled = true

showSitePassword = ->
    return if not $('site-border')?
    $('site-border').style.opacity = 1
    $('site-border').classList.remove 'no-pointer'
    $('site').disabled = false
    $('password-border').style.opacity = 1
    $('password-border').classList.remove 'no-pointer'
    $('password').disabled = false
    $('site').focus()

clearInput = (input) -> setInput input, ''

setInput = (input, value) ->
    $(input).value = value
    $(input+'-ghost').style.opacity = (value.length == 0 and 1 or 0)

hasLock = ->
    $('lock').classList.contains('open') or $('lock').classList.contains('closed')

hideLock = ->
    $('lock').classList.remove 'open'
    $('lock').classList.remove 'closed'

lockClosed = (e) ->
    e.innerHTML = '<span><i class="fa fa-lock fa-lg"></i></span>'
    e.classList.remove 'open'
    e.classList.add 'closed'

lockOpen = (e) ->
    e.innerHTML = '<span><i class="fa fa-unlock fa-lg"></i></span>'
    e.classList.remove 'closed'
    e.classList.add 'open'

setBool = (e, b) ->
    e.innerHTML = b and '<i class="fa fa-check fa-lg"></i>' or '<i class="fa fa-times fa-lg"></i>'
    e.classList.remove b and 'bool-false' or 'bool-true'
    e.classList.add b and 'bool-true' or 'bool-false'

updateFloppy = ->
    if floppy = $('floppy')
        if stash?.pattern != $("pattern").value or stash?.pattern == ''
            floppy.classList.remove 'saved'
        else
            floppy.classList.add 'saved'

updateStashButton = ->
    if empty stash.configs
        $('stash')?.disabled = true
        $('stash-border')?.classList.add 'disabled'
    else
        $('stash')?.disabled = false
        $('stash-border')?.classList.remove 'disabled'

###
 0000000  000000000  000   000  000      00000000
000          000      000 000   000      000
0000000      000       00000    000      0000000
     000     000        000     000      000
0000000      000        000     0000000  00000000
###

toggleStyle = ->
    link = $('style-link')
    currentScheme = last link.href.split '/'
    schemes = ['turtle-dark.css', 'turtle-bright.css']
    nextSchemeIndex = ( schemes.indexOf(currentScheme) + 1) % schemes.length
    newlink = elem 'link',
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
        al = [].slice.call arguments, 0
        if al.length == 3
            delay = al.pop()
            unsay = setTimeout say, delay
        $('bubble').className = "say"
        $('say').innerHTML = al.join "<br>"

ask = ->
    if prefs.get 'confirm', true
        if not $('say').innerHTML.endsWith(arguments[arguments.length-1])
            say.apply say, arguments
            $('bubble').className = "ask"
            return false
    true

module.exports = true
