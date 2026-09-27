// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "code/itemTypeCatalog.js" as ItemTypeCatalog

// Drop-down selector for the type the «Add item» dialog will build.
//
// The catalogue remains the only source of type metadata. The closed control
// shows the current draft type; opening it reveals the available types with
// their icon and description. An unavailable singleton stays visible with its
// reason, but cannot be activated.
//
// The draft is authoritative. Activating a row only emits `typeRequested`; the
// control then synchronizes back from `draftType`, so an edited draft that still
// awaits discard confirmation never appears to have changed type prematurely.
Controls.ComboBox {
    id: root

    objectName: "itemTypeSelector"

    property var draftController: null
    property int revision: 0

    readonly property var entries: ItemTypeCatalog.types()
    readonly property var rows: {
        root.revision
        const result = []
        for (let index = 0; index < root.entries.length; index++) {
            const descriptor = root.entries[index]
            const available = root.draftController
                ? root.draftController.isTypeAvailable(descriptor.type) : true
            result.push({
                "type": String(descriptor.type),
                "icon": String(descriptor.icon),
                "title": String(descriptor.title),
                "description": String(descriptor.description),
                "available": available,
                "detail": available
                    ? String(descriptor.description)
                    : String(root.draftController
                        ? root.draftController.unavailableReason(descriptor.type)
                        : "")
            })
        }
        return result
    }
    readonly property string selectedType: draftController
        ? String(draftController.draftType) : ""
    readonly property int entryHeight: Kirigami.Units.gridUnit * 3.2
    readonly property var selectedRow: currentIndex >= 0
        && currentIndex < rows.length ? rows[currentIndex] : null

    signal typeRequested(string type)

    implicitWidth: Kirigami.Units.gridUnit * 16
    model: rows
    textRole: "title"
    displayText: selectedRow ? String(selectedRow.title) : ""
    Kirigami.StyleHints.iconName: selectedRow ? String(selectedRow.icon) : ""
    Accessible.name: i18nc("@info:accessibility", "Element type") // qmllint disable unqualified
    Accessible.description: selectedRow ? String(selectedRow.detail) : ""

    Connections {
        target: root.draftController
        enabled: root.draftController !== null

        function onItemsChanged() {
            root.refresh()
        }

        function onDraftTypeChanged() {
            root.synchronizeSelection()
        }
    }

    function typeAt(index) {
        return index >= 0 && index < root.rows.length
            ? String(root.rows[index].type) : ""
    }

    function isEntryAvailable(index) {
        return index >= 0 && index < root.rows.length
            && Boolean(root.rows[index].available)
    }

    function reasonAt(index) {
        return index >= 0 && index < root.rows.length
            ? String(root.rows[index].detail || "") : ""
    }

    function indexOfType(type) {
        const wanted = String(type)
        for (let index = 0; index < root.rows.length; index++) {
            if (String(root.rows[index].type) === wanted) {
                return index
            }
        }
        return -1
    }

    function synchronizeSelection() {
        const selectedIndex = root.indexOfType(root.selectedType)
        if (root.currentIndex !== selectedIndex) {
            root.currentIndex = selectedIndex
        }
    }

    function refresh() {
        root.revision += 1
        root.synchronizeSelection()
    }

    function focusFirstAvailable() {
        root.synchronizeSelection()
        root.forceActiveFocus()
    }

    function requestIndex(index) {
        if (!root.isEntryAvailable(index)) {
            root.synchronizeSelection()
            return false
        }
        root.typeRequested(root.typeAt(index))
        root.synchronizeSelection()
        return true
    }

    onActivated: function(index) {
        root.requestIndex(index)
    }

    onRowsChanged: root.synchronizeSelection()
    Component.onCompleted: root.synchronizeSelection()

    delegate: Controls.ItemDelegate {
        id: entryDelegate

        required property int index
        // Qt Quick Controls exposes ComboBox roles through `model`; this is also
        // the contract used by KDE's own ComboBox delegates. `modelData` is not
        // the row object here and made every availability lookup undefined.
        required property var model

        objectName: "itemTypeEntry-" + String(model.type)

        width: ListView.view ? ListView.view.width : root.width
        height: root.entryHeight
        enabled: Boolean(model.available)
        highlighted: root.highlightedIndex === entryDelegate.index
        Accessible.name: String(model.title)
        Accessible.description: String(model.detail)

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                objectName: "itemTypeEntryIcon-"
                    + String(entryDelegate.model.type)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
                source: String(entryDelegate.model.icon)
                isMask: String(entryDelegate.model.icon)
                    .indexOf("-symbolic") >= 0
                Accessible.ignored: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Controls.Label {
                    Layout.fillWidth: true
                    text: String(entryDelegate.model.title)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Controls.Label {
                    objectName: "itemTypeEntryDetail-"
                        + String(entryDelegate.model.type)
                    Layout.fillWidth: true
                    text: String(entryDelegate.model.detail)
                    opacity: Boolean(entryDelegate.model.available) ? 0.7 : 1
                    color: Boolean(entryDelegate.model.available)
                        ? Kirigami.Theme.textColor
                        : Kirigami.Theme.negativeTextColor
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }
}
