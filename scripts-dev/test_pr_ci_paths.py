#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Tests for the fail-closed PR path classifier."""

import subprocess
import tempfile
import unittest
from pathlib import Path

from pr_ci_paths import changed_paths, classify_paths


class PullRequestPathClassifierTest(unittest.TestCase):
    def test_root_documentation_and_issue_forms_are_docs_only(self) -> None:
        self.assertEqual(
            classify_paths(
                [
                    "README.md",
                    "README.es.md",
                    "CHANGELOG.md",
                    "CONTRIBUTING.md",
                    ".github/PULL_REQUEST_TEMPLATE.md",
                    ".github/ISSUE_TEMPLATE/bug_report.yml",
                ]
            ),
            "docs",
        )

    def test_runtime_and_translation_paths_use_the_full_gate(self) -> None:
        self.assertEqual(classify_paths(["contents/ui/main.qml"]), "code")
        self.assertEqual(classify_paths(["po/es.po"]), "code")

    def test_ci_and_dependabot_configuration_use_the_full_gate(self) -> None:
        self.assertEqual(classify_paths([".github/workflows/ci.yml"]), "code")
        self.assertEqual(classify_paths([".github/dependabot.yml"]), "code")

    def test_unknown_or_empty_diffs_fail_closed_to_code(self) -> None:
        self.assertEqual(classify_paths(["docs-private/proposal.md"]), "code")
        self.assertEqual(classify_paths([".agents/skills/testing/SKILL.md"]), "code")
        self.assertEqual(classify_paths([]), "code")

    def test_mixed_diff_uses_the_full_gate(self) -> None:
        self.assertEqual(
            classify_paths(["README.md", "contents/ui/main.qml"]), "code"
        )

    def test_absolute_and_parent_paths_fail_closed(self) -> None:
        self.assertEqual(classify_paths(["/README.md"]), "code")
        self.assertEqual(classify_paths(["../README.md"]), "code")

    def test_renaming_runtime_code_to_readme_stays_code(self) -> None:
        with tempfile.TemporaryDirectory(prefix="punchi-ci-paths-") as directory:
            repository = Path(directory)

            def git(*arguments: str) -> str:
                result = subprocess.run(
                    ["git", *arguments],
                    cwd=repository,
                    check=True,
                    capture_output=True,
                    text=True,
                )
                return result.stdout.strip()

            git("init", "--quiet", "--initial-branch=main")
            git("config", "user.name", "CI Path Test")
            git("config", "user.email", "ci-path-test@example.invalid")
            git("config", "commit.gpgsign", "false")
            source = repository / "contents/ui/main.qml"
            source.parent.mkdir(parents=True)
            source.write_text("Item {}\n", encoding="utf-8")
            git("add", "contents/ui/main.qml")
            git("commit", "--quiet", "-m", "test: seed code path")
            base = git("rev-parse", "HEAD")

            git("mv", "contents/ui/main.qml", "README.md")
            git("commit", "--quiet", "-m", "docs: rename the code path")
            head = git("rev-parse", "HEAD")

            paths = changed_paths(base, head, repository=repository)
            self.assertIn("contents/ui/main.qml", paths)
            self.assertIn("README.md", paths)
            self.assertEqual(classify_paths(paths), "code")


if __name__ == "__main__":
    unittest.main(verbosity=2)
