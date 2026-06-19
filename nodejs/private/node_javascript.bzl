"""Rule for embedding Node.js built-in JavaScript sources."""

def _node_javascript_impl(ctx):
    repository_root = ctx.file.root_marker.dirname
    repository_prefix = repository_root + "/"
    execution_root_prefix = "../" * len(repository_root.split("/"))

    def root_relative(file):
        if file.path.startswith(repository_prefix):
            return file.path[len(repository_prefix):]
        return execution_root_prefix + file.path

    output = ctx.outputs.out
    arguments = [
        output.path,
        ctx.executable.node_js2c.path,
        repository_root,
        "lib",
        root_relative(ctx.file.config_gypi),
    ]
    arguments.extend([
        root_relative(file)
        for file in ctx.files.dependency_files
    ])

    ctx.actions.run_shell(
        arguments = arguments,
        command = """
output="$PWD/$1"
executable="$2"
repository_root="$3"
shift 3
exec "$executable" --root "$repository_root" "$output" "$@"
""",
        inputs = depset(
            direct = [ctx.file.config_gypi, ctx.file.root_marker],
            transitive = [
                depset(ctx.files.dependency_files),
                depset(ctx.files.library_files),
            ],
        ),
        mnemonic = "NodeJs2c",
        outputs = [output],
        progress_message = "Embedding Node.js built-in JavaScript sources",
        tools = [ctx.attr.node_js2c[DefaultInfo].files_to_run],
    )
    return [DefaultInfo(files = depset([output]))]

node_javascript = rule(
    implementation = _node_javascript_impl,
    attrs = {
        "config_gypi": attr.label(mandatory = True, allow_single_file = True),
        "dependency_files": attr.label_list(mandatory = True, allow_files = True),
        "library_files": attr.label_list(mandatory = True, allow_files = True),
        "node_js2c": attr.label(mandatory = True, cfg = "exec", executable = True),
        "out": attr.output(mandatory = True),
        "root_marker": attr.label(mandatory = True, allow_single_file = True),
    },
)
