#!/usr/bin/env python3
"""Regression tests for localized plasmashell version output."""

from __future__ import annotations

import importlib.util
import subprocess
import unittest
from pathlib import Path
from types import ModuleType


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SETUP_SCRIPT = PROJECT_ROOT / "scripts" / "Kubuntu" / "setup_kubuntu_build.py"
SHELL_HELPER = PROJECT_ROOT / "scripts" / "lib" / "plasma-version.sh"


def load_setup_module() -> ModuleType:
    """Load the setup script without executing its CLI entry point."""

    spec = importlib.util.spec_from_file_location("setup_kubuntu_build", SETUP_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load test target: {SETUP_SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


SETUP_MODULE = load_setup_module()


class PlasmaVersionDetectionTest(unittest.TestCase):
    """Ensure translated suffixes cannot replace the numeric version."""

    CASES = (
        ("plasmashell 6.6.4", "6.6.4"),
        ("plasmashell 6.6.4 (Conseguido).", "6.6.4"),
        ("Qt 6.10.2\nplasmashell versión 6.6.4 (Conseguido).", "6.6.4"),
        ("plasmashell version 6.6", "6.6"),
        ("plasmashell version unavailable", ""),
    )

    def shell_version(self, version_output: str) -> str:
        """Invoke the shared Bash parser with the supplied output as data."""

        result = subprocess.run(
            (
                "bash",
                "-c",
                'source "$1"; punchi_extract_plasma_version "$2"',
                "bash",
                str(SHELL_HELPER),
                version_output,
            ),
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        )
        return result.stdout.strip()

    def test_python_parser(self) -> None:
        """The Python bootstrap extracts versions from localized output."""

        for version_output, expected in self.CASES:
            with self.subTest(version_output=version_output):
                self.assertEqual(
                    SETUP_MODULE.extract_plasma_version(version_output), expected
                )

    def test_setup_script_resolves_project_root(self) -> None:
        """The bootstrap invokes build scripts from the repository root."""

        self.assertEqual(SETUP_MODULE.PROJECT_ROOT, PROJECT_ROOT)
        self.assertTrue(
            (SETUP_MODULE.PROJECT_ROOT / "scripts" / "check-build-environment.sh").is_file()
        )

    def test_shell_parser(self) -> None:
        """The Bash packaging wrappers use the same accepted forms."""

        for version_output, expected in self.CASES:
            with self.subTest(version_output=version_output):
                self.assertEqual(self.shell_version(version_output), expected)


if __name__ == "__main__":
    unittest.main()
