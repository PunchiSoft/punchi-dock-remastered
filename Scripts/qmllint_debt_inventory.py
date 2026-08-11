#!/usr/bin/env python3
"""Create a stable Markdown inventory from a qmllint diagnostic log."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, replace
from datetime import date
from pathlib import Path


WARNING_RE = re.compile(
    r"^Warning: (?P<path>.*?):(?P<line>\d+):(?P<column>\d+): "
    r"(?P<message>.*?)(?: \[(?P<category>[^\]]+)\])?$"
)
TABLE_ROW_RE = re.compile(r"^\| (?P<body>.*) \|$")

CATEGORY_EXPLANATIONS = {
    "alias-cycle": (
        "Two or more property aliases form a dependency cycle. Break the cycle and verify "
        "component creation because initialization can become invalid."
    ),
    "missing-property": (
        "The inferred QML type does not expose the referenced property. Check "
        "the type, Loader boundary, required property, or confirmed false positive."
    ),
    "import": (
        "The import cannot be resolved or is incompatible with the active Qt/KDE profile."
    ),
    "Quick.layout-positioning": (
        "Anchors or manual geometry conflict with a Qt Quick Layout responsibility."
    ),
    "unqualified": (
        "A name is resolved through an implicit scope. Qualify the root object, model role, "
        "delegate context, or attached object explicitly."
    ),
}


@dataclass(frozen=True)
class WarningDiagnostic:
    """One gate-counted qmllint warning."""

    identifier: str
    path: str
    line: int
    column: int
    category: str
    message: str


@dataclass(frozen=True)
class ManualState:
    """Human-maintained fields preserved across inventory regeneration."""

    checkbox: str = "- [ ]"
    observation: str = "—"
    evidence: str = "—"


@dataclass(frozen=True)
class ExistingRow:
    """A previously generated row retained for historical closure."""

    identifier: str
    cells: tuple[str, ...]


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""

    project_default = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=(
            "Generate a Markdown checklist containing every Warning diagnostic in a "
            "qmllint log. Existing checkboxes, observations, and evidence are preserved "
            "when the output file already exists."
        )
    )
    parser.add_argument("--log", required=True, type=Path, help="qmllint log to parse")
    parser.add_argument(
        "--output", required=True, type=Path, help="Markdown inventory to create or update"
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=project_default,
        help="project root used to remove absolute paths (default: repository root)",
    )
    parser.add_argument("--profile", required=True, help="distribution/profile label")
    parser.add_argument("--qt-version", required=True, help="effective qmllint/Qt version")
    parser.add_argument(
        "--date",
        default=date.today().isoformat(),
        help="inventory cutoff date in ISO format (default: today)",
    )
    return parser.parse_args()


def normalize_project_path(raw_path: str, project_root: Path) -> str:
    """Return a project-relative path and reject paths outside the project."""

    candidate = Path(raw_path)
    if candidate.is_absolute():
        try:
            return candidate.resolve().relative_to(project_root.resolve()).as_posix()
        except ValueError as error:
            raise ValueError(f"diagnostic path is outside project root: {raw_path}") from error

    normalized = candidate.as_posix().lstrip("./")
    if normalized.startswith("../") or normalized == "..":
        raise ValueError(f"diagnostic path escapes project root: {raw_path}")
    return normalized


def stable_identifier(
    path: str, category: str, message: str, occurrence: int
) -> str:
    """Build an ID that survives line shifts while distinguishing duplicate warnings."""

    source = "\0".join((path, category, message, str(occurrence))).encode("utf-8")
    return f"QML-{hashlib.sha256(source).hexdigest()[:12].upper()}"


def parse_log(log_path: Path, project_root: Path) -> tuple[list[WarningDiagnostic], int]:
    """Parse gate-counted warnings and count auxiliary non-gate Info lines."""

    diagnostics: list[WarningDiagnostic] = []
    occurrences: defaultdict[tuple[str, str, str], int] = defaultdict(int)
    info_count = 0

    for raw_line in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if raw_line.startswith("Info:"):
            info_count += 1
            continue
        match = WARNING_RE.match(raw_line)
        if not match:
            continue
        path = normalize_project_path(match.group("path"), project_root)
        category = match.group("category") or "uncategorized"
        message = match.group("message").strip()
        key = (path, category, message)
        occurrences[key] += 1
        diagnostics.append(
            WarningDiagnostic(
                identifier=stable_identifier(*key, occurrences[key]),
                path=path,
                line=int(match.group("line")),
                column=int(match.group("column")),
                category=category,
                message=message,
            )
        )

    return diagnostics, info_count


def split_markdown_cells(body: str) -> list[str]:
    """Split table cells while retaining escaped pipe characters."""

    cells: list[str] = []
    current: list[str] = []
    escaped = False
    for character in body:
        if character == "|" and not escaped:
            cells.append("".join(current).strip())
            current = []
            continue
        current.append(character)
        escaped = character == "\\" and not escaped
        if character != "\\":
            escaped = False
    cells.append("".join(current).strip())
    return cells


def read_existing_rows(output_path: Path) -> dict[str, ExistingRow]:
    """Read all diagnostic rows from an existing generated inventory."""

    if not output_path.exists():
        return {}

    rows: dict[str, ExistingRow] = {}
    for line in output_path.read_text(encoding="utf-8").splitlines():
        match = TABLE_ROW_RE.match(line)
        if not match:
            continue
        cells = split_markdown_cells(match.group("body"))
        if len(cells) != 9 or not cells[1].startswith("`QML-"):
            continue
        identifier = cells[1].strip("`")
        rows[identifier] = ExistingRow(
            identifier=identifier,
            cells=tuple(cells),
        )
    return rows


def read_manual_state(output_path: Path) -> dict[str, ManualState]:
    """Read editable fields from an existing generated inventory."""

    states: dict[str, ManualState] = {}
    for identifier, row in read_existing_rows(output_path).items():
        checkbox = row.cells[0]
        states[identifier] = ManualState(
            checkbox="- [x]" if checkbox.lower() == "- [x]" else "- [ ]",
            observation=row.cells[7],
            evidence=row.cells[8],
        )
    return states


def reconcile_identifiers(
    diagnostics: list[WarningDiagnostic], existing_rows: dict[str, ExistingRow]
) -> list[WarningDiagnostic]:
    """Reuse existing IDs without shifting duplicates when one warning disappears."""

    exact_rows: defaultdict[
        tuple[str, int, int, str, str], list[ExistingRow]
    ] = defaultdict(list)
    semantic_rows: defaultdict[tuple[str, str, str], list[ExistingRow]] = defaultdict(list)
    for row in existing_rows.values():
        try:
            line_text, column_text = row.cells[3].split(":", maxsplit=1)
            signature = (
                row.cells[2].strip("`"),
                int(line_text),
                int(column_text),
                row.cells[4].strip("`"),
                row.cells[5],
            )
        except (ValueError, IndexError):
            continue
        exact_rows[signature].append(row)
        semantic_rows[(signature[0], signature[3], signature[4])].append(row)

    used_ids: set[str] = set()
    reconciled: list[WarningDiagnostic] = []
    unmatched: list[WarningDiagnostic] = []
    for diagnostic in diagnostics:
        signature = (
            diagnostic.path,
            diagnostic.line,
            diagnostic.column,
            diagnostic.category,
            diagnostic.message,
        )
        candidates = [row for row in exact_rows[signature] if row.identifier not in used_ids]
        if candidates:
            selected = candidates[0]
            used_ids.add(selected.identifier)
            reconciled.append(replace(diagnostic, identifier=selected.identifier))
        else:
            unmatched.append(diagnostic)

    unmatched_groups = Counter(
        (item.path, item.category, item.message) for item in unmatched
    )
    for diagnostic in unmatched:
        key = (diagnostic.path, diagnostic.category, diagnostic.message)
        candidates = [row for row in semantic_rows[key] if row.identifier not in used_ids]
        if (
            unmatched_groups[key] == 1
            and len(semantic_rows[key]) == 1
            and len(candidates) == 1
        ):
            selected = candidates[0]
            used_ids.add(selected.identifier)
            reconciled.append(replace(diagnostic, identifier=selected.identifier))
        else:
            identifier = diagnostic.identifier
            salt = 1
            while identifier in existing_rows or identifier in used_ids:
                identifier = stable_identifier(
                    diagnostic.path,
                    diagnostic.category,
                    f"{diagnostic.message}\0{diagnostic.line}:{diagnostic.column}",
                    salt,
                )
                salt += 1
            used_ids.add(identifier)
            reconciled.append(replace(diagnostic, identifier=identifier))

    return sorted(reconciled, key=lambda item: (item.path, item.line, item.column))


def escape_cell(value: str) -> str:
    """Escape a value for a single-line Markdown table cell."""

    return value.replace("\\", "\\\\").replace("|", "\\|").replace("\n", " ")


def render_inventory(
    diagnostics: list[WarningDiagnostic],
    info_count: int,
    manual_states: dict[str, ManualState],
    profile: str,
    qt_version: str,
    cutoff_date: str,
    existing_rows: dict[str, ExistingRow] | None = None,
) -> str:
    """Render the complete inventory as Markdown."""

    categories = Counter(item.category for item in diagnostics)
    previous_rows = existing_rows or {}
    active_ids = {item.identifier for item in diagnostics}
    absent_rows = [row for identifier, row in previous_rows.items() if identifier not in active_ids]
    solved = sum(1 for row in absent_rows if row.cells[0].lower() == "- [x]")
    category_rows = "\n".join(
        f"| `{escape_cell(category)}` | {count} |"
        for category, count in sorted(categories.items(), key=lambda item: (-item[1], item[0]))
    )
    rows: list[str] = []
    for item in diagnostics:
        state = manual_states.get(item.identifier, ManualState())
        explanation = CATEGORY_EXPLANATIONS.get(
            item.category,
            "Diagnostic emitted by qmllint; classify its concrete cause before changing code.",
        )
        rows.append(
            "| {checkbox} | `{identifier}` | `{path}` | {line}:{column} | "
            "`{category}` | {message} | {explanation} | {observation} | {evidence} |".format(
                checkbox="- [ ]",
                identifier=item.identifier,
                path=escape_cell(item.path),
                line=item.line,
                column=item.column,
                category=escape_cell(item.category),
                message=escape_cell(item.message),
                explanation=escape_cell(explanation),
                observation=state.observation,
                evidence=state.evidence,
            )
        )

    absent_lines = []
    for row in absent_rows:
        cells = list(row.cells)
        cells[0] = "- [x]" if cells[0].lower() == "- [x]" else "- [ ]"
        absent_lines.append("| " + " | ".join(cells) + " |")
    absent_section = ""
    if absent_lines:
        absent_section = f"""

## Firmas ausentes del corte actual

Estas firmas estaban en el corte anterior y ya no aparecen. Revisar que el
perfil sea equivalente, completar la observación y evidencia, y solo entonces
cambiar su checkbox a `[x]`. El generador conservará estas filas históricas.

| Estado | ID | Archivo | Posición anterior | Categoría | Diagnóstico | A qué corresponde | Observación | Evidencia de cierre |
|---|---|---|---:|---|---|---|---|---|
{chr(10).join(absent_lines)}
"""

    return f"""# Inventario de deuda QML — {escape_cell(profile)}

Fecha de corte: {cutoff_date}

Perfil: `{escape_cell(profile)}`

Versión efectiva de `qmllint`: `{escape_cell(qt_version)}`

Estado: activo.

## Resumen

- advertencias contabilizadas por el gate: **{len(diagnostics)}**;
- advertencias marcadas como resueltas: **{solved}**;
- líneas auxiliares `Info:` fuera del gate: **{info_count}**;
- fuente: ejecución completa de `qmllint` sobre `contents/ui/**/*.qml`;
- regla de cierre: un checkbox solo cambia a `[x]` después de que la firma ya no
  aparezca al repetir el mismo perfil y quede registrada la evidencia.

| Categoría | Cantidad |
|---|---:|
{category_rows}

## Advertencias

Cada fila corresponde a una ocurrencia real. El identificador omite la línea
para sobrevivir a desplazamientos de código y distingue diagnósticos repetidos.

| Estado | ID | Archivo | Posición | Categoría | Diagnóstico | A qué corresponde | Observación | Evidencia de cierre |
|---|---|---|---:|---|---|---|---|---|
{chr(10).join(rows)}
{absent_section}
"""


def main() -> int:
    """Run the inventory generator."""

    args = parse_args()
    try:
        diagnostics, info_count = parse_log(args.log, args.project_root)
        if not diagnostics:
            raise ValueError("the log contains no gate-counted Warning diagnostics")
        existing_rows = read_existing_rows(args.output)
        diagnostics = reconcile_identifiers(diagnostics, existing_rows)
        manual_states = read_manual_state(args.output)
        rendered = render_inventory(
            diagnostics,
            info_count,
            manual_states,
            args.profile,
            args.qt_version,
            args.date,
            existing_rows,
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2

    print(
        f"Inventory written: {args.output} "
        f"({len(diagnostics)} warnings, {info_count} auxiliary info lines)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
