import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.config as KConfig
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    required property bool backgroundBlurEnabled
    required property int backgroundOpacityPercent
    required property bool showDistributionName
    required property bool showPageNavigationArrows
    required property bool sortApplicationsAlphabetically
    required property string closeButtonPosition
    required property int applicationIconScalePercent
    required property int folderMaximumColumns
    required property int folderMaximumRows
    property string errorMessage: ""

    signal settingChanged(string fieldName, var value)
    signal advancedConfigurationRequested()

    readonly property int contentMaximumWidth: Kirigami.Units.gridUnit * 40
    readonly property var closeButtonPositionOptions: [
        {
            "text": i18nc("@option:close-button-position", "Right"),
            "value": "right"
        },
        {
            "text": i18nc("@option:close-button-position", "Left"),
            "value": "left"
        }
    ]

    function closeButtonPositionIndex() {
        return root.closeButtonPosition === "left" ? 1 : 0
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
                            "fullScreenBlurEnabled", checked)
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
                                "fullScreenBackgroundOpacityPercent",
                                Math.round(value / stepSize) * stepSize)
                            onValueChanged: {
                                if (activeFocus && !pressed) {
                                    root.settingChanged(
                                        "fullScreenBackgroundOpacityPercent",
                                        Math.round(value / stepSize) * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
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
                            "PunchiMenu Full screen")
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

                    Controls.Switch {
                        Kirigami.FormData.label: i18n("Distribution label:")
                        text: i18n("Show distribution name in full screen")
                        checked: root.showDistributionName
                        Accessible.name: text
                        onToggled: root.settingChanged(
                            "showDistributionName", checked)
                    }

                    Controls.Switch {
                        Kirigami.FormData.label: i18n("Page navigation:")
                        text: i18n("Show page navigation arrows")
                        checked: root.showPageNavigationArrows
                        Accessible.name: text
                        onToggled: root.settingChanged(
                            "showPageNavigationArrows", checked)
                    }

                    Controls.ComboBox {
                        Kirigami.FormData.label: i18n("Close button:")
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                        model: root.closeButtonPositionOptions
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: root.closeButtonPositionIndex()
                        Accessible.name: i18n("Close button position")
                        onActivated: function(index) {
                            const option = root.closeButtonPositionOptions[index]
                            if (option) {
                                root.settingChanged(
                                    "fullScreenCloseButtonPosition", option.value)
                            }
                        }
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
                                    root.settingChanged("gridIconScalePercent",
                                        Math.round(value / stepSize) * stepSize)
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            horizontalAlignment: Text.AlignRight
                            text: i18n("%1%", Math.round(
                                applicationIconScaleSlider.value))
                        }
                    }

                    Controls.SpinBox {
                        Kirigami.FormData.label: i18n(
                            "Maximum folder columns:")
                        from: 1
                        to: 5
                        value: root.folderMaximumColumns
                        Accessible.name: i18n(
                            "Maximum application columns inside folders")
                        onValueModified: root.settingChanged(
                            "fullScreenFolderMaximumColumns", value)
                    }

                    Controls.SpinBox {
                        Kirigami.FormData.label: i18n(
                            "Maximum folder rows:")
                        from: 1
                        to: 5
                        value: root.folderMaximumRows
                        Accessible.name: i18n(
                            "Maximum application rows inside folders")
                        onValueModified: root.settingChanged(
                            "fullScreenFolderMaximumRows", value)
                    }
                }

                PlasmaComponents.Button {
                    id: advancedConfigurationButton
                    Layout.alignment: Qt.AlignRight
                    icon.name: "configure"
                    text: i18nc("@action:button", "Open Advanced Settings…")
                    Accessible.name: text
                    onClicked: root.advancedConfigurationRequested()
                }
            }
        }
    }
}
// qmllint enable unqualified
