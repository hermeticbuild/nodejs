"""Exact supported Node.js release records."""

def _nodejs_release(
        crates_repository_name,
        headers_sha256,
        icu_repository_name,
        release,
        repository_name,
        sha256,
        node_module_version,
        v8_repository_name,
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
        v8_repository_name = v8_repository_name,
        v8_strip_prefix = "node-v{}/deps/v8".format(release),
        v8_version = v8_version,
    )

NODEJS_RELEASES = {
    "26.3.1": _nodejs_release(
        crates_repository_name = "nodejs_crates_26_3_1",
        headers_sha256 = "e84075cd1296f089ad17bc87d34cea964bad7f1018378656af16d494adf91d1a",
        icu_repository_name = "nodejs_icu_26_3_1",
        release = "26.3.1",
        repository_name = "nodejs_26_3_1",
        sha256 = "979b9b8308a8d2d4a27c662ed50448c85f970c0fd4f5ce8b98e8da78c441f2bc",
        node_module_version = 147,
        v8_repository_name = "v8",
        v8_version = "14.6.202.34",
        uv_version = "1.52.1",
    ),
}

SUPPORTED_NODEJS_VERSIONS = sorted(NODEJS_RELEASES.keys())
