#!/usr/bin/env bash
set -euo pipefail

node="$1"
arch="$2"
platform="$3"

"$node" - "$arch" "$platform" <<'JS'
'use strict';

const assert = require('node:assert/strict');

assert.equal(process.version, 'v26.3.1');
assert.equal(process.arch, process.argv[2]);
assert.equal(process.platform, process.argv[3]);
JS
