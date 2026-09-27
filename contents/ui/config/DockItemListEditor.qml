pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Controls.Frame {
    id: root

    property var controller
    property var itemModel

    signal addItemRequested()

    function positionAtIndex(index) {
        if (index >= 0 && itemList.count > 0) {
            itemList.positionViewAtIndex(index, ListView.Contain)
        }
    }

    function focusAtIndex(index) {
        if (index < 0 || index >= itemList.count) {
            return
        }
        itemList.currentIndex = index
        itemList.positionViewAtIndex(index, ListView.Contain)
        itemList.forceActiveFocus()
    }

    function focusAddItemButton() {
        addItemButton.forceActiveFocus()
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    // Floor derived from the existing list metrics so the frame keeps a usable
    // body when the page is short; the embedded toolbar owns the remaining row.
    Layout.minimumHeight: root.controller.listRowHeight * 4
        + root.controller.listFooterHeight
        + root.controller.listFramePadding

    ColumnLayout {
        anchors.fill: parent

        // The item actions sit in the first row of the frame, above the list, in a
        // single continuous row: first the two actions that build or edit the
        // selection, then the three that reorder or remove it. All five share the
        // same spacing and no filler stands between them, so the row reads as one
        // group and the width left over stays at its end.
        RowLayout {
            Layout.fillWidth: true

            Controls.Button {
                id: addItemButton

                objectName: "addDockItemButton"
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                text: i18nc("@action:button", "Add") // qmllint disable unqualified
                icon.name: "list-add-symbolic"
                display: root.width >= Kirigami.Units.gridUnit * 19
                    ? Controls.AbstractButton.TextBesideIcon
                    : Controls.AbstractButton.IconOnly
                activeFocusOnTab: true
                Accessible.name: i18nc("@action:button", "Add item to Dock") // qmllint disable unqualified
                onClicked: root.addItemRequested()

                Controls.ToolTip.visible: hovered || activeFocus
                // qmllint disable unqualified
                Controls.ToolTip.text: i18nc("@info:tooltip",
                    "Open the item selector to choose what to add to the Dock.")
                // qmllint enable unqualified
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                text: i18n("Configure") // qmllint disable unqualified
                icon.name: "configure-symbolic"
                display: Controls.AbstractButton.TextBesideIcon
                enabled: root.controller.canConfigureSelectedItem()
                onClicked: root.controller.configureSelectedItem()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: root.controller.selectedConfigureTitle()
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "go-up-symbolic"
                enabled: root.controller.selectedIndex > 0
                onClicked: root.controller.moveSelectedItem(-1)
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "go-down-symbolic"
                enabled: root.controller.selectedIndex >= 0 && root.controller.selectedIndex < root.controller.items.length - 1
                onClicked: root.controller.moveSelectedItem(1)
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-delete-symbolic"
                enabled: root.controller.selectedIndex >= 0
                onClicked: root.controller.removeSelectedItem()
            }
        }

        ListView {
            id: itemList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            activeFocusOnTab: true
            // The page no longer draws a heading for this list, so the name only
            // lives in the accessible tree.
            Accessible.name: i18n("Items in Dock") // qmllint disable unqualified
            model: root.itemModel
            currentIndex: root.controller.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            delegate: Controls.ItemDelegate {
                id: itemDelegate

                required property int index
                required property string title
                required property string subtitle
                required property string iconName

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                property bool hasVerticalScroll: itemList.contentHeight > itemList.height

                // The row shows only the item identity. The former description
                // column duplicated the name for most types and consumed the
                // width the reserved editor area needs; the subtitle stays
                // available to assistive technology only.
                width: itemList.width
                height: root.controller.listRowHeight
                rightPadding: Kirigami.Units.smallSpacing
                    + (hasVerticalScroll ? root.controller.listScrollGutter : 0)
                text: itemDelegate.title
                Accessible.description: itemDelegate.subtitle
                icon.name: itemDelegate.iconName
                icon.source: root.controller.iconPreviewSource(itemDelegate.iconName)
                highlighted: itemDelegate.index === root.controller.selectedIndex
                onClicked: root.controller.selectItem(itemDelegate.index)

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: {
                        root.controller.selectItem(itemDelegate.index)
                        if (root.controller.canConfigureSelectedItem()) {
                            root.controller.configureSelectedItem()
                        }
                    }
                }
            }
        }
    }
}
