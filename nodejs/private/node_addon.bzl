"""Node.js addon build rule."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("//nodejs:compiler_options.bzl", "cxx20_copts")

def node_addon(name, output, srcs, copts = [], defines = [], deps = []):
    """Builds a shared library and copies it to an upstream output path."""
    shared_library = name + "_shared_library"
    cc_binary(
        name = shared_library,
        srcs = srcs,
        copts = ["-UNDEBUG"] + copts,
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

def node_module_addon(
        name,
        output,
        srcs,
        module_name = "binding",
        copts = [],
        defines = [],
        deps = []):
    """Builds a legacy NODE_MODULE addon using test/addons/common.gypi."""
    node_addon(
        name = name,
        output = output,
        srcs = srcs,
        copts = cxx20_copts() + [
            "-Wno-cast-function-type",
        ] + copts,
        defines = [
            "NODE_GYP_MODULE_NAME={}".format(module_name),
            "V8_DEPRECATION_WARNINGS=1",
        ] + defines,
        deps = deps,
    )
