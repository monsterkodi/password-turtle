###
 0000000  000   000  00000000  00000000  00000000 
000       000   000  000       000       000   000
0000000   000000000  0000000   0000000   00000000 
     000  000   000  000       000       000      
0000000   000   000  00000000  00000000  000      
###

shortcut      = require 'global-shortcut'
path          = require 'path'
app           = require 'app'
ipc           = require 'ipc'
fs            = require 'fs'
events        = require 'events'
Tray          = require 'tray'
BrowserWindow = require 'browser-window'

debug = false
win   = undefined
knx   = undefined
tray  = undefined

###
000   000  000   000  000  000   000  000       0000000    0000000 
000  000   0000  000  000   000 000   000      000   000  000      
0000000    000 0 000  000    00000    000      000   000  000  0000
000  000   000  0000  000   000 000   000      000   000  000   000
000   000  000   000  000  000   000  0000000   0000000    0000000 
###

ipc.on 'knixlog', (event, args) -> knx?.webContents.send 'knix_log', args
ipc.on 'knixerror', (event, args) -> knx?.webContents.send 'knix_error', args
ipc.on 'knixwarning', (event, args) -> knx?.webContents.send 'knix_warning', args
    
ipc.on 'console.log',   (event, args) -> console.log.apply console, args
ipc.on 'console.error', (event, args) -> console.log.apply console, args
ipc.on 'process.exit',  (event, code) -> console.log 'exit via ipc';  process.exit code
     
###
 0000000  000   000   0000000   000   000
000       000   000  000   000  000 0 000
0000000   000000000  000   000  000000000
     000  000   000  000   000  000   000
0000000   000   000   0000000   00     00
###

showWindow = () ->
    win.show() unless win.isVisible()
    win.setResizable debug
    win

###
000000000   0000000    0000000    0000000   000      00000000
   000     000   000  000        000        000      000     
   000     000   000  000  0000  000  0000  000      0000000 
   000     000   000  000   000  000   000  000      000     
   000      0000000    0000000    0000000   0000000  00000000
###

toggleWindow = () ->
    if win && win.isVisible()
        win.hide()
        knx?.hide()
    else
        knx?.show()
        win.show()

createWindow = () ->
    
    app.on 'ready', () ->

        if app.dock then app.dock.hide()

        cwd = path.join __dirname, '..'
        
        iconFile = path.join cwd, 'img', 'menuicon.png'

        tray = new Tray iconFile
        
        tray.on 'clicked', toggleWindow

        # 000   000  000   000  000  000   000
        # 000  000   0000  000  000   000 000 
        # 0000000    000 0 000  000    00000  
        # 000  000   000  0000  000   000 000 
        # 000   000  000   000  000  000   000

        if debug
            knx = new BrowserWindow
                dir:           cwd
                preloadWindow: true
                x:             0
                y:             0
                width:         658
                height:        800
                frame:         false
                show:          true
                transparent:   true
                
            knx.loadUrl 'file://' + cwd + '/knx.html'

        # 000   000  000  000   000
        # 000 0 000  000  0000  000
        # 000000000  000  000 0 000
        # 000   000  000  000  0000
        # 00     00  000  000   000

        screenSize = (require 'screen').getPrimaryDisplay().workAreaSize
        windowWidth = 364
        x = Number(((screenSize.width-windowWidth)/2).toFixed())
        y = 0

        values = loadPrefs()
        if values.winpos?
            x = values.winpos[0]
            y = values.winpos[1]

        win = new BrowserWindow
            dir:           cwd
            preloadWindow: true
            x: x
            y: y
            width:         windowWidth
            height:        330
            frame:         false

        shortcut.register (shortcut.shortcut or 'ctrl+`'), toggleWindow

        win.loadUrl 'file://' + cwd + '/sheep.html'
        
        setTimeout showWindow, 100
              
createWindow()            

###
00000000   00000000   00000000  00000000   0000000
000   000  000   000  000       000       000     
00000000   0000000    0000000   000000    0000000 
000        000   000  000       000            000
000        000   000  00000000  000       0000000 
###

prefsFile = process.env.HOME+'/Library/Preferences/sheepword.json'

loadPrefs = () ->
    try
        return JSON.parse(fs.readFileSync(prefsFile, encoding:'utf8'))
    catch err     
        return {}

savePrefs = (values) ->
    fs.writeFileSync prefsFile, jsonStr(values), encoding:'utf8'


###
000000000   0000000   0000000     0000000 
   000     000   000  000   000  000   000
   000     000   000  000   000  000   000
   000     000   000  000   000  000   000
   000      0000000   0000000     0000000 
###
###
- timeout
- autocompletion
- snatch site from firefox
- sort stash list
###
