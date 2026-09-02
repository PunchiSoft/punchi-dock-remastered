// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.private.brightnesscontrolplugin as Brightness

QtObject {
    id: root

    property string displayName: ""
    property int brightness: 0
    property int maximumBrightness: 0
    readonly property bool available: screenControl.isBrightnessAvailable
        && displayName.length > 0 && maximumBrightness > 0
    readonly property int value: available
        ? Math.max(0, Math.min(100,
            Math.round(brightness / maximumBrightness * 100.0)))
        : 0

    readonly property Brightness.ScreenBrightnessControl screenControl:
        Brightness.ScreenBrightnessControl {
            isSilent: true
        }

    readonly property Connections displayConnections: Connections {
        target: root.screenControl.displays

        function onDataChanged() {
            root.refreshDisplay()
        }

        function onModelReset() {
            root.refreshDisplay()
        }

        function onRowsInserted() {
            root.refreshDisplay()
        }

        function onRowsMoved() {
            root.refreshDisplay()
        }

        function onRowsRemoved() {
            root.refreshDisplay()
        }
    }

    function refreshDisplay() {
        const displays = screenControl.displays
        if (!displays || displays.rowCount() < 1) {
            displayName = ""
            brightness = 0
            maximumBrightness = 0
            return
        }

        const modelIndex = displays.index(0, 0)
        const displayNameRole =
            displays.KItemModels.KRoleNames.role("displayName")
        const brightnessRole =
            displays.KItemModels.KRoleNames.role("brightness")
        const maximumRole =
            displays.KItemModels.KRoleNames.role("maxBrightness")
        displayName = String(displays.data(modelIndex, displayNameRole) || "")
        brightness = Number(displays.data(modelIndex, brightnessRole)) || 0
        maximumBrightness = Number(displays.data(modelIndex, maximumRole)) || 0
    }

    function setValue(percentage) {
        if (!available) {
            return false
        }
        const boundedValue = Math.max(0, Math.min(100,
            Math.round(Number(percentage))))
        screenControl.setBrightness(displayName,
            Math.round(maximumBrightness * boundedValue / 100.0))
        return true
    }

    Component.onCompleted: refreshDisplay()
}
