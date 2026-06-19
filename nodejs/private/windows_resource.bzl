"""Hermetic Windows resource compilation with llvm-rc."""

def _run_llvm_rc(ctx, source, output, inputs, include_anchors):
    include_directories = [anchor.dirname for anchor in include_anchors]
    preprocessed = ctx.actions.declare_file(ctx.label.name + ".i")

    preprocess_args = ctx.actions.args()
    preprocess_args.add_all([
        "--driver-mode=gcc",
        "-target",
        "x86_64-pc-windows-msvc",
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
        inputs = depset(inputs + [ctx.file._windows_sdk_vfs_overlay]),
        mnemonic = "WindowsResourcePreprocess",
        outputs = [preprocessed],
        progress_message = "Preprocessing Windows resource %{input}",
        tools = [ctx.executable._clang],
    )

    resource_args = ctx.actions.args()
    resource_args.add("/FO" + output.path)
    resource_args.add("/no-preprocess")
    for anchor in include_anchors:
        resource_args.add("/I" + anchor.dirname)
    resource_args.add(preprocessed.path)

    ctx.actions.run(
        arguments = [resource_args],
        executable = ctx.executable._llvm_rc,
        inputs = depset(inputs + [preprocessed]),
        mnemonic = "WindowsResource",
        outputs = [output],
        progress_message = "Compiling Windows resource %{input}",
        tools = [
            ctx.executable._llvm_rc,
        ],
    )

def _windows_resource_impl(ctx):
    _run_llvm_rc(
        ctx,
        ctx.file.src,
        ctx.outputs.out,
        [ctx.file.src] + ctx.files.inputs,
        ctx.files.include_anchors,
    )

windows_resource = rule(
    implementation = _windows_resource_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = [".rc"],
            mandatory = True,
        ),
        "inputs": attr.label_list(allow_files = True),
        "include_anchors": attr.label_list(allow_files = True),
        "out": attr.output(mandatory = True),
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
        "_windows_sdk_vfs_overlay": attr.label(
            allow_single_file = True,
            default = Label("@windows_sdk//:windows_sdk_vfs_overlay.yaml"),
        ),
    },
)

def _windows_manifest_resource_impl(ctx):
    resource_script = ctx.actions.declare_file(ctx.label.name + ".rc")
    ctx.actions.write(
        output = resource_script,
        content = '1 24 "{}"\n'.format(ctx.file.manifest.path),
    )
    _run_llvm_rc(
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
        "_windows_sdk_vfs_overlay": attr.label(
            allow_single_file = True,
            default = Label("@windows_sdk//:windows_sdk_vfs_overlay.yaml"),
        ),
    },
)
