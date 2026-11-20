#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Classify a pull-request diff for the Remastered CI gate.

Only a small, explicit set of prose files may skip the native build. Unknown,
empty and mixed diffs take the full gate. A malformed or unavailable Git range
also takes the full gate, so a force-pushed branch cannot bypass validation.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path, PurePosixPath


DOCUMENTATION_ROOT_FILES = {
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "SUPPORT.md",
    "CODE_OF_CONDUCT.md",
}


def is_documentation_path(path: str) -> bool:
    """Return true only for paths whose content does not participate in builds."""
    if not path or path.startswith("/"):
        return False

    parsed = PurePosixPath(path)
    if ".." in parsed.parts:
        return False

    if path in DOCUMENTATION_ROOT_FILES:
        return True

    if len(parsed.parts) == 1 and parsed.name.startswith("README") and parsed.suffix == ".md":
        return True

    if (
        len(parsed.parts) == 3
        and parsed.parts[:2] == (".github", "ISSUE_TEMPLATE")
        and parsed.suffix in {".yml", ".yaml"}
    ):
        return True

    return path == ".github/PULL_REQUEST_TEMPLATE.md"


def classify_paths(paths: list[str] | tuple[str, ...]) -> str:
    """Classify all-documentation diffs as docs; everything else is code."""
    if not paths:
        return "code"
    return "docs" if all(is_documentation_path(path) for path in paths) else "code"


def changed_paths(
    base: str, head: str, *, repository: Path | None = None
) -> list[str]:
    """Read changed paths without shell interpolation, preserving unusual names."""
    result = subprocess.run(
        ["git", "diff", "--no-renames", "--name-only", "-z", f"{base}...{head}"],
        cwd=repository,
        check=False,
        capture_output=True,
    )
    if result.returncode:
        message = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"git diff failed: {message}")
    return [os.fsdecode(path) for path in result.stdout.split(b"\0") if path]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True, help="base commit SHA")
    parser.add_argument("--head", required=True, help="head commit SHA")
    args = parser.parse_args()

    try:
        paths = changed_paths(args.base, args.head)
    except (OSError, RuntimeError) as error:
        print(f"pr-ci-paths: {error}", file=sys.stderr)
        print("code: Git comparison unavailable; failing closed")
        print("code")
        return 0

    kind = classify_paths(paths)
    print(f"{kind}: {len(paths)} changed path(s)")
    for path in paths:
        print(f"  {path}")
    print(kind)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
