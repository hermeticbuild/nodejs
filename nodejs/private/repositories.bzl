"""Repository rule for an official Node.js source release."""

_REQUIRED_SOURCE_FILES = [
    "common.gypi",
    "configure.py",
    "deps/v8/BUILD.bazel",
    "deps/v8/MODULE.bazel",
    "deps/v8/bazel/defs.bzl",
    "node.gyp",
    "tools/test.py",
]

_V8_EXPORTED_FILES = [
    "include/js_protocol.pdl",
    "src/objects/intl-objects.h",
    "testing/gtest/include/gtest/gtest_prod.h",
    "third_party/googletest/src/googletest/include/gtest/gtest_prod.h",
    "tools/arguments.mjs",
    "tools/codemap.mjs",
    "tools/consarray.mjs",
    "tools/csvparser.mjs",
    "tools/gdbinit",
    "tools/lldb_commands.py",
    "tools/logreader.mjs",
    "tools/profile.mjs",
    "tools/profile_view.mjs",
    "tools/sourcemap.mjs",
    "tools/splaytree.mjs",
    "tools/tickprocessor-driver.mjs",
    "tools/tickprocessor.mjs",
]

def _integer_define(repository_ctx, path, name):
    prefix = "#define {} ".format(name)
    values = []
    for line in repository_ctx.read(path).splitlines():
        stripped = line.strip()
        if not stripped.startswith(prefix):
            continue
        value = stripped[len(prefix):].strip()
        if value.isdigit():
            values.append(int(value))
    if len(values) != 1:
        fail("{} must define {} as one integer; found {}".format(path, name, values))
    return values[0]

def _version(repository_ctx, path, names):
    return ".".join([
        str(_integer_define(repository_ctx, path, name))
        for name in names
    ])

def _validate_release(repository_ctx):
    for path in _REQUIRED_SOURCE_FILES:
        if not repository_ctx.path(path).exists:
            fail("Node.js {} source archive is missing {}".format(repository_ctx.attr.release, path))

    node_version_path = "src/node_version.h"
    node_version = _version(
        repository_ctx,
        node_version_path,
        ["NODE_MAJOR_VERSION", "NODE_MINOR_VERSION", "NODE_PATCH_VERSION"],
    )
    if node_version != repository_ctx.attr.release:
        fail("Node.js source version {} does not match requested {}".format(
            node_version,
            repository_ctx.attr.release,
        ))
    if _integer_define(repository_ctx, node_version_path, "NODE_VERSION_IS_RELEASE") != 1:
        fail("Node.js {} is not marked as a release".format(repository_ctx.attr.release))

    node_module_version = _integer_define(
        repository_ctx,
        node_version_path,
        "NODE_MODULE_VERSION",
    )
    if node_module_version != repository_ctx.attr.node_module_version:
        fail("Node.js {} module ABI is {}, expected {}".format(
            repository_ctx.attr.release,
            node_module_version,
            repository_ctx.attr.node_module_version,
        ))

    v8_version = _version(
        repository_ctx,
        "deps/v8/include/v8-version.h",
        ["V8_MAJOR_VERSION", "V8_MINOR_VERSION", "V8_BUILD_NUMBER", "V8_PATCH_LEVEL"],
    )
    if v8_version != repository_ctx.attr.v8_version:
        fail("Node.js {} bundles V8 {}, expected {}".format(
            repository_ctx.attr.release,
            v8_version,
            repository_ctx.attr.v8_version,
        ))

    uv_version = _version(
        repository_ctx,
        "deps/uv/include/uv/version.h",
        ["UV_VERSION_MAJOR", "UV_VERSION_MINOR", "UV_VERSION_PATCH"],
    )
    if uv_version != repository_ctx.attr.uv_version:
        fail("Node.js {} bundles libuv {}, expected {}".format(
            repository_ctx.attr.release,
            uv_version,
            repository_ctx.attr.uv_version,
        ))

def _nodejs_source_repository_impl(repository_ctx):
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.urls,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = repository_ctx.attr.strip_prefix,
    )
    release_headers_directory = "bazel/release_headers"
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.headers_urls,
        output = release_headers_directory,
        sha256 = repository_ctx.attr.headers_sha256,
        stripPrefix = repository_ctx.attr.headers_strip_prefix,
    )
    release_config_path = "{}/config.gypi".format(release_headers_directory)
    if not repository_ctx.path(release_config_path).exists:
        fail("Node.js {} headers archive is missing config.gypi".format(
            repository_ctx.attr.release,
        ))
    release_config = repository_ctx.read(release_config_path)
    if '"node_module_version": {}'.format(repository_ctx.attr.node_module_version) not in release_config:
        fail("Node.js {} headers config.gypi has the wrong module ABI".format(
            repository_ctx.attr.release,
        ))
    repository_ctx.file("bazel/release_config.gypi", release_config)
    repository_ctx.delete(release_headers_directory)

    v8_build_path = "deps/v8/BUILD.bazel"
    v8_build = repository_ctx.read(v8_build_path)
    v8_build += "\nexports_files({} + glob([\"include/**/*.h\"]))\n".format(repr(_V8_EXPORTED_FILES))
    repository_ctx.file(v8_build_path, v8_build)
    _validate_release(repository_ctx)

    release_metadata = {
        "node_module_version": repository_ctx.attr.node_module_version,
        "release": repository_ctx.attr.release,
        "uv_version": repository_ctx.attr.uv_version,
        "v8_version": repository_ctx.attr.v8_version,
    }
    repository_ctx.file(
        "bazel/release.bzl",
        "NODEJS_RELEASE = struct(\n" +
        "    node_module_version = {node_module_version},\n".format(
            node_module_version = release_metadata["node_module_version"],
        ) +
        "    release = {release},\n".format(release = repr(release_metadata["release"])) +
        "    uv_version = {uv_version},\n".format(uv_version = repr(release_metadata["uv_version"])) +
        "    v8_version = {v8_version},\n".format(v8_version = repr(release_metadata["v8_version"])) +
        ")\n",
    )
    repository_ctx.file(
        "bazel/release_metadata.json",
        json.encode_indent(release_metadata, indent = "  ") + "\n",
    )
    repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD.bazel")

nodejs_source_repository = repository_rule(
    implementation = _nodejs_source_repository_impl,
    attrs = {
        "build_file": attr.label(mandatory = True, allow_single_file = True),
        "headers_sha256": attr.string(mandatory = True),
        "headers_strip_prefix": attr.string(mandatory = True),
        "headers_urls": attr.string_list(mandatory = True),
        "node_module_version": attr.int(mandatory = True),
        "release": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
        "uv_version": attr.string(mandatory = True),
        "v8_version": attr.string(mandatory = True),
    },
)

def _nodejs_v8_repository_impl(repository_ctx):
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.urls,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = repository_ctx.attr.strip_prefix,
    )
    for patch in repository_ctx.attr.patches:
        repository_ctx.patch(repository_ctx.path(patch), strip = 1)
    repository_ctx.file(
        "third_party/fast_float/src/BUILD.bazel",
        repository_ctx.read(repository_ctx.attr.fast_float_build_file),
    )

nodejs_v8_repository = repository_rule(
    implementation = _nodejs_v8_repository_impl,
    attrs = {
        "fast_float_build_file": attr.label(mandatory = True, allow_single_file = True),
        "patches": attr.label_list(allow_files = True),
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
    },
)

def _nodejs_crates_repository_impl(repository_ctx):
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.urls,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = repository_ctx.attr.strip_prefix,
    )
    for path in [
        ".cargo/config.toml",
        "Cargo.lock",
        "Cargo.toml",
        "patches/resb/Cargo.toml",
        "vendor/temporal_capi/Cargo.toml",
        "vendor/temporal_rs/Cargo.toml",
    ]:
        if not repository_ctx.path(path).exists:
            fail("Node.js Rust crates are missing {}".format(path))
    repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD.bazel")
    for build_file, destination in repository_ctx.attr.build_files.items():
        repository_ctx.symlink(build_file, destination)

nodejs_crates_repository = repository_rule(
    implementation = _nodejs_crates_repository_impl,
    attrs = {
        "build_file": attr.label(mandatory = True, allow_single_file = True),
        "build_files": attr.label_keyed_string_dict(mandatory = True, allow_files = True),
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
    },
)

def _nodejs_icu_repository_impl(repository_ctx):
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.urls,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = repository_ctx.attr.strip_prefix,
    )

    # These BUILD.bazel files make ICU source directories subpackages, which
    # excludes their files from the BUILD.icu.bazel root globs.
    for build_file in [
        "source/common/BUILD.bazel",
        "source/i18n/BUILD.bazel",
        "source/stubdata/BUILD.bazel",
        "source/tools/toolutil/BUILD.bazel",
    ]:
        repository_ctx.delete(build_file)
    repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD.bazel")

nodejs_icu_repository = repository_rule(
    implementation = _nodejs_icu_repository_impl,
    attrs = {
        "build_file": attr.label(mandatory = True, allow_single_file = True),
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
    },
)
