import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: folderRoot
    implicitWidth: 280
    implicitHeight: classicPopupHeight
    width: implicitWidth
    height: implicitHeight

    // Properties injected by the main UI.
    property var folderItem: ({})
    property string layoutMode: "grid"
    property int maximumAvailableHeight: 640

    // Quick access entries.
    property var apps: folderItem.apps || []
    property int itemCount: apps.length
    readonly property int classicMargin: 12
    readonly property int classicSpacing: 8
    readonly property int gridCellWidth: 80
    readonly property int classicCellHeight: layoutMode === "detailed" ? 56 : (layoutMode === "list" ? 40 : 72)
    readonly property int classicContentWidth: implicitWidth - classicMargin * 2
    readonly property int gridColumnCount: Math.max(1, Math.floor(classicContentWidth / gridCellWidth))
    readonly property int classicRowCount: layoutMode === "grid"
        ? Math.ceil(itemCount / gridColumnCount)
        : itemCount
    readonly property int configuredRowLimit: Math.max(0, Number(folderItem.rows || 0))
    readonly property int visibleClassicRows: Math.max(1, configuredRowLimit > 0
        ? Math.min(classicRowCount, configuredRowLimit)
        : classicRowCount)
    readonly property int classicChromeHeight: classicMargin * 2 + classicHeader.implicitHeight + classicSpacing
    readonly property int classicNaturalHeight: classicChromeHeight + visibleClassicRows * classicCellHeight
    readonly property int configuredMaximumHeight: Math.max(0, Number(folderItem.popupMaxHeight || 0))
    readonly property int effectiveMaximumHeight: configuredMaximumHeight > 0
        ? Math.min(maximumAvailableHeight, Math.max(classicChromeHeight + classicCellHeight, configuredMaximumHeight))
        : maximumAvailableHeight
    readonly property int classicPopupHeight: Math.min(classicNaturalHeight, effectiveMaximumHeight)

    // Signals for launching applications and closing the popup.
    signal appLaunched(var app)
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: folderRoot.classicMargin
        spacing: folderRoot.classicSpacing

        // Folder title.
        RowLayout {
            id: classicHeader
            Layout.fillWidth: true
            PlasmaExtras.ShadowedLabel {
                text: folderItem.name || i18n("Folder")
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            // Close button.
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: closeMouse.containsMouse || closeMouse.activeFocus ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.backgroundColor
                PlasmaComponents.Label { text: "×"; anchors.centerIn: parent; color: Kirigami.Theme.textColor }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent; hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: i18n("Close")
                    onClicked: folderRoot.closeRequested()
                    Keys.onReturnPressed: folderRoot.closeRequested()
                    Keys.onSpacePressed: folderRoot.closeRequested()
                }
            }
        }

        // Grid or list view.
        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Keep cellWidth from producing scrollbars or horizontal clipping.
            cellWidth: layoutMode === "list" || layoutMode === "detailed"
                ? gridView.width
                : folderRoot.gridCellWidth
            cellHeight: folderRoot.classicCellHeight
            model: folderRoot.apps
            clip: true

            delegate: Item {
                width: gridView.cellWidth
                height: gridView.cellHeight

                // Interactive background.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 8
                    color: itemMouse.containsMouse || itemMouse.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    opacity: itemMouse.containsMouse || itemMouse.activeFocus ? 0.2 : 1
                    border.width: itemMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                }

                // List and detail modes place the icon before the label.
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: layoutMode === "list" || layoutMode === "detailed"
                    spacing: 8

                    Kirigami.Icon {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        source: modelData.icon || "application-x-executable"
                    }
                    Column {
                        Layout.fillWidth: true
                        PlasmaExtras.ShadowedLabel {
                            text: modelData.name
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        PlasmaComponents.Label {
                            text: modelData.command || ""
                            font.family: Kirigami.Theme.smallFont.family
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.textColor
                            opacity: 0.6
                            elide: Text.ElideRight
                            width: parent.width
                            visible: layoutMode === "detailed"
                        }
                    }
                }

                // Standard grid mode places the icon above the label.
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: layoutMode === "grid"
                    spacing: 4

                    Kirigami.Icon {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignHCenter
                        source: modelData.icon || "application-x-executable"
                    }
                    PlasmaExtras.ShadowedLabel {
                        text: modelData.name
                        font.family: Kirigami.Theme.smallFont.family
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name || i18n("Application")
                    onClicked: {
                        folderRoot.appLaunched(modelData)
                    }
                    Keys.onReturnPressed: folderRoot.appLaunched(modelData)
                    Keys.onSpacePressed: folderRoot.appLaunched(modelData)
                }
            }
        }
    }

}
