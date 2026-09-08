#!/usr/bin/env python3
"""Run KIO against a disposable Trash and a private D-Bus session."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    # Keep the disposable home Trash on the build filesystem. /tmp can be a
    # separate mount with no writable per-volume Trash (e.g. tmpfs).
    with (tempfile.TemporaryDirectory(prefix="punchi-theme-trash-", dir=Path.cwd()) as directory,
          tempfile.TemporaryDirectory(prefix="punchi-kio-") as runtime):
        env = os.environ.copy()
        for variable, folder in (
            ("XDG_DATA_HOME", "data"),
            ("XDG_CONFIG_HOME", "config"),
            ("XDG_CACHE_HOME", "cache"),
        ):
            path = Path(directory) / folder
            path.mkdir(mode=0o700)
            env[variable] = str(path)
        # Unix socket paths must fit sockaddr_un even with a long checkout path.
        env["XDG_RUNTIME_DIR"] = runtime
        env["PUNCHI_ISOLATED_TRASH_TEST"] = "1"
        env["QT_QPA_PLATFORM"] = "offscreen"
        env["QT_LOGGING_TO_CONSOLE"] = "1"
        env["QT_FORCE_STDERR_LOGGING"] = "1"
        return subprocess.run(sys.argv[1:], env=env, timeout=25, check=False).returncode


if __name__ == "__main__":
    sys.exit(main())
