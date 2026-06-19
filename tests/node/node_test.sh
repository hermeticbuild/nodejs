#!/usr/bin/env bash
set -euo pipefail

node="$1"
arch="$2"
platform="$3"

[[ "$("$node" --version)" == "v26.3.1" ]]

"$node" - "$arch" "$platform" <<'JS'
'use strict';

const assert = require('node:assert/strict');
const { AsyncLocalStorage } = require('node:async_hooks');
const crypto = require('node:crypto');
const inspector = require('node:inspector');
const { DatabaseSync } = require('node:sqlite');

const expectedArch = process.argv[2];
const expectedPlatform = process.argv[3];

assert.equal(process.version, 'v26.3.1');
assert.match(process.versions.v8, /^14\.6\.202\.34-node\.20$/);
assert.equal(process.versions.modules, '147');
assert.equal(process.versions.icu, '78.3');
assert.equal(process.arch, expectedArch);
assert.equal(process.platform, expectedPlatform);
assert.equal(process.config.variables.node_use_ffi, true);
assert.equal(process.config.variables.node_use_lief, true);
assert.equal(typeof Temporal, 'object');
assert.equal(Temporal.Instant.from('1970-01-01T00:00:00Z').epochMilliseconds, 0);
assert.equal(
    Intl.DateTimeFormat.supportedLocalesOf(['ar-EG', 'fr-FR', 'zh-Hant-TW'])
        .length,
    3,
);
assert.equal(typeof inspector.Session, 'function');
assert.equal(
    crypto.createHash('sha256').update('nodejs').digest('hex'),
    '81df1af4ed72b1b82fed99c73be4831908af977f3bd52c7cb7dfc738e38571dd',
);

const database = new DatabaseSync(':memory:');
database.exec('CREATE TABLE values_table (value INTEGER NOT NULL)');
database.prepare('INSERT INTO values_table VALUES (?)').run(42);
assert.equal(
    database.prepare('SELECT value FROM values_table').get().value,
    42,
);
database.close();

const storage = new AsyncLocalStorage();
storage.run(42, () => Promise.resolve().then(() => {
  assert.equal(storage.getStore(), 42);
  process.stdout.write('node-ok\n');
}));
JS
