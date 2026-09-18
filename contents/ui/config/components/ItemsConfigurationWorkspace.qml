// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// Translation helpers are supplied by the plasmoid configuration context.
// qmllint disable unqualified
ColumnLayout {
    id: root

    property var catalogEntries: []
    property var items: []
    property int selectedIndex: -1
    property bool selectedItemRemovable: false
    property bool loaded: false
    property bool dirty: false
    property bool committing: false
    property string errorText: ""
    // Inner width of the surface, supplied by the dialog. Using it instead of
    // the grid's own width keeps the row count stable during the first layout
    // pass, before the surface has a size.
    property real surfaceContentWidth: 0

    signal addRequested(string itemType, int insertionIndex)
    signal selected(int index)
    signal moveRequested(int sourceIndex, int targetIndex)
    signal moveToInsertionRequested(int sourceIndex, int insertionIndex)
    signal removeRequested(int index)
    signal cancelRequested()
    signal applyRequested()
    signal acceptRequested()

    spacing: Kirigami.Units.largeSpacing

    // The catalog lays every supported element out in as many rows as the
    // available width needs, so the surface never clips a tile. GridView has no
    // spacing property, so the gap travels inside the cell metrics.
    readonly property real catalogGap: Kirigami.Units.largeSpacing
    readonly property real catalogMinimumTileWidth:
        Kirigami.Units.gridUnit * 6
    readonly property real catalogTileHeight: Kirigami.Units.gridUnit * 5
    readonly property int catalogColumns: Math.max(1, Math.min(5,
        catalogEntries.length, Math.floor(
            (surfaceContentWidth + catalogGap)
            / (catalogMinimumTileWidth + catalogGap))))
    // Divide the complete row between the available columns. At the preferred
    // window width this produces two balanced rows of five catalog items,
    // while narrower screens reduce the column count without clipping.
    readonly property real catalogCellWidth:
        surfaceContentWidth / catalogColumns
    readonly property real catalogTileWidth:
        catalogCellWidth - catalogGap
    readonly property int catalogRows: Math.max(1, Math.ceil(
        catalogEntries.length / catalogColumns))
    readonly property var presentTypes: {
        const types = []
        const source = items
        for (let index = 0; index < source.length; index++) {
            types.push(String(source[index].type || ""))
        }
        return types
    }

    function focusInitialControl(reason) {
        const firstTile = catalogGrid.itemAtIndex(0)
        if (firstTile) {
            firstTile.forceActiveFocus(reason)
            return true
        }
        return false
    }

    function unavailableReason(type) {
        if (type === "punchimenu") {
            return i18n("Only one PunchiMenu item can be added.")
        }
        if (type === "control-center") {
            return i18n("Only one Control Center item can be added.")
        }
        return i18n("Only one media player item can be added.")
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    Controls.Label {
        Layout.fillWidth: true
        text: i18nc("@title:group", "Available elements")
        font.bold: true
    }

    GridView {
        id: catalogGrid

        objectName: "itemsConfigurationCatalog"
        Layout.fillWidth: true
        Layout.preferredHeight: cellHeight * root.catalogRows
        cellWidth: root.catalogCellWidth
        cellHeight: root.catalogTileHeight + root.catalogGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        model: root.catalogEntries
        currentIndex: 0
        activeFocusOnTab: true

        delegate: ItemsConfigurationCatalogTile {
            required property var modelData
            required property int index
            readonly property bool entryUnavailable:
                modelData.singleton === true
                && root.presentTypes.indexOf(String(modelData.type)) >= 0

            width: root.catalogTileWidth
            height: root.catalogTileHeight
            itemType: String(modelData.type || "")
            iconName: String(modelData.icon || "")
            text: String(modelData.title || "")
            enabled: root.loaded && !entryUnavailable
            tooltipText: entryUnavailable
                ? root.unavailableReason(String(modelData.type || ""))
                : ""
            accessibleDescription: entryUnavailable
                ? root.unavailableReason(String(modelData.type || ""))
                : String(modelData.description || "")
            onClicked: root.addRequested(itemType, root.items.length)
        }
    }

    Controls.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: i18nc("@info", "Drag elements to the dock")
        color: Kirigami.Theme.disabledTextColor
    }

    Kirigami.Icon {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        Layout.preferredHeight: Layout.preferredWidth
        source: "go-down"
        Accessible.ignored: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Item {
            Layout.fillWidth: true
        }

        Controls.ToolButton {
            id: moveLeftButton

            enabled: root.selectedIndex > 0 && !root.committing
            text: i18nc("@action:button", "Move left")
            icon.name: "go-previous"
            display: Controls.AbstractButton.IconOnly
            Accessible.name: text
            onClicked: root.moveRequested(root.selectedIndex,
                root.selectedIndex - 1)

            PlasmaCore.ToolTipArea {
                objectName: "itemsConfigurationMoveLeftToolTip"
                anchors.fill: parent
                active: moveLeftButton.enabled
                mainText: moveLeftButton.text
            }
        }

        Controls.ToolButton {
            id: moveRightButton

            enabled: root.selectedIndex >= 0
                && root.selectedIndex < root.items.length - 1
                && !root.committing
            text: i18nc("@action:button", "Move right")
            icon.name: "go-next"
            display: Controls.AbstractButton.IconOnly
            Accessible.name: text
            onClicked: root.moveRequested(root.selectedIndex,
                root.selectedIndex + 1)

            PlasmaCore.ToolTipArea {
                objectName: "itemsConfigurationMoveRightToolTip"
                anchors.fill: parent
                active: moveRightButton.enabled
                mainText: moveRightButton.text
            }
        }

        Controls.ToolButton {
            objectName: "itemsConfigurationRemoveButton"
            id: removeButton

            enabled: root.selectedIndex >= 0 && root.selectedItemRemovable
                && !root.committing
            text: i18nc("@action:button", "Remove selected element")
            icon.name: "edit-delete"
            display: Controls.AbstractButton.IconOnly
            Accessible.name: text
            onClicked: root.removeRequested(root.selectedIndex)

            PlasmaCore.ToolTipArea {
                objectName: "itemsConfigurationRemoveToolTip"
                anchors.fill: parent
                active: removeButton.enabled
                mainText: removeButton.text
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    ItemsConfigurationPreview {
        objectName: "itemsConfigurationDockPreview"
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5
        items: root.items
        selectedIndex: root.selectedIndex
        onSelected: function(index) {
            root.selected(index)
        }
        onAddRequested: function(itemType, insertionIndex) {
            root.addRequested(itemType, insertionIndex)
        }
        onMoveRequested: function(sourceIndex, insertionIndex) {
            root.moveToInsertionRequested(sourceIndex, insertionIndex)
        }
        onRemoveRequested: function(index) {
            root.removeRequested(index)
        }
    }

    Controls.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: i18nc("@title:group", "Punchi Dock preview")
        color: Kirigami.Theme.disabledTextColor
    }

    Kirigami.InlineMessage {
        objectName: "itemsConfigurationErrorMessage"
        Layout.fillWidth: true
        visible: root.errorText.length > 0
        type: Kirigami.MessageType.Error
        text: root.errorText
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Item {
            Layout.fillWidth: true
        }

        Controls.Button {
            objectName: "itemsConfigurationCancelButton"
            text: i18nc("@action:button", "Cancel")
            icon.name: "dialog-cancel"
            enabled: !root.committing
            onClicked: root.cancelRequested()
        }

        Controls.Button {
            objectName: "itemsConfigurationApplyButton"
            text: i18nc("@action:button", "Apply")
            icon.name: "dialog-ok-apply"
            enabled: root.loaded && root.dirty && !root.committing
            onClicked: root.applyRequested()
        }

        Controls.Button {
            objectName: "itemsConfigurationAcceptButton"
            text: i18nc("@action:button", "Save and close")
            icon.name: "dialog-ok"
            enabled: root.loaded && !root.committing
            onClicked: root.acceptRequested()
        }
    }
}
// qmllint enable unqualified
