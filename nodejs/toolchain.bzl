"""rules_nodejs runtime toolchain support for source-built Node.js."""

load("@rules_cc//cc:defs.bzl", "CcInfo")
load("@rules_nodejs//nodejs:toolchain.bzl", "NodeInfo")

def _manifest_path(ctx, file):
    if file.short_path.startswith("../"):
        return "external/" + file.short_path[3:]
    return ctx.workspace_name + "/" + file.short_path

def _source_nodejs_toolchain_impl(ctx):
    node = ctx.executable.node
    npm = ctx.file.npm
    npm_sources = depset(([npm] if npm else []) + ctx.files.npm_srcs)
    files = [node] + ([npm] if npm else [])
    default = DefaultInfo(
        files = depset(files),
        runfiles = ctx.runfiles(files = files, transitive_files = npm_sources),
    )
    nodeinfo = NodeInfo(
        headers = struct(
            providers_map = {
                "CcInfo": ctx.attr.headers[CcInfo],
                "DefaultInfo": ctx.attr.headers[DefaultInfo],
            },
        ),
        node = node,
        node_path = "",
        npm = npm,
        npm_files = npm_sources.to_list(),
        npm_path = _manifest_path(ctx, npm) if npm else "",
        npm_sources = npm_sources,
        target_tool_path = _manifest_path(ctx, node),
        tool_files = [node],
    )
    template_variables = platform_common.TemplateVariableInfo({
        "NODE_PATH": node.path,
        "NPM_PATH": npm.path if npm else "",
    })
    return [
        default,
        platform_common.ToolchainInfo(
            default = default,
            nodeinfo = nodeinfo,
            template_variables = template_variables,
        ),
        template_variables,
    ]

source_nodejs_toolchain = rule(
    implementation = _source_nodejs_toolchain_impl,
    attrs = {
        "headers": attr.label(mandatory = True),
        "node": attr.label(
            allow_single_file = True,
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
        "npm": attr.label(allow_single_file = True),
        "npm_srcs": attr.label_list(),
    },
    doc = "Provides source-built Node.js in the toolchain implementation's configuration.",
)
