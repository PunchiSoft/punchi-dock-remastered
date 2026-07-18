import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras

Item {
    id: noteRoot

    property var noteItem: ({})
    property string initialText: ""
    property alias currentText: editor.text
    property string transientStatus: ""
    property bool enforcingLength: false
    property bool maximumLengthWarning: false
    property bool deleteConfirmationVisible: false
    readonly property int activeWidth: Math.max(220, noteItem && noteItem.popupWidth ? noteItem.popupWidth : 360)
    readonly property int activeHeight: Math.max(160, noteItem && noteItem.popupHeight ? noteItem.popupHeight : 260)
    readonly property int maximumNoteLength: 6000
    readonly property int effectiveMaximumLength: Math.max(maximumNoteLength, initialText.length)
    readonly property bool hasPendingChanges: editor.text !== initialText
    readonly property bool showingSavedStatus: transientStatus.length === 0 && !hasPendingChanges

    implicitWidth: activeWidth
    implicitHeight: activeHeight
    width: implicitWidth
    height: implicitHeight

    signal noteChanged(string noteText, int popupWidth, int popupHeight)
    signal clearRequested(string noteText, int popupWidth, int popupHeight)
    signal deleteRequested()
    signal closeRequested()

    function syncFromItem() {
        var nextText = noteItem && noteItem.note ? noteItem.note : ""
        initialText = nextText
        editor.text = nextText
        transientStatus = ""
        maximumLengthWarning = false
        deleteConfirmationVisible = false
    }

    function focusEditor() {
        editor.forceActiveFocus()
    }

    function copyNote() {
        var selectionStart = editor.selectionStart
        var selectionEnd = editor.selectionEnd
        var cursorPosition = editor.cursorPosition

        editor.selectAll()
        editor.copy()

        if (selectionStart !== selectionEnd) {
            editor.select(selectionStart, selectionEnd)
        } else {
            editor.deselect()
            editor.cursorPosition = cursorPosition
        }

        transientStatus = i18n("Copied")
        maximumLengthWarning = false
        statusResetTimer.restart()
    }

    function enforceMaximumLength() {
        if (enforcingLength || editor.text.length <= effectiveMaximumLength) {
            return
        }

        var previousCursor = editor.cursorPosition
        enforcingLength = true
        editor.text = editor.text.slice(0, effectiveMaximumLength)
        editor.cursorPosition = Math.min(previousCursor, editor.text.length)
        enforcingLength = false
        transientStatus = i18n("Maximum length reached")
        maximumLengthWarning = true
        statusResetTimer.restart()
    }

    onNoteItemChanged: syncFromItem()
    Component.onCompleted: syncFromItem()

    Timer {
        id: statusResetTimer
        interval: 2500
        onTriggered: {
            noteRoot.transientStatus = ""
            noteRoot.maximumLengthWarning = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "view-pim-notes"
                color: Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }

            PlasmaExtras.ShadowedLabel {
                text: noteRoot.noteItem && noteRoot.noteItem.name ? noteRoot.noteItem.name : i18n("Note")
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Controls.ToolButton {
                id: clearNoteButton
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                padding: 2
                focusPolicy: Qt.StrongFocus
                Accessible.name: i18n("Clear")
                Controls.ToolTip.visible: hovered || activeFocus
                Controls.ToolTip.text: Accessible.name
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                contentItem: Kirigami.Icon {
                    source: "edit-clear"
                    color: Kirigami.Theme.textColor
                    implicitWidth: 16
                    implicitHeight: 16
                }
                background: Rectangle {
                    radius: 6
                    color: clearNoteButton.hovered || clearNoteButton.activeFocus
                        ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                            Kirigami.Theme.highlightColor.g,
                            Kirigami.Theme.highlightColor.b, 0.24)
                        : "transparent"
                    border.width: clearNoteButton.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.textColor
                }
                onClicked: {
                    editor.text = ""
                    noteRoot.initialText = editor.text
                    noteRoot.transientStatus = i18n("Cleared")
                    noteRoot.maximumLengthWarning = false
                    statusResetTimer.restart()
                    noteRoot.clearRequested("", noteRoot.activeWidth, noteRoot.activeHeight)
                }
            }

            Controls.ToolButton {
                id: copyNoteButton
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                padding: 2
                focusPolicy: Qt.StrongFocus
                enabled: editor.text.length > 0
                Accessible.name: i18n("Copy note")
                Controls.ToolTip.visible: hovered || activeFocus
                Controls.ToolTip.text: Accessible.name
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                contentItem: Kirigami.Icon {
                    source: "edit-copy"
                    color: Kirigami.Theme.textColor
                    implicitWidth: 16
                    implicitHeight: 16
                }
                background: Rectangle {
                    radius: 6
                    color: copyNoteButton.hovered || copyNoteButton.activeFocus
                        ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                            Kirigami.Theme.highlightColor.g,
                            Kirigami.Theme.highlightColor.b, 0.24)
                        : "transparent"
                    border.width: copyNoteButton.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.textColor
                }
                onClicked: noteRoot.copyNote()
            }

            Controls.ToolButton {
                id: deleteNoteButton
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                padding: 2
                focusPolicy: Qt.StrongFocus
                Accessible.name: i18nc("@action:button", "Delete Note")
                Controls.ToolTip.visible: hovered || activeFocus
                Controls.ToolTip.text: Accessible.name
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                contentItem: Kirigami.Icon {
                    source: "edit-delete"
                    color: Kirigami.Theme.textColor
                    implicitWidth: 16
                    implicitHeight: 16
                }
                background: Rectangle {
                    radius: 6
                    color: deleteNoteButton.hovered || deleteNoteButton.activeFocus
                        ? Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                            Kirigami.Theme.negativeTextColor.g,
                            Kirigami.Theme.negativeTextColor.b, 0.24)
                        : "transparent"
                    border.width: deleteNoteButton.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.textColor
                }
                onClicked: noteRoot.deleteConfirmationVisible = true
            }

            Controls.ToolButton {
                id: closeNoteButton
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                padding: 2
                focusPolicy: Qt.StrongFocus
                Accessible.name: i18n("Close")
                Controls.ToolTip.visible: hovered || activeFocus
                Controls.ToolTip.text: Accessible.name
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                contentItem: Kirigami.Icon {
                    source: "window-close"
                    color: Kirigami.Theme.textColor
                    implicitWidth: 16
                    implicitHeight: 16
                }
                background: Rectangle {
                    radius: 6
                    color: closeNoteButton.hovered || closeNoteButton.activeFocus
                        ? Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                            Kirigami.Theme.negativeTextColor.g,
                            Kirigami.Theme.negativeTextColor.b, 0.24)
                        : "transparent"
                    border.width: closeNoteButton.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.textColor
                }
                onClicked: noteRoot.closeRequested()
                Keys.onReturnPressed: noteRoot.closeRequested()
                Keys.onSpacePressed: noteRoot.closeRequested()
            }
        }

        Kirigami.InlineMessage {
            visible: noteRoot.deleteConfirmationVisible
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: i18n("Delete this note from the dock? Its contents cannot be recovered.")
            actions: [
                Kirigami.Action {
                    text: i18nc("@action:button", "Cancel")
                    icon.name: "dialog-cancel"
                    onTriggered: {
                        noteRoot.deleteConfirmationVisible = false
                        editor.forceActiveFocus()
                    }
                },
                Kirigami.Action {
                    text: i18nc("@action:button", "Delete Note")
                    icon.name: "edit-delete"
                    onTriggered: noteRoot.deleteRequested()
                }
            ]
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
            Controls.ScrollBar.vertical.policy: Controls.ScrollBar.AsNeeded

            Controls.TextArea {
                id: editor
                Layout.fillWidth: true
                Layout.fillHeight: true
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.Wrap
                placeholderText: i18n("Write a quick note")
                color: Kirigami.Theme.textColor
                selectByMouse: true
                activeFocusOnTab: true
                Accessible.name: i18n("Note content")

                onTextChanged: noteRoot.enforceMaximumLength()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                visible: noteRoot.showingSavedStatus
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                Layout.alignment: Qt.AlignVCenter
                radius: width / 2
                color: Kirigami.Theme.positiveTextColor
            }

            Controls.Label {
                Layout.fillWidth: true
                text: noteRoot.transientStatus.length > 0
                    ? noteRoot.transientStatus
                    : (noteRoot.hasPendingChanges ? i18n("Changes pending") : i18n("Saved"))
                color: noteRoot.maximumLengthWarning
                    ? Kirigami.Theme.negativeTextColor
                    : Kirigami.Theme.disabledTextColor
                font.family: Kirigami.Theme.smallFont.family
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
                Accessible.name: text
            }

            Controls.Label {
                text: i18n("%1 / %2", editor.text.length, noteRoot.maximumNoteLength)
                color: editor.text.length >= noteRoot.maximumNoteLength
                    ? Kirigami.Theme.neutralTextColor
                    : Kirigami.Theme.disabledTextColor
                font.family: Kirigami.Theme.smallFont.family
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Accessible.name: i18n("%1 of %2 characters", editor.text.length, noteRoot.maximumNoteLength)
            }
        }
    }
}
