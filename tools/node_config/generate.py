#!/usr/bin/env python3

import argparse
import ast
import json
from pathlib import Path
from typing import Any


def _read_config(path: Path) -> dict[str, Any]:
    lines = path.read_text().splitlines()
    value = ast.literal_eval("\n".join(line for line in lines if not line.startswith("#")))
    if not isinstance(value, dict) or not isinstance(value.get("variables"), dict):
        raise ValueError(f"{path} must contain a variables dictionary")
    return value


def _cargo_rust_target(target_os: str, target_arch: str) -> str:
    if target_os == "win":
        return (
            "aarch64-pc-windows-msvc"
            if target_arch == "arm64"
            else "x86_64-pc-windows-msvc"
        )
    if target_os == "mac" and target_arch == "x64":
        return "x86_64-apple-darwin"
    return ""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--arch", required=True, choices=("arm64", "x64"))
    parser.add_argument("--os", required=True, choices=("linux", "mac", "win"))
    arguments = parser.parse_args()

    config = _read_config(arguments.input)
    variables = config["variables"]
    variables.update(
        {
            "cargo_rust_target": _cargo_rust_target(arguments.os, arguments.arch),
            "host_arch": arguments.arch,
            "llvm_version": "22.1",
            "shlib_suffix": (
                "147.dylib" if arguments.os == "mac" else "so.147"
            ),
            "target_arch": arguments.arch,
            "v8_enable_gdbjit": int(
                arguments.os == "linux" and arguments.arch == "x64"
            ),
            "want_separate_host_toolset": 0,
        }
    )

    if arguments.arch == "arm64":
        variables["arm_fpu"] = "neon"
        variables.pop("v8_enable_short_builtin_calls", None)
    else:
        variables.pop("arm_fpu", None)
        variables["v8_enable_short_builtin_calls"] = 1

    if arguments.os == "linux" and arguments.arch == "x64":
        variables["v8_enable_wasm_simd256_revec"] = 1
    else:
        variables.pop("v8_enable_wasm_simd256_revec", None)

    if arguments.os == "win":
        variables.update(
            {
                "node_use_node_code_cache": "false",
                "node_use_node_snapshot": "false",
                "node_write_snapshot_as_array_literals": "true",
            }
        )

    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(
        "# Do not edit. Generated from the Node.js 26.3.1 release config.gypi.\n"
        + json.dumps(config, indent=2)
        + "\n"
    )


if __name__ == "__main__":
    main()
