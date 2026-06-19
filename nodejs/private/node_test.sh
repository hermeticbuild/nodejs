#!/usr/bin/env bash
set -euo pipefail

test_runner="$1"
node="$2"
root_status="$3"
getaddrinfo_library="$4"
shift 4

if [[ "$test_runner" != /* ]]; then
  test_runner="$PWD/$test_runner"
fi
if [[ "$node" != /* ]]; then
  node="$PWD/$node"
fi
if [[ "$root_status" != /* ]]; then
  root_status="$PWD/$root_status"
fi
if [[ "$getaddrinfo_library" != /* ]]; then
  getaddrinfo_library="$PWD/$getaddrinfo_library"
fi
if [[ "$getaddrinfo_library" == *.so ]]; then
  export LD_PRELOAD="${getaddrinfo_library}${LD_PRELOAD:+:$LD_PRELOAD}"
fi

test_root="$(dirname "$root_status")"
workspace="$(dirname "$test_root")"
# Linux limits Unix-domain socket paths to 107 bytes. Bazel test directories
# can exceed that limit before Node.js appends the test-specific socket name.
test_directory="/tmp/node-test-$$"
mkdir -p "$test_directory"
trap 'rm -rf "$test_directory"' EXIT

cd "$workspace"
"$test_runner" \
  --arch=none \
  --flaky-tests="${NODE_TEST_FLAKY_TESTS:-run}" \
  --mode=release \
  --progress=tap \
  --shell="$node" \
  --temp-dir="$test_directory" \
  --test-root="$test_root" \
  -j="${NODE_TEST_JOBS:-1}" \
  "$@"
