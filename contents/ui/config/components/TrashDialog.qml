import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import ".."


Controls.Dialog {
    id: root

    property var controller
    property alias nameText: trashName.text
    property alias emptyIconText: trashIconName.text
    property alias fullIconText: trashFullIconName.text
    property alias showStateChecked: trashShowState.checked
    property alias acceptDropsChecked: trashAcceptDrops.checked
    property alias soundPath: trashEmptySound.soundPath

    signal formChanged()
    signal emptyIconPickerRequested()
    signal fullIconPickerRequested()
    signal soundPreviewRequested()
    signal soundResetRequested()
    signal soundPickerRequested()

    modal: true
    title: i18n("Configure trash")
    standardButtons: Controls.Dialog.Close

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                text: i18n("Name:")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            Controls.TextField {
                id: trashName
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 18
                enabled: root.controller.selectedItemType === "trash"
                onEditingFinished: root.formChanged()
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: root.controller.selectedItemType === "trash"

            Controls.CheckBox {
                id: trashShowState
                Layout.fillWidth: true
                text: i18n("Show trash state")
                onClicked: root.formChanged()
            }

            Controls.CheckBox {
                id: trashAcceptDrops
                Layout.fillWidth: true
                text: i18n("Drag files")
                onClicked: root.formChanged()
            }
        }

        GridLayout {
            Layout.fillWidth: true
            visible: trashShowState.checked
            enabled: root.controller.selectedItemType === "trash"
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                text: i18n("Empty icon:")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true

                Controls.Button {
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    icon.name: trashIconName.text.length > 0 ? trashIconName.text : "user-trash"
                    display: Controls.AbstractButton.IconOnly
                    onClicked: root.emptyIconPickerRequested()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: i18n("Choose icon")
                }

                Controls.TextField {
                    id: trashIconName
                    Layout.fillWidth: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
                    placeholderText: "user-trash"
                    onEditingFinished: root.formChanged()
                }
            }

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                text: i18n("Full icon:")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true

                Controls.Button {
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    icon.name: trashFullIconName.text.length > 0 ? trashFullIconName.text : "user-trash-full"
                    display: Controls.AbstractButton.IconOnly
                    onClicked: root.fullIconPickerRequested()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: i18n("Choose icon")
                }

                Controls.TextField {
                    id: trashFullIconName
                    Layout.fillWidth: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
                    placeholderText: "user-trash-full"
                    onEditingFinished: root.formChanged()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: root.controller.selectedItemType === "trash"
            spacing: Kirigami.Units.smallSpacing

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                text: i18n("Empty sound:")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            Controls.TextField {
                id: trashEmptySound
                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 16
                readOnly: true
                text: root.controller.fileName(soundPath)
                placeholderText: root.controller.fileName(root.controller.defaultTrashEmptySound)

                property string soundPath: root.controller.defaultTrashEmptySound

                onSoundPathChanged: {
                    if (soundPath.length === 0) {
                        soundPath = root.controller.defaultTrashEmptySound
                    }
                }
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "media-playback-start-symbolic"
                display: Controls.AbstractButton.IconOnly
                onClicked: root.soundPreviewRequested()
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Test sound")
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-reset-symbolic"
                display: Controls.AbstractButton.IconOnly
                onClicked: root.soundResetRequested()
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Default")
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "document-open-symbolic"
                display: Controls.AbstractButton.IconOnly
                onClicked: root.soundPickerRequested()
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Choose sound")
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        }
    }
}
