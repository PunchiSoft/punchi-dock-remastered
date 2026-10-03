#!/usr/bin/env python3
"""Create controlled directory fixtures in a parent-owned disposable environment."""
import os
from pathlib import Path
import sys


def main() -> int:
    root = Path(os.environ["PUNCHI_TEST_ENVIRONMENT_ROOT"])
    for variable, name in (("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("XDG_CONFIG_DIRS", "system-config")):
        path = root / name
        path.mkdir(mode=0o700)
        os.environ[variable] = str(path)
    (root / "config" / "kdeglobals").write_text("[Icons]\nTheme=breeze\n")
    base = root / "runtime" / "navigation"
    (base / "one" / "two" / "three" / "four").mkdir(parents=True)
    (base / "empty").mkdir()
    (base / "document.txt").write_text("Fixture\n")
    (base / ".hidden").write_text("Hidden fixture\n")
    outside = root / "runtime" / "outside"
    outside.mkdir()
    (base / "escape").symlink_to(outside, target_is_directory=True)
    (base / "one" / "cycle").symlink_to(base, target_is_directory=True)
    (base / "many").mkdir()
    for number in range(100):
        (base / "many" / f"entry-{number}").write_text("Fixture\n")
    os.environ["QT_QPA_PLATFORM"] = "offscreen"
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "org.kde.desktop"
    os.environ["LANGUAGE"] = "en"
    os.execvpe(sys.argv[1], sys.argv[1:], os.environ)
    return 1


if __name__ == "__main__":
    sys.exit(main())
