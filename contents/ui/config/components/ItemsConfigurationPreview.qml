// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

import "../code/configItems.js" as ConfigItemsJS

// Translation helpers are supplied by the plasmoid configuration context.
// qmllint disable unqualified
FocusScope {
    id: root

    property var items: []
    property int selectedIndex: -1
    property int dropInsertionIndex: -1
    readonly property real delegateWidth: Kirigami.Units.gridUnit * 4
    readonly property real delegateSpacing: Kirigami.Units.smallSpacing
    readonly property real delegateExtent: delegateWidth + delegateSpacing

    signal selected(int index)
    signal addRequested(string itemType, int insertionIndex)
    signal moveRequested(int sourceIndex, int insertionIndex)
    signal removeRequested(int index)

    implicitHeight: Kirigami.Units.gridUnit * 6
    Accessible.role: Accessible.List
    Accessible.name: i18nc("@title:group", "Punchi Dock preview")

    function titleForItem(item) {
        return ConfigItemsJS.itemTitle(item, function(text) {
            return i18n(text)
        })
    }

    function insertionIndexAt(positionX) {
        const local = Math.max(0,
            Number(positionX) + previewList.contentX - previewList.leftMargin)
        return Math.max(0, Math.min(items.length,
            Math.round(local / delegateExtent)))
    }

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.34)
        border.width: previewDropArea.containsDrag || root.activeFocus ? 2 : 1
        border.color: previewDropArea.containsDrag || root.activeFocus
            ? Kirigami.Theme.highlightColor
            : Qt.alpha(Kirigami.Theme.textColor, 0.32)
    }

    Controls.Label {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - Kirigami.Units.gridUnit * 4)
        visible: root.items.length === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Kirigami.Theme.disabledTextColor
        text: i18nc("@info:placeholder",
            "Drag elements here or activate one above to add it")
    }

    ListView {
        id: previewList

        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        orientation: ListView.Horizontal
        spacing: root.delegateSpacing
        leftMargin: Kirigami.Units.smallSpacing
        rightMargin: Kirigami.Units.smallSpacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.items
        currentIndex: root.selectedIndex
        keyNavigationWraps: false
        activeFocusOnTab: root.items.length > 0
        visible: root.items.length > 0

        delegate: Controls.ItemDelegate {
            id: itemDelegate

            required property var modelData
            required property int index
            readonly property string dragKind: "preview"
            readonly property int sourceIndex: index

            width: root.delegateWidth
            height: previewList.height
            highlighted: index === root.selectedIndex
            hoverEnabled: true
            activeFocusOnTab: true
            Accessible.name: root.titleForItem(modelData)
            Accessible.description: i18nc("@info:accessibility",
                "Dock element %1 of %2", index + 1, root.items.length)

            Drag.active: false
            Drag.source: itemDelegate
            Drag.keys: ["punchi-config-preview-item"]
            Drag.supportedActions: Qt.MoveAction
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            onClicked: {
                root.selected(index)
                forceActiveFocus(Qt.MouseFocusReason)
            }
            Keys.onDeletePressed: function(event) {
                root.removeRequested(index)
                event.accepted = true
            }
            Keys.onLeftPressed: function(event) {
                if (index > 0) {
                    root.selected(index - 1)
                    previewList.itemAtIndex(index - 1).forceActiveFocus(
                        Qt.TabFocusReason)
                    event.accepted = true
                }
            }
            Keys.onRightPressed: function(event) {
                if (index < root.items.length - 1) {
                    root.selected(index + 1)
                    previewList.itemAtIndex(index + 1).forceActiveFocus(
                        Qt.TabFocusReason)
                    event.accepted = true
                }
            }

            contentItem: Column {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: ConfigItemsJS.itemIcon(itemDelegate.modelData)
                }

                Controls.Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.titleForItem(itemDelegate.modelData)
                    elide: Text.ElideRight
                }
            }

            DragHandler {
                id: itemDragHandler
                target: null
                enabled: itemDelegate.enabled
                onActiveChanged: {
                    if (active) {
                        itemDelegate.Drag.active = true
                    } else if (itemDelegate.Drag.active) {
                        itemDelegate.Drag.drop()
                    }
                }
            }
        }
    }

    DropArea {
        id: previewDropArea

        anchors.fill: parent
        keys: ["punchi-config-catalog-item", "punchi-config-preview-item"]
        onEntered: function(drag) {
            root.dropInsertionIndex = root.insertionIndexAt(drag.x)
        }
        onPositionChanged: function(drag) {
            root.dropInsertionIndex = root.insertionIndexAt(drag.x)
        }
        onExited: root.dropInsertionIndex = -1
        onDropped: function(drop) {
            const insertion = root.insertionIndexAt(drop.x)
            // DragEvent.source has the runtime type of the originating QML
            // delegate, while the generated metadata exposes only QObject.
            // qmllint disable missing-property
            if (drop.source && drop.source.dragKind === "catalog") {
                root.addRequested(String(drop.source.itemType || ""), insertion)
                drop.acceptProposedAction()
            } else if (drop.source
                    && drop.source.dragKind === "preview") {
                root.moveRequested(Number(drop.source.sourceIndex), insertion)
                drop.acceptProposedAction()
            }
            // qmllint enable missing-property
            root.dropInsertionIndex = -1
        }
    }

    Rectangle {
        width: 2
        height: Math.max(0, parent.height - Kirigami.Units.largeSpacing * 2)
        y: Kirigami.Units.largeSpacing
        x: Math.max(Kirigami.Units.largeSpacing,
            Math.min(parent.width - Kirigami.Units.largeSpacing,
                Kirigami.Units.largeSpacing + previewList.leftMargin
                + root.dropInsertionIndex * root.delegateExtent
                - previewList.contentX))
        visible: previewDropArea.containsDrag && root.dropInsertionIndex >= 0
        color: Kirigami.Theme.highlightColor
        radius: 1
    }
}
// qmllint enable unqualified
