#!/usr/bin/env python3
"""Set animation speed only inside the parent-owned navigation fixture."""
import os
from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) < 3 or sys.argv[1] not in ("0", "4"):
        raise ValueError("An instant (0) or slow (4) animation profile and runner are required")
    root = Path(os.environ["PUNCHI_TEST_ENVIRONMENT_ROOT"]).resolve(strict=True)
    configuration = Path(os.environ["XDG_CONFIG_HOME"]).resolve(strict=True)
    if configuration != root / "config":
        raise ValueError("The animation profile must use the isolated fixture configuration")
    globals_file = configuration / "kdeglobals"
    with globals_file.open("a") as stream:
        stream.write("\n[KDE]\nAnimationDurationFactor=" + sys.argv[1] + "\n")
    os.execvpe(sys.argv[2], sys.argv[2:], os.environ)
    return 1


if __name__ == "__main__":
    sys.exit(main())
