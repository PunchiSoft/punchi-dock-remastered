// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.config as KConfig
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
PunchiMenuSettingsBase {
    id: root

    required property bool sortApplicationsAlphabetically
    property bool normalShowCategories: true

    required property string normalPlacementMode
    required property int normalPanelGap
    required property int normalWidthPercent
    required property int normalHeightPercent

    readonly property bool anchoredMode:
        normalPlacementMode === "anchored"
    readonly property var placementOptions: [
        {
            "text": i18nc("@option:punchimenu-placement",
                "Attached to dock or panel"),
            "value": "anchored"
        },
        {
            "text": i18nc("@option:punchimenu-placement",
                "Centered on desktop"),
            "value": "centered"
        }
    ]

    function placementIndex() {
        return root.normalPlacementMode === "centered" ? 1 : 0
    }

    function focusInitialAction() {
        backgroundBlurSwitch.forceActiveFocus()
    }

    Controls.ScrollView {
        id: settingsScrollView

        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        Item {
            width: settingsScrollView.availableWidth
            implicitHeight: settingsColumn.implicitHeight
                + Kirigami.Units.largeSpacing * 2

            ColumnLayout {
                id: settingsColumn

                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.largeSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(1, Math.min(parent.width
                    - Kirigami.Units.largeSpacing * 2,
                    root.contentMaximumWidth))
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    text: i18nc("@title", "PunchiMenu Settings")
                    Accessible.role: Accessible.Heading
                    Accessible.name: text
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: i18nc("@info", "Changes are saved immediately.")
                    wrapMode: Text.WordWrap
                    color: Kirigami.Theme.disabledTextColor
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: root.errorMessage.length > 0
                    type: Kirigami.MessageType.Error
                    text: root.errorMessage
                    showCloseButton: false
                    Accessible.name: text
                }

                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    Kirigami.Heading {
                        Kirigami.FormData.isSection: true
                        level: 2
                        text: i18n("Background and legibility")
                    }

                    Controls.Switch {
                        id: backgroundBlurSwitch

                        Kirigami.FormData.label: i18n("Background blur:")
                        text: i18n("Use background blur when available")
                        checked: root.backgroundBlurEnabled
                        Accessible.name: text
                        Accessible.description: i18n("Requests the desktop blur effect for the selected PunchiMenu mode.")
                        onToggled: root.settingChanged(
                            "normalBlurEnabled", checked)
                    }

                    Kirigami.InlineMessage {
                        Kirigami.FormData.isSection: true
                        Layout.fillWidth: true
                        visible: true
                        type: Kirigami.MessageType.Information
                        text: root.backgroundBlurEnabled
                            ? i18n("The background will use KWin blur when available. The selected opacity controls how much content behind the menu remains visible.")
                            : i18n("Without blur, the background depends on the Plasma theme and the selected opacity.")
                        Accessible.name: text
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n("Background opacity:")

                        Controls.Slider {
                            id: backgroundOpacitySlider

                            Layout.fillWidth: true
                            from: 50
                            to: 100
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.backgroundOpacityPercent
                            Accessible.name: i18n("PunchiMenu background opacity")
                            Accessible.description: i18n("Changes only the menu background opacity; text and icons remain fully opaque.")
                            onMoved: root.settingChanged(
                                "normalBackgroundOpacityPercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "normalBackgroundOpacityPercent",
                                        Math.round(value / stepSize)
                                            * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth:
                                Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                backgroundOpacitySlider.value))
                        }
                    }

                    PlasmaComponents.Button {
                        Kirigami.FormData.isSection: true
                        Layout.alignment: Qt.AlignRight
                        visible: KConfig.KAuthorized.authorizeControlModule(
                            "kcm_kwin_effects")
                        icon.name: "configure"
                        text: i18nc("@action:button opens system settings",
                            "Configure Desktop Effects…")
                        Accessible.name: text
                        onClicked: KCM.KCMLauncher.openSystemSettings(
                            "kcm_kwin_effects")

                        HoverHandler {
                            enabled: parent.enabled
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Kirigami.Heading {
                        Kirigami.FormData.isSection: true
                        level: 2
                        text: i18nc("@option:punchimenu-mode",
                            "PunchiMenu Normal")
                    }

                    Controls.Switch {
                        Kirigami.FormData.label: i18n("Application labels:")
                        text: i18n("Show application names")
                        checked: root.showApplicationLabels
                        Accessible.name: text
                        Accessible.description: i18n("Shows application names below their icons in the application grid and Favorites.")
                        onToggled: root.settingChanged(
                            "showApplicationLabels", checked)
                    }

                    Controls.Switch {
                        Kirigami.FormData.label: i18n("Categories bar:")
                        text: i18n("Show category carousel")
                        checked: root.normalShowCategories
                        Accessible.name: text
                        Accessible.description: i18n("Shows the horizontal category carousel above applications in PunchiMenu Normal.")
                        onToggled: root.settingChanged(
                            "normalShowCategories", checked)
                    }

                    GridLayout {
                        id: hoverAnimationOptionsLayout

                        Kirigami.FormData.label: i18n("Hover animation:")
                        Kirigami.FormData.buddyFor:
                            hoverAnimationRepeater.count > 0
                                ? hoverAnimationRepeater.itemAt(0)
                                : hoverAnimationOptionsLayout
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: 0
                        Accessible.role: Accessible.Grouping
                        Accessible.name: i18n(
                            "PunchiMenu hover animation")
                        Accessible.description: i18n("Animates the complete application item, including its background, icon, and name.")

                        Controls.ButtonGroup {
                            id: hoverAnimationButtonGroup
                            exclusive: true
                        }

                        Repeater {
                            id: hoverAnimationRepeater

                            model: root.hoverAnimationOptions

                            delegate: Controls.RadioButton {
                                id: hoverAnimationOption

                                required property int index
                                required property var modelData

                                Layout.alignment: Qt.AlignLeft
                                text: String(modelData.text || "")
                                checked: index === root.hoverAnimationIndex()
                                Controls.ButtonGroup.group:
                                    hoverAnimationButtonGroup
                                Accessible.name: text
                                Accessible.description: i18n("Animates the complete application item, including its background, icon, and name.")
                                onClicked: root.settingChanged(
                                    "hoverAnimation", modelData.value)
                            }
                        }
                    }

                    Controls.Switch {
                        Kirigami.FormData.label: i18n("Application order:")
                        text: i18n("Sort applications alphabetically")
                        checked: root.sortApplicationsAlphabetically
                        Accessible.name: text
                        Accessible.description: i18n("Keeps drag and drop available, but prevents manual reordering while alphabetical sorting is enabled.")
                        onToggled: root.settingChanged(
                            "sortApplicationsAlphabetically", checked)
                    }

                    Kirigami.InlineMessage {
                        Kirigami.FormData.isSection: true
                        Layout.fillWidth: true
                        visible: root.sortApplicationsAlphabetically
                        type: Kirigami.MessageType.Information
                        text: i18n("Alphabetical sorting is active. Application positions cannot be changed manually, but drag and drop remains available.")
                        Accessible.name: text
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n(
                            "Application grid icon scale:")

                        Controls.Slider {
                            id: applicationIconScaleSlider

                            Layout.fillWidth: true
                            from: 75
                            to: 150
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.applicationIconScalePercent
                            Accessible.name: i18n(
                                "PunchiMenu application icon scale")
                            onMoved: root.settingChanged(
                                "gridIconScalePercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "gridIconScalePercent",
                                        Math.round(value / stepSize)
                                            * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth:
                                Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                applicationIconScaleSlider.value))
                        }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n(
                            "Favorites icon scale:")

                        Controls.Slider {
                            id: favoriteIconScaleSlider

                            Layout.fillWidth: true
                            from: 75
                            to: 110
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.favoriteIconScalePercent
                            Accessible.name: i18n(
                                "PunchiMenu Favorites icon scale")
                            Accessible.description: i18n("Changes the icon size in the reserved Favorites section in both menu modes.")
                            onMoved: root.settingChanged(
                                "favoriteIconScalePercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "favoriteIconScalePercent",
                                        Math.round(value / stepSize)
                                            * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth:
                                Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                favoriteIconScaleSlider.value))
                        }
                    }

                    Controls.SpinBox {
                        Kirigami.FormData.label: i18n(
                            "Maximum folder columns:")
                        from: 1
                        to: 3
                        value: root.folderMaximumColumns
                        Accessible.name: i18n(
                            "Maximum application columns inside folders")
                        onValueModified: root.settingChanged(
                            "normalFolderMaximumColumns", value)
                    }

                    Controls.SpinBox {
                        Kirigami.FormData.label: i18n(
                            "Maximum folder rows:")
                        from: 1
                        to: 3
                        value: root.folderMaximumRows
                        Accessible.name: i18n(
                            "Maximum application rows inside folders")
                        onValueModified: root.settingChanged(
                            "normalFolderMaximumRows", value)
                    }

                    Kirigami.Heading {
                        Kirigami.FormData.isSection: true
                        level: 2
                        text: i18n("Location and size")
                    }

                    GridLayout {
                        id: normalPlacementOptionsLayout

                        Kirigami.FormData.label: i18n(
                            "Normal menu placement:")
                        Kirigami.FormData.buddyFor:
                            normalPlacementRepeater.count > 0
                                ? normalPlacementRepeater.itemAt(0)
                                : normalPlacementOptionsLayout
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        columns: 1
                        rowSpacing: 0
                        Accessible.role: Accessible.Grouping
                        Accessible.name: i18n("Normal menu placement")
                        Accessible.description: i18n("Attached keeps the menu next to its dock or panel. Centered uses the available area of the active screen.")

                        Controls.ButtonGroup {
                            id: normalPlacementButtonGroup
                            exclusive: true
                        }

                        Repeater {
                            id: normalPlacementRepeater

                            model: root.placementOptions

                            delegate: Controls.RadioButton {
                                id: normalPlacementOption

                                required property int index
                                required property var modelData

                                Layout.alignment: Qt.AlignLeft
                                text: String(modelData.text || "")
                                checked: index === root.placementIndex()
                                Controls.ButtonGroup.group:
                                    normalPlacementButtonGroup
                                Accessible.name: text
                                Accessible.description: i18n("Attached keeps the menu next to its dock or panel. Centered uses the available area of the active screen.")
                                onClicked: root.settingChanged(
                                    "normalPlacementMode", modelData.value)
                            }
                        }
                    }

                    RowLayout {
                        visible: root.anchoredMode
                        Kirigami.FormData.label: i18n("Panel distance:")

                        Controls.Slider {
                            id: normalPanelGapSlider

                            Layout.fillWidth: true
                            from: 0
                            to: 32
                            stepSize: 1
                            snapMode: Controls.Slider.SnapAlways
                            value: root.normalPanelGap
                            Accessible.name: i18n(
                                "PunchiMenu panel distance")
                            Accessible.description: i18n("Adds space between PunchiMenu Normal and the panel edge.")
                            onMoved: root.settingChanged(
                                "normalPanelGap", Math.round(value))
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "normalPanelGap", Math.round(value))
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth:
                                Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1 px", Math.round(
                                normalPanelGapSlider.value))
                        }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n("Normal menu width:")

                        Controls.Slider {
                            id: normalWidthSlider

                            Layout.fillWidth: true
                            from: 30
                            to: 90
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.normalWidthPercent
                            Accessible.name: i18n("Normal menu width")
                            onMoved: root.settingChanged(
                                "normalWidthPercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "normalWidthPercent",
                                        Math.round(value / stepSize)
                                            * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth:
                                Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                normalWidthSlider.value))
                        }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n("Normal menu height:")

                        Controls.Slider {
                            id: normalHeightSlider

                            Layout.fillWidth: true
                            from: 30
                            to: 90
                            stepSize: 5
                            snapMode: Controls.Slider.SnapAlways
                            value: root.normalHeightPercent
                            Accessible.name: i18n("Normal menu height")
                            onMoved: root.settingChanged(
                                "normalHeightPercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "normalHeightPercent",
                                        Math.round(value / stepSize)
                                            * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth:
                                Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                normalHeightSlider.value))
                        }
                    }
                }

                PlasmaComponents.Button {
                    Layout.alignment: Qt.AlignRight
                    icon.name: "configure"
                    text: i18nc("@action:button",
                        "Open mode and icon settings…")
                    Accessible.name: text
                    onClicked: root.advancedConfigurationRequested()
                }
            }
        }
    }
}
// qmllint enable unqualified
