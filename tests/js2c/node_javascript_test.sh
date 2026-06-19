#!/usr/bin/env bash
set -euo pipefail

generated="$1"
arch="$2"

grep -F '{"fs", BuiltinSource{' "$generated"
grep -F '{"internal/deps/amaro/dist/index", BuiltinSource{' "$generated"
grep -F '{"internal/deps/undici/undici", BuiltinSource{' "$generated"
grep -F '"node_module_version": 147' "$generated"
grep -F '"target_arch": "'"$arch"'"' "$generated"
