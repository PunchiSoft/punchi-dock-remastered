#!/usr/bin/env python3
"""Run the tooltip fixture inside the parent wrapper's disposable environment."""

import argparse
import os
from pathlib import Path
import sys


def main() -> int:
    """Set disposable XDG roots before replacing this child with the test."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs=argparse.REMAINDER,
                        help="Test command launched inside the parent-owned environment")
    arguments = parser.parse_args()
    if not arguments.command:
        parser.error("a test command is required")
    environment_root = os.environ.get("PUNCHI_TEST_ENVIRONMENT_ROOT")
    if not environment_root:
        parser.error("the parent isolation wrapper is required")
    root = Path(environment_root)
    environment = os.environ.copy()
    for variable, folder in (
        ("XDG_DATA_HOME", "data"),
        ("XDG_CONFIG_HOME", "config"),
        ("XDG_CACHE_HOME", "cache"),
        ("XDG_RUNTIME_DIR", "runtime"),
    ):
        path = root / folder
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    os.execvpe(arguments.command[0], arguments.command, environment)
    return 1


if __name__ == "__main__":
    sys.exit(main())
