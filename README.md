# Node.js for Bazel

This module is building Node.js release artifacts from the official Node.js
source archive with hermetic Bazel toolchains and declared Bazel actions. The
only supported release is Node.js 26.3.1.

The initial public contract selects and validates the upstream source archive.
Compilation targets, release archives, and the complete upstream test matrix
will be added against this exact source contract.

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

`@v8` projects `deps/v8` from the same Node.js 26.3.1 archive as a repository
because V8's Bazel targets use repository-root labels. `@nodejs_icu_26_3_1`
projects Node.js's bundled ICU 78 source and provides `//:icudata`, which
decompresses `icudt78l.dat.bz2` with the hermetic `@bzip2//:bzip2` executable.

`@nodejs_crates_26_3_1` projects `deps/crates` from the Node.js 26.3.1
archive. It contains Node.js's Cargo lockfile, vendored crates, patched `resb`
crate, `temporal_capi`, and `temporal_rs`. Rust targets use the pinned Rust
1.82.0 toolchain for Linux x86_64, Linux arm64, macOS x86_64, macOS arm64, and
Windows x86_64.
