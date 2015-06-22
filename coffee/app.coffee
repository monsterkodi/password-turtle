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

mstr        = undefined
stashFile   = process.env.HOME+'/Library/Preferences/sheepword.stash'
stash       = undefined
stashExists = false
stashLoaded = false

log   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0
dbg   = () -> ipc.send 'knixlog',   [].slice.call arguments, 0

console.log   = () -> ipc.send 'console.log', [].slice.call arguments, 0
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
    $('password').on 'click', copyPassword
    $('pattern' ).on 'input', patternChanged
    $('sheep'   ).on 'click', toggleSettings
    $('list'    ).on 'click', listStash
    $('prefs'   ).on 'click', showPrefs
    $('about'   ).on 'click', showAbout
    $('help'    ).on 'click', showHelp
    $('delete'  ).on 'click', deleteStash
    $('sheep'   ).on 'mouseenter', (e) -> $('sheep').focus()
        
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
    # dbg key
    
    if not $('bubble')?
        switch key 
            when 'esc', 'command-l', 'ctrl-l'
                restoreBody()
                return
            when 'command-,', 'ctrl-,' # comma
                restoreBody()
                hideSitePassword()
                showSettings()
                return

        if $('stashlist')?
            onListKey event
            return
        if $('preferences')?
            onPrefsKey event
            return
    
    if key == 'command-l' or key == 'ctrl-l'
        listStash()
        return
        
    if not $('site')?
        switch key 
            when 'esc', 'command-l', 'ctrl-l'
                restoreBody()
            when 'command-,', 'ctrl-,' # comma
                restoreBody()
                hideSitePassword()
                showSettings()
        return
    
    site = $('site').value
    hash = genHash(site+mstr)
    
    if e == $('password')
        switch key
            when 'backspace', 'command-x', 'ctrl-x'
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
0000000     0000000   0000000    000   000
000   000  000   000  000   000   000 000 
0000000    000   000  000   000    00000  
000   000  000   000  000   000     000   
0000000     0000000   0000000       000   
###

saveBody = () ->
    if not $('bubble')? then return
    savedFocus = document.activeElement.id
    savedSite  = $('site')?.value
    savedBody  = document.body.innerHTML
    
    window.restoreBody = (site) ->
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
            updateListButton()
            if isEmpty(stash.configs) and savedFocus == 'list'
                $('prefs').focus()

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

onListKey = (event) ->
    key = keyname event
    e   = document.activeElement
    switch key 
        when 'right', 'down'
            if e? then e.parentElement?.nextSibling?.firstElementChild?.focus()
        when 'left', 'up'
            if e? then e.parentElement?.previousSibling?.firstElementChild?.focus()
        when 'backspace', 'command-x', 'ctrl-x'
            if e.id.length
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
            restoreBody e.nextSibling.innerHTML
        # else
        #     dbg key

listStash = () ->
    
    if isEmpty stash.configs then return
    
    saveBody()
        
    document.body.innerHTML = '<div id="stashlist"></div>'    
        
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
            
        item.on 'mouseenter', (e) -> e.target.childElements[0]?.focus()
        $(hash).on 'click',   (e) -> restoreBody e.target.nextSibling.innerHTML

    for input in $$('input')
        input.on 'focus',      (e) -> $(e.target.parentElement).addClassName 'focus'
        input.on 'blur',       (e) -> $(e.target.parentElement).removeClassName 'focus'
        input.on 'mouseenter', (e) -> $(e.target).focus()
            
    $('stashlist').firstElementChild.firstElementChild.focus()
    
###
00000000   00000000   00000000  00000000   0000000
000   000  000   000  000       000       000     
00000000   0000000    0000000   000000    0000000 
000        000   000  000       000            000
000        000   000  00000000  000       0000000 
###

prefsFile = process.env.HOME+'/Library/Preferences/sheepword.json'
prefs = 
    shortcut: { default: 'ctrl+`', type: 'shortcut', text: 'global shortcut' }
    timeout:  { default: 60,       type: 'int',      text: 'autoclose delay' }
    dark:     { default: true,     type: 'bool',     text: 'dark theme' }
    talking:  { default: true,     type: 'bool',     text: 'sheep is talking' }
    confirm:  { default: true,     type: 'bool' ,    text: 'confirm forgetting' }
    mask:     { default: true,     type: 'bool',     text: 'mask saved passwords' }

loadPrefs = () ->
    values = {}
    try
        values = JSON.parse fs.readFileSync(prefsFile, encoding:'utf8')
        # log 'loaded values:', jsonStr values
    catch        
        log 'can\'t load prefs file', prefsFile
    for key in Object.keys prefs
        if not values[key]?
            values[key] = prefs[key].default
    # log jsonStr values    
    values

savePrefs = (values) ->
    fs.writeFileSync prefsFile, jsonStr(values), encoding:'utf8'

showPrefs = () ->
    saveBody()
    document.body.innerHTML = '<div id="preferences"></div>'

    values = loadPrefs()
    
    for key in Object.keys prefs
        pref = prefs[key]
        value = values[key]
        item =       new Element 'div', class: 'pref-item-border border'
        item.insert  new Element 'input', id: key, type: 'button', class: 'pref-item'
        item.insert (new Element 'span', class: 'pref').update pref.text
        switch pref.type
            when 'bool'
                bool = new Element 'span', class: 'bool'
                item.insert bool
                setBool bool, value
            when 'int', 'shortcut'
                item.insert (new Element 'span', class: 'pattern').update value
            
        $('preferences').insert item
        
    for input in $$('input')
        input.on 'focus',      (e) -> $(e.target.parentElement).addClassName 'focus'
        input.on 'blur',       (e) -> $(e.target.parentElement).removeClassName 'focus'
        input.on 'mouseenter', (e) -> $(e.target).focus()
        input.on 'click',      (e) -> 
            key = e.target.id
            pref = prefs[key]
            # log 'input click', key, pref
            if pref.type == 'bool'
                values[key] = not values[key]
                bool = e.target.parentElement.select('.bool')[0]
                setBool bool, values[key]
                savePrefs values
                
                if key == 'dark'
                    toggleStyle()
            
    $('preferences').firstElementChild.firstElementChild.focus()
    
onPrefsKey = (event) ->
    key = keyname event
    e   = document.activeElement
    switch key 
        when 'right', 'down'
            if e? then e.parentElement?.nextSibling?.firstElementChild?.focus()
        when 'left', 'up'
            if e? then e.parentElement?.previousSibling?.firstElementChild?.focus()
        else
            dbg key
                    
###
 0000000   0000000     0000000   000   000  000000000
000   000  000   000  000   000  000   000     000   
000000000  0000000    000   000  000   000     000   
000   000  000   000  000   000  000   000     000   
000   000  0000000     0000000    0000000      000   
###
showAbout = () ->
    saveBody()
    version = '::package.json:version::'
    document.body.innerHTML = '<div id="about"><h1 id="title">sheepword</h1><sub>version %s</sub>'.fmt version
    githubIcon = new Element 'div', { id: 'about-github' }
    githubIcon.insert '<svg viewbox="0 0 16 16" width="80px" height="80px" class="kitty-svg"><path class="github-svg" d="M7.999,0.431c-4.285,0-7.76,3.474-7.76,7.761 c0,3.428,2.223,6.337,5.307,7.363c0.388,0.071,0.53-0.168,0.53-0.374c0-0.184-0.007-0.672-0.01-1.32 c-2.159,0.469-2.614-1.04-2.614-1.04c-0.353-0.896-0.862-1.135-0.862-1.135c-0.705-0.481,0.053-0.472,0.053-0.472 c0.779,0.055,1.189,0.8,1.189,0.8c0.692,1.186,1.816,0.843,2.258,0.645c0.071-0.502,0.271-0.843,0.493-1.037 C4.86,11.425,3.049,10.76,3.049,7.786c0-0.847,0.302-1.54,0.799-2.082C3.768,5.507,3.501,4.718,3.924,3.65 c0,0,0.652-0.209,2.134,0.796C6.677,4.273,7.34,4.187,8,4.184c0.659,0.003,1.323,0.089,1.943,0.261 c1.482-1.004,2.132-0.796,2.132-0.796c0.423,1.068,0.157,1.857,0.077,2.054c0.497,0.542,0.798,1.235,0.798,2.082 c0,2.981-1.814,3.637-3.543,3.829c0.279,0.24,0.527,0.713,0.527,1.437c0,1.037-0.01,1.874-0.01,2.129 c0,0.208,0.14,0.449,0.534,0.373c3.081-1.028,5.302-3.935,5.302-7.362C15.76,3.906,12.285,0.431,7.999,0.431z"/></svg>'
    $('about').insert githubIcon
    $('about-github').on 'click', () -> open "http://coffeescript.org/"
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
showHelp = ()    -> open "https://github.com/monsterkodi/sheepword"
    
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
    updateListButton()
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

setBool = (e, b) -> 
    e.innerHTML = b and '<i class="fa fa-check fa-lg"></i>' or '<i class="fa fa-times fa-lg"></i>'
    e.removeClassName b and 'bool-false' or 'bool-true'
    e.addClassName b and 'bool-true' or 'bool-false'

hideLock = -> 
    $('lock').removeClassName 'open'
    $('lock').removeClassName 'closed'
            
updateFloppy = ->
    if floppy = $('floppy')
        if stash?.pattern != $("pattern").value or stash?.pattern == ''
            floppy.removeClassName 'saved'
        else
            floppy.addClassName 'saved'

updateListButton = ->        
    if isEmpty stash.configs
        $('list').disabled = true
        $('list-border').addClassName 'disabled'
    else 
        $('list').disabled = false
        $('list-border').removeClassName 'disabled'
        
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
    schemes = ['sheep-dark.css', 'sheep-bright.css']
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
