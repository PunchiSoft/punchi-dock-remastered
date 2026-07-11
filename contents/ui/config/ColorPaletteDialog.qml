import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami


Item {
    id: root

    property string title: ""
    property string currentColor: ""
    property color fallbackColor: Kirigami.Theme.textColor
    property var colorChoices: []
    property string themeText: ""

    signal colorChosen(string color)
    signal themeChosen()

    function open() {
        if (themeText.length > 0) {
            choiceDialog.open()
            return
        }
        openNativeColorDialog()
    }

    function openNativeColorDialog() {
        plasmaColorDialog.selectedColor = parseColor(currentColor, fallbackColor)
        plasmaColorDialog.open()
    }

    function parseColor(value, fallback) {
        var text = String(value || "")
        if (text.length > 0) {
            return text
        }
        return fallback
    }

    function colorToHex(value) {
        return "#" + channelToHex(value.r * 255) + channelToHex(value.g * 255) + channelToHex(value.b * 255)
    }

    function channelToHex(value) {
        var text = Math.max(0, Math.min(255, Math.round(value))).toString(16)
        return text.length === 1 ? "0" + text : text
    }

    ColorDialog {
        id: plasmaColorDialog

        title: root.title
        selectedColor: root.parseColor(root.currentColor, root.fallbackColor)
        onAccepted: root.colorChosen(root.colorToHex(selectedColor))
    }

    Controls.Dialog {
        id: choiceDialog

        title: root.title
        modal: true
        standardButtons: Controls.Dialog.Close

        ColumnLayout {
            width: Math.max(Kirigami.Units.gridUnit * 18, choiceDialog.availableWidth)
            spacing: Kirigami.Units.smallSpacing

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Layout.fillWidth: true
                leftPadding: Kirigami.Units.smallSpacing
                rightPadding: Kirigami.Units.smallSpacing
                onClicked: {
                    choiceDialog.close()
                    root.themeChosen()
                }

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        source: "preferences-desktop-theme-global"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Controls.Label {
                            Layout.fillWidth: true
                            text: i18n("Use environment color")
                            elide: Text.ElideRight
                        }

                        Controls.Label {
                            Layout.fillWidth: true
                            text: i18n("Use the color provided by the Plasma theme")
                            elide: Text.ElideRight
                            opacity: 0.72
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }
                }
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Layout.fillWidth: true
                leftPadding: Kirigami.Units.smallSpacing
                rightPadding: Kirigami.Units.smallSpacing
                onClicked: {
                    choiceDialog.close()
                    root.openNativeColorDialog()
                }

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        source: "color-picker"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Controls.Label {
                            Layout.fillWidth: true
                            text: i18n("Select custom color")
                            elide: Text.ElideRight
                        }

                        Controls.Label {
                            Layout.fillWidth: true
                            text: i18n("Open the Plasma color selector")
                            elide: Text.ElideRight
                            opacity: 0.72
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }
                }
            }
        }
    }
}
