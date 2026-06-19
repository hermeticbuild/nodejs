"""Bzlmod extension for selecting Node.js source releases."""

load("//nodejs/private:repositories.bzl", "nodejs_source_repository")
load("//nodejs/private:versions.bzl", "NODEJS_RELEASES")

_BUILD_FILE = Label("//:nodejs.BUILD.bazel")

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
            node_module_version = release.node_module_version,
            release = release.release,
            sha256 = release.sha256,
            strip_prefix = release.strip_prefix,
            urls = release.urls,
            uv_version = release.uv_version,
            v8_version = release.v8_version,
        )

    root_direct_deps = [
        NODEJS_RELEASES[version].repository_name
        for version in sorted(root_requested_versions.keys())
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
