#!/usr/bin/env python3
"""Protect the single replacement spectrum used by Plasma and JSON panels."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
MAIN_QML = ROOT / "contents/ui/main.qml"
PANEL_SURFACE_QML = ROOT / "contents/ui/components/PanelFlatThemeBackground.qml"


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        raise AssertionError(message)


def main() -> int:
    main_qml = MAIN_QML.read_text(encoding="utf-8")
    panel_surface = PANEL_SURFACE_QML.read_text(encoding="utf-8")

    require(
        main_qml,
        "spectrumActive: !root.inPanel && audioSpectrumController.active",
        "DockBackground must not render its internal spectrum in panel mode",
    )
    require(
        main_qml,
        "readonly property bool audioSpectrumReplacesPanelBackground: root.inPanel",
        "Spectrum-only mode must expose a theme-independent panel replacement state",
    )
    require(
        main_qml,
        "onAudioSpectrumReplacesPanelBackgroundChanged: applyConfiguredPanelOpacityMode()",
        "Panel background hints must refresh when spectrum replacement changes",
    )
    require(
        main_qml,
        "|| root.audioSpectrumReplacesPanelBackground",
        "Spectrum replacement must force the native panel background off",
    )
    require(
        main_qml,
        "&& (root.audioSpectrumReplacesPanelBackground",
        "The adjusted panel surface must not require an active JSON theme",
    )
    require(
        main_qml,
        "visible: root.inPanel && !panelFlatBackground.spectrumHosted",
        "The local panel viewport must remain only as the hosted surface fallback",
    )
    require(
        panel_surface,
        "readonly property bool spectrumHosted: aligned && spectrumVisible",
        "The panel surface must expose whether the replacement spectrum is hosted",
    )
    require(
        panel_surface,
        'objectName: "panelAudioSpectrumRenderer"',
        "The adjusted surface must own the panel audio spectrum renderer",
    )

    if main_qml.count("spectrumActive: !root.inPanel && audioSpectrumController.active") != 1:
        raise AssertionError("The floating DockBackground spectrum route must be unique")

    print("Audio spectrum panel contract passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
