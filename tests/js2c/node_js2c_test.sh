#!/usr/bin/env bash
set -euo pipefail

node_js2c="$1"
config_gypi="$2"
fixture_js="$3"
fixture_mjs="$4"
output="$TEST_TMPDIR/node_javascript.cc"

"$node_js2c" "$output" "$config_gypi" "$fixture_js" "$fixture_mjs"

grep -F 'module.exports = 26;' "$output"
grep -F 'export const minor = 3;' "$output"
grep -F 'node_module_version' "$output"
