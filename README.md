# Node.js for Bazel

This module is building Node.js release artifacts from the official Node.js
source archive with hermetic Bazel toolchains and declared Bazel actions. The
only supported release is Node.js 26.3.1.

The public contract selects and validates the upstream source archive, builds
the Node.js executable, and creates Linux and macOS release archives. The
complete upstream test matrix is still being added against this exact source
contract.

## Select Node.js 26.3.1

```starlark
bazel_dep(name = "nodejs", version = "<module version>")

nodejs = use_extension("@nodejs//nodejs:extensions.bzl", "nodejs")
nodejs.version(version = "26.3.1")
use_repo(nodejs, "nodejs_26_3_1", "nodejs_crates_26_3_1", "nodejs_icu_26_3_1", "v8")
```

`@nodejs_26_3_1//:release_metadata` contains the checked Node.js, Node module
ABI, V8, and libuv versions. `@nodejs_26_3_1//:configure_audit_sources`
contains the upstream configuration files that define the release build.
`@nodejs_26_3_1//:bazel/release_config.gypi` is the generated release
configuration from the pinned official Node.js 26.3.1 headers archive.
`@nodejs_26_3_1//:config_gypi` applies the target OS and architecture values
for Linux and macOS x86_64 and arm64 builds.

## Configure/GYP inventory

[`tools/configure_inventory.py`](tools/configure_inventory.py) reads the
pinned `configure.py`, `common.gypi`, `node.gyp`, and `tools/v8_gypfiles`
files without executing `configure.py` or GYP. The generated
[`docs/configure-check-audit.md`](docs/configure-check-audit.md) records every
configure option, every direct configure.py GYP-variable assignment, every GYP
default, and every GYP reference. It also records the reviewed Linux and macOS
release values that the Bazel build must preserve.

Run `tools/configure_check_audit.sh` to update the inventory. Run
`tools/configure_check_audit.sh --check` to verify the checked-in inventory.

## Build targets

`@nodejs_26_3_1//:libuv` builds the libuv 1.52.1 source bundled in the Node.js
26.3.1 archive. The target uses the upstream source lists, preprocessor
definitions, and system libraries for Linux and macOS. The hermetic LLVM
toolchains build x86_64 and arm64 variants for both operating systems.

`@nodejs_26_3_1//:node_js2c` builds Node.js's `node_js2c` executable with the
bundled libuv and V8 simdutf sources. `//tests/js2c:node_js2c_test` verifies
that `node_js2c` embeds JavaScript, ES module, and `config.gypi` inputs.
`@nodejs_26_3_1//:node_javascript` embeds every Node.js built-in JavaScript
module plus the pinned target `config.gypi` into `node_javascript.cc`.

`@nodejs_26_3_1//:zlib` builds Node.js's bundled zlib 1.3.1 sources with the
x86-64 and arm64 SIMD source sets and release preprocessor definitions.
`//tests/zlib:zlib_test` verifies compression, decompression, and the bundled
zlib version.

`@nodejs_26_3_1//:llhttp` and `@nodejs_26_3_1//:cares` build Node.js's bundled
llhttp 9.4.2 and c-ares 1.34.6 sources. `//tests/llhttp:llhttp_test` parses an
HTTP request, and `//tests/cares:cares_test` initializes c-ares and checks the
bundled version.

`@nodejs_26_3_1//:histogram` and `@nodejs_26_3_1//:nbytes` build Node.js's
bundled hdr-histogram 0.11.9 and nbytes 0.1.4 sources. Their tests verify value
recording, percentile lookup, byte swapping, and the bundled versions.

`@nodejs_26_3_1//:brotli` builds the exact common, encoder, and decoder sources
from Node.js's bundled Brotli 1.2.0. `//tests/brotli:brotli_test` verifies an
encode/decode round trip.

`@nodejs_26_3_1//:nghttp2` builds the exact source list and static-library
configuration from Node.js's bundled nghttp2 1.69.0. Its test checks the
version API and creates a client session.

`@nodejs_26_3_1//:zstd` builds the exact source list from Node.js's bundled
zstd 1.5.7 without linking a host zstd library. Its test checks the version API
and a compression/decompression round trip.

`@nodejs_26_3_1//:uvwasi` builds the exact uvwasi 0.0.23 source list with
`@nodejs_26_3_1//:libuv`. Its test initializes and destroys a uvwasi instance.

`@nodejs_26_3_1//:sqlite` builds Node.js's SQLite 3.53.1 amalgamation with the
upstream release feature definitions. Its test verifies FTS5 and session
support and executes an in-memory query.

`@nodejs_26_3_1//:ada`, `@nodejs_26_3_1//:merve`, and
`@nodejs_26_3_1//:simdjson` build Node.js's bundled Ada 3.4.4, merve 1.2.2, and
simdjson 4.6.4 sources. Their tests parse a URL, analyze CommonJS exports, and
read a JSON field.

`@nodejs_26_3_1//:openssl` builds Node.js's bundled OpenSSL 3.5.7 no-assembly
source inventory and generated configuration for Linux and macOS x86_64 and
arm64 targets. `//tests/openssl:openssl_test` checks the bundled version and
computes a SHA-256 digest through the OpenSSL EVP API.

`@nodejs_26_3_1//:ncrypto` builds Node.js's `deps/ncrypto/engine.cc` and
`deps/ncrypto/ncrypto.cc` against `@nodejs_26_3_1//:openssl`.
`//tests/ncrypto:ncrypto_test` checks ncrypto 0.0.1, computes a SHA-256 digest,
and requests random bytes through `ncrypto::CSPRNG`.

`@nodejs_26_3_1//:libffi` builds Node.js's bundled libffi 3.5.2 common and
target-architecture sources. Node.js's `deps/libffi/generate-headers.py`
generates `ffi.h`, `fficonfig.h`, and `ffitarget.h` for each target platform.
`//tests/libffi:libffi_test` calls a C function through `ffi_call`.

`@nodejs_26_3_1//:lief` builds Node.js's bundled LIEF 0.17.0 source inventory
and its checked-in mbedTLS sources. `//tests/lief:lief_test` checks the bundled
version and parses its own ELF or Mach-O executable.

`@v8` projects `deps/v8` from the same Node.js 26.3.1 archive as a repository
because V8's Bazel targets use repository-root labels. `@nodejs_icu_26_3_1`
projects Node.js's bundled ICU 78 source and provides `//:icudata`, which
decompresses `icudt78l.dat.bz2` with the hermetic `@bzip2//:bzip2` executable.

`@nodejs_crates_26_3_1` projects `deps/crates` from the Node.js 26.3.1
archive. It contains Node.js's Cargo lockfile, vendored crates, patched `resb`
crate, `temporal_capi`, and `temporal_rs`. Rust targets use the pinned Rust
1.82.0 toolchain for Linux x86_64, Linux arm64, macOS x86_64, macOS arm64, and
Windows x86_64.

`@nodejs_26_3_1//:libnode` builds the Node.js 26.3.1 implementation with the
bundled dependencies. `@nodejs_26_3_1//:node` builds the executable and embeds
the ICU data, Node.js startup snapshot, and built-in JavaScript code cache.
`//tests/node:node_test` exercises the release version, V8, ICU, Temporal,
OpenSSL, inspector, SQLite, promises, and `AsyncLocalStorage`.

`@nodejs_26_3_1//:release_tree` stages the upstream binary distribution
layout. `@nodejs_26_3_1//:release_archives_tar_gz` and
`@nodejs_26_3_1//:release_archives_tar_xz` create the platform-specific
`node-v26.3.1-<platform>.tar.gz` and `node-v26.3.1-<platform>.tar.xz` files.
The archives contain `node`, npm 11.16.0, the public Node.js and dependency
headers, debugger files, and the `node(1)` manual. Node.js 26.3.1 disables
Corepack in its release configuration, so the archives do not contain
Corepack. `tar.bzl` creates both deterministic archives with hermetic
`bsdtar`.

Build release archives with the optimized release configuration and a runner
that matches the target operating system and architecture:

```console
bazel build --config=release \
  --platforms=@llvm//platforms:macos_aarch64 \
  @nodejs_26_3_1//:release_archives
```

`//tests/release:release_archive_test` verifies the official 5,714-entry
layout, normalized metadata, gzip/xz equivalence, and relocated execution of
`node`, `npm`, and `npx`.

`@nodejs_26_3_1//:node_test` runs Node.js's upstream Python test harness with
the Bazel-built `node` executable and the complete upstream `test` directory.
Pass upstream suite or test names after `--`:

```console
bazel run --config=release @nodejs_26_3_1//:node_test -- \
  parallel/test-assert parallel/test-buffer-alloc
```

`@nodejs_26_3_1//:node_upstream_smoke_test` runs representative upstream
assertion, buffer, crypto, filesystem, and HTTP tests in CI.

`@nodejs_26_3_1//:node_upstream_parallel_tests` runs 3,978 tests from the
upstream `parallel` suite in 16 deterministic Linux x86_64 shards. The Linux
test runner preloads `node_test_getaddrinfo.so`, which retries a failed
`localhost` lookup with the matching numeric loopback address while BuildBuddy
runs the tests with `network=off`.

The sharded suite excludes `parallel/test-debugger-preserve-breaks`. The test
times out after the `restart` command with both the official Node.js 26.3.1
macOS arm64 binary and the Bazel-built Linux x86_64 binary. The test already
contains the wait added by nodejs/node#62471.

`@nodejs_26_3_1//:node_upstream_sequential_tests` runs all 119 upstream
`sequential` tests in one Linux x86_64 action with `NODE_TEST_JOBS=1`.
`node_test_runner.py` removes the `PYTHONSAFEPATH` value set by the
`rules_python` launcher so nested upstream `tools/test.py` invocations can
import the adjacent `tools/utils.py` file.

The following targets run 563 additional upstream tests across 23 Linux
x86_64 shards:

- `@nodejs_26_3_1//:node_upstream_async_hooks_tests`
- `@nodejs_26_3_1//:node_upstream_es_module_tests`
- `@nodejs_26_3_1//:node_upstream_message_tests`
- `@nodejs_26_3_1//:node_upstream_module_hooks_tests`
- `@nodejs_26_3_1//:node_upstream_report_tests`
- `@nodejs_26_3_1//:node_upstream_test_runner_tests`

`node_upstream_test_runner_tests` places `NODE_TEST_DIR` under the upstream
`test/` directory for snapshot path normalization. Other suites place
`NODE_TEST_DIR` under `/tmp` so absolute Unix-domain socket paths remain below
Linux's 108-byte limit.

`@nodejs_26_3_1//:node_upstream_js_native_api_tutorial_tests` builds the nine
native addons used by the `2_function_arguments` through `8_passing_wrapped`
directories and runs their ten JavaScript tests in one Linux x86_64 remote
action.

`@nodejs_26_3_1//:node_upstream_js_native_api_value_tests` builds 14 native
addons for `test_array`, `test_bigint`, `test_constructor`, `test_conversions`,
`test_date`, `test_error`, `test_function`, `test_new_target`, `test_number`,
`test_promise`, `test_properties`, `test_sharedarraybuffer`, `test_string`, and
`test_symbol`, then runs their 20 JavaScript tests in one Linux x86_64 remote
action.

`@nodejs_26_3_1//:node_upstream_js_native_api_tests` builds all 38 native
addons used by the upstream `js-native-api` suite and runs all 56 JavaScript
tests in two Linux x86_64 remote shards. CI runs this complete target; the
tutorial and value targets remain available for focused validation.

`@nodejs_26_3_1//:node_upstream_node_api_default_compile_tests` builds 15
single-target `node-api` addons whose `binding.gyp` targets use no `defines` or
target-specific compiler flags, then runs their 23 JavaScript tests in two
Linux x86_64 remote shards.

`node_addon` passes `-UNDEBUG` because node-gyp addon targets do not inherit
Bazel's `opt`-mode `NDEBUG` definition. The Linux `node` executable uses the
SysV ELF hash table with `--export-dynamic`; this preserves Node-API symbol
lookup after postject rewrites the PIE executable in `test_sea_addon`.

`@nodejs_26_3_1//:node_upstream_node_api_tests` builds all 33 native addons
used by the upstream `node-api` suite and runs all 45 JavaScript tests in two
Linux x86_64 remote shards. CI runs this complete target; the default-compile
target remains available for focused validation.

`@nodejs_26_3_1//:node_upstream_addon_async_hello_world_tests` builds the seven
legacy `NODE_MODULE` addons in the four async directories and three hello-world
directories, then runs their ten JavaScript tests in one Linux x86_64 remote
action.

`@nodejs_26_3_1//:node_upstream_addon_context_worker_tests` builds nine legacy
`NODE_MODULE` addons for callback scope, contexts, isolates, request interrupts,
and workers, then runs their 15 JavaScript tests in one Linux x86_64 remote
action.

`@nodejs_26_3_1//:node_upstream_addon_callback_conversion_report_tests` builds
ten legacy `NODE_MODULE` addons for buffer callbacks, callback recursion,
encoding and errno conversion, reports, and external string and buffer limits,
then runs their 17 JavaScript tests in one Linux x86_64 remote action.

`@nodejs_26_3_1//:node_upstream_addon_module_loading_tests` builds seven addon
fixtures for ESM exports, long paths, `--no-addons`, module-version rejection,
missing self-registration, and symlinked loading, then runs their ten JavaScript
tests in one Linux x86_64 remote action.

`@nodejs_26_3_1//:node_upstream_addon_cppgc_profiler_repl_uv_tests` builds the
`cppgc-object`, `heap-profiler`, `repl-domain-abort`, and `uv-thread-name`
addons and runs their four JavaScript tests in one Linux x86_64 remote action.

`@nodejs_26_3_1//:node_upstream_addon_dlopen_esm_tests` builds the
`dlopen-ping-pong` addon and `ping.so`, builds the `esm` addon at both paths
required by the package export tests, and runs all six JavaScript tests in one
Linux x86_64 remote action.

`@nodejs_26_3_1//:node_upstream_addon_openssl_zlib_tests` builds three OpenSSL
addons, the Linux `testsetengine.engine`, and the zlib addon, then selects 11
JavaScript tests in one Linux x86_64 remote action. The macOS-only client-cert
and key-engine tests report runtime skips on Linux.

`@nodejs_26_3_1//:node_upstream_addon_tests` selects all 75 upstream `addons`
JavaScript tests in two Linux x86_64 remote shards. The 73 cross-platform tests
run, and the two macOS-only engine tests report runtime skips. CI runs this
complete target; the grouped addon targets remain available for focused
validation.

The Linux x86_64 test job also selects 51 tests from these upstream suites
across nine remote actions:

- `@nodejs_26_3_1//:node_upstream_abort_tests`
- `@nodejs_26_3_1//:node_upstream_ffi_tests`
- `@nodejs_26_3_1//:node_upstream_sqlite_tests`
- `@nodejs_26_3_1//:node_upstream_wasi_tests`
- `@nodejs_26_3_1//:node_upstream_wasm_allocation_tests`

The Bazel `node` target exports dynamic symbols on Linux, matching upstream
Node.js's `-rdynamic` link setting and allowing FFI to resolve
`uv_os_getpid`. Bazel builds the FFI and SQLite fixture libraries at the paths
expected by the upstream tests.

Bazel builds the `register-signal-handler` and `uv-handle-leak` addon fixtures,
so all 10 `abort` cases run. The WASI target excludes `wasi/test-wasi-readdir`
because BuildBuddy's execution filesystem includes directory entries beyond
the four entries asserted by that test.

The following Linux x86_64 targets run 64 more upstream tests across five
remote actions:

- `@nodejs_26_3_1//:node_upstream_pseudo_tty_tests`
- `@nodejs_26_3_1//:node_upstream_wpt_tests`

`node_upstream_pseudo_tty_tests` uses the pinned Python 3.11 toolchain because
upstream `tools/pseudo-tty.py` creates the controlling terminal for each of its
39 tests. `node_upstream_wpt_tests` runs 25 Node.js WPT runner files against
the WPT files pinned in the Node.js source archive.

`@nodejs_26_3_1//:node_upstream_pummel_tests` runs all 65 upstream `pummel`
cases sequentially in one Linux x86_64 remote action. The suite reports runtime
skips for `test-fs-watch-system-limit` when the executor's inotify limit is too
large, `test-keep-alive` when `wrk` is unavailable, and the 32-bit-only
`test-webcrypto-kangarootwelve-32bit-overflow` case.

The following Linux x86_64 targets run 68 upstream test files across ten
remote actions:

- `@nodejs_26_3_1//:node_upstream_client_proxy_tests`
- `@nodejs_26_3_1//:node_upstream_test426_tests`
- `@nodejs_26_3_1//:node_upstream_v8_updates_tests`

The 65 `client-proxy` tests use loopback HTTP, HTTPS, and proxy servers. The
`test426` runner uses the ECMA-426 source-map tests pinned in the Node.js source
archive. The upstream `v8-updates.status` file excludes `test-linux-perf`, so
the `v8-updates` target runs `test-linux-perf-logger` and
`test-trace-gc-flag`.

`@nodejs_26_3_1//:node_upstream_benchmark_tests` runs 39 benchmark validation
cases sequentially. `@nodejs_26_3_1//:node_upstream_benchmark_napi_test` runs
`benchmark/test-benchmark-napi` in a separate action with 13 Bazel-built native
bindings. The benchmark tests use test parameters and validate that each
benchmark entry point completes; they do not record performance measurements.

`@nodejs_26_3_1//:node_upstream_known_issues_tests` runs 22 cases sequentially
with the upstream suite's inverted expected-failure configuration. A target
failure means a known-issue case no longer produced its expected failure or
failed in a different way.

`@nodejs_26_3_1//:node_upstream_sea_tests` runs all 36 Single Executable
Application cases sequentially in one Linux x86_64 remote action. The tests
validate the LIEF-backed `--build-sea` implementation and the postject copy
pinned in the Node.js source archive.

`@nodejs_26_3_1//:node_upstream_embedding_tests` builds upstream `embedtest`
against the Bazel `node_snapshot_stub` and runs 13 embedding cases across four
Linux x86_64 shards. The 12 static-embedding cases run; upstream
`test-shared-embedding-v8` reports a runtime skip because this repository links
static `libnode`.
