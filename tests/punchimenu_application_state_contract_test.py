#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
PUNCHIMENU = ROOT / "contents/ui/components/punchimenu"


def require_markers(source: str, markers: tuple[str, ...], label: str) -> bool:
    passed = True
    for marker in markers:
        if marker not in source:
            print(f"{label}: missing shared application-state contract: {marker}", file=sys.stderr)
            passed = False
    return passed


def main() -> int:
    controller_source = (PUNCHIMENU / "PunchiMenuApplicationState.qml").read_text(
        encoding="utf-8"
    )
    mode_sources = {
        name: (PUNCHIMENU / name).read_text(encoding="utf-8")
        for name in (
            "PunchiMenuNormal.qml",
            "PunchiMenuOverlay.qml",
            "PunchiMenuCompact.qml",
        )
    }

    passed = require_markers(
        controller_source,
        (
            "readonly property var hiddenApplicationLookup:",
            "readonly property int hiddenIdCount:",
            "readonly property int hiddenCatalogApplicationCount:",
            "function normalizedStorageId(value)",
            "function isFavorite(storageId)",
            "function isApplicationHidden(storageId)",
        ),
        "PunchiMenuApplicationState.qml",
    )

    for name, source in mode_sources.items():
        passed = require_markers(
            source,
            (
                "PunchiMenuApplicationState {",
                "favorites: root.favorites",
                "return applicationState.isFavorite(storageId)",
            ),
            name,
        ) and passed
        if source.count("PunchiMenuApplicationState {") != 1:
            print(f"{name}: application-state controller must be instantiated once", file=sys.stderr)
            passed = False

    for name in ("PunchiMenuNormal.qml", "PunchiMenuOverlay.qml"):
        source = mode_sources[name]
        passed = require_markers(
            source,
            (
                "hiddenApplicationIds: root.hiddenApplicationIds",
                "applicationCatalog: root.applicationCatalog",
                "return applicationState.isApplicationHidden(storageId)",
            ),
            name,
        ) and passed

    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
