#!/usr/bin/env python3
"""Regression tests for the Kubuntu Bash setup helpers."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SETUP_SCRIPT = PROJECT_ROOT / "scripts" / "distro" / "kubuntu-setup.sh"
SETUP_WRAPPER = PROJECT_ROOT / "scripts" / "setup-kubuntu.sh"
SHELL_HELPER = PROJECT_ROOT / "scripts" / "lib" / "plasma-version.sh"


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

    def test_shell_parser(self) -> None:
        """The Bash packaging wrappers use the same accepted forms."""

        for version_output, expected in self.CASES:
            with self.subTest(version_output=version_output):
                self.assertEqual(self.shell_version(version_output), expected)

    def test_setup_help_is_available_from_implementation_and_wrapper(self) -> None:
        """Both Kubuntu setup entry points expose the Bash CLI without host checks."""

        with tempfile.TemporaryDirectory() as log_directory:
            environment = os.environ.copy()
            environment["PUNCHI_LOG_DIR"] = log_directory

            for script_path in (SETUP_SCRIPT, SETUP_WRAPPER):
                with self.subTest(script_path=script_path):
                    result = subprocess.run(
                        ("bash", str(script_path), "--help"),
                        check=True,
                        cwd=PROJECT_ROOT,
                        env=environment,
                        text=True,
                        stdout=subprocess.PIPE,
                    )
                    self.assertIn("Usage: scripts/setup-kubuntu.sh", result.stdout)


if __name__ == "__main__":
    unittest.main()
