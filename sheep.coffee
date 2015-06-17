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

win = undefined
knx = undefined

###
000   000  000   000  000  000   000  000       0000000    0000000 
000  000   0000  000  000   000 000   000      000   000  000      
0000000    000 0 000  000    00000    000      000   000  000  0000
000  000   000  0000  000   000 000   000      000   000  000   000
000   000  000   000  000  000   000  0000000   0000000    0000000 
###

ipc.on 'knixlog', (event, args) -> knx.webContents.send 'knix_log', args
ipc.on 'knixerror', (event, args) -> knx.webContents.send 'knix_error', args
ipc.on 'knixwarning', (event, args) -> knx.webContents.send 'knix_warning', args

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
    win.setMinimumSize 364, 466
    win.setMaximumSize 364, screenSize.height
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
        knx.hide()
    else
        knx.show()
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

        knx = new BrowserWindow
            dir:           cwd
            preloadWindow: true
            x:             0
            y:             0
            width:         658
            height:        800
            frame:         false
            show:          true
            
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
            height:        466
            frame:         false

        win.loadUrl 'file://' + cwd + '/sheep.html'
        
        # win.on 'blur', win.hide
        
        shortcut.register 'ctrl+`', toggleWindow
        
        setTimeout showWindow, 10
              
createWindow()            
