#!/usr/bin/env python3
"""Verify the version declarations, the Unreleased section and the release record."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

VERSION = r"\d+\.\d+\.\d+\.\d+"
PROJECT_ID = "Punchi Dock Remastered"

UNRELEASED_HEADING = re.compile(r"^## Unreleased\s*$", re.M)
RELEASE_HEADING = re.compile(rf"^## \[({VERSION})\] - (\d{{4}}-\d{{2}}-\d{{2}})\s*$", re.M)
CMAKE_VERSION = re.compile(
    rf"project\(\s*punchi-dock-remastered\s+VERSION\s+({VERSION})\b"
)
POT_VERSION = re.compile(
    rf'^"Project-Id-Version: {re.escape(PROJECT_ID)} ({VERSION})\\n"$', re.M
)
DECLARED_VERSION = re.compile(rf"^({VERSION})$")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def declared_versions(root: Path) -> list[tuple[Path, str | None]]:
    """Return each declaration and the version it states, or None when absent."""
    metadata_path = root / "metadata.json"
    metadata_version = None
    try:
        metadata = json.loads(read(metadata_path))
        candidate = metadata["KPlugin"]["Version"]
        if isinstance(candidate, str) and DECLARED_VERSION.fullmatch(candidate):
            metadata_version = candidate
    except (OSError, ValueError, KeyError, TypeError):
        metadata_version = None

    cmake_match = CMAKE_VERSION.search(read(root / "CMakeLists.txt"))
    pot_path = root / "po" / "plasma_applet_org.kde.plasma.punchi-dock-remastered.pot"
    pot_match = POT_VERSION.search(read(pot_path))

    return [
        (metadata_path, metadata_version),
        (root / "CMakeLists.txt", cmake_match[1] if cmake_match else None),
        (pot_path, pot_match[1] if pot_match else None),
    ]


def check_changelog(root: Path, declared: str) -> list[str]:
    changelog_path = root / "CHANGELOG.md"
    try:
        changelog = read(changelog_path)
    except OSError as error:
        return [f"{changelog_path}: cannot be read ({error.strerror})"]

    problems = []
    if not UNRELEASED_HEADING.search(changelog):
        problems.append(
            f"{changelog_path}: missing a '## Unreleased' heading for pending work"
        )

    releases = [(version, date) for version, date in RELEASE_HEADING.findall(changelog)]
    if not releases:
        problems.append(
            f"{changelog_path}: no '## [<version>] - <YYYY-MM-DD>' release heading"
        )
        return problems

    newest = max(releases, key=lambda release: version_key(release[0]))
    if version_key(newest[0]) > version_key(declared):
        problems.append(
            f"{changelog_path}: newest release {newest[0]} ({newest[1]}) is ahead of "
            f"the declared version {declared}"
        )
    return problems


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    problems: list[str] = []

    declarations = declared_versions(root)
    for path, version in declarations:
        if version is None:
            problems.append(f"{path.relative_to(root)}: no version in the expected {VERSION} form")

    found = {version for _, version in declarations if version is not None}
    declared = None
    if len(found) == 1:
        declared = found.pop()
        problems.extend(check_changelog(root, declared))
    elif len(found) > 1:
        rendered = ", ".join(sorted(found))
        problems.append(f"version declarations disagree: {rendered}")

    if problems:
        for problem in problems:
            print(f"FAIL {problem}", file=sys.stderr)
        return 1

    print(f"PASS version declarations agree on {declared}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
