###
000000000  000   000  00000000   000000000  000      00000000
   000     000   000  000   000     000     000      000     
   000     000   000  0000000       000     000      0000000 
   000     000   000  000   000     000     000      000     
   000      0000000   000   000     000     0000000  00000000
###

{ slash, karg, prefs, log, fs } = require 'kxk'

pkg      = require '../package.json'
events   = require 'events'
electron = require 'electron'

app           = electron.app
ipc           = electron.ipcMain
Tray          = electron.Tray
BrowserWindow = electron.BrowserWindow
Menu          = electron.Menu

args   = karg """

password-turtle
    stash  . ? stash file   . *
    debug  . ? log debug    . = false . - D

version  #{pkg.version}
"""

debug = args.debug
win   = undefined
tray  = undefined
    
prefs.init shortcut:'CmdOrCtrl+F3', confirm: true, timeout: 2

ipc.on 'console.log',   (event, args) -> log.apply console, args
ipc.on 'console.error', (event, args) -> log.apply console, args
ipc.on 'process.exit',  (event, code) -> log 'exit via ipc';  process.exit code
    
noToggle = false 
ipc.on 'enableToggle', -> noToggle = false
ipc.on 'disableToggle', -> noToggle = true
ipc.on 'globalShortcut', (event, key) ->     
    prefs.set 'shortcut', key
    electron.globalShortcut.register key, toggleWindow
     
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
    return if noToggle
    if win and win.isVisible()
        win.hide()
    else
        win.show()

createWindow = () ->
    
    app.on 'ready', () ->

        app.dock?.hide()
        
        Menu.setApplicationMenu Menu.buildFromTemplate [
            label: app.getName()
            submenu: [
                label: 'Cut'
                accelerator: 'CmdOrCtrl+X'
                selector: 'cut:'
            ,
                label: 'Copy'
                accelerator: 'CmdOrCtrl+C'
                selector: 'copy:'
            ,
                label: 'Paste'
                accelerator: 'CmdOrCtrl+V'
                selector: 'paste:'
            ,
                label: 'Select All'
                accelerator: 'Command+A'
                selector: 'selectAll:'            
            ,
                label: 'Quit'
                accelerator: 'Command+Q'
                click: app.quit
            ]
        ]
        
        cwd = slash.join __dirname, '..'
        
        iconFile = slash.join cwd, 'img', 'menuicon.png'

        tray = new Tray iconFile
        
        tray.on 'click', toggleWindow

        # 000   000  000  000   000
        # 000 0 000  000  0000  000
        # 000000000  000  000 0 000
        # 000   000  000  000  0000
        # 00     00  000  000   000

        screenSize = electron.screen.getPrimaryDisplay().workAreaSize
        windowWidth = 364

        winpos = prefs.get 'winpos', x:Number(((screenSize.width-windowWidth)/2).toFixed()), y:0

        win = new BrowserWindow
            dir:           cwd
            preloadWindow: true
            x:             winpos.x
            y:             winpos.y
            width:         windowWidth
            height:        360
            frame:         false
            
        win.webContents.on 'did-finish-load', =>
             if debug
                win.webContents.openDevTools()
            
        electron.globalShortcut.register prefs.get('shortcut'), toggleWindow

        win.loadURL slash.fileUrl cwd + '/turtle.html'
        
        if not debug
            win.on 'blur', win.hide
            
        setTimeout showWindow, 100
              
createWindow()            
  