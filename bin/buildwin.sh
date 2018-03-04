#!/usr/bin/env bash
cd `dirname $0`/..

# rm -rf password-turtle-win32-x64
# rm -rf js

grunt bower
konrad --run

node_modules/electron-packager/cli.js . password-turtle --n0-prune --icon=img/turtle.ico
