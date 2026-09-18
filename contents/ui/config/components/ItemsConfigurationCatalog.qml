// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// Elements the items configuration surface can add. Wording and icons reuse the
// ones already published by the existing Items page so both editors stay
// consistent and no duplicated translation is introduced.
//
// Open applications stays out until its legacy showActiveTasks transaction
// migrates; adding it here would desynchronize that preference.
QtObject {
    id: root

    // Translation helpers are supplied by the plasmoid configuration context.
    // qmllint disable unqualified
    readonly property var entries: [
        {
            "type": "app",
            "title": i18nc("@action:button", "Application"),
            "icon": "application-x-executable",
            "description": i18nc("@info:accessibility",
                "Add an application launcher to the dock")
        },
        {
            "type": "folder",
            "title": i18nc("@action:button", "Folder"),
            "icon": "folder",
            "description": i18nc("@info:accessibility",
                "Add an application folder to the dock")
        },
        {
            "type": "punchimenu",
            "title": i18n("PunchiMenu"),
            "icon": "start-here-kde",
            "description": i18n("Open application menu & carousel"),
            "singleton": true
        },
        {
            "type": "control-center",
            "title": i18n("Control Center"),
            "icon": "preferences-system",
            "description": i18n("Open system controls and notifications"),
            "singleton": true
        },
        {
            "type": "media",
            "title": i18n("Media player"),
            "icon": "emblem-music-symbolic",
            "description": i18n("Automatically select the active player"),
            "singleton": true
        },
        {
            "type": "calendar",
            "title": i18n("Calendar/Clock"),
            "icon": "x-office-calendar",
            "description": i18n("Show date information")
        },
        {
            "type": "note",
            "title": i18n("Note"),
            "icon": "knotes",
            "description": i18n("Write a quick editable note")
        },
        {
            "type": "separator",
            "title": i18nc("@action:button", "Separator"),
            "icon": "draw-line",
            "description": i18nc("@info:accessibility",
                "Add a visual separator to the dock")
        },
        {
            "type": "spacer",
            "title": i18n("Spacer"),
            "icon": "distribute-horizontal-x",
            "description": i18n("Add empty space between items")
        },
        {
            "type": "trash",
            "title": i18nc("@action:button", "Trash"),
            "icon": "user-trash",
            "description": i18nc("@info:accessibility",
                "Add a trash item to the dock")
        }
    ]
    // qmllint enable unqualified
}
