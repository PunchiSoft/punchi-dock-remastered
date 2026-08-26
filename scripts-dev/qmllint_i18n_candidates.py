#!/usr/bin/env python3
"""Extract exact Plasma translation false-positive candidates from qmllint logs."""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import qmllint_debt_inventory as inventory


I18N_CALL_RE = re.compile(r"\b(?P<function>i18n|i18nc|i18np)\s*\(")


@dataclass(frozen=True)
class Candidate:
    """One warning whose reported column points at a translation function."""

    identifier: str
    path: str
    line: int
    column: int
    function: str


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""

    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=(
            "Generate a Markdown queue containing only warnings whose exact "
            "reported column points at i18n, i18nc, or i18np."
        )
    )
    parser.add_argument("--log", required=True, type=Path, help="qmllint text log")
    parser.add_argument(
        "--inventory", required=True, type=Path, help="active debt inventory"
    )
    parser.add_argument("--output", required=True, type=Path, help="Markdown output")
    parser.add_argument(
        "--project-root",
        type=Path,
        default=project_root,
        help="project root used to normalize paths",
    )
    parser.add_argument("--profile", required=True, help="qmllint profile label")
    parser.add_argument("--qt-version", required=True, help="effective Qt version")
    return parser.parse_args()


def source_by_warning(
    log_path: Path, project_root: Path
) -> dict[tuple[str, int, int, str, str], str]:
    """Return the source line printed immediately after every warning."""

    lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
    sources: dict[tuple[str, int, int, str, str], str] = {}
    for index, line in enumerate(lines):
        match = inventory.WARNING_RE.match(line)
        if match is None or index + 1 >= len(lines):
            continue
        source = lines[index + 1]
        if source.startswith(("Warning:", "Info:")):
            continue
        path = inventory.normalize_project_path(match.group("path"), project_root)
        category = match.group("category") or "uncategorized"
        key = (
            path,
            int(match.group("line")),
            int(match.group("column")),
            category,
            match.group("message").strip(),
        )
        sources[key] = source
    return sources


def translation_function_at_column(source: str, column: int) -> str | None:
    """Return the translation function when a one-based column points at it."""

    offset = column - 1
    if offset < 0:
        return None
    for match in I18N_CALL_RE.finditer(source):
        start, end = match.span("function")
        if start <= offset < end:
            return match.group("function")
    return None


def collect_candidates(
    log_path: Path, inventory_path: Path, project_root: Path
) -> list[Candidate]:
    """Parse, reconcile, and return exact translation warning candidates."""

    diagnostics, _ = inventory.parse_log(log_path, project_root)
    diagnostics = inventory.reconcile_identifiers(
        diagnostics, inventory.read_existing_rows(inventory_path)
    )
    sources = source_by_warning(log_path, project_root)
    candidates: list[Candidate] = []
    for diagnostic in diagnostics:
        key = (
            diagnostic.path,
            diagnostic.line,
            diagnostic.column,
            diagnostic.category,
            diagnostic.message,
        )
        function = translation_function_at_column(sources.get(key, ""), diagnostic.column)
        if function is None:
            continue
        candidates.append(
            Candidate(
                identifier=diagnostic.identifier,
                path=diagnostic.path,
                line=diagnostic.line,
                column=diagnostic.column,
                function=function,
            )
        )
    return candidates


def render_markdown(
    candidates: list[Candidate], profile: str, qt_version: str
) -> str:
    """Render a review queue without absolute paths."""

    per_file = Counter(candidate.path for candidate in candidates)
    file_rows = "\n".join(
        f"| `{path}` | {count} |"
        for path, count in sorted(per_file.items(), key=lambda item: (item[1], item[0]))
    )
    candidate_rows = "\n".join(
        "| - [ ] | `{identifier}` | `{path}` | {line}:{column} | `{function}` |".format(
            identifier=candidate.identifier,
            path=candidate.path,
            line=candidate.line,
            column=candidate.column,
            function=candidate.function,
        )
        for candidate in candidates
    )
    return f"""# Cola exacta de falsos positivos de traducción

Perfil: `{profile}`

Versión efectiva de `qmllint`: `{qt_version}`

Esta cola incluye únicamente diagnósticos cuya columna apunta directamente al
nombre de `i18n`, `i18nc` o `i18np`. La presencia de una traducción en la misma
línea no basta para clasificar otra advertencia como falso positivo.

- candidatos exactos pendientes: **{len(candidates)}**;
- orden de archivos: menor cantidad primero;
- cierre: lotes revisados de 5 a 20 IDs mediante `qmllint_debt_cycle.py`.

## Resumen por archivo

| Archivo | Candidatos |
|---|---:|
{file_rows}

## Cola

| Estado | ID | Archivo | Posición | Función |
|---|---|---|---:|---|
{candidate_rows}
"""


def main() -> int:
    """Generate the exact translation candidate queue."""

    args = parse_args()
    try:
        project_root = args.project_root.resolve()
        candidates = collect_candidates(args.log, args.inventory, project_root)
        output = args.output
        if not output.is_absolute():
            output = project_root / output
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            render_markdown(candidates, args.profile, args.qt_version),
            encoding="utf-8",
        )
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2
    print(f"Wrote {len(candidates)} exact candidates to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
