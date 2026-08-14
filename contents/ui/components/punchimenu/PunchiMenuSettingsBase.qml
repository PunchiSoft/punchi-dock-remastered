// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    required property bool backgroundBlurEnabled
    required property int backgroundOpacityPercent
    required property bool showApplicationLabels
    required property string hoverAnimation
    required property bool sortApplicationsAlphabetically
    required property int applicationIconScalePercent
    required property int favoriteIconScalePercent
    required property int folderMaximumColumns
    required property int folderMaximumRows
    property string errorMessage: ""

    signal settingChanged(string fieldName, var value)
    signal advancedConfigurationRequested()

    readonly property int contentMaximumWidth: Kirigami.Units.gridUnit * 40
    readonly property var hoverAnimationOptions: [
        { "text": i18n("None"), "value": "none" },
        { "text": i18n("Individual"), "value": "individual" },
        { "text": i18n("Pulse"), "value": "pulse" },
        { "text": i18n("Bounce"), "value": "bounce" }
    ]

    function hoverAnimationIndex() {
        for (let index = 0; index < hoverAnimationOptions.length; ++index) {
            if (hoverAnimationOptions[index].value === root.hoverAnimation) {
                return index
            }
        }
        return 2
    }
}
// qmllint enable unqualified
