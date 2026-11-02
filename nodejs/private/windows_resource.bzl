"""Hermetic Windows resource compilation with llvm-rc."""

load("@bazel_skylib//rules/directory:providers.bzl", "DirectoryInfo")

def _windows_resource_impl(ctx):
    source = ctx.file.src
    include_anchors = ctx.files.include_anchors
    sdk_includes = [target[DirectoryInfo] for target in ctx.attr._sdk_includes]
    include_directories = [directory.path for directory in sdk_includes] + [anchor.dirname for anchor in include_anchors]
    preprocessed = ctx.actions.declare_file(ctx.label.name + ".i")

    preprocess_args = ctx.actions.args()
    preprocess_args.add_all([
        "--driver-mode=gcc",
        "-target",
        ctx.attr.target_triple,
        "-E",
        "-xc",
        "-DRC_INVOKED",
        "-ivfsoverlay",
        ctx.file._windows_sdk_vfs_overlay,
    ])
    for include_directory in include_directories:
        preprocess_args.add("-I" + include_directory)
    preprocess_args.add_all([
        source,
        "-o",
        preprocessed,
    ])

    ctx.actions.run(
        arguments = [preprocess_args],
        executable = ctx.executable._clang,
        inputs = depset(
            [source, ctx.file._windows_sdk_vfs_overlay] + include_anchors,
            transitive = [directory.transitive_files for directory in sdk_includes],
        ),
        mnemonic = "WindowsResourcePreprocess",
        outputs = [preprocessed],
        progress_message = "Preprocessing Windows resource %{input}",
        tools = [ctx.executable._clang],
    )

    _compile_llvm_rc(
        ctx,
        preprocessed,
        ctx.outputs.out,
        include_anchors + [preprocessed],
        include_anchors,
    )

def _compile_llvm_rc(ctx, source, output, inputs, include_anchors):
    resource_args = ctx.actions.args()
    resource_args.add("/FO" + output.path)
    resource_args.add("/no-preprocess")
    for anchor in include_anchors:
        resource_args.add("/I" + anchor.dirname)
    resource_args.add(source.path)
    ctx.actions.run(
        arguments = [resource_args],
        executable = ctx.executable._llvm_rc,
        inputs = depset(inputs),
        mnemonic = "WindowsResource",
        outputs = [output],
        progress_message = "Compiling Windows resource %{input}",
        tools = [
            ctx.executable._llvm_rc,
        ],
    )

windows_resource = rule(
    implementation = _windows_resource_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = [".rc"],
            mandatory = True,
        ),
        "include_anchors": attr.label_list(allow_files = True),
        "out": attr.output(mandatory = True),
        "target_triple": attr.string(mandatory = True),
        "_clang": attr.label(
            allow_files = True,
            cfg = "exec",
            default = Label("@llvm//tools:clang"),
            executable = True,
        ),
        "_llvm_rc": attr.label(
            allow_files = True,
            cfg = "exec",
            default = Label("@llvm//tools:llvm-rc"),
            executable = True,
        ),
        "_sdk_includes": attr.label_list(
            default = [
                Label("@llvm//runtimes/msvc:winsdk_shared_include"),
                Label("@llvm//runtimes/msvc:winsdk_um_include"),
            ],
            providers = [DirectoryInfo],
        ),
        "_windows_sdk_vfs_overlay": attr.label(
            allow_single_file = True,
            default = Label("@llvm//runtimes/msvc:msvc_sdk_header_case_overlay"),
        ),
    },
)

def _windows_manifest_resource_impl(ctx):
    resource_script = ctx.actions.declare_file(ctx.label.name + ".rc")
    ctx.actions.write(
        output = resource_script,
        content = '1 24 "{}"\n'.format(ctx.file.manifest.path),
    )
    _compile_llvm_rc(
        ctx,
        resource_script,
        ctx.outputs.out,
        [resource_script, ctx.file.manifest],
        [],
    )

windows_manifest_resource = rule(
    implementation = _windows_manifest_resource_impl,
    attrs = {
        "manifest": attr.label(
            allow_single_file = [".manifest"],
            mandatory = True,
        ),
        "out": attr.output(mandatory = True),
        "_llvm_rc": attr.label(
            allow_files = True,
            cfg = "exec",
            default = Label("@llvm//tools:llvm-rc"),
            executable = True,
        ),
    },
)
