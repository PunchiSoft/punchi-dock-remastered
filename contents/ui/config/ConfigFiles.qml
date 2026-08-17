import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "code/configItems.js" as ConfigItemsJS
import "code/items.js" as ItemsJS
import "../../code/logic.js" as DockLogic
import "components"

KCM.SimpleKCM {
    id: page

    title: i18n("JSON Configuration") // qmllint disable unqualified
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
    property alias statusMessage: statusLabel

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
        if (text.length > DockLogic.maximumDockItemsJsonLength) {
            // qmllint disable unqualified
            page.statusMessage.text = i18n("The dock configuration is too large. The maximum supported size is 1 MiB.")
            // qmllint enable unqualified
            page.statusMessage.type = Kirigami.MessageType.Error
            return false
        }
        editorDockItemsJson = text
        cfg_dockItemsJson = text
        return true
    }

    function setItems(nextItems) {
        setEditorText(JSON.stringify(nextItems, null, 4))
    }

    function validateJson() {
        if (advancedJsonEditor.text.length > DockLogic.maximumDockItemsJsonLength) {
            // qmllint disable unqualified
            page.statusMessage.text = i18n("The dock configuration is too large. The maximum supported size is 1 MiB.")
            // qmllint enable unqualified
            page.statusMessage.type = Kirigami.MessageType.Error
            return false
        }
        try {
            var result = ConfigItemsJS.parseJsonArray(advancedJsonEditor.text)
            if (!result.ok) {
                statusLabel.text = i18n("The root value must be a JSON array.") // qmllint disable unqualified
                statusLabel.type = Kirigami.MessageType.Error
                return false
            }
            if (result.items.length > DockLogic.maximumDockItemCount) {
                // qmllint disable unqualified
                page.statusMessage.text = i18n("The dock configuration contains too many items. The maximum is %1.", DockLogic.maximumDockItemCount)
                // qmllint enable unqualified
                page.statusMessage.type = Kirigami.MessageType.Error
                return false
            }
            var duplicateSingleton = DockLogic.duplicateSingletonType(result.items)
            if (duplicateSingleton.length > 0) {
                statusLabel.text = duplicateSingleton === "punchimenu"
                    ? i18n("Only one PunchiMenu item is allowed in the dock configuration.") // qmllint disable unqualified
                    : i18n("Only one media player item is allowed in the dock configuration.") // qmllint disable unqualified
                statusLabel.type = Kirigami.MessageType.Error
                return false
            }
        } catch (error) {
            statusLabel.text = i18n("Invalid JSON: %1", error) // qmllint disable unqualified
            statusLabel.type = Kirigami.MessageType.Error
            return false
        }

        statusLabel.text = i18n("JSON looks valid.") // qmllint disable unqualified
        statusLabel.type = Kirigami.MessageType.Positive
        return true
    }

    function prepareDefaultItems() {
        var formatted = ItemsJS.defaultJson()
        page.setEditorText(formatted)
        statusLabel.text = i18n("Default items restored.") // qmllint disable unqualified
        statusLabel.type = Kirigami.MessageType.Information
    }

    function cleanItemsFileConfirmed() {
        var formatted = "[]"
        page.setEditorText(formatted)
        statusLabel.text = i18n("Clean completed.") // qmllint disable unqualified
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
        statusLabel.text = i18n("Copied to clipboard! You can paste this in any file to save your backup.") // qmllint disable unqualified
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
        title: i18n("Clean configuration file?") // qmllint disable unqualified
        standardButtons: Controls.Dialog.Cancel | Controls.Dialog.Ok
        anchors.centerIn: parent
        width: Math.min(page.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 28)

        onAccepted: page.cleanItemsFileConfirmed()

        Controls.Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: i18n("This will replace the saved dock items with an empty array. This cannot be undone from Punchi Dock.") // qmllint disable unqualified
        }
    }

    FileDialog {
        id: importDialog
        title: i18n("Import JSON Configuration") // qmllint disable unqualified
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
                        if (text.length > DockLogic.maximumDockItemsJsonLength) {
                            // qmllint disable unqualified
                            page.statusMessage.text = i18n("The dock configuration is too large. The maximum supported size is 1 MiB.")
                            // qmllint enable unqualified
                            page.statusMessage.type = Kirigami.MessageType.Error
                            return
                        }
                        var result = ConfigItemsJS.parseJsonArray(text)
                        if (result.ok && result.items.length <= DockLogic.maximumDockItemCount) {
                            var normalizedItems = DockLogic.withSingletonItems(result.items)
                            var formatted = JSON.stringify(ItemsJS.withConfigureDockItem(normalizedItems), null, 4)
                            page.setEditorText(formatted)
                            statusLabel.text = i18n("Configuration imported successfully.") // qmllint disable unqualified
                            statusLabel.type = Kirigami.MessageType.Positive
                        } else if (result.ok) {
                            // qmllint disable unqualified
                            page.statusMessage.text = i18n("The dock configuration contains too many items. The maximum is %1.", DockLogic.maximumDockItemCount)
                            // qmllint enable unqualified
                            page.statusMessage.type = Kirigami.MessageType.Error
                        } else {
                            statusLabel.text = i18n("Loaded file, but JSON is invalid: %1", result.error) // qmllint disable unqualified
                            statusLabel.type = Kirigami.MessageType.Error
                        }
                    } else {
                        statusLabel.text = i18n("Failed to read file.") // qmllint disable unqualified
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
