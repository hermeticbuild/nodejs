#!/usr/bin/env python3
"""Generate the Node.js configure.py and GYP configuration inventory.

This program reads Node.js source files. It does not execute configure.py.
"""

from __future__ import annotations

import argparse
import ast
import dataclasses
import json
import pathlib
import re
import sys
from collections.abc import Sequence


_SUPPORTED_PLATFORMS = (
    "darwin_arm64",
    "darwin_x86_64",
    "linux_arm64",
    "linux_x86_64",
)
@dataclasses.dataclass(frozen=True)
class ConfigureOption:
    line: int
    flags: tuple[str, ...]
    destination: str
    action: str
    default: str
    choices: str


@dataclasses.dataclass(frozen=True)
class VariableWrite:
    name: str
    function: str
    line: int
    expression: str


@dataclasses.dataclass(frozen=True)
class GypDefault:
    name: str
    path: str
    line: int
    expression: str


@dataclasses.dataclass(frozen=True)
class ReleaseSetting:
    name: str
    values: dict[str, object]
    required_assignments: tuple[str, ...]
    justification: str


def _one_line(value: str) -> str:
    return " ".join(value.split())


def _render_expression(node: ast.AST) -> str:
    return _one_line(ast.unparse(node))


def _string_literal(node: ast.AST) -> str | None:
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    return None


def _keyword(call: ast.Call, name: str) -> ast.AST | None:
    for keyword in call.keywords:
        if keyword.arg == name:
            return keyword.value
    return None


def _destination(flags: tuple[str, ...], explicit: ast.AST | None) -> str:
    if explicit is not None:
        value = _string_literal(explicit)
        return value if value is not None else _render_expression(explicit)
    for flag in flags:
        if flag.startswith("--"):
            return flag[2:].replace("-", "_")
    return flags[0].lstrip("-").replace("-", "_")


def _variable_name(target: ast.AST) -> str | None:
    if not isinstance(target, ast.Subscript):
        return None
    name = _string_literal(target.slice)
    if name is None:
        return None
    owner = target.value
    if isinstance(owner, ast.Name) and owner.id == "variables":
        return name
    if not isinstance(owner, ast.Subscript):
        return None
    return name if _string_literal(owner.slice) == "variables" else None


class _ConfigureVisitor(ast.NodeVisitor):
    def __init__(self) -> None:
        self.functions: list[str] = []
        self.options: list[ConfigureOption] = []
        self.writes: list[VariableWrite] = []

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
        self.functions.append(node.name)
        self.generic_visit(node)
        self.functions.pop()

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> None:
        self.functions.append(node.name)
        self.generic_visit(node)
        self.functions.pop()

    def visit_Call(self, node: ast.Call) -> None:
        if isinstance(node.func, ast.Attribute) and node.func.attr == "add_argument":
            flags = tuple(
                value
                for argument in node.args
                if (value := _string_literal(argument)) is not None
                and value.startswith("-")
            )
            if flags:
                action_node = _keyword(node, "action")
                default_node = _keyword(node, "default")
                choices_node = _keyword(node, "choices")
                self.options.append(
                    ConfigureOption(
                        line=node.lineno,
                        flags=flags,
                        destination=_destination(flags, _keyword(node, "dest")),
                        action=(
                            _render_expression(action_node)
                            if action_node is not None
                            else "'store'"
                        ),
                        default=(
                            _render_expression(default_node)
                            if default_node is not None
                            else "argparse implicit"
                        ),
                        choices=(
                            _render_expression(choices_node)
                            if choices_node is not None
                            else "—"
                        ),
                    )
                )
        self.generic_visit(node)

    def visit_Assign(self, node: ast.Assign) -> None:
        for target in node.targets:
            name = _variable_name(target)
            if name is not None:
                self.writes.append(
                    VariableWrite(
                        name=name,
                        function=self.functions[-1] if self.functions else "<module>",
                        line=node.lineno,
                        expression=_render_expression(node.value),
                    )
                )
        self.generic_visit(node)


def _read_configure(path: pathlib.Path) -> tuple[list[ConfigureOption], list[VariableWrite]]:
    text = path.read_text(encoding="utf-8")
    visitor = _ConfigureVisitor()
    visitor.visit(ast.parse(text, filename=str(path)))
    return visitor.options, visitor.writes


def _gyp_defaults(path: pathlib.Path, relative_path: str) -> list[GypDefault]:
    result = []
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path), mode="eval")
    for node in ast.walk(tree):
        if not isinstance(node, ast.Dict):
            continue
        for key, value in zip(node.keys, node.values, strict=True):
            if key is None or _string_literal(key) != "variables" or not isinstance(value, ast.Dict):
                continue
            for variable_key, variable_value in zip(value.keys, value.values, strict=True):
                if variable_key is None:
                    continue
                name = _string_literal(variable_key)
                if name is None:
                    continue
                result.append(
                    GypDefault(
                        name=name,
                        path=relative_path,
                        line=variable_key.lineno,
                        expression=_render_expression(variable_value),
                    )
                )
    return result


def _load_release_settings(path: pathlib.Path) -> tuple[str, list[ReleaseSetting]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        raise ValueError(f"unsupported release-setting schema in {path}")
    release = data.get("release")
    if not isinstance(release, str) or not release:
        raise ValueError(f"invalid Node.js release in {path}")

    settings = []
    names = set()
    for item in data.get("settings", []):
        name = item.get("name")
        if not isinstance(name, str) or not name:
            raise ValueError(f"invalid release-setting name in {path}")
        if name in names:
            raise ValueError(f"duplicate release setting {name!r} in {path}")
        names.add(name)
        values = item.get("values")
        if not isinstance(values, dict) or not values:
            raise ValueError(f"release setting {name} must define values")
        for selector in values:
            if selector != "*" and selector not in _SUPPORTED_PLATFORMS:
                raise ValueError(f"release setting {name} has unknown platform {selector!r}")
        required_assignments = item.get("required_assignments", [])
        if not isinstance(required_assignments, list) or not all(
            isinstance(expression, str) and expression
            for expression in required_assignments
        ):
            raise ValueError(f"release setting {name} has invalid required_assignments")
        justification = item.get("justification")
        if not isinstance(justification, str) or not justification:
            raise ValueError(f"release setting {name} must define a justification")
        settings.append(
            ReleaseSetting(
                name=name,
                values=values,
                required_assignments=tuple(required_assignments),
                justification=justification,
            )
        )
    if not settings:
        raise ValueError(f"{path} contains no release settings")
    return release, settings


def _markdown_code(value: object) -> str:
    rendered = json.dumps(value, sort_keys=True)
    return f"`{rendered}`"


def _markdown_text(value: str) -> str:
    return value.replace("|", "\\|")


def _setting_value(setting: ReleaseSetting, platform: str) -> object:
    if platform in setting.values:
        return setting.values[platform]
    if "*" in setting.values:
        return setting.values["*"]
    raise ValueError(f"release setting {setting.name} has no value for {platform}")


def _locations(items: Sequence[VariableWrite | GypDefault]) -> str:
    result = []
    for item in items[:4]:
        if isinstance(item, VariableWrite):
            result.append(f"`configure.py:{item.line}` `{item.expression}`")
        else:
            result.append(f"`{item.path}:{item.line}` `{item.expression}`")
    if len(items) > 4:
        result.append(f"+{len(items) - 4}")
    return "<br>".join(result) if result else "—"


def _generate(
    release: str,
    configure_path: pathlib.Path,
    gyp_paths: Sequence[pathlib.Path],
    settings: Sequence[ReleaseSetting],
) -> str:
    options, writes = _read_configure(configure_path)
    source_root = configure_path.parent.resolve()

    defaults = []
    source_texts = {}
    for path in sorted(gyp_paths):
        resolved = path.resolve()
        try:
            relative_path = resolved.relative_to(source_root).as_posix()
        except ValueError as error:
            raise ValueError(f"GYP source is outside the Node.js source root: {resolved}") from error
        source_texts[relative_path] = resolved.read_text(encoding="utf-8")
        defaults.extend(_gyp_defaults(resolved, relative_path))

    writes_by_name: dict[str, list[VariableWrite]] = {}
    for write in writes:
        writes_by_name.setdefault(write.name, []).append(write)
    defaults_by_name: dict[str, list[GypDefault]] = {}
    for default in defaults:
        defaults_by_name.setdefault(default.name, []).append(default)

    known_names = set(writes_by_name) | set(defaults_by_name)
    references: dict[str, list[str]] = {name: [] for name in known_names}
    for relative_path, text in source_texts.items():
        for line_number, line in enumerate(text.splitlines(), 1):
            for name in known_names:
                if re.search(rf"(?<![A-Za-z0-9_]){re.escape(name)}(?![A-Za-z0-9_])", line):
                    references[name].append(f"{relative_path}:{line_number}")

    for setting in settings:
        setting_writes = writes_by_name.get(setting.name, [])
        setting_defaults = defaults_by_name.get(setting.name, [])
        if not setting_writes and not setting_defaults:
            raise ValueError(f"release setting {setting.name} has no configure.py or GYP definition")
        actual_expressions = {write.expression for write in setting_writes}
        for expression in setting.required_assignments:
            if expression not in actual_expressions:
                raise ValueError(
                    f"release setting {setting.name} requires configure.py assignment "
                    f"{expression!r}; found {sorted(actual_expressions)!r}"
                )

    lines = [
        f"# Node.js {release} configure/GYP inventory",
        "",
        "This file is generated by `tools/configure_inventory.py`. The generator reads",
        "`configure.py`, `common.gypi`, `node.gyp`, and `tools/v8_gypfiles`; it does not",
        "execute `configure.py` or GYP.",
        "",
        "The reviewed release settings below define the values that the Bazel release",
        "build must preserve for Linux and macOS. A configure.py assignment is evidence",
        "for the upstream mechanism; the reviewed value is the Bazel build requirement.",
        "",
        "## Reviewed release settings",
        "",
        "| GYP variable | Darwin arm64 | Darwin x86_64 | Linux arm64 | Linux x86_64 | configure.py assignments | Requirement |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for setting in settings:
        lines.append(
            "| {name} | {darwin_arm64} | {darwin_x86_64} | {linux_arm64} | "
            "{linux_x86_64} | {assignments} | {justification} |".format(
                name=f"`{setting.name}`",
                darwin_arm64=_markdown_code(_setting_value(setting, "darwin_arm64")),
                darwin_x86_64=_markdown_code(_setting_value(setting, "darwin_x86_64")),
                linux_arm64=_markdown_code(_setting_value(setting, "linux_arm64")),
                linux_x86_64=_markdown_code(_setting_value(setting, "linux_x86_64")),
                assignments=_locations(writes_by_name.get(setting.name, [])),
                justification=_markdown_text(setting.justification),
            )
        )

    lines.extend([
        "",
        f"## configure.py options ({len(options)})",
        "",
        "| Line | Flags | Destination | Action | Default | Choices |",
        "| ---: | --- | --- | --- | --- | --- |",
    ])
    for option in sorted(options, key=lambda option: option.line):
        lines.append(
            "| {line} | {flags} | {destination} | {action} | {default} | {choices} |".format(
                line=option.line,
                flags="<br>".join(f"`{flag}`" for flag in option.flags),
                destination=f"`{option.destination}`",
                action=f"`{_markdown_text(option.action)}`",
                default=f"`{_markdown_text(option.default)}`",
                choices=f"`{_markdown_text(option.choices)}`" if option.choices != "—" else "—",
            )
        )

    lines.extend([
        "",
        f"## configure.py and GYP variables ({len(known_names)})",
        "",
        "| Variable | configure.py assignments | GYP defaults | GYP references |",
        "| --- | --- | --- | --- |",
    ])
    for name in sorted(known_names):
        reference_locations = references.get(name, [])
        reference_text = "<br>".join(f"`{location}`" for location in reference_locations[:4])
        if len(reference_locations) > 4:
            reference_text += f"<br>+{len(reference_locations) - 4}"
        lines.append(
            "| `{name}` | {writes} | {defaults} | {references} |".format(
                name=name,
                writes=_locations(writes_by_name.get(name, [])),
                defaults=_locations(defaults_by_name.get(name, [])),
                references=reference_text or "—",
            )
        )
    lines.append("")
    return "\n".join(lines)


def _parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", action="append", required=True, type=pathlib.Path)
    parser.add_argument("--settings", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--check", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = _parse_args(argv or sys.argv[1:])
    configure_paths = [path.resolve() for path in args.source if path.name == "configure.py"]
    if len(configure_paths) != 1:
        raise ValueError(f"expected one configure.py; found {configure_paths}")
    gyp_paths = [
        path.resolve()
        for path in args.source
        if path.name in {"common.gypi", "node.gyp"}
        or path.suffix in {".gyp", ".gypi"}
    ]
    if len(gyp_paths) < 3:
        raise ValueError(f"expected common.gypi, node.gyp, and V8 GYP files; found {gyp_paths}")

    release, settings = _load_release_settings(args.settings)
    generated = _generate(release, configure_paths[0], gyp_paths, settings)
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != generated:
            print(f"{args.output} is stale; run tools/configure_check_audit.sh", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(generated, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
