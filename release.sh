#!/usr/bin/env bash

source ~/shell/tokens.sh

# node_modules/electron-packager/cli.js . password-turtle --app-version=::package.json:version:: --platform=darwin --arch=x64 --prune --version=0.28.2 --app-bundle-id=net.monsterkodi.password-turtle --ignore=node_modules/electron --icon=img/turtle.icns
# tar cvzf password-turtle.tgz password-turtle.app

$VERSION=::package.json:version::
API_JSON=$(printf '{"tag_name": "v%s","target_commitish": "master","name": "v%s","body": "password-turtle version %s","draft": false,"prerelease": false}' $VERSION $VERSION $VERSION)
curl --data "$API_JSON" https://api.github.com/repos/monsterkodi/password-turtle/releases?access_token=$GITHUB_API_TOKEN
