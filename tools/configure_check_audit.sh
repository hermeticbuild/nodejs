#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$workspace"

case "${1:-}" in
  "")
    check_args=()
    ;;
  --check)
    check_args=(--check)
    ;;
  *)
    echo "usage: $0 [--check]" >&2
    exit 2
    ;;
esac

execution_root="$(bazel info execution_root)"
output_base="$(bazel info output_base)"
source_files="$(bazel cquery \
  --lockfile_mode=error \
  '@nodejs_26_3_1//:configure_audit_sources' \
  --output=files)"

source_args=()
while IFS= read -r source_file; do
  if [[ -z "$source_file" ]]; then
    continue
  fi
  if [[ "$source_file" != /* ]]; then
    if [[ "$source_file" == external/* ]]; then
      source_file="$output_base/$source_file"
    else
      source_file="$execution_root/$source_file"
    fi
  fi
  if [[ ! -f "$source_file" ]]; then
    echo "missing Node.js configure audit source: $source_file" >&2
    exit 1
  fi
  source_args+=(--source "$source_file")
done <<<"$source_files"

if [[ "${#source_args[@]}" -lt 8 ]]; then
  echo "expected configure.py, common.gypi, node.gyp, and V8 GYP sources" >&2
  exit 1
fi

python3 tools/configure_inventory.py \
  "${source_args[@]}" \
  --settings tools/configure_release_settings.json \
  --output docs/configure-check-audit.md \
  "${check_args[@]}"
