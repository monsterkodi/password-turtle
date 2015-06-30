#!/usr/bin/env bash

node_modules/electron-packager/cli.js . password-turtle --app-version=::package.json:version:: --platform=darwin --arch=x64 --prune --version=0.28.2 --app-bundle-id=net.monsterkodi.password-turtle --ignore=node_modules/electron-prebuild --icon=img/turtle.icns

rm -rf password-turtle.app/Contents/Resources/app/.*
rm -rf password-turtle.app/Contents/Resources/default_app
rm -f password-turtle.app/Contents/Resources/release.sh

ditto -c -k --rsrc --extattr --keepParent password-turtle.app password-turtle.zip

git commit -a -m "v::package.json:version::"
git tag v::package.json:version::
git push origin v::package.json:version::
