pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Controls.Frame {
    id: root

    property var controller
    property var itemModel

    function positionAtIndex(index) {
        if (index >= 0 && itemList.count > 0) {
            itemList.positionViewAtIndex(index, ListView.Contain)
        }
    }

    Layout.fillWidth: true
    Layout.preferredHeight: root.controller.itemsColumnBodyHeight
    Layout.maximumHeight: root.controller.itemsColumnBodyHeight

    ColumnLayout {
        anchors.fill: parent

        ListView {
            id: itemList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
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

                width: itemList.width
                height: root.controller.listRowHeight
                rightPadding: width * 0.42 + Kirigami.Units.largeSpacing + (hasVerticalScroll ? root.controller.listScrollGutter : 0)
                text: itemDelegate.title
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

                Controls.Label {
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.smallSpacing + (itemDelegate.hasVerticalScroll ? root.controller.listScrollGutter : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.38
                    text: itemDelegate.subtitle
                    elide: Text.ElideRight
                    opacity: 0.7
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

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

            Item {
                Layout.fillWidth: true
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
                icon.name: "edit-delete-symbolic"
                enabled: root.controller.selectedIndex >= 0
                onClicked: root.controller.removeSelectedItem()
            }
        }
    }
}
