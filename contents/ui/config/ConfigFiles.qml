import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "code/configItems.js" as ConfigItemsJS
import "code/items.js" as ItemsJS
import "components"

KCM.SimpleKCM {
    id: page

    title: i18n("JSON Configuration")
    implicitWidth: layoutMetrics.pageImplicitWidth

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property string cfg_dockItemsJson: ""
    property string editorDockItemsJson: ""
    property string pendingOperation: "load"
    property bool syncing: false
    property bool loadingFromDisk: false

    function initialJson() {
        return ItemsJS.defaultJson()
    }

    function setEditorText(text) {
        syncing = true
        advancedJsonEditor.text = text
        editorDockItemsJson = text
        cfg_dockItemsJson = text
        syncing = false
    }

    function advancedJsonChanged(text) {
        editorDockItemsJson = text
        cfg_dockItemsJson = text
    }

    function setItems(nextItems) {
        setEditorText(JSON.stringify(nextItems, null, 4))
    }

    function validateJson() {
        try {
            var result = ConfigItemsJS.parseJsonArray(advancedJsonEditor.text)
            if (!result.ok) {
                statusLabel.text = i18n("The root value must be a JSON array.")
                statusLabel.type = Kirigami.MessageType.Error
                return false
            }
        } catch (error) {
            statusLabel.text = i18n("Invalid JSON: %1", error)
            statusLabel.type = Kirigami.MessageType.Error
            return false
        }

        statusLabel.text = i18n("JSON looks valid.")
        statusLabel.type = Kirigami.MessageType.Positive
        return true
    }

    function prepareDefaultItems() {
        var formatted = ItemsJS.defaultJson()
        setEditorText(formatted)
        statusLabel.text = i18n("Default items restored.")
        statusLabel.type = Kirigami.MessageType.Information
    }

    function cleanItemsFileConfirmed() {
        var formatted = "[]"
        setEditorText(formatted)
        statusLabel.text = i18n("Clean completed.")
        statusLabel.type = Kirigami.MessageType.Information
    }

    function cleanItemsFile() {
        cleanConfirmDialog.open()
    }

    function importJsonRequested() {
        importDialog.open()
    }
    
    function exportJsonRequested() {
        advancedJsonEditor.text = cfg_dockItemsJson
        // Since we cannot write to arbitrary disk paths from pure QML in Plasma 6 due to security constraints,
        // we copy the configuration to the clipboard, allowing the user to paste it into any text file they want.
        // We select the text first so the user also sees what's happening.
        advancedJsonEditor.selectAll()
        advancedJsonEditor.copy()
        statusLabel.text = i18n("Copied to clipboard! You can paste this in any file to save your backup.")
        statusLabel.type = Kirigami.MessageType.Positive
    }

    Component.onCompleted: {
        if (cfg_dockItemsJson && cfg_dockItemsJson.length > 0) {
            setEditorText(cfg_dockItemsJson)
        } else {
            setEditorText(initialJson())
        }
    }
    
    onCfg_dockItemsJsonChanged: {
        if (!syncing && cfg_dockItemsJson !== editorDockItemsJson) {
            syncing = true
            advancedJsonEditor.text = cfg_dockItemsJson
            editorDockItemsJson = cfg_dockItemsJson
            syncing = false
        }
    }

    Timer {
        id: statusHideTimer
        interval: 3500
        repeat: false
        onTriggered: statusLabel.text = ""
    }

    Controls.Dialog {
        id: cleanConfirmDialog
        modal: true
        title: i18n("Clean configuration file?")
        standardButtons: Controls.Dialog.Cancel | Controls.Dialog.Ok
        anchors.centerIn: parent
        width: Math.min(page.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 28)

        onAccepted: page.cleanItemsFileConfirmed()

        Controls.Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: i18n("This will replace the saved dock items with an empty array. This cannot be undone from Punchi Dock.")
        }
    }

    FileDialog {
        id: importDialog
        title: i18n("Import JSON Configuration")
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        fileMode: FileDialog.OpenFile
        onAccepted: {
            var path = selectedFile.toString()
            if (path.startsWith("file://")) {
                path = path.substring(7)
            }
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + path)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200 || xhr.status === 0) {
                        var text = xhr.responseText
                        var result = ConfigItemsJS.parseJsonArray(text)
                        if (result.ok) {
                            var formatted = JSON.stringify(ItemsJS.withConfigureDockItem(result.items), null, 4)
                            setEditorText(formatted)
                            statusLabel.text = i18n("Configuration imported successfully.")
                            statusLabel.type = Kirigami.MessageType.Positive
                        } else {
                            statusLabel.text = i18n("Loaded file, but JSON is invalid: %1", result.error)
                            statusLabel.type = Kirigami.MessageType.Error
                        }
                    } else {
                        statusLabel.text = i18n("Failed to read file.")
                        statusLabel.type = Kirigami.MessageType.Error
                    }
                }
            }
            xhr.send()
        }
    }

    ColumnLayout {
        width: Math.max(0, Math.min(parent.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 46))
        spacing: Kirigami.Units.largeSpacing

        ConfigFileToolbar {
            controller: page
        }

        AdvancedJsonEditor {
            id: advancedJsonEditor
            Layout.preferredHeight: Kirigami.Units.gridUnit * 22
            controller: page
            active: true
        }

        Kirigami.InlineMessage {
            id: statusLabel
            Layout.fillWidth: true
            visible: text.length > 0
            text: ""
            onTextChanged: {
                if (text.length > 0 && type !== Kirigami.MessageType.Error) {
                    statusHideTimer.restart()
                } else {
                    statusHideTimer.stop()
                }
            }
            onTypeChanged: {
                if (text.length > 0 && type !== Kirigami.MessageType.Error) {
                    statusHideTimer.restart()
                } else {
                    statusHideTimer.stop()
                }
            }
        }
    }
}
