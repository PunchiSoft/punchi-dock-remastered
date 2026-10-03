#!/usr/bin/env python3
"""Seed a disposable desktop appearance before launching the QML fixture."""

import argparse
import os
from pathlib import Path
import sys


def main() -> int:
    """Prepare fixture settings in the parent-owned temporary, then exec."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs=argparse.REMAINDER,
                        help="Command launched with disposable appearance settings")
    arguments = parser.parse_args()
    root_value = os.environ.get("PUNCHI_TEST_ENVIRONMENT_ROOT")
    if not root_value or not arguments.command:
        parser.error("a parent-owned environment and test command are required")
    root = Path(root_value)
    environment = os.environ.copy()
    for variable, folder in (
        ("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
        ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "runtime"),
        ("XDG_CONFIG_DIRS", "system-config"),
    ):
        path = root / folder
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    (root / "config" / "kdeglobals").write_text("[Icons]\nTheme=breeze\n", encoding="utf-8")
    os.execvpe(arguments.command[0], arguments.command, environment)
    return 1


if __name__ == "__main__":
    sys.exit(main())
