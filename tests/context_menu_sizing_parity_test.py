#!/usr/bin/env python3
"""Static contract for context-menu sizing parity with the trash menu.

The trash menu is part of the same context-menu family as AppActionsPopup.
It must consume the automatic mode and the theme/anchor width floor instead of
keeping a fixed 300 px surface.
"""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
MAIN_QML = PROJECT_ROOT / "contents/ui/main.qml"
TRASH_CONTEXT = (
    PROJECT_ROOT / "contents/ui/components/TrashContextPopup.qml"
)
TRASH_MENU = PROJECT_ROOT / "contents/ui/components/TrashMenuPopup.qml"
APP_ACTIONS = PROJECT_ROOT / "contents/ui/components/AppActionsPopup.qml"


def require(condition: bool, message: str) -> None:
    """Raise a focused contract failure when condition is false."""

    if not condition:
        raise AssertionError(message)


def trash_dialog_body(source: str) -> str:
    """Return the trash dialog block without reaching the app actions menu."""

    start = source.index("id: trashMenuDialog")
    end = source.index("id: appActionsDialog", start)
    return source[start:end]


def main() -> int:
    main_qml = MAIN_QML.read_text()
    trash_context = TRASH_CONTEXT.read_text()
    trash_menu = TRASH_MENU.read_text()
    app_actions = APP_ACTIONS.read_text()
    trash_dialog = trash_dialog_body(main_qml)

    for fragment, message in (
        ("menuWidth: dockConfig.contextMenuWidth",
         "The trash menu must keep consuming the configured target width"),
        ("autoSize: dockConfig.contextMenuAutoSize",
         "The trash menu must consume the automatic sizing mode"),
        ("minimumAnchorWidth: trashMenuDialog.sourceAnchor",
         "The trash menu must keep the same anchor floor as the app menu"),
    ):
        require(fragment in trash_dialog, message)

    for fragment, message in (
        ("property bool autoSize: false",
         "TrashContextPopup must expose the automatic sizing input"),
        ("property real minimumAnchorWidth: 0",
         "TrashContextPopup must accept the anchor width floor"),
        ("readonly property int automaticIconSize: "
         "Kirigami.Units.iconSizes.small",
         "Automatic mode must use the same icon size as the app menu"),
        ("readonly property int minimumMenuWidth:",
         "TrashContextPopup must derive a theme and anchor width floor"),
        ("readonly property real automaticWidth:",
         "TrashContextPopup must derive the automatic width from its content"),
        ("readonly property real targetSurfaceWidth: autoSize",
         "Automatic mode must replace the manual target width"),
        ("menuPage.naturalWidth", "The automatic width must measure the rows"),
    ):
        require(fragment in trash_context, message)

    require(
        "Math.max(300" not in trash_context,
        "The trash menu must not keep the fixed 300 px floor",
    )
    for fragment in (
        "Math.max(Kirigami.Units.gridUnit * 18",
        "Math.ceil(Kirigami.Units.gridUnit * 1.8)",
    ):
        require(
            fragment in trash_context and fragment in app_actions,
            "Automatic row and width floors must match AppActionsPopup",
        )

    for fragment, message in (
        ("readonly property real naturalWidth:",
         "TrashMenuPopup must expose the natural width of its rows"),
        ("implicitWidth: naturalWidth",
         "The trash rows must size from their measured content"),
        ("id: openLabelMetrics", "The open action must be measured"),
        ("id: emptyLabelMetrics", "The empty action must be measured"),
        ("text: openOption.text", "The open label text must feed the metrics"),
        ("text: emptyOption.text", "The empty label text must feed the metrics"),
    ):
        require(fragment in trash_menu, message)

    print("context_menu_sizing_parity_test: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
