#!/usr/bin/env python3
"""Seed deterministic native discovery inputs in a parent-owned temporary."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys


def main() -> int:
    """Build a disposable service cache and replace this child with the QML test."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    root_value = os.environ.get("PUNCHI_TEST_ENVIRONMENT_ROOT")
    if not root_value or not arguments.command:
        parser.error("a parent-owned temporary and test command are required")
    cache_builder = shutil.which("kbuildsycoca6")
    if cache_builder is None:
        parser.error("kbuildsycoca6 is required for native discovery")
    root = Path(root_value)
    environment = os.environ.copy()
    for variable, folder in (
        ("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
        ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "runtime"),
        ("XDG_DATA_DIRS", "system-data"), ("XDG_CONFIG_DIRS", "system-config"),
    ):
        path = root / folder
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    environment["XDG_CURRENT_DESKTOP"] = "KDE"
    environment["XDG_MENU_PREFIX"] = ""
    icons = Path("/usr/share/icons")
    if icons.is_dir():
        (root / "system-data" / "icons").symlink_to(icons, target_is_directory=True)
    (root / "config" / "kdeglobals").write_text("[Icons]\nTheme=breeze\n", encoding="utf-8")
    applications = root / "data" / "applications"
    applications.mkdir()
    for filename, name, category, hidden in (
        ("fixture-browser.desktop", "Fixture Browser", "Network", False),
        ("fixture-mail.desktop", "Fixture Mail", "Email", False),
        ("fixture-office.desktop", "Fixture Office", "Office", False),
        ("fixture-hidden.desktop", "Fixture Hidden", "Network", True),
    ):
        (applications / filename).write_text(
            "[Desktop Entry]\nType=Application\n"
            f"Name={name}\nCategories={category};\n"
            f"NoDisplay={'true' if hidden else 'false'}\n"
            "Icon=application-x-executable\nExec=/bin/true\nTerminal=false\n",
            encoding="utf-8",
        )
    menus = root / "config" / "menus"
    menus.mkdir()
    (menus / "applications.menu").write_text(
        "<Menu><Name>Applications</Name><DefaultAppDirs/>"
        "<Include><All/></Include></Menu>\n", encoding="utf-8",
    )
    fixtures = root / "runtime" / "fixtures"
    populated = fixtures / "populated"
    populated.mkdir(parents=True)
    (populated / "subfolder").mkdir()
    (populated / "document.txt").write_text("Controlled folder entry.\n", encoding="utf-8")
    (populated / ".hidden.txt").write_text("Hidden fixture.\n", encoding="utf-8")
    (fixtures / "empty").mkdir()
    result = subprocess.run(
        [cache_builder, "--noincremental"], env=environment,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=10,
    )
    if result.returncode != 0:
        print(result.stdout, file=sys.stderr)
        return result.returncode
    os.execvpe(arguments.command[0], arguments.command, environment)
    return 1


if __name__ == "__main__":
    sys.exit(main())
