#!/usr/bin/env bash

rm -rf password-turtle-darwin-x64
rm -rf password-turtle.app

node_modules/electron-packager/cli.js . password-turtle --platform=darwin --arch=x64 --prune --version=0.28.3 --app-version=1.0.2 --app-bundle-id=net.monsterkodi.password-turtle --icon=img/turtle.icns

mv password-turtle-darwin-x64/password-turtle.app .

rm -rf password-turtle-darwin-x64
rm -rf password-turtle.app/Contents/Resources/app/.*
rm -rf password-turtle.app/Contents/Resources/app/web
rm -rf password-turtle.app/Contents/Resources/default_app
rm  -f password-turtle.app/Contents/Resources/app/*.sh
rm  -f password-turtle.app/Contents/Resources/app/node.js