"""Test rule that runs an action with the rules_nodejs execution toolchain."""

def _node_execution_check_impl(ctx):
    toolchain = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"]
    nodeinfo = toolchain.nodeinfo
    if not nodeinfo.node:
        fail("The resolved Node.js execution toolchain is not hermetic")

    ctx.actions.run(
        arguments = [
            ctx.file.script.path,
            ctx.outputs.out.path,
        ],
        executable = nodeinfo.node,
        inputs = [ctx.file.script],
        mnemonic = "SourceNodejsExecutionCheck",
        outputs = [ctx.outputs.out],
        tools = nodeinfo.tool_files,
    )
    return DefaultInfo(files = depset([ctx.outputs.out]))

node_execution_check = rule(
    implementation = _node_execution_check_impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "script": attr.label(
            allow_single_file = [".js"],
            mandatory = True,
        ),
    },
    toolchains = ["@rules_nodejs//nodejs:toolchain_type"],
)
