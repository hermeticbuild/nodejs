#!/usr/bin/env bash
set -euo pipefail

config="$1"
arch="$2"
shlib_suffix="$3"
gdbjit="$4"
has_simd256="$5"

grep -F '"host_arch": "'"$arch"'"' "$config"
grep -F '"target_arch": "'"$arch"'"' "$config"
grep -F '"shlib_suffix": "'"$shlib_suffix"'"' "$config"
grep -F '"v8_enable_gdbjit": '"$gdbjit" "$config"
grep -F '"llvm_version": "22.1"' "$config"
grep -F '"node_module_version": 147' "$config"
grep -F '"node_use_ffi": "true"' "$config"
grep -F '"node_use_lief": "true"' "$config"

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
