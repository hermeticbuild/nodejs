"""Validates and executes the Node.js release archives."""

from __future__ import annotations

import hashlib
import os
import pathlib
import subprocess
import sys
import tarfile
import tempfile


_LAYOUT_SHA256 = "68c7a42727e0fab80741e1dddb25b0ac90665eacbff07cc4e13f4bcc5caae8be"
_MTIME = 1704067200


def _relative_name(member: tarfile.TarInfo, root: str) -> str:
    name = member.name.rstrip("/")
    if name == root:
        return "."
    prefix = root + "/"
    assert name.startswith(prefix), name
    return name[len(prefix) :]


def _validate_archive(
    archive: pathlib.Path, root: str
) -> list[tuple[str, bytes, int, int, str]]:
    assert archive.name in {root + ".tar.gz", root + ".tar.xz"}, archive
    with tarfile.open(archive) as tar:
        members = tar.getmembers()

    assert len(members) == 5714
    relative_names = [_relative_name(member, root) for member in members]
    archive_order_names = [
        name + "/" if member.isdir() else name
        for member, name in zip(members, relative_names, strict=True)
    ]
    assert archive_order_names == sorted(archive_order_names)
    assert len(relative_names) == len(set(relative_names))
    layout = "".join(name + "\n" for name in sorted(relative_names)).encode()
    assert hashlib.sha256(layout).hexdigest() == _LAYOUT_SHA256

    regular_files = [member for member in members if member.isfile()]
    directories = [member for member in members if member.isdir()]
    symlinks = [member for member in members if member.issym()]
    assert len(regular_files) == 4649
    assert len(directories) == 1063
    assert len(symlinks) == 2
    assert sum(member.mode == 0o755 for member in regular_files) == 35
    assert sum(member.mode == 0o644 for member in regular_files) == 4614

    links = {
        _relative_name(member, root): member.linkname for member in symlinks
    }
    assert links == {
        "bin/npm": "../lib/node_modules/npm/bin/npm-cli.js",
        "bin/npx": "../lib/node_modules/npm/bin/npx-cli.js",
    }
    assert "bin/node" in relative_names
    assert "include/node/config.gypi" in relative_names
    assert "lib/node_modules/npm/package.json" in relative_names
    assert "share/man/man1/node.1" in relative_names
    assert not any(name.startswith("lib/node_modules/corepack/") for name in relative_names)

    metadata = []
    for member, relative_name in zip(members, relative_names, strict=True):
        assert member.uid == 0
        assert member.gid == 0
        assert member.uname == "root"
        assert member.gname == "root"
        assert member.mtime == _MTIME
        if member.isdir():
            kind = b"d"
            assert member.mode == 0o755
        elif member.issym():
            kind = b"l"
            assert member.mode == 0o777
        else:
            kind = b"f"
        metadata.append(
            (relative_name, kind, member.mode, member.size, member.linkname)
        )
    return metadata


def _execute_archive(archive: pathlib.Path, root: str) -> None:
    with tempfile.TemporaryDirectory() as directory:
        extraction = pathlib.Path(directory)
        with tarfile.open(archive) as tar:
            tar.extractall(extraction)
        release = extraction / root
        node = release / "bin/node"
        npm = release / "bin/npm"
        npx = release / "bin/npx"
        environment = os.environ.copy()
        environment["PATH"] = str(release / "bin") + os.pathsep + environment["PATH"]
        assert subprocess.check_output([node, "--version"], text=True).strip() == "v26.3.1"
        assert subprocess.check_output([npm, "--version"], env=environment, text=True).strip() == "11.16.0"
        assert subprocess.check_output([npx, "--version"], env=environment, text=True).strip() == "11.16.0"


def main() -> None:
    gzip_archive = pathlib.Path(sys.argv[1])
    xz_archive = pathlib.Path(sys.argv[2])
    root = sys.argv[3]
    gzip_metadata = _validate_archive(gzip_archive, root)
    assert _validate_archive(xz_archive, root) == gzip_metadata
    _execute_archive(gzip_archive, root)


if __name__ == "__main__":
    main()
