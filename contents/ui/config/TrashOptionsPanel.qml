// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

// Options of a trash element: its name, its two icons, its state and its sound.
//
// This is a passive visual component. It receives every value it shows through its
// properties—including the names of the sound files, which the caller resolves, so
// no formatting rule is repeated here—announces what the user asked for through its
// signals and writes nothing: it never touches the dock item list, the
// configuration values or the draft of the add dialog.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
ColumnLayout {
    id: root

    // Values the caller owns. The three text fields and the two switches keep the
    // same shape they had in the dialog, so every existing writer and reader keeps
    // working; the sound path is a value of its own, because the field next to it
    // shows a resolved name instead of the path.
    property alias nameText: trashName.text
    property alias emptyIconText: trashIconName.text
    property alias fullIconText: trashFullIconName.text
    property alias showStateChecked: trashShowState.checked
    property alias acceptDropsChecked: trashAcceptDrops.checked
    property string soundPath: ""
    // Names the controls show for the sound above and for the sound a new element
    // ships with. The caller resolves both, because the rule that turns a path into
    // a visible name is not this panel's.
    property string soundFileName: ""
    property string defaultSoundFileName: ""
    // False when the element being configured is not a trash element, which is when
    // the whole form is shown read-only.
    property bool editable: true
    // Layout variant: two columns by default, one when the panel lives in a narrow
    // column, so the existing dialog keeps the distribution it already had.
    property bool compactLayout: false

    // Intentions of the user, announced as they are.
    signal formChanged()
    signal emptyIconPickerRequested()
    signal fullIconPickerRequested()
    signal soundPreviewRequested()
    signal soundResetRequested()
    signal soundPickerRequested()

    spacing: Kirigami.Units.largeSpacing

    GridLayout {
        Layout.fillWidth: true
        columns: root.compactLayout ? 1 : 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.alignment: root.compactLayout
                ? Qt.AlignLeft : (Qt.AlignLeft | Qt.AlignVCenter)
            Layout.preferredWidth: root.compactLayout
                ? -1 : Kirigami.Units.gridUnit * 8
            text: i18n("Name:")
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        Controls.TextField {
            id: trashName

            objectName: "trashNameField"

            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            enabled: root.editable
            onEditingFinished: root.formChanged()
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.compactLayout ? 1 : 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing
        enabled: root.editable

        Controls.CheckBox {
            id: trashShowState

            objectName: "trashShowStateCheckBox"

            Layout.fillWidth: true
            text: i18n("Show trash state")
            onClicked: root.formChanged()
        }

        Controls.CheckBox {
            id: trashAcceptDrops

            objectName: "trashAcceptDropsCheckBox"

            Layout.fillWidth: true
            text: i18n("Drag files")
            onClicked: root.formChanged()
        }
    }

    GridLayout {
        Layout.fillWidth: true
        visible: trashShowState.checked
        enabled: root.editable
        columns: root.compactLayout ? 1 : 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.alignment: root.compactLayout
                ? Qt.AlignLeft : (Qt.AlignLeft | Qt.AlignVCenter)
            Layout.preferredWidth: root.compactLayout
                ? -1 : Kirigami.Units.gridUnit * 8
            text: i18n("Empty icon:")
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true

            Controls.Button {
                objectName: "trashEmptyIconButton"

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: trashIconName.text.length > 0
                    ? trashIconName.text : "user-trash"
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18n("Choose icon")
                onClicked: root.emptyIconPickerRequested()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Choose icon")
            }

            Controls.TextField {
                id: trashIconName

                objectName: "trashEmptyIconField"

                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 18
                placeholderText: "user-trash"
                onEditingFinished: root.formChanged()
            }
        }

        Controls.Label {
            Layout.alignment: root.compactLayout
                ? Qt.AlignLeft : (Qt.AlignLeft | Qt.AlignVCenter)
            Layout.preferredWidth: root.compactLayout
                ? -1 : Kirigami.Units.gridUnit * 8
            text: i18n("Full icon:")
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true

            Controls.Button {
                objectName: "trashFullIconButton"

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: trashFullIconName.text.length > 0
                    ? trashFullIconName.text : "user-trash-full"
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18n("Choose icon")
                onClicked: root.fullIconPickerRequested()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Choose icon")
            }

            Controls.TextField {
                id: trashFullIconName

                objectName: "trashFullIconField"

                Layout.fillWidth: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 18
                placeholderText: "user-trash-full"
                onEditingFinished: root.formChanged()
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        enabled: root.editable
        columns: root.compactLayout ? 1 : 5
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.alignment: root.compactLayout
                ? Qt.AlignLeft : (Qt.AlignLeft | Qt.AlignVCenter)
            Layout.preferredWidth: root.compactLayout
                ? -1 : Kirigami.Units.gridUnit * 8
            text: i18n("Empty sound:")
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        Controls.TextField {
            id: trashEmptySound

            objectName: "trashEmptySoundField"

            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 16
            readOnly: true
            text: root.soundFileName
            placeholderText: root.defaultSoundFileName
        }

        Controls.Button {
            objectName: "trashSoundPreviewButton"

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            icon.name: "media-playback-start-symbolic"
            display: Controls.AbstractButton.IconOnly
            Accessible.name: i18n("Test sound")
            onClicked: root.soundPreviewRequested()
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: i18n("Test sound")
        }

        Controls.Button {
            objectName: "trashSoundResetButton"

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            icon.name: "edit-reset-symbolic"
            display: Controls.AbstractButton.IconOnly
            Accessible.name: i18n("Default")
            onClicked: root.soundResetRequested()
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: i18n("Default")
        }

        Controls.Button {
            objectName: "trashSoundPickerButton"

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            icon.name: "document-open-symbolic"
            display: Controls.AbstractButton.IconOnly
            Accessible.name: i18n("Choose sound")
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
// qmllint enable unqualified
