"""Node.js addon build rule."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

def node_addon(name, output, srcs, copts = [], defines = [], deps = []):
    """Builds a shared library and copies it to an upstream .node path."""
    shared_library = name + "_shared_library"
    cc_binary(
        name = shared_library,
        srcs = srcs,
        copts = copts,
        defines = defines,
        linkopts = select(
            {
                ":target_linux": [],
                ":target_macos": ["-Wl,-undefined,dynamic_lookup"],
            },
            no_match_error = "Node.js addons currently support Linux and macOS targets",
        ),
        linkshared = True,
        deps = [":node_addon_headers"] + deps,
    )
    native.genrule(
        name = name,
        srcs = [":" + shared_library],
        outs = [output],
        cmd = "cp $< $@",
    )
