#!/usr/bin/env bash
cd `dirname $0`/..

if rm -rf password-turtle-win32-x64; then

    konrad 

    node_modules/.bin/electron-rebuild
    
    node_modules/electron-packager/cli.js . password-turtle --no-prune --icon=img/turtle.ico
    
else
    handle64 -nobanner password-turtle-win32-x64\\resources\\electron.asar
fi
