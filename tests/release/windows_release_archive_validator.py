"""Validates the Node.js Windows x86_64 release ZIP."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys
import zipfile


_LAYOUT_SHA256 = "707030fa300fc1cfa3570e45e23fb609cfce01d311007da71d830fca0329d2cb"
_ROOT_FILES = {
    "CHANGELOG.md",
    "LICENSE",
    "README.md",
    "install_tools.bat",
    "node.exe",
    "nodevars.bat",
    "npm",
    "npm.cmd",
    "npm.ps1",
    "npx",
    "npx.cmd",
    "npx.ps1",
}
_WRAPPERS = ("npm", "npm.cmd", "npm.ps1", "npx", "npx.cmd", "npx.ps1")


def _relative_name(name: str, root: str) -> str:
    name = name.rstrip("/")
    if name == root:
        return "."
    prefix = root + "/"
    assert name.startswith(prefix), name
    return name[len(prefix) :]


def main() -> None:
    archive_path = pathlib.Path(sys.argv[1])
    output_path = pathlib.Path(sys.argv[2])
    root = sys.argv[3]
    assert archive_path.name == root + ".zip", archive_path

    with zipfile.ZipFile(archive_path) as archive:
        members = archive.infolist()
        names = [member.filename for member in members]
        assert names == sorted(names)
        assert len(names) == len(set(names)) == 2388
        assert archive.testzip() is None

        relative_names = [_relative_name(name, root) for name in names]
        layout = "".join(name + "\n" for name in sorted(relative_names)).encode()
        assert hashlib.sha256(layout).hexdigest() == _LAYOUT_SHA256

        files = [member for member in members if not member.is_dir()]
        directories = [member for member in members if member.is_dir()]
        assert len(files) == 1928
        assert len(directories) == 460
        assert all(member.date_time == (2010, 1, 1, 0, 0, 0) for member in members)

        root_files = {
            relative_name
            for member in files
            if "/" not in (relative_name := _relative_name(member.filename, root))
        }
        assert root_files == _ROOT_FILES
        assert "node_modules/npm/package.json" in relative_names
        assert "node_modules/npm/tap-snapshots/workspaces/arborist" in relative_names
        assert not any(name.startswith("node_modules/corepack/") for name in relative_names)

        for wrapper in _WRAPPERS:
            assert archive.read(root + "/" + wrapper) == archive.read(
                root + "/node_modules/npm/bin/" + wrapper
            )

        assert archive.read(root + "/node.exe").startswith(b"MZ")
        package = json.loads(archive.read(root + "/node_modules/npm/package.json"))
        assert package["version"] == "11.16.0"

    output_path.write_text("validated\n")


if __name__ == "__main__":
    main()
