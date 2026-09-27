#!/usr/bin/env python3
"""Audit Punchi Dock's static KConfig/KCM/runtime configuration contract."""

from __future__ import annotations

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ElementTree
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable, Sequence


RUNTIME_ONLY_KEYS = {
    "punchiMenuFavoriteStorageIds": (
        "Runtime-managed favorite state; it is not a user-editable KCM field."
    ),
}

EXPECTED_MULTI_PAGE_OWNERS = {
    "dockItemsJson": {"ConfigFiles.qml", "ConfigItems.qml"},
    "dockThemeMode": {"ConfigAspect.qml", "ConfigGeneral.qml", "ConfigMouse.qml"},
    "showActiveTasks": {"ConfigItems.qml", "ConfigWindows.qml"},
}

QML_SOURCE_PATTERN = re.compile(r"\bsource\s*:\s*\"([^\"]+)\"")
CFG_PROPERTY_PATTERN = re.compile(
    r"\bproperty\s+(?:readonly\s+)?(?:alias|[A-Za-z_][A-Za-z0-9_.<>]*)"
    r"\s+cfg_([A-Za-z_][A-Za-z0-9_]*)\b"
)
DIRECT_CONFIGURATION_PATTERN = re.compile(
    r"\bPlasmoid\.configuration\.([A-Za-z_][A-Za-z0-9_]*)\b"
    r"|\bPlasmoid\.configuration\[\s*['\"]([A-Za-z_][A-Za-z0-9_]*)['\"]\s*\]"
)
BLOCK_COMMENT_PATTERN = re.compile(r"/\*.*?\*/", re.DOTALL)
LINE_COMMENT_PATTERN = re.compile(r"//[^\n]*")
RUNTIME_SUFFIXES = {".qml", ".js", ".cpp", ".h"}


@dataclass(frozen=True)
class Issue:
    """One deterministic audit diagnostic."""

    level: str
    code: str
    message: str


@dataclass
class AuditReport:
    """Structured result returned by the static audit."""

    schema_entries: dict[str, str] = field(default_factory=dict)
    schema_groups: dict[str, str] = field(default_factory=dict)
    kcm_pages: list[str] = field(default_factory=list)
    kcm_owners: dict[str, list[str]] = field(default_factory=dict)
    reactive_references: dict[str, list[str]] = field(default_factory=dict)
    runtime_consumers: dict[str, list[str]] = field(default_factory=dict)
    issues: list[Issue] = field(default_factory=list)

    @property
    def errors(self) -> list[Issue]:
        """Return diagnostics that make the audit fail."""

        return [issue for issue in self.issues if issue.level == "error"]

    @property
    def warnings(self) -> list[Issue]:
        """Return non-fatal diagnostics."""

        return [issue for issue in self.issues if issue.level == "warning"]

    def add_issue(self, level: str, code: str, message: str) -> None:
        """Append one issue while preserving stable output ordering later."""

        self.issues.append(Issue(level, code, message))


def local_name(tag: str) -> str:
    """Return an XML tag without its namespace."""

    return tag.rsplit("}", 1)[-1]


def relative_display(path: Path, project_root: Path) -> str:
    """Render a project-relative path without leaking an absolute checkout path."""

    try:
        return path.resolve().relative_to(project_root.resolve()).as_posix()
    except ValueError:
        return path.name


def read_text(path: Path, project_root: Path, report: AuditReport) -> str:
    """Read UTF-8 source and turn failures into deterministic diagnostics."""

    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        report.add_issue(
            "error",
            "read-failed",
            f"Cannot read {relative_display(path, project_root)}: {error}",
        )
        return ""


def parse_schema(project_root: Path, report: AuditReport) -> None:
    """Load KConfig entries, groups, and types from main.xml."""

    schema_path = project_root / "contents/config/main.xml"
    if not schema_path.is_file():
        report.add_issue("error", "schema-missing", "Missing contents/config/main.xml")
        return

    try:
        root = ElementTree.parse(schema_path).getroot()
    except (ElementTree.ParseError, OSError) as error:
        report.add_issue("error", "schema-invalid", f"Cannot parse contents/config/main.xml: {error}")
        return

    for group in root.iter():
        if local_name(group.tag) != "group":
            continue
        group_name = group.attrib.get("name", "")
        for entry in group:
            if local_name(entry.tag) != "entry":
                continue
            key = entry.attrib.get("name", "").strip()
            entry_type = entry.attrib.get("type", "").strip()
            if not key:
                report.add_issue("error", "schema-entry-name", f"Group {group_name!r} has an entry without a name")
                continue
            if key in report.schema_entries:
                report.add_issue("error", "schema-duplicate", f"Schema entry {key!r} is declared more than once")
                continue
            if not entry_type:
                report.add_issue("error", "schema-entry-type", f"Schema entry {key!r} has no type")
            report.schema_entries[key] = entry_type
            report.schema_groups[key] = group_name


def is_safe_relative_source(source: str) -> bool:
    """Accept only normalized relative QML sources below contents/ui."""

    candidate = Path(source)
    return bool(source) and not candidate.is_absolute() and ".." not in candidate.parts


def parse_kcm(project_root: Path, report: AuditReport) -> None:
    """Resolve ConfigModel pages and their schema-facing cfg_* properties."""

    config_model_path = project_root / "contents/config/config.qml"
    source = read_text(config_model_path, project_root, report)
    if not source:
        if not config_model_path.is_file():
            report.add_issue("error", "config-model-missing", "Missing contents/config/config.qml")
        return

    declared_sources = QML_SOURCE_PATTERN.findall(remove_comments(source))
    if not declared_sources:
        report.add_issue("error", "config-pages-empty", "contents/config/config.qml declares no page sources")

    seen_sources: set[str] = set()
    for declared_source in declared_sources:
        if declared_source in seen_sources:
            report.add_issue("error", "config-page-duplicate", f"KCM source {declared_source!r} is declared more than once")
            continue
        seen_sources.add(declared_source)

        if not is_safe_relative_source(declared_source):
            report.add_issue("error", "config-page-unsafe", f"KCM source {declared_source!r} escapes contents/ui")
            continue

        page_path = project_root / "contents/ui" / declared_source
        if not page_path.is_file():
            report.add_issue("error", "config-page-missing", f"KCM source {declared_source!r} does not exist")
            continue

        display_path = relative_display(page_path, project_root)
        report.kcm_pages.append(display_path)
        page_source = remove_comments(read_text(page_path, project_root, report))
        for key in sorted(set(CFG_PROPERTY_PATTERN.findall(page_source))):
            report.kcm_owners.setdefault(key, []).append(display_path)

    config_root = project_root / "contents/ui/config"
    if config_root.is_dir():
        for qml_path in sorted(config_root.rglob("*.qml")):
            qml_source = remove_comments(read_text(qml_path, project_root, report))
            for key in sorted(set(CFG_PROPERTY_PATTERN.findall(qml_source))):
                if key not in report.schema_entries:
                    report.add_issue(
                        "error",
                        "cfg-without-schema",
                        f"{relative_display(qml_path, project_root)} declares cfg_{key} without a schema entry",
                    )


def remove_comments(source: str) -> str:
    """Remove QML/JavaScript/C++ comments while preserving strings and lines."""

    without_blocks = BLOCK_COMMENT_PATTERN.sub(
        lambda match: "\n" * match.group(0).count("\n"), source
    )
    return LINE_COMMENT_PATTERN.sub("", without_blocks)


def runtime_source_paths(project_root: Path) -> Iterable[Path]:
    """Yield executable source files while excluding the KCM implementation."""

    for base in (project_root / "contents", project_root / "src"):
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix not in RUNTIME_SUFFIXES:
                continue
            try:
                relative = path.relative_to(project_root)
            except ValueError:
                continue
            if relative.parts[:3] == ("contents", "ui", "config"):
                continue
            if relative.parts[:2] == ("contents", "config"):
                continue
            yield path


def parse_runtime(project_root: Path, report: AuditReport) -> None:
    """Find direct reactive reads or writes through Plasmoid.configuration."""

    for source_path in runtime_source_paths(project_root):
        source = remove_comments(read_text(source_path, project_root, report))
        relative_path = relative_display(source_path, project_root)
        for match in DIRECT_CONFIGURATION_PATTERN.finditer(source):
            key = match.group(1) or match.group(2)
            if key not in report.schema_entries and key != "writeConfig":
                report.add_issue(
                    "error",
                    "runtime-key-without-schema",
                    f"{relative_path} accesses Plasmoid.configuration.{key} without a schema entry",
                )
                continue
            if key == "writeConfig":
                continue
            report.reactive_references.setdefault(key, []).append(relative_path)
            report.runtime_consumers.setdefault(key, []).append(relative_path)

    for mapping in (report.reactive_references, report.runtime_consumers):
        for key, paths in mapping.items():
            mapping[key] = sorted(set(paths))


def validate_contract(report: AuditReport) -> None:
    """Compare the four inventories and add actionable diagnostics."""

    schema_keys = set(report.schema_entries)
    owner_keys = set(report.kcm_owners)
    reactive_keys = set(report.reactive_references)
    consumer_keys = set(report.runtime_consumers)

    for key in sorted(schema_keys):
        owners = report.kcm_owners.get(key, [])
        owner_names = {Path(owner).name for owner in owners}
        if not owners and key not in RUNTIME_ONLY_KEYS:
            report.add_issue("error", "schema-without-kcm", f"Schema entry {key!r} has no cfg_* owner in a declared KCM page")
        if key in RUNTIME_ONLY_KEYS and owners:
            report.add_issue("warning", "runtime-only-has-kcm", f"Runtime-only entry {key!r} now has a KCM owner; review its classification")

        if len(owners) > 1:
            expected = EXPECTED_MULTI_PAGE_OWNERS.get(key)
            if expected != owner_names:
                rendered = ", ".join(sorted(owner_names))
                report.add_issue("error", "unexpected-multiple-owners", f"Schema entry {key!r} has unexpected KCM owners: {rendered}")

        if key in EXPECTED_MULTI_PAGE_OWNERS and owner_names != EXPECTED_MULTI_PAGE_OWNERS[key]:
            rendered = ", ".join(sorted(owner_names)) or "none"
            report.add_issue("error", "expected-owner-set-changed", f"Schema entry {key!r} owner set changed: {rendered}")

        if key not in reactive_keys:
            report.add_issue("error", "schema-without-reactive-reference", f"Schema entry {key!r} has no direct Plasmoid.configuration reference in runtime code")
        if key not in consumer_keys:
            report.add_issue("error", "schema-without-runtime-consumer", f"Schema entry {key!r} has no runtime consumer")

    for key in sorted(owner_keys - schema_keys):
        report.add_issue("error", "kcm-without-schema", f"KCM property cfg_{key} has no schema entry")


def audit_project(project_root: Path) -> AuditReport:
    """Run the complete static audit for one project tree."""

    report = AuditReport()
    resolved_root = project_root.resolve()
    if not resolved_root.is_dir():
        report.add_issue("error", "project-root-missing", "Project root does not exist or is not a directory")
        return report

    parse_schema(resolved_root, report)
    parse_kcm(resolved_root, report)
    parse_runtime(resolved_root, report)
    validate_contract(report)
    report.kcm_pages.sort()
    for owners in report.kcm_owners.values():
        owners.sort()
    report.issues.sort(key=lambda issue: (issue.level, issue.code, issue.message))
    return report


def render_text(report: AuditReport, verbose: bool = False) -> str:
    """Render a stable human-readable report."""

    runtime_only_present = sorted(set(report.schema_entries) & set(RUNTIME_ONLY_KEYS))
    lines = [
        "KConfig audit",
        "",
        f"Schema entries: {len(report.schema_entries)}",
        f"KCM pages: {len(report.kcm_pages)}",
        f"KCM cfg_* entries: {len(report.kcm_owners)}",
        f"Runtime-only entries: {len(runtime_only_present)}",
        f"Reactive configuration entries: {len(report.reactive_references)}",
        f"Runtime-consumed entries: {len(report.runtime_consumers)}",
        f"Errors: {len(report.errors)}",
        f"Warnings: {len(report.warnings)}",
    ]

    if report.issues:
        lines.append("")
        lines.append("Diagnostics:")
        for issue in report.issues:
            lines.append(f"  {issue.level.upper()} [{issue.code}] {issue.message}")

    if verbose:
        lines.append("")
        lines.append("KCM ownership:")
        for key in sorted(report.schema_entries):
            owners = report.kcm_owners.get(key, [])
            if key in RUNTIME_ONLY_KEYS and not owners:
                owner_text = "runtime-only"
            else:
                owner_text = ", ".join(owners) or "missing"
            lines.append(f"  {key}: {owner_text}")

    lines.extend(("", f"Result: {'FAIL' if report.errors else 'PASS'}"))
    return "\n".join(lines)


def render_json(report: AuditReport) -> str:
    """Render a machine-readable report without environment-specific paths."""

    payload = {
        "summary": {
            "schema_entries": len(report.schema_entries),
            "kcm_pages": len(report.kcm_pages),
            "kcm_entries": len(report.kcm_owners),
            "runtime_only_entries": len(set(report.schema_entries) & set(RUNTIME_ONLY_KEYS)),
            "reactive_entries": len(report.reactive_references),
            "runtime_consumed_entries": len(report.runtime_consumers),
            "errors": len(report.errors),
            "warnings": len(report.warnings),
        },
        "schema_entries": report.schema_entries,
        "schema_groups": report.schema_groups,
        "kcm_pages": report.kcm_pages,
        "kcm_owners": report.kcm_owners,
        "reactive_references": report.reactive_references,
        "runtime_consumers": report.runtime_consumers,
        "issues": [asdict(issue) for issue in report.issues],
        "result": "fail" if report.errors else "pass",
    }
    return json.dumps(payload, indent=2, sort_keys=True)


def build_argument_parser() -> argparse.ArgumentParser:
    """Create the command-line interface."""

    parser = argparse.ArgumentParser(
        description=(
            "Audit Punchi Dock's static KConfig contract across main.xml, "
            "declared KCM pages, cfg_* properties, and runtime consumers."
        ),
        epilog=(
            "This audit proves static connectivity only. It does not replace "
            "QML behavior tests or validation in a real Plasma session."
        ),
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Project root containing contents/config/main.xml (default: script parent project)",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Include the KCM owner selected for every schema entry",
    )
    return parser


def main(arguments: Sequence[str] | None = None) -> int:
    """Run the CLI and return a pipeline-friendly exit status."""

    options = build_argument_parser().parse_args(arguments)
    report = audit_project(options.project_root)
    if options.format == "json":
        print(render_json(report))
    else:
        print(render_text(report, options.verbose))
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
