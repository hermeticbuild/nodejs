"""Shared rules_rs values for Node.js vendored Rust crates."""

RESOLVED_PLATFORMS = select({
    "@rules_rust//rust/platform:aarch64-apple-darwin": [],
    "@rules_rust//rust/platform:aarch64-unknown-linux-gnu": [],
    "@rules_rust//rust/platform:x86_64-apple-darwin": [],
    "@rules_rust//rust/platform:x86_64-pc-windows-msvc": [],
    "@rules_rust//rust/platform:x86_64-unknown-linux-gnu": [],
    "//conditions:default": ["@platforms//:incompatible"],
})
