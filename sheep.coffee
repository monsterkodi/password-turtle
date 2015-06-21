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
events        = require 'events'
Tray          = require 'tray'
BrowserWindow = require 'browser-window'

debug = true
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

###
 0000000  000   000   0000000   000   000
000       000   000  000   000  000 0 000
0000000   000000000  000   000  000000000
     000  000   000  000   000  000   000
0000000   000   000   0000000   00     00
###

showWindow = () ->
    screenSize = (require 'screen').getPrimaryDisplay().workAreaSize
    win.show() unless win.isVisible()
    win.setResizable debug
    windowWidth = win.getSize()[0]
    screenWidth = screenSize.width
    winPosX = Number(((screenWidth-windowWidth)/2).toFixed())
    win.setPosition winPosX, 0
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

        ###
        000   000  000   000  000   000
        000  000   0000  000   000 000 
        0000000    000 0 000    00000  
        000  000   000  0000   000 000 
        000   000  000   000  000   000
        ###

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

        ###
        000   000  000  000   000
        000 0 000  000  0000  000
        000000000  000  000 0 000
        000   000  000  000  0000
        00     00  000  000   000
        ###

        win = new BrowserWindow
            dir:           cwd
            preloadWindow: true
            width:         364
            height:        310
            frame:         false

        win.loadUrl 'file://' + cwd + '/sheep.html'
        
        if not debug then win.on 'blur', win.hide
        
        shortcut.register 'ctrl+`', toggleWindow
        
        setTimeout showWindow, 10
              
createWindow()            

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
- bright style
- remember window pos
- render clean sheep image(s)
- snatch site from firefox
- preferences
    - global shortcut
    - timeout delay
    - bright/dark style
    - mask saved passwords
    - enable site snatching
    - less verbose mode?
- sort stash list
- tests?
###
