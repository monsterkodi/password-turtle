#!/usr/bin/env bash

DIR=`dirname $0`
BIN=$DIR/../node_modules/.bin
cd $DIR/..

if rm -rf password-turtle-darwin-x64; then

    if $BIN/konrad; then
    
        IGNORE="/(.*\.dmg$|Icon$|watch$|icons$|.*md$|pug$|styl$|.*\.lock$|img/banner\.png)"
        
        if $BIN/electron-packager . --overwrite --icon=img/app.icns --darwinDarkModeSupport --ignore=$IGNORE; then
        
            rm -rf /Applications/password-turtle.app
            cp -R password-turtle-darwin-x64/password-turtle.app /Applications
            
            open /Applications/password-turtle.app 
        fi
    fi
fi
