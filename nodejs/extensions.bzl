"""Bzlmod extension for selecting Node.js source releases."""

load(
    "//nodejs/private:repositories.bzl",
    "nodejs_crates_repository",
    "nodejs_doc_dependencies_repository",
    "nodejs_icu_repository",
    "nodejs_source_repository",
    "nodejs_v8_repository",
)
load("//nodejs/private:versions.bzl", "NODEJS_RELEASES")
load("//nodejs/private/overlays/crates:files.bzl", "CRATES_BUILD_FILES")

_BUILD_FILE = Label("//:nodejs.BUILD.bazel")
_CRATES_BUILD_FILE = Label("//nodejs/private/overlays/crates:BUILD.crates.bazel")
_ICU_BUILD_FILE = Label("//nodejs/private/overlays/icu:BUILD.icu.bazel")
_V8_FAST_FLOAT_BUILD_FILE = Label("//nodejs/private/overlays/v8/third_party/fast_float/src:BUILD.fast_float.bazel")
_V8_PATCHES = [
    Label("//nodejs/private/patches/v8:hermetic-toolchain.patch"),
    Label("//nodejs/private/patches/v8:nodejs-icu.patch"),
    Label("//nodejs/private/patches/v8:nodejs-targets.patch"),
    Label("//nodejs/private/patches/v8:temporal.patch"),
    Label("//nodejs/private/patches/v8:nodejs-config.patch"),
    Label("//nodejs/private/patches/v8:zlib.patch"),
    Label("//nodejs/private/patches/v8:simd256.patch"),
]

def _nodejs_impl(module_ctx):
    requested_versions = {}
    root_requested_versions = {}

    for module in module_ctx.modules:
        for version_tag in module.tags.version:
            version = version_tag.version
            if version not in NODEJS_RELEASES:
                fail(
                    "Unsupported Node.js version {version}; supported versions are {supported}".format(
                        version = repr(version),
                        supported = ", ".join(sorted(NODEJS_RELEASES.keys())),
                    ),
                )

            requested_versions[version] = True
            if module.is_root:
                root_requested_versions[version] = True

    for version in sorted(requested_versions.keys()):
        release = NODEJS_RELEASES[version]
        nodejs_source_repository(
            name = release.repository_name,
            build_file = _BUILD_FILE,
            headers_sha256 = release.headers_sha256,
            headers_strip_prefix = release.headers_strip_prefix,
            headers_urls = release.headers_urls,
            node_module_version = release.node_module_version,
            release = release.release,
            sha256 = release.sha256,
            strip_prefix = release.strip_prefix,
            urls = release.urls,
            uv_version = release.uv_version,
            v8_version = release.v8_version,
        )
        nodejs_doc_dependencies_repository(
            name = release.doc_dependencies_repository_name,
            sha256 = release.sha256,
            strip_prefix = release.strip_prefix,
            urls = release.urls,
        )
        nodejs_v8_repository(
            name = release.v8_repository_name,
            fast_float_build_file = _V8_FAST_FLOAT_BUILD_FILE,
            patches = _V8_PATCHES,
            sha256 = release.sha256,
            strip_prefix = release.v8_strip_prefix,
            urls = release.urls,
        )
        nodejs_crates_repository(
            name = release.crates_repository_name,
            build_file = _CRATES_BUILD_FILE,
            build_files = CRATES_BUILD_FILES,
            sha256 = release.sha256,
            strip_prefix = release.crates_strip_prefix,
            urls = release.urls,
        )
        nodejs_icu_repository(
            name = release.icu_repository_name,
            build_file = _ICU_BUILD_FILE,
            sha256 = release.sha256,
            strip_prefix = release.icu_strip_prefix,
            urls = release.urls,
        )

    root_direct_deps = [
        repository_name
        for version in sorted(root_requested_versions.keys())
        for repository_name in [
            NODEJS_RELEASES[version].repository_name,
            NODEJS_RELEASES[version].crates_repository_name,
            NODEJS_RELEASES[version].icu_repository_name,
            NODEJS_RELEASES[version].v8_repository_name,
        ]
    ]
    root_direct_dev_deps = []
    if not module_ctx.root_module_has_non_dev_dependency:
        root_direct_dev_deps = root_direct_deps
        root_direct_deps = []

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = root_direct_deps,
        root_module_direct_dev_deps = root_direct_dev_deps,
    )

_version = tag_class(
    attrs = {
        "version": attr.string(mandatory = True),
    },
    doc = "Selects an exact supported Node.js release.",
)

nodejs = module_extension(
    implementation = _nodejs_impl,
    tag_classes = {
        "version": _version,
    },
)
