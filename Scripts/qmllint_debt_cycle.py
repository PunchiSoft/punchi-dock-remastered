#!/usr/bin/env python3
"""Close a verified qmllint debt batch as an atomic developer workflow."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import qmllint_debt_inventory as inventory


BASELINE_KEYS = (
    "QMLLINT_BASELINE_TOTAL",
    "QMLLINT_BASELINE_UNQUALIFIED",
    "QMLLINT_BASELINE_LAYOUT",
    "QMLLINT_BASELINE_MISSING_PROPERTY",
    "QMLLINT_BASELINE_IMPORT",
)
ID_RE = re.compile(r"`(?P<identifier>QML-[A-F0-9]+)`")


class CycleError(RuntimeError):
    """Raised when a debt-cycle safety condition is not satisfied."""


@dataclass(frozen=True)
class CycleConfig:
    """Validated inputs for one batch close operation."""

    identifiers: tuple[str, ...]
    observation: str
    profile: str
    project_root: Path
    inventory_path: Path
    baseline_path: Path
    qmllint_path: Path
    gate_script: Path
    backup_root: Path


@dataclass(frozen=True)
class GateCounts:
    """Gate categories derived from one complete qmllint run."""

    total: int
    unqualified: int
    layout: int
    missing_property: int
    import_count: int

    def as_baseline(self) -> dict[str, int]:
        """Return counts keyed by the baseline environment variable names."""

        return {
            "QMLLINT_BASELINE_TOTAL": self.total,
            "QMLLINT_BASELINE_UNQUALIFIED": self.unqualified,
            "QMLLINT_BASELINE_LAYOUT": self.layout,
            "QMLLINT_BASELINE_MISSING_PROPERTY": self.missing_property,
            "QMLLINT_BASELINE_IMPORT": self.import_count,
        }


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""

    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=(
            "Verify and close one or more qmllint inventory IDs. The command refuses "
            "to write when a target remains active, a new ID appears, a baseline would increase, "
            "or the profile gate fails."
        )
    )
    parser.add_argument(
        "--id",
        required=True,
        dest="identifiers",
        action="append",
        help="inventory ID; repeat for every ID in the verified batch",
    )
    parser.add_argument(
        "--observation", required=True, help="technical cause or resolution note"
    )
    parser.add_argument("--profile", required=True, help="inventory profile label")
    parser.add_argument(
        "--project-root", type=Path, default=project_root, help="repository root"
    )
    parser.add_argument("--inventory", required=True, type=Path, help="active inventory")
    parser.add_argument("--baseline", required=True, type=Path, help="profile baseline")
    parser.add_argument("--qmllint", required=True, type=Path, help="qmllint executable")
    parser.add_argument(
        "--gate-script", required=True, type=Path, help="profile packaging gate script"
    )
    parser.add_argument(
        "--backup-root",
        type=Path,
        default=project_root / "backup/qmllint-debt-cycle",
        help="durable backup directory inside the repository",
    )
    return parser.parse_args()


def resolve_inside_project(path: Path, project_root: Path, label: str) -> Path:
    """Resolve a path and reject targets outside the repository."""

    resolved_root = project_root.resolve()
    candidate = path if path.is_absolute() else resolved_root / path
    resolved = candidate.resolve()
    try:
        resolved.relative_to(resolved_root)
    except ValueError as error:
        raise CycleError(f"{label} must stay inside the project: {path}") from error
    return resolved


def validate_config(config: CycleConfig) -> CycleConfig:
    """Validate paths, ID, profile, and executable inputs."""

    project_root = config.project_root.resolve()
    inventory_path = resolve_inside_project(config.inventory_path, project_root, "inventory")
    baseline_path = resolve_inside_project(config.baseline_path, project_root, "baseline")
    gate_script = resolve_inside_project(config.gate_script, project_root, "gate script")
    backup_root = resolve_inside_project(config.backup_root, project_root, "backup root")
    qmllint_path = config.qmllint_path.resolve()

    if not config.identifiers:
        raise CycleError("at least one inventory ID is required")
    if len(set(config.identifiers)) != len(config.identifiers):
        raise CycleError("inventory IDs must be unique")
    for identifier in config.identifiers:
        if not re.fullmatch(r"QML-[A-F0-9]{12}", identifier):
            raise CycleError(f"invalid inventory ID: {identifier}")
    if not config.observation.strip():
        raise CycleError("observation must not be empty")
    if not config.profile.strip():
        raise CycleError("profile must not be empty")
    for path, label in (
        (inventory_path, "inventory"),
        (baseline_path, "baseline"),
        (gate_script, "gate script"),
        (qmllint_path, "qmllint executable"),
    ):
        if not path.is_file():
            raise CycleError(f"{label} does not exist: {path}")
    if not os.access(qmllint_path, os.X_OK):
        raise CycleError(f"qmllint is not executable: {qmllint_path}")
    if not os.access(gate_script, os.X_OK):
        raise CycleError(f"gate script is not executable: {gate_script}")

    return CycleConfig(
        identifiers=tuple(config.identifiers),
        observation=config.observation.strip(),
        profile=config.profile.strip(),
        project_root=project_root,
        inventory_path=inventory_path,
        baseline_path=baseline_path,
        qmllint_path=qmllint_path,
        gate_script=gate_script,
        backup_root=backup_root,
    )


def active_ids(markdown: str) -> set[str]:
    """Return IDs from the active-warning table only."""

    identifiers: set[str] = set()
    in_active_section = False
    for line in markdown.splitlines():
        if line == "## Advertencias":
            in_active_section = True
            continue
        if in_active_section and line.startswith("## "):
            break
        if not in_active_section or not line.startswith("| - ["):
            continue
        match = ID_RE.search(line)
        if match:
            identifiers.add(match.group("identifier"))
    return identifiers


def verify_inventory_profile(markdown: str, profile: str, version: str) -> None:
    """Reject an inventory from another distribution or qmllint version."""

    if f"Perfil: `{profile}`" not in markdown:
        raise CycleError(f"inventory profile does not match: {profile}")
    if f"Versión efectiva de `qmllint`: `{version}`" not in markdown:
        raise CycleError(f"inventory qmllint version does not match: {version}")


def read_baseline(path: Path) -> dict[str, int]:
    """Read the strict numeric baseline format."""

    values: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        key, separator, raw_value = line.partition("=")
        if not separator or key not in BASELINE_KEYS or not raw_value.isdigit():
            raise CycleError(f"invalid baseline line: {line}")
        values[key] = int(raw_value)
    missing = [key for key in BASELINE_KEYS if key not in values]
    if missing:
        raise CycleError(f"baseline is missing keys: {', '.join(missing)}")
    return values


def render_baseline(values: dict[str, int]) -> str:
    """Render a baseline in canonical key order."""

    return "".join(f"{key}={values[key]}\n" for key in BASELINE_KEYS)


def gate_counts(
    diagnostics: list[inventory.WarningDiagnostic],
) -> GateCounts:
    """Count the categories enforced by the package gate."""

    categories = Counter(item.category for item in diagnostics)
    return GateCounts(
        total=len(diagnostics),
        unqualified=categories["unqualified"],
        layout=categories["Quick.layout-positioning"],
        missing_property=categories["missing-property"],
        import_count=categories["import"],
    )


def run_complete_lint(config: CycleConfig, log_path: Path) -> tuple[str, list[inventory.WarningDiagnostic], int]:
    """Run qmllint over every project QML file and parse the resulting log."""

    version_result = subprocess.run(
        [str(config.qmllint_path), "--version"],
        cwd=config.project_root,
        capture_output=True,
        text=True,
        check=False,
    )
    if version_result.returncode != 0:
        raise CycleError("qmllint --version failed")
    version_output = (version_result.stdout + version_result.stderr).strip()
    match = re.search(r"(?P<version>\d+\.\d+(?:\.\d+)?)", version_output)
    if not match:
        raise CycleError(f"cannot parse qmllint version: {version_output}")
    version = match.group("version")

    qml_root = config.project_root / "contents/ui"
    qml_files = sorted(path for path in qml_root.rglob("*.qml") if path.is_file())
    if not qml_files:
        raise CycleError("no QML files found under contents/ui")
    result = subprocess.run(
        [str(config.qmllint_path), *(str(path) for path in qml_files)],
        cwd=config.project_root,
        capture_output=True,
        text=True,
        check=False,
    )
    log_text = result.stdout + result.stderr
    log_path.write_text(log_text, encoding="utf-8")
    if result.returncode != 0:
        raise CycleError(f"qmllint failed with exit code {result.returncode}")
    diagnostics, info_count = inventory.parse_log(log_path, config.project_root)
    return version, diagnostics, info_count


def close_target_rows(
    markdown: str,
    identifiers: tuple[str, ...],
    observation: str,
    evidence: str,
) -> str:
    """Mark an absent historical batch as closed and refresh the solved count."""

    lines = markdown.splitlines()
    in_absent_section = False
    requested = set(identifiers)
    closed: set[str] = set()
    for index, line in enumerate(lines):
        if line == "## Firmas ausentes del corte actual":
            in_absent_section = True
            continue
        if in_absent_section and line.startswith("## "):
            in_absent_section = False
        if not in_absent_section:
            continue
        id_match = ID_RE.search(line)
        if not id_match or id_match.group("identifier") not in requested:
            continue
        identifier = id_match.group("identifier")
        match = inventory.TABLE_ROW_RE.match(line)
        if not match:
            raise CycleError(f"cannot parse absent inventory row: {identifier}")
        cells = inventory.split_markdown_cells(match.group("body"))
        if len(cells) != 9:
            raise CycleError(f"unexpected inventory row shape: {identifier}")
        cells[0] = "- [x]"
        cells[7] = inventory.escape_cell(observation)
        cells[8] = inventory.escape_cell(evidence)
        lines[index] = "| " + " | ".join(cells) + " |"
        closed.add(identifier)
    missing = sorted(requested - closed)
    if missing:
        raise CycleError(
            "target IDs did not move to the absent section: " + ", ".join(missing)
        )

    solved = 0
    in_absent_section = False
    for line in lines:
        if line == "## Firmas ausentes del corte actual":
            in_absent_section = True
            continue
        if in_absent_section and line.startswith("## "):
            in_absent_section = False
        if in_absent_section and line.startswith("| - [x] | `QML-"):
            solved += 1
    solved_pattern = re.compile(r"^- advertencias marcadas como resueltas: \*\*\d+\*\*;$")
    for index, line in enumerate(lines):
        if solved_pattern.match(line):
            lines[index] = f"- advertencias marcadas como resueltas: **{solved}**;"
            break
    return "\n".join(lines) + "\n"


def atomic_write(path: Path, content: str) -> None:
    """Replace one text file atomically after all validation gates pass."""

    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, delete=False
    ) as temporary_file:
        temporary_file.write(content)
        temporary_path = Path(temporary_file.name)
    os.replace(temporary_path, path)


def create_backups(config: CycleConfig) -> Path:
    """Create durable, non-overwriting backups for both mutable state files."""

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    backup_directory = config.backup_root / f"{stamp}-{len(config.identifiers)}-ids"
    backup_directory.mkdir(parents=True, exist_ok=False)
    shutil.copy2(config.inventory_path, backup_directory / "inventory.before.md")
    shutil.copy2(config.baseline_path, backup_directory / "baseline.before.env")
    return backup_directory


def commit_state(
    config: CycleConfig,
    inventory_content: str,
    baseline_content: str,
    backup_directory: Path,
) -> None:
    """Write both state files and restore both if either replacement fails."""

    inventory_before = (backup_directory / "inventory.before.md").read_text(
        encoding="utf-8"
    )
    baseline_before = (backup_directory / "baseline.before.env").read_text(
        encoding="utf-8"
    )
    try:
        atomic_write(config.baseline_path, baseline_content)
        atomic_write(config.inventory_path, inventory_content)
    except OSError as write_error:
        try:
            atomic_write(config.baseline_path, baseline_before)
            atomic_write(config.inventory_path, inventory_before)
        except OSError as rollback_error:
            raise CycleError(
                "state write failed and rollback was incomplete; restore from "
                f"{backup_directory}"
            ) from rollback_error
        raise CycleError("state write failed; inventory and baseline were restored") from write_error


def run_gate(config: CycleConfig, prospective_baseline: Path) -> None:
    """Run the profile package gate against the prospective lower baseline."""

    environment = os.environ.copy()
    environment["QMLLINT_BASELINE_FILE"] = str(prospective_baseline)
    environment["QMLLINT_BIN"] = str(config.qmllint_path)
    result = subprocess.run(
        [str(config.gate_script)],
        cwd=config.project_root,
        env=environment,
        check=False,
    )
    if result.returncode != 0:
        raise CycleError(f"profile gate failed with exit code {result.returncode}")


def close_cycle(config: CycleConfig) -> tuple[GateCounts, Path]:
    """Verify, gate, back up, and commit one inventory batch locally."""

    config = validate_config(config)
    existing_markdown = config.inventory_path.read_text(encoding="utf-8")
    before_active = active_ids(existing_markdown)
    inactive_targets = sorted(set(config.identifiers) - before_active)
    if inactive_targets:
        raise CycleError("target IDs are not active: " + ", ".join(inactive_targets))
    existing_rows = inventory.read_existing_rows(config.inventory_path)
    manual_states = inventory.read_manual_state(config.inventory_path)
    current_baseline = read_baseline(config.baseline_path)

    with tempfile.TemporaryDirectory(prefix="punchi-qmllint-cycle-") as temporary_directory:
        temporary_root = Path(temporary_directory)
        log_path = temporary_root / "qmllint.log"
        version, diagnostics, info_count = run_complete_lint(config, log_path)
        verify_inventory_profile(existing_markdown, config.profile, version)
        diagnostics = inventory.reconcile_identifiers(diagnostics, existing_rows)
        counts = gate_counts(diagnostics)
        after_ids = {item.identifier for item in diagnostics}
        new_ids = sorted(after_ids - before_active)
        if new_ids:
            raise CycleError(f"new diagnostic IDs detected: {', '.join(new_ids)}")
        remaining_targets = sorted(set(config.identifiers) & after_ids)
        if remaining_targets:
            raise CycleError("target IDs are still active: " + ", ".join(remaining_targets))

        prospective_baseline_values = counts.as_baseline()
        increases = [
            key
            for key, value in prospective_baseline_values.items()
            if value > current_baseline[key]
        ]
        if increases:
            raise CycleError(f"baseline increase would be required: {', '.join(increases)}")

        rendered_inventory = inventory.render_inventory(
            diagnostics,
            info_count,
            manual_states,
            config.profile,
            version,
            datetime.now(timezone.utc).date().isoformat(),
            existing_rows,
        )
        evidence = (
            f"{config.profile}, qmllint {version}: complete scan "
            f"{len(before_active)}->{counts.total}; no new IDs; profile gate passed."
        )
        rendered_inventory = close_target_rows(
            rendered_inventory,
            config.identifiers,
            config.observation,
            evidence,
        )
        rendered_baseline = render_baseline(prospective_baseline_values)
        prospective_baseline = temporary_root / "baseline.env"
        prospective_baseline.write_text(rendered_baseline, encoding="utf-8")
        run_gate(config, prospective_baseline)

        backup_directory = create_backups(config)
        commit_state(
            config,
            rendered_inventory,
            rendered_baseline,
            backup_directory,
        )

    return counts, backup_directory


def main() -> int:
    """Run the automated close command."""

    args = parse_args()
    config = CycleConfig(
        identifiers=tuple(args.identifiers),
        observation=args.observation,
        profile=args.profile,
        project_root=args.project_root,
        inventory_path=args.inventory,
        baseline_path=args.baseline,
        qmllint_path=args.qmllint,
        gate_script=args.gate_script,
        backup_root=args.backup_root,
    )
    try:
        counts, backup_directory = close_cycle(config)
    except (CycleError, OSError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2
    print(
        "Closed {identifiers}: total={total}, unqualified={unqualified}, "
        "layout={layout}, missing-property={missing}, import={imports}".format(
            identifiers=", ".join(config.identifiers),
            total=counts.total,
            unqualified=counts.unqualified,
            layout=counts.layout,
            missing=counts.missing_property,
            imports=counts.import_count,
        )
    )
    print(f"Backup: {backup_directory.relative_to(config.project_root.resolve())}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
