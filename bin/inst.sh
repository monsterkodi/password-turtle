#!/usr/bin/env bash
cd `dirname $0`/..

2>/dev/null 1>/dev/null killall password-turtle
2>/dev/null 1>/dev/null killall password-turtle

rm -rf /Applications/password-turtle.app
cp -R password-turtle-darwin-x64/password-turtle.app /Applications

open /Applications/password-turtle.app 
