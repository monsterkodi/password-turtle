#!/usr/bin/env bash
cd `dirname $0`/..

if rm -rf password-turtle-linux-ia32; then

    konrad 

    node_modules/.bin/electron-rebuild
    
    node_modules/electron-packager/cli.js . password-turtle --no-prune --icon=img/tray.png
    
    rm -rf password-turtle-linux-ia32/resources/app/node_modules/electron-packager
    rm -rf password-turtle-linux-ia32/resources/app/node_modules/electron-rebuild
    rm -rf password-turtle-linux-ia32/resources/app/node_modules/electron
    rm -rf password-turtle-linux-ia32/resources/app/inno

fi
