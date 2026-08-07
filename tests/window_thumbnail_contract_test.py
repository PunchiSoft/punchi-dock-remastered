#!/usr/bin/env python3

from pathlib import Path
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        raise AssertionError(message)


def main() -> int:
    thumbnail = (PROJECT_ROOT / "contents/ui/components/WindowLiveThumbnail.qml").read_text()
    card = (PROJECT_ROOT / "contents/ui/components/WindowPreviewCard.qml").read_text()
    popup = (PROJECT_ROOT / "contents/ui/components/TaskWindowsPopup.qml").read_text()

    require(thumbnail, "property bool minimized: false",
            "WindowLiveThumbnail must receive the minimized state explicitly")
    require(thumbnail, "root.isX11 && root.minimized",
            "The minimized fallback must be restricted to X11")
    require(thumbnail, "root.isX11 && !root.minimized && Number(root.winId) > 0",
            "X11 thumbnails must require a restored window and an explicit XID")
    if "Number(root.winId || root.windowUuid)" in thumbnail:
        raise AssertionError("Wayland UUIDs must not be used as X11 window identifiers")

    for source, consumer in ((card, "WindowPreviewCard"), (popup, "TaskWindowsPopup")):
        require(source, "minimized:", f"{consumer} must propagate minimized state")
        require(source, "KWindowSystem.isPlatformX11",
                f"{consumer} must restrict the minimized fallback to X11")
        require(source, "i18n(\"Window minimized\")",
                f"{consumer} must present the intentional minimized fallback")

    require(popup, "winId: windowRow.previewWinId",
            "TaskWindowsPopup must propagate the explicit X11 window identifier")

    print("Window thumbnail platform contracts are consistent")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"window thumbnail contract failed: {error}", file=sys.stderr)
        raise SystemExit(1)
