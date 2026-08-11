import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: root

    // This popup owns a widgets/background surface and must not inherit the
    // panel palette. The Window color set follows light and dark Plasma themes.
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    property var entries: []
    property var taskControllerRef: null
    property int maxVisibleRows: 4
    property bool textShadowsEnabled: true
    readonly property int rowHeight: 48
    readonly property int visibleRows: Math.max(1, Math.min(maxVisibleRows, entries.length))
    readonly property int contentMargin: 12
    readonly property int contentSpacing: 8
    readonly property int rowSpacing: 2
    readonly property int listBottomReserve: Kirigami.Units.smallSpacing
    readonly property int headerTopReserve: listBottomReserve
    readonly property int visibleListHeight: visibleRows * rowHeight
        + Math.max(0, visibleRows - 1) * rowSpacing

    implicitWidth: 300
    implicitHeight: Math.min(420, header.implicitHeight
        + contentMargin * 2 + contentSpacing + visibleListHeight
        + headerTopReserve + listBottomReserve)
    width: implicitWidth
    height: implicitHeight

    signal entryActivated(var entry)
    signal minimizeWindowRequested(int taskRow)
    signal maximizeWindowRequested(int taskRow)
    signal closeWindowRequested(int taskRow)
    signal closeRequested()

    function singleWindowForEntry(entry) {
        if (!root.taskControllerRef
                || typeof root.taskControllerRef.taskWindowsForRows !== "function") {
            return null
        }
        const rows = entry && entry.rows instanceof Array ? entry.rows : []
        const windows = root.taskControllerRef.taskWindowsForRows(rows) || []
        return windows.length === 1 ? windows[0] : null
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.contentMargin
        spacing: root.contentSpacing

        RowLayout {
            id: header
            Layout.fillWidth: true
            Layout.topMargin: root.headerTopReserve

            PlasmaExtras.ShadowedLabel {
                Layout.fillWidth: true
                text: i18n("More window groups") // qmllint disable unqualified
                color: Kirigami.Theme.textColor
                renderShadow: root.textShadowsEnabled
                font.bold: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            Controls.ToolButton {
                icon.name: "window-close-symbolic"
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18n("Close window group list") // qmllint disable unqualified
                onClicked: root.closeRequested()
            }
        }

        Controls.ScrollView {
            id: overflowScroll

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.bottomMargin: root.listBottomReserve
            clip: true
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff

            ListView {
                id: overflowList

                model: root.entries
                implicitWidth: overflowScroll.availableWidth
                width: overflowScroll.availableWidth
                spacing: root.rowSpacing
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Controls.ItemDelegate {
                    id: entryDelegate
                    required property var modelData
                    readonly property var singleWindow:
                        root.singleWindowForEntry(entryDelegate.modelData) // qmllint disable unqualified
                    readonly property bool hasSingleWindow: !!singleWindow
                    width: ListView.view.width
                    height: root.rowHeight
                    text: entryDelegate.modelData.name
                    icon.name: entryDelegate.modelData.icon
                    Accessible.description: i18np("%1 open window", "%1 open windows", entryDelegate.modelData.count) // qmllint disable unqualified
                    onClicked: root.entryActivated(entryDelegate.modelData)

                    contentItem: RowLayout {
                        spacing: 8

                        Kirigami.Icon {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            source: entryDelegate.modelData.icon
                        }

                        PlasmaExtras.ShadowedLabel {
                            Layout.fillWidth: true
                            text: entryDelegate.modelData.name
                            color: Kirigami.Theme.textColor
                            renderShadow: root.textShadowsEnabled
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }

                        PlasmaExtras.ShadowedLabel {
                            visible: !entryDelegate.hasSingleWindow
                            text: String(entryDelegate.modelData.count)
                            color: Kirigami.Theme.textColor
                            renderShadow: root.textShadowsEnabled
                            opacity: 0.68
                            wrapMode: Text.NoWrap
                        }

                        WindowPreviewActionButton {
                            objectName: "overflowMinimizeWindowButton"
                            visible: entryDelegate.hasSingleWindow
                                && !!entryDelegate.singleWindow.minimizable
                            text: entryDelegate.singleWindow
                                    && entryDelegate.singleWindow.minimized
                                ? i18n("Restore from minimized state") // qmllint disable unqualified
                                : i18n("Minimize window") // qmllint disable unqualified
                            icon.name: entryDelegate.singleWindow
                                    && entryDelegate.singleWindow.minimized
                                ? "window-restore" : "window-minimize"
                            onClicked: root.minimizeWindowRequested( // qmllint disable unqualified
                                Number(entryDelegate.singleWindow.row))
                        }

                        WindowPreviewActionButton {
                            objectName: "overflowMaximizeWindowButton"
                            visible: entryDelegate.hasSingleWindow
                                && !!entryDelegate.singleWindow.maximizable
                            text: entryDelegate.singleWindow
                                    && entryDelegate.singleWindow.maximized
                                ? i18n("Restore window size") // qmllint disable unqualified
                                : i18n("Maximize window") // qmllint disable unqualified
                            icon.name: entryDelegate.singleWindow
                                    && entryDelegate.singleWindow.maximized
                                ? "view-restore" : "view-fullscreen"
                            onClicked: root.maximizeWindowRequested( // qmllint disable unqualified
                                Number(entryDelegate.singleWindow.row))
                        }

                        WindowPreviewActionButton {
                            objectName: "overflowCloseWindowButton"
                            visible: entryDelegate.hasSingleWindow
                                && !!entryDelegate.singleWindow.closable
                            text: i18n("Close window") // qmllint disable unqualified
                            icon.name: "window-close"
                            destructive: true
                            onClicked: root.closeWindowRequested( // qmllint disable unqualified
                                Number(entryDelegate.singleWindow.row))
                        }
                    }
                }
            }
        }
    }
}
