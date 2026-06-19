#!/usr/bin/env bash
set -euo pipefail

test_runner="$1"
node="$2"
root_status="$3"
shift 3

if [[ "$test_runner" != /* ]]; then
  test_runner="$PWD/$test_runner"
fi
if [[ "$node" != /* ]]; then
  node="$PWD/$node"
fi
if [[ "$root_status" != /* ]]; then
  root_status="$PWD/$root_status"
fi

test_root="$(dirname "$root_status")"
workspace="$(dirname "$test_root")"
test_directory="${TEST_TMPDIR:-${TMPDIR:-/tmp}}/node-test-$$"
mkdir -p "$test_directory"
trap 'rm -rf "$test_directory"' EXIT

cd "$workspace"
"$test_runner" \
  --arch=none \
  --flaky-tests=skip \
  --mode=release \
  --progress=tap \
  --shell="$node" \
  --temp-dir="$test_directory" \
  --test-root="$test_root" \
  -j="${NODE_TEST_JOBS:-1}" \
  "$@"
