#!/usr/bin/env bash

# ditto -c -k --rsrc --extattr --keepParent password-turtle.app password-turtle.zip

git commit -a -m "v::package.json:version::"
git push
git tag v::package.json:version::
git push origin v::package.json:version::
