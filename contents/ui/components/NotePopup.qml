import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: noteRoot

    property var noteItem: ({})
    property string initialText: ""
    property alias currentText: editor.text
    readonly property int activeWidth: Math.max(220, noteItem && noteItem.popupWidth ? noteItem.popupWidth : 360)
    readonly property int activeHeight: Math.max(160, noteItem && noteItem.popupHeight ? noteItem.popupHeight : 260)
    readonly property int maximumNoteLength: 2000

    width: activeWidth
    height: activeHeight
    implicitWidth: width
    implicitHeight: height

    signal noteChanged(string noteText, int popupWidth, int popupHeight)
    signal clearRequested(string noteText, int popupWidth, int popupHeight)
    signal closeRequested()

    function syncFromItem() {
        var nextText = noteItem && noteItem.note ? noteItem.note : ""
        editor.text = nextText
        initialText = editor.text
    }

    function focusEditor() {
        editor.forceActiveFocus()
    }

    function wrapSelectionWithTag(tagName) {
        var start = Math.min(editor.selectionStart, editor.selectionEnd)
        var end = Math.max(editor.selectionStart, editor.selectionEnd)
        var openingTag = "<" + tagName + ">"
        var closingTag = "</" + tagName + ">"

        if (start === end) {
            editor.insert(start, openingTag + closingTag)
            editor.cursorPosition = start + openingTag.length
            return
        }

        var selectedContent = editor.text.slice(start, end)
        editor.remove(start, end)
        editor.insert(start, openingTag + selectedContent + closingTag)
        editor.select(start, start + openingTag.length + selectedContent.length + closingTag.length)
    }

    onNoteItemChanged: syncFromItem()
    Component.onCompleted: syncFromItem()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Label {
                text: noteRoot.noteItem && noteRoot.noteItem.name ? noteRoot.noteItem.name : i18n("Note")
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
            }

            Controls.ToolButton {
                icon.name: "edit-clear-all-symbolic"
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18n("Clear")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Clear")
                onClicked: {
                    editor.text = ""
                    noteRoot.initialText = editor.text
                    noteRoot.clearRequested("", noteRoot.activeWidth, noteRoot.activeHeight)
                }
            }

            Controls.ToolButton {
                icon.name: "window-close-symbolic"
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18n("Close")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Close")
                onClicked: noteRoot.closeRequested()
                Keys.onReturnPressed: noteRoot.closeRequested()
                Keys.onSpacePressed: noteRoot.closeRequested()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Controls.ToolButton {
                text: i18n("B")
                font.bold: true
                Accessible.name: i18n("Bold")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Bold")
                onClicked: noteRoot.wrapSelectionWithTag("b")
            }

            Controls.ToolButton {
                text: i18n("I")
                font.italic: true
                Accessible.name: i18n("Italic")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Italic")
                onClicked: noteRoot.wrapSelectionWithTag("i")
            }

            Controls.ToolButton {
                text: i18n("U")
                font.underline: true
                Accessible.name: i18n("Underline")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Underline")
                onClicked: noteRoot.wrapSelectionWithTag("u")
            }

            Controls.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: i18n("Basic rich text")
                color: Kirigami.Theme.disabledTextColor
            }
        }

        Controls.TextArea {
            id: editor
            Layout.fillWidth: true
            Layout.fillHeight: true
            textFormat: TextEdit.RichText
            wrapMode: TextEdit.Wrap
            placeholderText: i18n("Write a quick note")
            color: Kirigami.Theme.textColor
            selectByMouse: true
            activeFocusOnTab: true

            onTextChanged: {
                if (text.length > noteRoot.maximumNoteLength) {
                    text = text.slice(0, noteRoot.maximumNoteLength)
                }
            }
        }
    }
}
