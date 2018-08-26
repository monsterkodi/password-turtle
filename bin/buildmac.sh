#!/usr/bin/env bash
cd `dirname $0`/..
rm -rf password-turtle-darwin-x64
rm -rf js

#grunt bower
konrad
node_modules/.bin/electron-rebuild
node_modules/electron-packager/cli.js . password-turtle --icon=img/turtle.icns
# node_modules/electron-packager/cli.js . password-turtle --platform=darwin --arch=x64 --prune --version=0.36.4 --app-version=`sds -rp version` --app-bundle-id=net.monsterkodi.password-turtle --icon=img/turtle.icns

# mv password-turtle-darwin-x64/password-turtle.app .

# rm -rf password-turtle-darwin-x64
# rm -rf password-turtle.app/Contents/Resources/app/.*
# rm -rf password-turtle.app/Contents/Resources/app/web
# rm -rf password-turtle.app/Contents/Resources/default_app
# rm  -f password-turtle.app/Contents/Resources/app/*.sh
# rm  -f password-turtle.app/Contents/Resources/app/node.js