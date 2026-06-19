"""Node.js release archive layout."""

load("@bazel_lib//lib:copy_file.bzl", "copy_file")
load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_lib//lib:paths.bzl", "to_repository_relative_path")
load("@bazel_lib//lib:run_binary.bzl", "run_binary")
load("@tar.bzl", "mtree_spec", "tar")

_RELEASE_V8_HEADERS = [
    "deps/v8/include/cppgc/allocation.h",
    "deps/v8/include/cppgc/common.h",
    "deps/v8/include/cppgc/cross-thread-persistent.h",
    "deps/v8/include/cppgc/custom-space.h",
    "deps/v8/include/cppgc/default-platform.h",
    "deps/v8/include/cppgc/explicit-management.h",
    "deps/v8/include/cppgc/garbage-collected.h",
    "deps/v8/include/cppgc/heap-consistency.h",
    "deps/v8/include/cppgc/heap-handle.h",
    "deps/v8/include/cppgc/heap-state.h",
    "deps/v8/include/cppgc/heap-statistics.h",
    "deps/v8/include/cppgc/heap.h",
    "deps/v8/include/cppgc/internal/api-constants.h",
    "deps/v8/include/cppgc/internal/atomic-entry-flag.h",
    "deps/v8/include/cppgc/internal/base-page-handle.h",
    "deps/v8/include/cppgc/internal/caged-heap-local-data.h",
    "deps/v8/include/cppgc/internal/caged-heap.h",
    "deps/v8/include/cppgc/internal/compiler-specific.h",
    "deps/v8/include/cppgc/internal/conditional-stack-allocated.h",
    "deps/v8/include/cppgc/internal/finalizer-trait.h",
    "deps/v8/include/cppgc/internal/gc-info.h",
    "deps/v8/include/cppgc/internal/logging.h",
    "deps/v8/include/cppgc/internal/member-storage.h",
    "deps/v8/include/cppgc/internal/name-trait.h",
    "deps/v8/include/cppgc/internal/persistent-node.h",
    "deps/v8/include/cppgc/internal/pointer-policies.h",
    "deps/v8/include/cppgc/internal/write-barrier.h",
    "deps/v8/include/cppgc/liveness-broker.h",
    "deps/v8/include/cppgc/macros.h",
    "deps/v8/include/cppgc/member.h",
    "deps/v8/include/cppgc/name-provider.h",
    "deps/v8/include/cppgc/object-size-trait.h",
    "deps/v8/include/cppgc/persistent.h",
    "deps/v8/include/cppgc/platform.h",
    "deps/v8/include/cppgc/prefinalizer.h",
    "deps/v8/include/cppgc/process-heap-statistics.h",
    "deps/v8/include/cppgc/sentinel-pointer.h",
    "deps/v8/include/cppgc/source-location.h",
    "deps/v8/include/cppgc/testing.h",
    "deps/v8/include/cppgc/trace-trait.h",
    "deps/v8/include/cppgc/type-traits.h",
    "deps/v8/include/cppgc/visitor.h",
    "deps/v8/include/libplatform/libplatform-export.h",
    "deps/v8/include/libplatform/libplatform.h",
    "deps/v8/include/libplatform/v8-tracing.h",
    "deps/v8/include/v8-array-buffer.h",
    "deps/v8/include/v8-callbacks.h",
    "deps/v8/include/v8-container.h",
    "deps/v8/include/v8-context.h",
    "deps/v8/include/v8-cppgc.h",
    "deps/v8/include/v8-data.h",
    "deps/v8/include/v8-date.h",
    "deps/v8/include/v8-debug.h",
    "deps/v8/include/v8-embedder-heap.h",
    "deps/v8/include/v8-embedder-state-scope.h",
    "deps/v8/include/v8-exception.h",
    "deps/v8/include/v8-extension.h",
    "deps/v8/include/v8-external.h",
    "deps/v8/include/v8-forward.h",
    "deps/v8/include/v8-function-callback.h",
    "deps/v8/include/v8-function.h",
    "deps/v8/include/v8-handle-base.h",
    "deps/v8/include/v8-initialization.h",
    "deps/v8/include/v8-internal.h",
    "deps/v8/include/v8-isolate.h",
    "deps/v8/include/v8-json.h",
    "deps/v8/include/v8-local-handle.h",
    "deps/v8/include/v8-locker.h",
    "deps/v8/include/v8-maybe.h",
    "deps/v8/include/v8-memory-span.h",
    "deps/v8/include/v8-message.h",
    "deps/v8/include/v8-microtask-queue.h",
    "deps/v8/include/v8-microtask.h",
    "deps/v8/include/v8-object.h",
    "deps/v8/include/v8-persistent-handle.h",
    "deps/v8/include/v8-platform.h",
    "deps/v8/include/v8-primitive-object.h",
    "deps/v8/include/v8-primitive.h",
    "deps/v8/include/v8-profiler.h",
    "deps/v8/include/v8-promise.h",
    "deps/v8/include/v8-proxy.h",
    "deps/v8/include/v8-regexp.h",
    "deps/v8/include/v8-sandbox.h",
    "deps/v8/include/v8-script.h",
    "deps/v8/include/v8-snapshot.h",
    "deps/v8/include/v8-source-location.h",
    "deps/v8/include/v8-statistics.h",
    "deps/v8/include/v8-template.h",
    "deps/v8/include/v8-traced-handle.h",
    "deps/v8/include/v8-typed-array.h",
    "deps/v8/include/v8-unwinder.h",
    "deps/v8/include/v8-value-serializer.h",
    "deps/v8/include/v8-value.h",
    "deps/v8/include/v8-version.h",
    "deps/v8/include/v8-wasm.h",
    "deps/v8/include/v8-weak-callback-info.h",
    "deps/v8/include/v8.h",
    "deps/v8/include/v8config.h",
]

# tools/install.py installs deps/openssl/config after the public OpenSSL
# headers. The generated headers below replace public headers with the same
# destination path.
_OPENSSL_GENERATED_HEADERS = [
    "asn1.h",
    "asn1t.h",
    "bio.h",
    "cmp.h",
    "cms.h",
    "comp.h",
    "conf.h",
    "configuration.h",
    "core_names.h",
    "crmf.h",
    "crypto.h",
    "ct.h",
    "err.h",
    "ess.h",
    "fipskey.h",
    "lhash.h",
    "ocsp.h",
    "opensslv.h",
    "pkcs12.h",
    "pkcs7.h",
    "safestack.h",
    "srp.h",
    "ssl.h",
    "ui.h",
    "x509.h",
    "x509_acert.h",
    "x509_vfy.h",
    "x509v3.h",
]

_NODE_HEADERS = [
    "common.gypi",
    "src/js_native_api.h",
    "src/js_native_api_types.h",
    "src/node.h",
    "src/node_api.h",
    "src/node_api_types.h",
    "src/node_buffer.h",
    "src/node_object_wrap.h",
    "src/node_version.h",
]

_EXECUTABLE_RELEASE_FILES = [
    "bin/node",
    "lib/node_modules/npm/bin/node-gyp-bin/node-gyp",
    "lib/node_modules/npm/bin/node-gyp-bin/node-gyp.cmd",
    "lib/node_modules/npm/bin/npm",
    "lib/node_modules/npm/bin/npm-cli.js",
    "lib/node_modules/npm/bin/npm-prefix.js",
    "lib/node_modules/npm/bin/npm.cmd",
    "lib/node_modules/npm/bin/npx",
    "lib/node_modules/npm/bin/npx-cli.js",
    "lib/node_modules/npm/bin/npx.cmd",
    "lib/node_modules/npm/lib/utils/completion.sh",
    "lib/node_modules/npm/node_modules/@npmcli/arborist/bin/index.js",
    "lib/node_modules/npm/node_modules/@npmcli/installed-package-contents/bin/index.js",
    "lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin/node-gyp",
    "lib/node_modules/npm/node_modules/@npmcli/run-script/lib/node-gyp-bin/node-gyp.cmd",
    "lib/node_modules/npm/node_modules/cssesc/bin/cssesc",
    "lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/gyp",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/gyp.bat",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/gyp_main.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/MSVSSettings_test.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/__init__.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/common_test.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/easy_xml_test.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/flock_tool.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/generator/msvs_test.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/input_test.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/mac_tool.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/pylib/gyp/win_tool.py",
    "lib/node_modules/npm/node_modules/node-gyp/gyp/test_gyp.py",
    "lib/node_modules/npm/node_modules/nopt/bin/nopt.js",
    "lib/node_modules/npm/node_modules/pacote/bin/index.js",
    "lib/node_modules/npm/node_modules/qrcode-terminal/bin/qrcode-terminal.js",
    "lib/node_modules/npm/node_modules/semver/bin/semver.js",
    "lib/node_modules/npm/node_modules/which/bin/which.js",
]

_WINDOWS_EMPTY_RELEASE_DIRECTORIES = [
    "node_modules/npm/tap-snapshots",
    "node_modules/npm/tap-snapshots/workspaces",
    "node_modules/npm/tap-snapshots/workspaces/arborist",
]

_WINDOWS_RELEASE_WRAPPERS = [
    "npm",
    "npm.cmd",
    "npm.ps1",
    "npx",
    "npx.cmd",
    "npx.ps1",
]

_RELEASE_FILES = [
    "CHANGELOG.md",
    "LICENSE",
    "README.md",
    "deps/zlib/zconf.h",
    "deps/zlib/zlib.h",
    "doc/node.1",
]

_V8_RELEASE_FILES = [
    "//deps/v8:tools/gdbinit",
    "//deps/v8:tools/lldb_commands.py",
]

_REPLACE_PREFIXES = {
    "CHANGELOG.md": "CHANGELOG.md",
    "LICENSE": "LICENSE",
    "README.md": "README.md",
    "common.gypi": "include/node/common.gypi",
    "deps/npm": "lib/node_modules/npm",
    "deps/openssl/config": "include/node/openssl",
    "deps/openssl/openssl/include/openssl": "include/node/openssl",
    "deps/uv/include": "include/node",
    "deps/v8/include": "include/node",
    "deps/v8/tools/gdbinit": "share/doc/node/gdbinit",
    "deps/v8/tools/lldb_commands.py": "share/doc/node/lldb_commands.py",
    "deps/zlib/zconf.h": "include/node/zconf.h",
    "deps/zlib/zlib.h": "include/node/zlib.h",
    "doc/node.1": "share/man/man1/node.1",
    "generated/config/linux_arm64/config.gypi": "include/node/config.gypi",
    "generated/config/linux_x86_64/config.gypi": "include/node/config.gypi",
    "generated/config/macos_arm64/config.gypi": "include/node/config.gypi",
    "generated/config/macos_x86_64/config.gypi": "include/node/config.gypi",
    "node": "bin/node",
    "src": "include/node",
}

_WINDOWS_REPLACE_PREFIXES = {
    "CHANGELOG.md": "CHANGELOG.md",
    "LICENSE": "LICENSE",
    "README.md": "README.md",
    "deps/npm": "node_modules/npm",
    "generated/release/windows": "",
    "node.exe": "node.exe",
    "tools/msvs/install_tools/install_tools.bat": "install_tools.bat",
    "tools/msvs/nodevars.bat": "nodevars.bat",
}

_PLATFORMS = [
    struct(
        archive_formats = ["tar_gz", "tar_xz"],
        config = ":target_linux_x86_64",
        constraints = ["@platforms//cpu:x86_64", "@platforms//os:linux"],
        name = "linux_x86_64",
        release_name = "linux-x64",
    ),
    struct(
        archive_formats = ["tar_gz", "tar_xz"],
        config = ":target_linux_arm64",
        constraints = ["@platforms//cpu:aarch64", "@platforms//os:linux"],
        name = "linux_arm64",
        release_name = "linux-arm64",
    ),
    struct(
        archive_formats = ["tar_gz", "tar_xz"],
        config = ":target_macos_x86_64",
        constraints = ["@platforms//cpu:x86_64", "@platforms//os:macos"],
        name = "macos_x86_64",
        release_name = "darwin-x64",
    ),
    struct(
        archive_formats = ["tar_gz", "tar_xz"],
        config = ":target_macos_arm64",
        constraints = ["@platforms//cpu:aarch64", "@platforms//os:macos"],
        name = "macos_arm64",
        release_name = "darwin-arm64",
    ),
    struct(
        archive_formats = ["zip"],
        config = ":target_windows_arm64",
        constraints = ["@platforms//cpu:aarch64", "@platforms//os:windows"],
        name = "windows_arm64",
        release_name = "win-arm64",
    ),
    struct(
        archive_formats = ["zip"],
        config = ":target_windows_x86_64",
        constraints = ["@platforms//cpu:x86_64", "@platforms//os:windows"],
        name = "windows_x86_64",
        release_name = "win-x64",
    ),
]

def _release_sources(node, config_gypi):
    public_openssl_headers = native.glob(
        ["deps/openssl/openssl/include/openssl/**/*.h"],
        exclude = [
            "deps/openssl/openssl/include/openssl/{}".format(header)
            for header in _OPENSSL_GENERATED_HEADERS
        ],
    )
    v8_headers = [
        "//deps/v8:" + path[len("deps/v8/"):]
        for path in _RELEASE_V8_HEADERS
    ]
    return [node, config_gypi] + _NODE_HEADERS + _RELEASE_FILES + _V8_RELEASE_FILES + v8_headers + native.glob(
        [
            "deps/npm/**",
            "deps/openssl/config/**/*.h",
            "deps/uv/include/**/*.h",
        ],
        exclude = ["deps/npm/**/test/**"],
    ) + public_openssl_headers

def _windows_release_sources(node, wrappers):
    return [node] + wrappers + [
        "CHANGELOG.md",
        "LICENSE",
        "README.md",
        "tools/msvs/install_tools/install_tools.bat",
        "tools/msvs/nodevars.bat",
    ] + native.glob(
        ["deps/npm/**"],
        exclude = ["deps/npm/**/test/**"],
    )

def _replace_prefix(path, replace_prefixes):
    matched_prefix = None
    for prefix in replace_prefixes:
        if (path == prefix or path.startswith(prefix + "/")) and (matched_prefix == None or len(prefix) > len(matched_prefix)):
            matched_prefix = prefix
    if matched_prefix == None:
        fail("Windows release file has no destination: {}".format(path))

    suffix = path[len(matched_prefix):].lstrip("/")
    replacement = replace_prefixes[matched_prefix].rstrip("/")
    if replacement and suffix:
        return replacement + "/" + suffix
    return replacement or suffix

def _release_zip_impl(ctx):
    directories = ctx.files.directory
    if len(directories) != 1 or not directories[0].is_directory:
        fail("directory must produce one directory")
    directory = directories[0]

    files = {}
    archive_directories = {ctx.attr.root: True}
    for source in ctx.files.srcs:
        destination = _replace_prefix(to_repository_relative_path(source), ctx.attr.replace_prefixes)
        archive_path = ctx.attr.root + "/" + destination
        if archive_path in files:
            fail("duplicate Windows release destination: {}".format(archive_path))
        files[archive_path] = source

        components = destination.split("/")
        for index in range(len(components) - 1):
            archive_directories[ctx.attr.root + "/" + "/".join(components[:index + 1])] = True

    for relative_directory in ctx.attr.empty_directories:
        components = relative_directory.split("/")
        for index in range(len(components)):
            archive_directories[ctx.attr.root + "/" + "/".join(components[:index + 1])] = True

    mappings_by_name = {
        archive_path + "/": "{}={}".format(archive_path, directory.path)
        for archive_path in archive_directories
    }
    for archive_path, source in files.items():
        mappings_by_name[archive_path] = "{}={}".format(archive_path, source.path)
    mappings = [mappings_by_name[name] for name in sorted(mappings_by_name)]

    filelist = ctx.actions.declare_file(ctx.label.name + ".filelist")
    ctx.actions.write(filelist, "\n".join(mappings) + "\n")
    ctx.actions.run(
        executable = ctx.executable._zipper,
        arguments = ["cC", ctx.outputs.out.path, "@" + filelist.path],
        inputs = depset(ctx.files.srcs + [directory, filelist]),
        outputs = [ctx.outputs.out],
        mnemonic = "NodejsReleaseZip",
        progress_message = "Creating Windows Node.js release ZIP %{output}",
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

_release_zip = rule(
    implementation = _release_zip_impl,
    attrs = {
        "directory": attr.label(allow_files = True, mandatory = True),
        "empty_directories": attr.string_list(),
        "out": attr.output(mandatory = True),
        "replace_prefixes": attr.string_dict(mandatory = True),
        "root": attr.string(mandatory = True),
        "srcs": attr.label_list(allow_files = True),
        "_zipper": attr.label(
            default = "@bazel_tools//tools/zip:zipper",
            cfg = "exec",
            executable = True,
        ),
    },
)

def nodejs_release_archives(name, version, node, config_gypi):
    """Creates the upstream Node.js binary archive layout."""
    windows_wrappers = []
    for wrapper in _WINDOWS_RELEASE_WRAPPERS:
        target = "_windows_release_{}".format(wrapper.replace(".", "_"))
        copy_file(
            name = target,
            src = "deps/npm/bin/{}".format(wrapper),
            out = "generated/release/windows/{}".format(wrapper),
            visibility = ["//visibility:private"],
        )
        windows_wrappers.append(":" + target)

    windows_sources = _windows_release_sources(node, windows_wrappers)

    copy_to_directory(
        name = "release_tree",
        srcs = select({
            ":target_windows": windows_sources,
            "//conditions:default": _release_sources(node, config_gypi),
        }),
        out = "release",
        hardlink = "off",
        replace_prefixes = select({
            ":target_windows": _WINDOWS_REPLACE_PREFIXES,
            "//conditions:default": _REPLACE_PREFIXES,
        }),
        root_paths = ["."],
        visibility = ["//visibility:public"],
    )

    mtree_spec(
        name = "_release_mtree",
        srcs = [":release_tree"],
        include_runfiles = False,
        visibility = ["//visibility:private"],
    )

    gzip_archives = {}
    xz_archives = {}
    zip_archives = {}
    for platform in _PLATFORMS:
        root = "node-v{}-{}".format(version, platform.release_name)
        release_constraints = platform.constraints + select({
            ":release_build": [],
            "//conditions:default": ["@platforms//:incompatible"],
        })
        normalized_mtree = "_release_mtree_{}".format(platform.name)
        if "tar_gz" in platform.archive_formats or "tar_xz" in platform.archive_formats:
            run_binary(
                name = normalized_mtree,
                srcs = [
                    ":_release_mtree",
                    ":release_tree",
                ],
                outs = [normalized_mtree + ".mtree"],
                args = [
                    "$(execpath :_release_mtree)",
                    "$(execpath {}.mtree)".format(normalized_mtree),
                    root,
                ] + _EXECUTABLE_RELEASE_FILES,
                target_compatible_with = release_constraints,
                tool = "@nodejs//nodejs/private:release_mtree",
                visibility = ["//visibility:private"],
            )

        if "tar_gz" in platform.archive_formats:
            gzip_target = "_release_archive_{}_tar_gz".format(platform.name)
            tar(
                name = gzip_target,
                srcs = [":release_tree"],
                compress = "gzip",
                compute_unused_inputs = 0,
                mtree = ":" + normalized_mtree,
                out = root + ".tar.gz",
                target_compatible_with = release_constraints,
                visibility = ["//visibility:private"],
            )
            gzip_archives[platform.config] = ":" + gzip_target

        if "tar_xz" in platform.archive_formats:
            xz_target = "_release_archive_{}_tar_xz".format(platform.name)
            tar(
                name = xz_target,
                srcs = [":release_tree"],
                compress = "xz",
                compute_unused_inputs = 0,
                mtree = ":" + normalized_mtree,
                out = root + ".tar.xz",
                target_compatible_with = release_constraints,
                visibility = ["//visibility:private"],
            )
            xz_archives[platform.config] = ":" + xz_target

        if "zip" in platform.archive_formats:
            zip_target = "_release_archive_{}_zip".format(platform.name)
            _release_zip(
                name = zip_target,
                directory = ":release_tree",
                empty_directories = _WINDOWS_EMPTY_RELEASE_DIRECTORIES,
                out = root + ".zip",
                replace_prefixes = _WINDOWS_REPLACE_PREFIXES,
                root = root,
                srcs = windows_sources,
                target_compatible_with = release_constraints,
                visibility = ["//visibility:private"],
            )
            zip_archives[platform.config] = ":" + zip_target

    native.alias(
        name = name + "_tar_gz",
        actual = select(gzip_archives),
        visibility = ["//visibility:public"],
    )
    native.alias(
        name = name + "_tar_xz",
        actual = select(xz_archives),
        visibility = ["//visibility:public"],
    )
    native.alias(
        name = name + "_zip",
        actual = select(
            zip_archives,
            no_match_error = "{}_zip currently supports Windows x86_64 and arm64 targets".format(name),
        ),
        visibility = ["//visibility:public"],
    )
    native.filegroup(
        name = name,
        srcs = select({
            ":target_windows_arm64": [":" + name + "_zip"],
            ":target_windows_x86_64": [":" + name + "_zip"],
            "//conditions:default": [
                ":" + name + "_tar_gz",
                ":" + name + "_tar_xz",
            ],
        }),
        visibility = ["//visibility:public"],
    )
