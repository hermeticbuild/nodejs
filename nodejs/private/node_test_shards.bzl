"""Sharded upstream Node.js test suites."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

def nodejs_upstream_test_shards(
        name,
        suites,
        shards,
        node,
        root_status,
        getaddrinfo_library,
        skip_tests,
        test_sources,
        test_runner,
        test_directory_under_test_root = False):
    """Creates deterministic shards for upstream Node.js test suites."""
    tests = []
    for shard in range(shards):
        test_name = "{}_{}".format(name, shard)
        sh_test(
            name = test_name,
            srcs = ["@nodejs//nodejs/private:node_test.sh"],
            args = [
                "$(rootpath {})".format(test_runner),
                "$(rootpath {})".format(node),
                "$(rootpath {})".format(root_status),
                "$(rootpath {})".format(getaddrinfo_library),
                "--skip-tests={}".format(",".join(skip_tests)),
                "--run={},{}".format(shard, shards),
            ] + suites,
            data = [
                node,
                root_status,
                getaddrinfo_library,
                test_sources,
                test_runner,
            ],
            env = {"NODE_TEST_DIRECTORY_UNDER_TEST_ROOT": "1"} if test_directory_under_test_root else {},
            exec_properties = {"network": "off"},
            tags = [
                "requires-network",
                "upstream-node-test",
            ],
            timeout = "long",
        )
        tests.append(":" + test_name)

    native.test_suite(
        name = name,
        tests = tests,
    )
