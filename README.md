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

`@v8` projects `deps/v8` from the same Node.js 26.3.1 archive as a repository
because V8's Bazel targets use repository-root labels. `@nodejs_icu_26_3_1`
projects Node.js's bundled ICU 78 source and provides `//:icudata`, which
decompresses `icudt78l.dat.bz2` with the hermetic `@bzip2//:bzip2` executable.

`@nodejs_crates_26_3_1` projects `deps/crates` from the Node.js 26.3.1
archive. It contains Node.js's Cargo lockfile, vendored crates, patched `resb`
crate, `temporal_capi`, and `temporal_rs`. Rust targets use the pinned Rust
1.82.0 toolchain for Linux x86_64, Linux arm64, macOS x86_64, macOS arm64, and
Windows x86_64.
