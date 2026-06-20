# Node.js for Bazel

This repository builds Node.js 26.3.1 from the official source archive with
hermetic Bazel toolchains. Node.js 26.3.1 is the only supported release.

The build supports these target platforms:

- Linux x86_64 and arm64
- macOS x86_64 and arm64
- Windows x86_64 and arm64

`MODULE.bazel` selects Node.js 26.3.1 through
`//nodejs:extensions.bzl`. The extension creates the Node.js, V8, ICU, Rust
crate, and documentation dependency repositories from pinned inputs.

## Build

Use remote execution for builds and tests:

```console
bazel build --config=release --config=remote @nodejs_26_3_1//:node
bazel test --config=release --config=remote //tests/node:node_test
```

Select a non-Linux target with an LLVM platform:

```console
bazel build --config=release --config=remote \
  --platforms=@llvm//platforms:macos_aarch64 \
  @nodejs_26_3_1//:node

bazel build --config=release --config=remote \
  --platforms=@llvm//platforms:windows_aarch64_msvc \
  //tests/node:node_windows_binary
```

The Windows build runs compilation and linking on remote Linux workers. CI
downloads the resulting `node.exe` and executes it on native Windows x86_64
and Windows arm64 runners.

## Source and configuration

`@nodejs_26_3_1` contains the pinned Node.js source and the generated release
configuration. Important targets include:

- `//:release_metadata`: Node.js, Node module ABI, V8, and libuv versions.
- `//:configure_audit_sources`: upstream configuration inputs.
- `//:config_gypi`: target-specific Linux, macOS, and Windows release values.
- `//:node_javascript`: generated built-in JavaScript and `config.gypi`.
- `//:libnode`: Node.js and its bundled dependencies.
- `//:node`: the Node.js executable.

`tools/configure_inventory.py` reads `configure.py`, `common.gypi`,
`node.gyp`, and `tools/v8_gypfiles` without executing configure.py or GYP.
`docs/configure-check-audit.md` records the reviewed release settings and
the upstream assignments, defaults, and references.

Update or verify the inventory with:

```console
tools/configure_check_audit.sh
tools/configure_check_audit.sh --check
```

## Bundled dependencies

The build uses the dependency sources bundled in Node.js 26.3.1, including
V8, ICU, OpenSSL, libuv, zlib, Brotli, nghttp2, zstd, SQLite, libffi, LIEF,
llhttp, c-ares, simdjson, Ada, merve, and the Temporal Rust crates.

`@v8` projects `deps/v8` as a repository because V8's Bazel files use
repository-root labels. Target CPU and target OS values come from
`platform_mappings` and remain configured for execution-platform tools such
as `mksnapshot`.

`@nodejs_icu_26_3_1` builds ICU 78 and embeds `icudt78l.dat`. The source
archive stores that file as a raw bzip2 stream, so the build uses the
hermetic `@bzip2//:bzip2` executable. The stream is not a tar archive and
cannot be extracted by `bsdtar`.

`@nodejs_crates_26_3_1` contains Node.js's Cargo manifests, lockfile,
vendored crates, and patched `resb` crate. `@nodejs_crates` uses `rules_rs`
0.0.86 and the pinned Rust 1.92.0 toolchain for all six target platforms.

## Release archives

`@nodejs_26_3_1//:release_archives` creates the upstream binary distribution
layout:

- `.tar.gz` and `.tar.xz` for Linux and macOS x86_64 and arm64
- `.zip` for Windows x86_64 and arm64

The archives contain Node.js, npm, public headers, debugger files, and the
platform-specific launch scripts. Node.js 26.3.1 disables Corepack in its
release configuration.

`tar.bzl` and its hermetic `bsdtar` toolchain create deterministic tar
archives. `@bazel_tools//tools/zip:zipper` creates deterministic Windows ZIP
archives.

`//tests/release:release_archive_test` validates Linux and macOS archive
layout, metadata, gzip/xz equivalence, relocation, Node.js, npm, and npx.
`//tests/release:windows_release_archive_validation` validates the Windows
layout, metadata, wrappers, npm, and PE executable for the selected Windows
architecture.

## Tests

The repository has focused tests for the bundled dependencies, release
configuration, generated JavaScript, `libnode`, Node.js, Temporal, Rust, and
release archives.

`@nodejs_26_3_1//:node_test` exposes the upstream Node.js Python test harness:

```console
bazel run --config=release --config=remote @nodejs_26_3_1//:node_test -- \
  parallel/test-assert parallel/test-buffer-alloc
```

CI runs the upstream smoke, parallel, sequential, addon, Node-API,
JavaScript, WPT, pummel, benchmark, SEA, embedding, and documentation test
targets. The complete target list is in `.github/workflows/ci.yml`; shard
definitions and exclusions are in `nodejs/private/node_test_shards.bzl` and
`nodejs.BUILD.bazel`.

## Continuous integration

`.github/workflows/ci.yml` validates:

- configure inventory and source selection
- Linux and macOS x86_64 and arm64 builds and tests
- Windows x86_64 and arm64 remote builds
- native Windows x86_64 and arm64 execution
- release archives
- Rust 1.92.0 and Temporal

CI commands use `--config=remote` and reject stale module lockfiles.
