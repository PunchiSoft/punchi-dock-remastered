import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami


Controls.Dialog {
    id: root

    property var controller
    property var filteredIconModel
    property alias searchText: iconSearch.text
    property alias categoryIndex: iconCategory.currentIndex
    property alias iconName: iconNameEdit.text
    readonly property string categoryValue: iconCategory.currentValue || "all"

    signal iconAccepted(string iconName)
    signal browseRequested()
    signal reloadRequested()
    signal filterChanged()

    modal: true
    title: i18n("Choose icon")
    standardButtons: Controls.Dialog.Cancel | Controls.Dialog.Ok
    onOpened: Qt.callLater(showSelectedIcon)
    onAccepted: iconAccepted(iconNameEdit.text)

    function showSelectedIcon() {
        for (var index = 0; index < iconGrid.count; index++) {
            var row = iconGrid.model.get(index)
            if (row && row.iconName === iconNameEdit.text) {
                iconGrid.currentIndex = index
                iconGrid.positionViewAtIndex(index, GridView.Contain)
                return
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.ComboBox {
                id: iconCategory
                Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                textRole: "text"
                valueRole: "value"
                model: root.controller.iconCategories
                onActivated: root.filterChanged()
            }

            Controls.TextField {
                id: iconSearch
                Layout.fillWidth: true
                placeholderText: i18n("Search icons...")
                selectByMouse: true
                onTextChanged: root.filterChanged()
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                display: Controls.AbstractButton.IconOnly
                icon.name: "view-filter-symbolic"
                enabled: false

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Filter")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                source: root.controller.iconPreviewSource(iconNameEdit.text)
            }

            Controls.TextField {
                id: iconNameEdit
                Layout.fillWidth: true
                placeholderText: i18n("Icon name")
                selectByMouse: true
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                display: Controls.AbstractButton.IconOnly
                icon.name: "view-refresh-symbolic"
                onClicked: root.reloadRequested()

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Reload icons")
            }
        }

        Controls.Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: Kirigami.Units.smallSpacing

            GridView {
                id: iconGrid
                anchors.fill: parent
                clip: true
                cellWidth: Kirigami.Units.gridUnit * 5.4
                cellHeight: Kirigami.Units.gridUnit * 5.2
                model: root.filteredIconModel
                boundsBehavior: Flickable.StopAtBounds
                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }

                delegate: Controls.ItemDelegate {
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    width: iconGrid.cellWidth - Kirigami.Units.smallSpacing
                    height: iconGrid.cellHeight - Kirigami.Units.smallSpacing
                    icon.name: iconName
                    icon.source: root.controller.iconPreviewSource(iconName)
                    icon.width: Kirigami.Units.gridUnit * 2
                    icon.height: Kirigami.Units.gridUnit * 2
                    text: iconName
                    display: Controls.AbstractButton.TextUnderIcon
                    highlighted: iconNameEdit.text === iconName
                    onClicked: iconNameEdit.text = iconName
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                text: i18n("Browse...")
                icon.name: "document-open-folder-symbolic"
                onClicked: root.browseRequested()
            }

            Controls.Label {
                Layout.fillWidth: true
                text: root.controller.filteredIconTotal > root.filteredIconModel.count
                    ? i18n("%1 icons shown", root.filteredIconModel.count) + " / " + i18n("%1 matches", root.controller.filteredIconTotal)
                    : i18n("%1 icons shown", root.filteredIconModel.count)
                opacity: 0.7
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }
}
