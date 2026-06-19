"""Executes a Node.js 26.3.1 Windows binary."""

import subprocess
import sys


NODE_TEST = r"""
'use strict';

process.stderr.write('node_windows_test: started\n');

const assert = require('node:assert/strict');
const { AsyncLocalStorage } = require('node:async_hooks');
const crypto = require('node:crypto');
const { DatabaseSync } = require('node:sqlite');

process.stderr.write('node_windows_test: modules loaded\n');

assert.equal(process.version, 'v26.3.1');
assert.match(process.versions.v8, /^14\.6\.202\.34-node\.20$/);
assert.equal(process.versions.modules, '147');
assert.equal(process.versions.icu, '78.3');
assert.equal(process.arch, process.argv[1]);
assert.equal(process.platform, process.argv[2]);
assert.equal(process.config.variables.node_use_ffi, true);
assert.equal(process.config.variables.node_use_lief, true);
assert.equal(typeof Temporal, 'object');
assert.equal(Temporal.Instant.from('1970-01-01T00:00:00Z').epochMilliseconds, 0);
process.stderr.write('node_windows_test: runtime metadata checked\n');

assert.equal(
    crypto.createHash('sha256').update('nodejs').digest('hex'),
    '81df1af4ed72b1b82fed99c73be4831908af977f3bd52c7cb7dfc738e38571dd',
);
process.stderr.write('node_windows_test: crypto checked\n');

const database = new DatabaseSync(':memory:');
database.exec('CREATE TABLE values_table (value INTEGER NOT NULL)');
database.prepare('INSERT INTO values_table VALUES (?)').run(42);
assert.equal(database.prepare('SELECT value FROM values_table').get().value, 42);
database.close();
process.stderr.write('node_windows_test: sqlite checked\n');

const storage = new AsyncLocalStorage();
storage.run(42, () => Promise.resolve().then(() => {
  assert.equal(storage.getStore(), 42);
  process.stderr.write('node_windows_test: async hooks checked\n');
  process.stdout.write('node-ok\n');
}));
"""


def run_node(node: str, *args: str) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [node, *args],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Node.js failed with status {result.returncode}: {[node, *args]!r}\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )
    return result


def main() -> None:
    node, expected_arch, expected_platform = sys.argv[1:]
    version = run_node(node, "--version")
    if version.stdout != "v26.3.1\n":
        raise AssertionError(f"unexpected Node.js version: {version.stdout!r}")

    test = run_node(node, "-e", NODE_TEST, expected_arch, expected_platform)
    if test.stdout != "node-ok\n":
        raise AssertionError(f"unexpected Node.js output: {test.stdout!r}")


if __name__ == "__main__":
    main()
