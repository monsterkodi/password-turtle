#!/usr/bin/env node

// electron's npm package does not download the binary on install anymore
// (it used to run a postinstall script), so we do it here to keep
// `pnpm install` enough to get a working app.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const install = path.join(__dirname, '..', 'node_modules', 'electron', 'install.js');

if (!fs.existsSync(install)) {
    console.log('electron package not installed, skipping binary download');
    process.exit(0);
}

const result = spawnSync(process.execPath, [install], { stdio: 'inherit' });

if (result.error) {
    console.error('could not run electron installer:', result.error.message);
    process.exit(1);
}

process.exit(result.status === null ? 1 : result.status);
