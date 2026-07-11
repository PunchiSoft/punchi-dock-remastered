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
    Layout.preferredHeight: controller.itemsColumnBodyHeight
    Layout.maximumHeight: controller.itemsColumnBodyHeight

    ColumnLayout {
        anchors.fill: parent

        ListView {
            id: itemList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.itemModel
            currentIndex: controller.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            delegate: Controls.ItemDelegate {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                property bool hasVerticalScroll: itemList.contentHeight > itemList.height

                width: itemList.width
                height: controller.listRowHeight
                rightPadding: width * 0.42 + Kirigami.Units.largeSpacing + (hasVerticalScroll ? controller.listScrollGutter : 0)
                text: title
                icon.name: iconName
                icon.source: controller.iconPreviewSource(iconName)
                highlighted: index === controller.selectedIndex
                onClicked: controller.selectItem(index)

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: {
                        controller.selectItem(index)
                        controller.configureSelectedItem()
                    }
                }

                Controls.Label {
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.smallSpacing + (parent.hasVerticalScroll ? controller.listScrollGutter : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.38
                    text: subtitle
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
                enabled: controller.selectedIndex > 0
                onClicked: controller.moveSelectedItem(-1)
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "go-down-symbolic"
                enabled: controller.selectedIndex >= 0 && controller.selectedIndex < controller.items.length - 1
                onClicked: controller.moveSelectedItem(1)
            }

            Item {
                Layout.fillWidth: true
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                text: i18n("Configure")
                icon.name: "configure-symbolic"
                display: Controls.AbstractButton.TextBesideIcon
                enabled: controller.selectedIndex >= 0
                onClicked: controller.configureSelectedItem()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: controller.selectedConfigureTitle()
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-delete-symbolic"
                enabled: controller.selectedIndex >= 0
                onClicked: controller.removeSelectedItem()
            }
        }
    }
}
