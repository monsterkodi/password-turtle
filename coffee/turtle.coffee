###
000000000  000   000  00000000   000000000  000      00000000
   000     000   000  000   000     000     000      000     
   000     000   000  0000000       000     000      0000000 
   000     000   000  000   000     000     000      000     
   000      0000000   000   000     000     0000000  00000000
###

{ slash, args, prefs, fs, klog } = require 'kxk'

pkg      = require '../package.json'
events   = require 'events'
electron = require 'electron'

app           = electron.app
ipc           = electron.ipcMain
Tray          = electron.Tray
BrowserWindow = electron.BrowserWindow
Menu          = electron.Menu

args = args.init """
    stash  stash file   *
    debug  log debug    false . - D
"""

debug    = args.debug ? false
win      = undefined
tray     = undefined
noToggle = false 
    
prefs.init shortcut:'ctrl+f3' confirm:true timeout:2

# 000  00000000    0000000  
# 000  000   000  000       
# 000  00000000   000       
# 000  000        000       
# 000  000         0000000  

ipc.on 'console.log'   (event, args) -> log.apply console, args
ipc.on 'console.error' (event, args) -> log.apply console, args
ipc.on 'process.exit'  (event, code) -> log 'exit via ipc';  process.exit code
    
ipc.on 'debug'         -> debug    = true
ipc.on 'enableToggle'  -> noToggle = false
ipc.on 'disableToggle' -> noToggle = true
ipc.on 'globalShortcut' (event, key) ->     
    prefs.set 'shortcut' key
    electron.globalShortcut.register key, toggleWindow
     
###
 0000000  000   000   0000000   000   000
000       000   000  000   000  000 0 000
0000000   000000000  000   000  000000000
     000  000   000  000   000  000   000
0000000   000   000   0000000   00     00
###

activating = false

showWindow = ->
    activating = true
    win.show() 
    win.focus() 
    win.setResizable debug
    win

###
000000000   0000000    0000000    0000000   000      00000000
   000     000   000  000        000        000      000     
   000     000   000  000  0000  000  0000  000      0000000 
   000     000   000  000   000  000   000  000      000     
   000      0000000    0000000    0000000   0000000  00000000
###

toggleWindow = ->
    return if noToggle
    if win and win.isVisible()
        win.hide()
    else
        win.show()

onBlur = ->
    if not debug and not activating
        win.hide()
    activating = false
        
createWindow = ->
    
    app.on 'activate' showWindow
    
    app.on 'ready' ->

        if app.requestSingleInstanceLock()
            app.on 'second-instance' showWindow 
        else
            app.quit()
            return
        
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
        
        tray = new Tray slash.join cwd, 'img' 'tray.png'
        
        tray.on 'click' toggleWindow

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
                nodeIntegration: true
            
        win.on 'ready-to-show' (event) -> 
            win = event.sender
            win.show()
            if debug then win.openDevTools()
        
        electron.globalShortcut.register prefs.get('shortcut'), toggleWindow

        win.loadURL slash.fileUrl cwd + '/turtle.html'
        
        win.on 'blur' onBlur
                    
createWindow()            
  