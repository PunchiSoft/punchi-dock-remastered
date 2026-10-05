#!/usr/bin/env python3
"""Adapt the verified null TabButton baseline only in a Debian Qt 6.8 copy."""

import argparse
from pathlib import Path
import re
import subprocess


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", required=True, type=Path)
    arguments = parser.parse_args()
    source = arguments.source_root.resolve()
    # The parent owns this disposable source. Never patch a working checkout.
    if source.name != "source" or not source.parent.name.startswith("debian-qt68-"):
        parser.error("A disposable Debian source copy is required")
    qtpaths = "/usr/lib/qt6/bin/qtpaths6"
    version = subprocess.check_output([qtpaths, "--qt-version"], text=True).strip()
    if not version.startswith("6.8."):
        parser.error("The style adaptation requires Qt 6.8")
    imports = Path(subprocess.check_output([qtpaths, "--query", "QT_INSTALL_QML"], text=True).strip())
    style = imports / "org/kde/desktop/TabButton.qml"
    if not style.is_file():
        return 0
    definition = style.read_text()
    if ("baselineOffset: contentItem.y + contentItem.baselineOffset" not in definition
            or "contentItem: null" not in definition):
        print("==> Native TabButton baseline needs no Debian adaptation")
        return 0
    files = {
        "contents/ui/config/ConfigGeneral.qml": 2,
        "contents/ui/config/ConfigAspect.qml": 5,
        "contents/ui/components/controlcenter/ControlCenterAudioPage.qml": 2,
    }
    pattern = re.compile(r"(?m)^([ \t]*)Controls\.TabButton \{[ \t]*$")
    changes = []
    for name, expected in files.items():
        path = source / name
        text = path.read_text()
        updated, count = pattern.subn(
            lambda match: match.group(0) + "\n" + match.group(1)
            + "    baselineOffset: 0", text)
        if count != expected:
            parser.error(f"Review the changed TabButton structure before adapting {name}")
        changes.append((path, updated))
    for path, updated in changes:
        path.write_text(updated)
    print("==> Applied the verified null-content baseline to 9 Debian TabButtons")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
