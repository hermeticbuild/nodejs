#!/usr/bin/env bash
set -euo pipefail

config="$1"
arch="$2"
shlib_suffix="$3"
gdbjit="$4"
has_simd256="$5"
use_snapshot="$6"
use_code_cache="$7"
array_literals="$8"

grep -F '"host_arch": "'"$arch"'"' "$config"
grep -F '"target_arch": "'"$arch"'"' "$config"
grep -F '"shlib_suffix": "'"$shlib_suffix"'"' "$config"
grep -F '"v8_enable_gdbjit": '"$gdbjit" "$config"
grep -F '"llvm_version": "22.1"' "$config"
grep -F '"node_module_version": 147' "$config"
grep -F '"node_use_ffi": "true"' "$config"
grep -F '"node_use_lief": "true"' "$config"
grep -F '"node_use_node_snapshot": "'"$use_snapshot"'"' "$config"
grep -F '"node_use_node_code_cache": "'"$use_code_cache"'"' "$config"
grep -F '"node_write_snapshot_as_array_literals": "'"$array_literals"'"' "$config"

if [[ "$has_simd256" == "true" ]]; then
  grep -F '"v8_enable_wasm_simd256_revec": 1' "$config"
else
  ! grep -F '"v8_enable_wasm_simd256_revec"' "$config"
fi

if [[ "$arch" == "arm64" ]]; then
  grep -F '"arm_fpu": "neon"' "$config"
  ! grep -F '"v8_enable_short_builtin_calls"' "$config"
else
  ! grep -F '"arm_fpu"' "$config"
  grep -F '"v8_enable_short_builtin_calls": 1' "$config"
fi
