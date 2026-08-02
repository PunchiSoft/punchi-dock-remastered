#!/usr/bin/env python3
"""Detect and repair source text accidentally prepended to PO translations."""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


FIELD_PATTERN = re.compile(
    r'^(?P<name>msgctxt|msgid|msgid_plural|msgstr(?:\[(?:0|[1-9][0-9]*)\])?)\s+(?P<value>".*")\s*$'
)
CONTINUATION_PATTERN = re.compile(r'^\s*(?P<value>".*")\s*$')


@dataclass(frozen=True)
class PoField:
    """A decoded PO field and the lines that encode it."""

    name: str
    start: int
    end: int
    value: str


@dataclass(frozen=True)
class Contamination:
    """A translation containing a source or context prefix."""

    field: PoField
    prefix: str
    source: str


def decode_po_string(encoded: str, path: Path, line_number: int) -> str:
    """Decode one quoted PO fragment with Python's compatible string parser."""

    try:
        value = ast.literal_eval(encoded)
    except (SyntaxError, ValueError) as error:
        raise ValueError(f"{path}:{line_number}: invalid PO string: {error}") from error
    if not isinstance(value, str):
        raise ValueError(f"{path}:{line_number}: PO field is not a string")
    return value


def parse_fields(lines: Sequence[str], path: Path) -> list[PoField]:
    """Parse active fields while leaving comments and obsolete entries untouched."""

    fields: list[PoField] = []
    index = 0
    while index < len(lines):
        line = lines[index].rstrip("\n")
        match = FIELD_PATTERN.match(line)
        if not match:
            index += 1
            continue

        fragments = [decode_po_string(match.group("value"), path, index + 1)]
        end = index + 1
        while end < len(lines):
            continuation = CONTINUATION_PATTERN.match(lines[end].rstrip("\n"))
            if not continuation:
                break
            fragments.append(decode_po_string(continuation.group("value"), path, end + 1))
            end += 1

        fields.append(PoField(match.group("name"), index, end, "".join(fragments)))
        index = end

    return fields


def source_candidates(field: PoField, singular: str, plural: str) -> tuple[str, ...]:
    """Return the likely source strings for a singular or plural translation."""

    if field.name == "msgstr[0]" or field.name == "msgstr":
        ordered = (singular, plural)
    else:
        ordered = (plural, singular)
    return tuple(source for source in ordered if source)


def find_prefix(translation: str, context: str, sources: Iterable[str]) -> tuple[str, str] | None:
    """Find a non-empty source/context prefix followed by an actual translation."""

    prefixes: list[tuple[str, str]] = []
    for source in sources:
        if context:
            prefixes.append((context + source, source))
        prefixes.append((source, source))

    for prefix, source in sorted(prefixes, key=lambda candidate: len(candidate[0]), reverse=True):
        if translation.startswith(prefix) and len(translation) > len(prefix):
            return prefix, source
    return None


def entry_ranges(lines: Sequence[str]) -> Iterable[tuple[int, int]]:
    """Yield non-empty PO entry ranges separated by blank lines."""

    start = 0
    for index, line in enumerate(lines):
        if line.strip():
            continue
        if start < index:
            yield start, index
        start = index + 1
    if start < len(lines):
        yield start, len(lines)


def contaminations(lines: Sequence[str], path: Path) -> list[Contamination]:
    """Return every active translation polluted with its own context or source."""

    issues: list[Contamination] = []
    for start, end in entry_ranges(lines):
        relative_fields = parse_fields(lines[start:end], path)
        values = {field.name: field.value for field in relative_fields}
        singular = values.get("msgid", "")
        if not singular:
            continue

        plural = values.get("msgid_plural", "")
        context = values.get("msgctxt", "")
        for relative_field in relative_fields:
            if not relative_field.name.startswith("msgstr") or not relative_field.value:
                continue
            prefix = find_prefix(
                relative_field.value,
                context,
                source_candidates(relative_field, singular, plural),
            )
            if prefix:
                field = PoField(
                    relative_field.name,
                    start + relative_field.start,
                    start + relative_field.end,
                    relative_field.value,
                )
                issues.append(Contamination(field, prefix[0], prefix[1]))
    return issues


def repair_lines(lines: Sequence[str], path: Path) -> tuple[list[str], list[Contamination]]:
    """Remove only confirmed prefixes and preserve every other PO line."""

    issues = contaminations(lines, path)
    repaired = list(lines)
    for issue in sorted(issues, key=lambda item: item.field.start, reverse=True):
        value = issue.field.value[len(issue.prefix) :]
        replacement = f"{issue.field.name} {json.dumps(value, ensure_ascii=False)}\n"
        repaired[issue.field.start : issue.field.end] = [replacement]
    return repaired, issues


def read_catalog(path: Path) -> list[str]:
    """Read a UTF-8 catalog without normalizing its existing line structure."""

    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def check_catalog(path: Path) -> int:
    """Report semantic contamination and return the number of affected entries."""

    issues = contaminations(read_catalog(path), path)
    for issue in issues:
        preview = issue.source.replace("\n", " ")[:100]
        print(
            f"{path}:{issue.field.start + 1}: translation starts with its source/context: {preview}",
            file=sys.stderr,
        )
    return len(issues)


def repair_catalog(source: Path, destination: Path) -> int:
    """Write a repaired copy and return the number of translations changed."""

    repaired, issues = repair_lines(read_catalog(source), source)
    destination.write_text("".join(repaired), encoding="utf-8")
    return len(issues)


def self_test() -> None:
    """Verify context, singular, and plural contamination detection in memory."""

    fixture = [
        'msgctxt "@info:status"\n',
        'msgid "Current state"\n',
        'msgstr "@info:statusCurrent stateEstado actual"\n',
        "\n",
        'msgid "When enabled"\n',
        'msgstr "When enabledCuando está activado"\n',
        "\n",
        'msgid "%1 second"\n',
        'msgid_plural "%1 seconds"\n',
        'msgstr[0] "%1 second%1 segundo"\n',
        'msgstr[1] "%1 seconds%1 segundos"\n',
    ]
    fixture_path = Path("<semantic-self-test>")
    repaired, issues = repair_lines(fixture, fixture_path)
    if len(issues) != 4:
        raise AssertionError(f"expected 4 contaminated translations, found {len(issues)}")
    if contaminations(repaired, fixture_path):
        raise AssertionError("repaired fixture still contains semantic contamination")
    repaired_text = "".join(repaired)
    for expected in ("Estado actual", "Cuando está activado", "%1 segundo", "%1 segundos"):
        if expected not in repaired_text:
            raise AssertionError(f"repaired fixture lost translation: {expected}")


def parse_arguments() -> argparse.Namespace:
    """Parse the semantic-check and controlled-repair command line."""

    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--check",
        nargs="+",
        type=Path,
        metavar="CATALOG",
        help="fail when a catalog translation starts with its own source or context",
    )
    mode.add_argument(
        "--repair",
        nargs=2,
        type=Path,
        metavar=("SOURCE", "DESTINATION"),
        help="write a repaired copy without replacing the source catalog",
    )
    mode.add_argument(
        "--self-test",
        action="store_true",
        help="verify the semantic detector with in-memory contaminated fixtures",
    )
    return parser.parse_args()


def main() -> int:
    """Run the requested semantic operation."""

    arguments = parse_arguments()
    if arguments.self_test:
        self_test()
        return 0
    if arguments.check:
        issue_count = sum(check_catalog(path) for path in arguments.check)
        if issue_count:
            print(f"Found {issue_count} contaminated translations.", file=sys.stderr)
            return 1
        return 0

    source, destination = arguments.repair
    change_count = repair_catalog(source, destination)
    print(f"Repaired {change_count} translations: {source} -> {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
