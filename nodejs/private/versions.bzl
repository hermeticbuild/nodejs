"""Exact supported Node.js release records."""

def _nodejs_release(
        crates_repository_name,
        doc_dependencies_repository_name,
        doc_package_lock_sha256,
        headers_sha256,
        icu_repository_name,
        node_patches,
        release,
        repository_name,
        sha256,
        node_module_version,
        v8_repository_name,
        v8_patches,
        v8_version,
        uv_version):
    version_parts = release.split(".")
    if len(version_parts) != 3:
        fail("Node.js release must contain major, minor, and patch: {}".format(repr(release)))
    for part in version_parts:
        int(part)

    return struct(
        crates_repository_name = crates_repository_name,
        crates_strip_prefix = "node-v{}/deps/crates".format(release),
        doc_dependencies_repository_name = doc_dependencies_repository_name,
        doc_package_lock_sha256 = doc_package_lock_sha256,
        doc_package_lock_urls = [
            "https://raw.githubusercontent.com/nodejs/node/v{}/tools/doc/package-lock.json".format(release),
        ],
        headers_sha256 = headers_sha256,
        headers_strip_prefix = "node-v{}/include/node".format(release),
        headers_urls = [
            "https://nodejs.org/dist/v{release}/node-v{release}-headers.tar.xz".format(
                release = release,
            ),
        ],
        icu_repository_name = icu_repository_name,
        icu_strip_prefix = "node-v{}/deps/icu-small".format(release),
        node_module_version = node_module_version,
        node_patches = node_patches,
        release = release,
        repository_name = repository_name,
        sha256 = sha256,
        strip_prefix = "node-v{}".format(release),
        urls = [
            "https://nodejs.org/dist/v{release}/node-v{release}.tar.xz".format(
                release = release,
            ),
        ],
        uv_version = uv_version,
        v8_patches = v8_patches,
        v8_repository_name = v8_repository_name,
        v8_strip_prefix = "node-v{}/deps/v8".format(release),
        v8_version = v8_version,
    )

NODEJS_RELEASES = {
    "26.13.0": _nodejs_release(
        crates_repository_name = "nodejs_crates_26_13_0",
        doc_dependencies_repository_name = "nodejs_doc_dependencies_26_13_0",
        doc_package_lock_sha256 = "b044cacc3ef141d3a3bc1f00cc13429bb34aa60ae942c069ca8934b99020089b",
        headers_sha256 = "519e269c3e78bf513fdf53d2ab114b763173a7c9424bd477d4e182d782ea366f",
        icu_repository_name = "nodejs_icu_26_13_0",
        node_patches = [],
        release = "26.13.0",
        repository_name = "nodejs_26_13_0",
        sha256 = "263f639ecfa7a17b49438d76cdbf9aff73179e3c7cb789da69b900718427fa2e",
        node_module_version = 147,
        v8_repository_name = "v8",
        v8_patches = [
            Label("//nodejs/private/patches/v8:hermetic-toolchain.patch"),
            Label("//nodejs/private/patches/v8:llvm-ml.patch"),
            Label("//nodejs/private/patches/v8:nodejs-icu.patch"),
            Label("//nodejs/private/patches/v8:nodejs-targets.patch"),
            Label("//nodejs/private/patches/v8:temporal.patch"),
            Label("//nodejs/private/patches/v8:windows-defines.patch"),
            Label("//nodejs/private/patches/v8:windows-libraries.patch"),
            Label("//nodejs/private/patches/v8:nodejs-config.patch"),
            Label("//nodejs/private/patches/v8:windows-target-config.patch"),
            Label("//nodejs/private/patches/v8:zlib.patch"),
            Label("//nodejs/private/patches/v8:simd256.patch"),
        ],
        v8_version = "14.6.202.34",
        uv_version = "1.52.1",
    ),
}

SUPPORTED_NODEJS_VERSIONS = sorted(NODEJS_RELEASES.keys())
