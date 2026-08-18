// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
PunchiMenuSettingsBase {
    id: root

    required property bool sortApplicationsAlphabetically
    property bool compactShowQuickLaunchers: true
    property int normalPanelGap: 0

    signal returnToMenuRequested()

    Controls.ScrollView {
        id: settingsScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        Item {
            width: settingsScrollView.availableWidth
            implicitHeight: settingsColumn.implicitHeight + Kirigami.Units.largeSpacing * 2

            ColumnLayout {
                id: settingsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                // Header with Back Button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Controls.Button {
                        icon.name: "go-previous"
                        text: i18nc("@action:button", "Back")
                        onClicked: root.returnToMenuRequested()
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        text: i18nc("@title:window", "Compact Menu Settings")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                        elide: Text.ElideRight
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                // Visual Appearance Section
                Controls.Label {
                    text: i18nc("@title:group", "Appearance & Background")
                    font.bold: true
                }

                Controls.Switch {
                    id: backgroundBlurSwitch
                    Layout.fillWidth: true
                    text: i18nc("@option:check", "Enable background blur (BlurBehind)")
                    checked: root.backgroundBlurEnabled
                    onToggled: root.settingChanged("compactBlurEnabled", checked)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    Controls.Label {
                        text: i18nc("@label:slider", "Background opacity:")
                    }

                    Controls.Slider {
                        id: opacitySlider
                        Layout.fillWidth: true
                        from: 50
                        to: 100
                        stepSize: 5
                        value: root.backgroundOpacityPercent
                        onMoved: root.settingChanged("compactBackgroundOpacityPercent", Math.round(value))
                    }

                    Controls.Label {
                        text: Math.round(opacitySlider.value) + "%"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        horizontalAlignment: Text.AlignRight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    Controls.Label {
                        text: i18n("Panel distance:")
                    }

                    Controls.Slider {
                        id: panelGapSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 32
                        stepSize: 1
                        value: root.normalPanelGap
                        onMoved: root.settingChanged("normalPanelGap", Math.round(value))
                    }

                    Controls.Label {
                        text: Math.round(panelGapSlider.value) + " px"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                // Layout & Launchers Section
                Controls.Label {
                    text: i18nc("@title:group", "Menu Options")
                    font.bold: true
                }

                Controls.Switch {
                    id: quickLaunchersSwitch
                    Layout.fillWidth: true
                    text: i18nc("@option:check", "Show favorites row")
                    checked: root.compactShowQuickLaunchers
                    onToggled: root.settingChanged("compactShowQuickLaunchers", checked)
                }

                Controls.Switch {
                    id: alphabeticalSortSwitch
                    Layout.fillWidth: true
                    text: i18nc("@option:check", "Sort applications alphabetically")
                    checked: root.sortApplicationsAlphabetically
                    onToggled: root.settingChanged("sortApplicationsAlphabetically", checked)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    Controls.Label {
                        text: i18nc("@label:listbox", "Hover animation:")
                    }

                    Controls.ComboBox {
                        Layout.fillWidth: true
                        model: root.hoverAnimationOptions
                        textRole: "text"
                        currentIndex: root.hoverAnimationIndex()
                        onActivated: function(index) {
                            const option = root.hoverAnimationOptions[index]
                            if (option) {
                                root.settingChanged("hoverAnimation", option.value)
                            }
                        }
                    }
                }
            }
        }
    }
}
