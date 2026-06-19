"""Install generated crate_universe BUILD files for Node.js vendored crates."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tomllib


_GENERATED_LABEL_PREFIX = "//tools/crates_vendor/generated/"
_OVERLAY_PACKAGE = "//nodejs/private/overlays/crates"


def _version_key(version: str) -> tuple[int, ...]:
    numeric_version = version.split("+", 1)[0].split("-", 1)[0]
    return tuple(int(component) for component in numeric_version.split("."))


def _crate_identity(crate_directory: Path) -> tuple[str, str]:
    manifest = tomllib.loads((crate_directory / "Cargo.toml").read_text())
    package = manifest["package"]
    return package["name"], package["version"]


def _transform_build_file(
    content: str,
    crate_destinations: dict[str, str],
) -> str:
    for generated_directory, destination in crate_destinations.items():
        content = content.replace(
            _GENERATED_LABEL_PREFIX + generated_directory,
            "//vendor/" + destination,
        )

    content = re.sub(
        r'"///[^"\n]*/patches/resb"',
        '"//patches/resb:resb"',
        content,
    )
    content = content.replace(
        "#     bazel run @@//tools/crates_vendor:generate",
        "#     bazel run //tools/crates_vendor:generate\n"
        "#     bazel run //tools/crates_vendor:install",
    )

    if _GENERATED_LABEL_PREFIX in content or '"///' in content:
        raise ValueError("BUILD file contains an unconverted generated label")
    return content


def _add_temporal_cpp_target(content: str) -> str:
    content = content.replace(
        'load("@rules_rust//rust:defs.bzl", "rust_library")',
        'load("@rules_cc//cc:cc_library.bzl", "cc_library")\n'
        'load("@rules_rust//rust:defs.bzl", "rust_library")',
    )
    return content + """

cc_library(
    name = "temporal_capi_cpp",
    hdrs = glob(["bindings/cpp/**/*.hpp"]),
    strip_include_prefix = "bindings/cpp",
    deps = [":temporal_capi"],
)
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--buildifier", required=True, type=Path)
    args = parser.parse_args()

    workspace = Path(os.environ["BUILD_WORKSPACE_DIRECTORY"])
    generated_root = workspace / "tools/crates_vendor/generated"
    overlay_root = workspace / "nodejs/private/overlays/crates"

    generated_directories = sorted(
        path
        for path in generated_root.iterdir()
        if path.is_dir() and (path / "BUILD.bazel").is_file()
    )
    identities = {
        path.name: _crate_identity(path) for path in generated_directories
    }

    versions_by_name: dict[str, list[str]] = {}
    for name, version in identities.values():
        versions_by_name.setdefault(name, []).append(version)

    crate_destinations = {}
    for generated_directory, (name, version) in identities.items():
        versions = versions_by_name[name]
        destination = name
        if len(versions) > 1 and version != max(versions, key=_version_key):
            destination = f"{name}-{version}"
        crate_destinations[generated_directory] = destination

    for old_directory in [
        overlay_root / "vendor",
        overlay_root / "patches",
        overlay_root / "build_files",
    ]:
        shutil.rmtree(old_directory, ignore_errors=True)

    build_file_entries = []
    for generated_directory, destination in sorted(crate_destinations.items()):
        content = _transform_build_file(
            (generated_root / generated_directory / "BUILD.bazel").read_text(),
            crate_destinations,
        )
        if destination == "temporal_capi":
            content = _add_temporal_cpp_target(content)
        repository_destination = f"vendor/{destination}/BUILD.bazel"
        output_name = "BUILD." + repository_destination.replace("/", "__")
        output = overlay_root / "build_files" / output_name
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(content)
        build_file_entries.append((output_name, repository_destination))

    resb_content = _transform_build_file(
        (workspace / "patches/resb/BUILD.bazel").read_text(),
        crate_destinations,
    )
    resb_destination = "patches/resb/BUILD.bazel"
    resb_output_name = "BUILD." + resb_destination.replace("/", "__")
    resb_output = overlay_root / "build_files" / resb_output_name
    resb_output.parent.mkdir(parents=True, exist_ok=True)
    resb_output.write_text(resb_content)
    build_file_entries.append((resb_output_name, resb_destination))

    files_module = [
        '"""Generated BUILD files for Node.js vendored Rust crates."""',
        "",
        "CRATES_BUILD_FILES = {",
    ]
    files_module.extend(
        f'    Label("{_OVERLAY_PACKAGE}:build_files/{output_name}"): '
        f'"{destination}",'
        for output_name, destination in sorted(build_file_entries)
    )
    files_module.extend([
        "}",
        "",
    ])
    files_module_path = overlay_root / "files.bzl"
    files_module_path.write_text("\n".join(files_module))

    subprocess.run(
        [
            args.buildifier,
            "-lint=fix",
            "-mode=fix",
            files_module_path,
            *sorted((overlay_root / "build_files").glob("*.bazel")),
        ],
        check=True,
    )


if __name__ == "__main__":
    main()
