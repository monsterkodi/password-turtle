###
000000000  000   000  00000000   000000000  000      00000000
   000     000   000  000   000     000     000      000     
   000     000   000  0000000       000     000      0000000 
   000     000   000  000   000     000     000      000     
   000      0000000   000   000     000     0000000  00000000
###

{ app, args, prefs, slash, win } = require 'kxk'

pkg      = require '../package.json'
events   = require 'events'
electron = require 'electron'

app           = electron.app
ipc           = electron.ipcMain
Tray          = electron.Tray
BrowserWindow = electron.BrowserWindow
Menu          = electron.Menu

args = args.init """
    stash       stash file   *
    devtools    open developer tools        false  -D
"""

debug    = args.devtools
win      = undefined
tray     = undefined
noToggle = false 
    
prefs.init shortcut:'CmdOrCtrl+F3' confirm:true timeout:2

# 000  00000000    0000000  
# 000  000   000  000       
# 000  00000000   000       
# 000  000        000       
# 000  000         0000000  

winForEvent = (event) -> electron.BrowserWindow.fromWebContents event.sender

ipc.on 'console.log'   (event, args) -> log.apply console, args
ipc.on 'console.error' (event, args) -> log.apply console, args
ipc.on 'process.exit'  (event, code) -> log 'exit via ipc';  process.exit code
    
ipc.on 'debug'         -> debug    = true
ipc.on 'enableToggle'  -> noToggle = false
ipc.on 'disableToggle' -> noToggle = true
ipc.on 'globalShortcut' (event, key) ->     
    prefs.set 'shortcut' key
    electron.globalShortcut.register key, toggleWindow
     
ipc.on 'setWinSize' (event, w, h) -> winForEvent(event).setSize w, h 
ipc.on 'getWinSize' (event, w, h) -> event.returnValue = winForEvent(event).getSize()
ipc.on 'hide' (event) -> winForEvent(event).hide()
ipc.on 'quit' -> electron.app.exit 0
    
###
000000000   0000000    0000000    0000000   000      00000000
   000     000   000  000        000        000      000     
   000     000   000  000  0000  000  0000  000      0000000 
   000     000   000  000   000  000   000  000      000     
   000      0000000    0000000    0000000   0000000  00000000
###

activating = false
showWin = -> activating = true; win?.show(); win?.focus(); electron.app.dock?.show()
hideWin = -> win?.hide(); electron.app.dock?.hide()

onBlur = -> 
    if not debug and not activating
        hideWin()
    activating = false
        
app.on 'activate' showWin

app.on 'ready' ->

    if app.requestSingleInstanceLock()
        app.on 'second-instance' showWin
    else
        app.quit()
        return
    
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
    
    tray = new Tray slash.join cwd, 'img' 'tray.png'
    
    tray.on 'click' showWin

    # 000   000  000  000   000
    # 000 0 000  000  0000  000
    # 000000000  000  000 0 000
    # 000   000  000  000  0000
    # 00     00  000  000   000

    screenSize = electron.screen.getPrimaryDisplay().workAreaSize
    windowWidth = 364

    winpos = prefs.get 'winpos' x:Number(((screenSize.width-windowWidth)/2).toFixed()), y:0

    win = new BrowserWindow
        dir:                cwd
        show:               false
        backgroundColor:    '#222'
        x:                  winpos.x
        y:                  winpos.y
        width:              windowWidth
        height:             360
        frame:              false
        webPreferences: 
            webSecurity:            false
            contextIsolation:       false
            nodeIntegration:        true
            nodeIntegrationInWorker: true
        
    win.on 'ready-to-show' -> 
        win.show()
        if args.devtools
            win.webContents.openDevTools mode:'detach'
    
    if prefs.get('shortcut')
        electron.globalShortcut.register prefs.get('shortcut'), showWin

    win.loadURL slash.fileUrl cwd + '/turtle.html'
    
    win.on 'blur' onBlur
                
  