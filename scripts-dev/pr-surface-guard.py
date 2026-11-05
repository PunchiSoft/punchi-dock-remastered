#!/usr/bin/env python3
"""Reject pull requests whose diff hides intent in its shape.

The guard looks at how a change is delivered, not at whether it is welcome:
binaries, symlinks, executable bits and infrastructure paths are the places
where a contribution can hide something that a review of the source misses.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys


SENSITIVE_PREFIXES = (
    ".github/",
    "scripts-dev/",
    "contents/ui/org/punchi/dock/compat/",
)

SENSITIVE_PATHS = {
    ".kpackageignore",
    "CMakeLists.txt",
    "LICENSE",
    "NOTICE",
    "metadata.json",
}


class Finding:
    def __init__(self, kind: str, path: str, detail: str) -> None:
        self.kind = kind
        self.path = path
        self.detail = detail

    def __str__(self) -> str:
        return f"[{self.kind}] {self.path}: {self.detail}"


def git(*arguments: str) -> str:
    result = subprocess.run(
        ["git", *arguments],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(
            f"git {' '.join(arguments)} failed: {result.stderr.strip()}"
        )
    return result.stdout


def base_commit(base: str) -> str:
    merge_base = git("merge-base", base, "HEAD").strip()
    return merge_base or git("rev-parse", base).strip()


def check_numstat(base: str) -> list[Finding]:
    findings: list[Finding] = []
    for line in git("diff", "--numstat", base, "HEAD").splitlines():
        parts = line.split("\t", 2)
        if len(parts) != 3:
            continue
        added, removed, path = parts
        if added == "-" or removed == "-":
            findings.append(
                Finding("binary", path, "binary content is not reviewable as a diff")
            )
    return findings


def check_modes(base: str) -> list[Finding]:
    findings: list[Finding] = []
    for line in git("diff", "--summary", base, "HEAD").splitlines():
        line = line.strip()
        created = re.match(r"^create mode (\d+) (.+)$", line)
        changed = re.match(r"^mode change (\d+) => (\d+) (.+)$", line)
        if created:
            previous, mode, path = None, created.group(1), created.group(2)
        elif changed:
            previous, mode, path = changed.group(1), changed.group(2), changed.group(3)
        else:
            continue
        if mode == "120000":
            findings.append(
                Finding("symlink", path, "symlinks escape the reviewable tree")
            )
        elif mode == "160000":
            findings.append(
                Finding("submodule", path, "submodules change code outside the diff")
            )
        elif mode == "100755" and previous != "100755":
            findings.append(
                Finding("executable", path, "a new executable file needs a reason")
            )
    return findings


def check_paths(base: str) -> list[Finding]:
    findings: list[Finding] = []
    for path in git("diff", "--name-only", base, "HEAD").splitlines():
        path = path.strip()
        if not path:
            continue
        if path in SENSITIVE_PATHS or path.startswith(SENSITIVE_PREFIXES):
            findings.append(
                Finding(
                    "sensitive-path",
                    path,
                    "changes here alter the build, the packaging or the review tooling",
                )
            )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--base",
        default="origin/main",
        help="commit or branch the pull request is based on (default: origin/main)",
    )
    parser.add_argument(
        "--sensitive-paths",
        choices=("fail", "warn"),
        default="fail",
        help="treat infrastructure edits as a failure or as a notice (default: fail)",
    )
    arguments = parser.parse_args()

    base = base_commit(arguments.base)
    shape = [*check_numstat(base), *check_modes(base)]
    infrastructure = check_paths(base)

    if arguments.sensitive_paths == "warn":
        for finding in infrastructure:
            print(f"notice {finding}")
        infrastructure = []

    findings = [*shape, *infrastructure]

    if not findings:
        print(f"PASS diff against {arguments.base} stays reviewable")
        return 0

    for finding in findings:
        print(finding)
    print(
        f"\nFAIL {len(findings)} finding(s). A maintainer must authorize each one "
        "explicitly before this change is accepted."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
