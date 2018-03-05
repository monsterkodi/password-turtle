#!/usr/bin/env bash
cd `dirname $0`/..

# rm -rf password-turtle-win32-x64
# rm -rf js

konrad --run

node_modules/electron-packager/cli.js . password-turtle --no-prune --icon=img/turtle.ico
