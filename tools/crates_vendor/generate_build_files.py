"""Install rules_rs BUILD files for Node.js vendored crates."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tomllib


_GENERATED_REPOSITORY = "nodejs_crates_generated"
_GENERATED_REPOSITORY_PREFIX = "rules_rs++crate+nodejs_crates_generated__"
_NODEJS_CRATES_REPOSITORY = "+nodejs+nodejs_crates_26_3_1"
_OVERLAY_PACKAGE = "//nodejs/private/overlays/crates"

_HEADER = """\
###############################################################################
# @generated
# DO NOT MODIFY: This file is generated from rules_rs. To regenerate this file,
# run the following:
#
#     bazel run //tools/crates_vendor:generate
###############################################################################

"""


def _crate_identity(crate_directory: Path) -> tuple[str, str]:
    manifest = tomllib.loads((crate_directory / "Cargo.toml").read_text())
    package = manifest["package"]
    return package["name"], package["version"]


def _crate_destinations(source_repository: Path) -> dict[tuple[str, str], str]:
    crate_directories = [source_repository / "patches/resb"]
    crate_directories.extend(
        path
        for path in (source_repository / "vendor").iterdir()
        if path.is_dir() and (path / "Cargo.toml").is_file()
    )
    return {
        _crate_identity(path): str(path.relative_to(source_repository))
        for path in crate_directories
    }


def _generated_repositories(
    external_root: Path,
) -> dict[tuple[str, str], Path]:
    repositories = {}
    for path in external_root.glob(_GENERATED_REPOSITORY_PREFIX + "*"):
        if not (path / "Cargo.toml").is_file() or not (path / "BUILD.bazel").is_file():
            continue
        repositories[_crate_identity(path)] = path
    return repositories


def _transform_build_file(
    content: str,
    local_labels: dict[str, str],
) -> str:
    content = content.replace(
        f'load("@{_GENERATED_REPOSITORY}//:defs.bzl", "RESOLVED_PLATFORMS")',
        'load("//:rust_crate_defs.bzl", "RESOLVED_PLATFORMS")',
    )
    for generated_label, local_label in local_labels.items():
        content = content.replace(generated_label, local_label)
    if f"@{_GENERATED_REPOSITORY}//" in content:
        raise ValueError("BUILD file contains an unconverted generated label")
    return _HEADER + content


def _add_temporal_cpp_target(content: str) -> str:
    content = content.replace(
        'load("@rules_rs//rs:rust_crate.bzl", "rust_crate")',
        'load("@rules_cc//cc:cc_library.bzl", "cc_library")\n'
        'load("@rules_rs//rs:rust_crate.bzl", "rust_crate")',
    )
    return content + """

cc_library(
    name = "temporal_capi_cpp",
    hdrs = glob(["bindings/cpp/**/*.hpp"]),
    strip_include_prefix = "bindings/cpp",
    visibility = ["//visibility:public"],
    deps = [":temporal_capi"],
)
"""


def _run_bazel_query(workspace: Path) -> Path:
    bazel = os.environ.get("BAZEL_REAL", "bazel")
    environment = os.environ.copy()
    environment.pop("OUTPUT_BASE", None)
    subprocess.run(
        [
            bazel,
            "query",
            f"deps(@{_GENERATED_REPOSITORY}//:_workspace_deps)",
        ],
        cwd=workspace,
        check=True,
        env=environment,
        stdout=subprocess.DEVNULL,
    )
    output_base = subprocess.run(
        [bazel, "info", "output_base"],
        cwd=workspace,
        check=True,
        env=environment,
        stdout=subprocess.PIPE,
        text=True,
    ).stdout.strip()
    return Path(output_base)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--buildifier", required=True, type=Path)
    args = parser.parse_args()

    workspace = Path(os.environ["BUILD_WORKSPACE_DIRECTORY"])
    external_root = _run_bazel_query(workspace) / "external"
    source_repository = external_root / _NODEJS_CRATES_REPOSITORY
    if not source_repository.is_dir():
        raise FileNotFoundError(source_repository)

    crate_destinations = _crate_destinations(source_repository)
    generated_repositories = _generated_repositories(external_root)
    if crate_destinations.keys() != generated_repositories.keys():
        missing = sorted(crate_destinations.keys() - generated_repositories.keys())
        unexpected = sorted(generated_repositories.keys() - crate_destinations.keys())
        raise ValueError(
            f"rules_rs crate mismatch; missing={missing}, unexpected={unexpected}"
        )

    local_labels = {}
    for name, version in crate_destinations:
        generated_label = f"@{_GENERATED_REPOSITORY}//:{name}-{version}"
        destination = crate_destinations[(name, version)]
        local_labels[generated_label] = f"//{destination}:{name}"

    overlay_root = workspace / "nodejs/private/overlays/crates"
    build_files_root = overlay_root / "build_files"
    shutil.rmtree(build_files_root, ignore_errors=True)
    build_files_root.mkdir(parents=True)

    build_file_entries = []
    for identity, destination in sorted(crate_destinations.items()):
        content = _transform_build_file(
            (generated_repositories[identity] / "BUILD.bazel").read_text(),
            local_labels,
        )
        if identity[0] == "temporal_capi":
            content = _add_temporal_cpp_target(content)
        repository_destination = destination + "/BUILD.bazel"
        output_name = "BUILD." + repository_destination.replace("/", "__")
        (build_files_root / output_name).write_text(content)
        build_file_entries.append((output_name, repository_destination))

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
    files_module.extend(["}", ""])
    files_module_path = overlay_root / "files.bzl"
    files_module_path.write_text("\n".join(files_module))

    subprocess.run(
        [
            args.buildifier,
            "-lint=fix",
            "-mode=fix",
            files_module_path,
            *sorted(build_files_root.glob("*.bazel")),
        ],
        check=True,
    )


if __name__ == "__main__":
    main()
