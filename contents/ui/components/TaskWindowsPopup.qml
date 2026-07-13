import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
Item {
    id: taskPopupRoot
    implicitWidth: Math.max(196, previewFrameWidth + 40) + scrollBarGutter
    implicitHeight: verticalPadding * 2 + headerHeight + contentSpacing + listViewportHeight
    width: implicitWidth
    height: implicitHeight

    property string appName: ""
    property var windows: []
    property string previewStyle: "card"
    property real previewScale: 1.0
    property bool automaticPopupRadius: true
    property int popupRadius: 4
    property int popupDirection: Qt.BottomEdge
    property bool inPanel: false
    property int maxVisibleRows: 4
    property int maximumAvailableHeight: 640
    readonly property bool showLiveThumbnails: previewStyle === "thumbnail"
    readonly property bool containsMouse: popupHover.hovered
    readonly property real effectivePreviewScale: Math.max(0.5, Math.min(2.0, previewScale))
    readonly property int configuredCornerRadius: Math.max(4, Math.min(32, popupRadius))
    readonly property int previewFrameWidth: Math.round(184 * effectivePreviewScale)
    readonly property int previewFrameHeight: Math.round(previewFrameWidth / 1.6)
    readonly property int horizontalPadding: 12
    readonly property int verticalPadding: 12
    readonly property int headerHeight: 0
    readonly property int contentSpacing: 0
    readonly property int cardOuterPadding: 5
    readonly property int previewRadius: automaticPopupRadius ? 4 : configuredCornerRadius
    readonly property int previewInnerRadius: previewRadius - 1
    readonly property int cardRadius: Math.min(40, previewRadius + 6)
    readonly property int cardOverlayHeight: Math.max(68, Math.round(previewFrameHeight * 0.34))
    readonly property int cardHeight: previewFrameHeight + (cardOuterPadding * 2)
    readonly property int listSpacing: 8
    readonly property int actionGroupRadius: Math.max(8, Math.min(16, previewInnerRadius))
    readonly property int actionButtonRadius: Math.max(6, actionGroupRadius - 2)
    readonly property int listContentHeight: windows.length > 0
        ? windows.length * cardHeight + (windows.length - 1) * listSpacing
        : 0
    readonly property int configuredRowsHeight: Math.max(1, Math.min(8, maxVisibleRows)) * cardHeight
        + (Math.max(1, Math.min(8, maxVisibleRows)) - 1) * listSpacing
    readonly property int availableListHeight: Math.max(cardHeight,
        maximumAvailableHeight - verticalPadding * 2 - headerHeight - contentSpacing)
    readonly property int listViewportHeight: Math.min(listContentHeight,
        configuredRowsHeight, availableListHeight)
    readonly property bool scrollRequired: listContentHeight > listViewportHeight
    readonly property int scrollBarGutter: scrollRequired
        ? Math.ceil(windowScrollBar.implicitWidth) + Kirigami.Units.smallSpacing
        : 0
    Layout.maximumHeight: maximumAvailableHeight

    signal activateRequested(int taskRow)
    signal presentWindowRequested(int taskRow)
    signal minimizeWindowRequested(int taskRow)
    signal maximizeWindowRequested(int taskRow)
    signal closeWindowRequested(int taskRow)
    signal closeRequested()

    HoverHandler {
        id: popupHover
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.leftMargin: taskPopupRoot.horizontalPadding
        anchors.rightMargin: taskPopupRoot.horizontalPadding
        anchors.topMargin: taskPopupRoot.verticalPadding
        anchors.bottomMargin: taskPopupRoot.verticalPadding
        spacing: taskPopupRoot.contentSpacing

        Controls.ScrollView {
            id: windowsScrollView
            Layout.fillWidth: true
            Layout.preferredHeight: taskPopupRoot.listViewportHeight
            clip: true
            rightPadding: taskPopupRoot.scrollBarGutter
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: windowScrollBar
                parent: windowsScrollView
                x: windowsScrollView.width - width
                y: windowsScrollView.topPadding
                height: windowsScrollView.availableHeight
                policy: taskPopupRoot.scrollRequired
                    ? Controls.ScrollBar.AsNeeded
                    : Controls.ScrollBar.AlwaysOff
            }

            ListView {
                id: windowList
                width: windowsScrollView.availableWidth
                model: taskPopupRoot.windows
                spacing: taskPopupRoot.listSpacing

                delegate: Controls.ItemDelegate {
                    id: windowRow
                    required property var modelData
                    readonly property string primaryText: modelData.title || modelData.name || i18n("Window")
                    readonly property string secondaryText: modelData.active
                        ? i18n("Active window")
                        : (modelData.subtitle || modelData.name || i18n("Window preview"))
                    readonly property bool canMinimize: !!modelData.minimizable
                    readonly property bool isMinimized: !!modelData.minimized
                    readonly property bool canMaximize: !!modelData.maximizable
                    readonly property bool isMaximized: !!modelData.maximized
                    readonly property string previewWindowUuid: String(modelData.windowUuid || "")
                    readonly property bool previewStreamActive: taskPopupRoot.visible
                        && taskPopupRoot.showLiveThumbnails
                        && previewWindowUuid.length > 0
                        && (windowRow.y + windowRow.height >= windowList.contentY - 8)
                        && (windowRow.y <= windowList.contentY + windowList.height + 8)

                    width: windowList.width
                    height: taskPopupRoot.cardHeight
                    padding: 0
                    highlighted: !!modelData.active
                    Accessible.name: primaryText
                    Accessible.description: modelData.active ? i18n("Active window") : i18n("Activate window")
                    onClicked: taskPopupRoot.activateRequested(modelData.row)

                    background: Rectangle {
                        radius: taskPopupRoot.cardRadius
                        color: windowRow.hovered || windowRow.activeFocus || windowRow.modelData.active
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                Kirigami.Theme.highlightColor.g,
                                Kirigami.Theme.highlightColor.b,
                                windowRow.modelData.active ? 0.14 : 0.08)
                            : "transparent"
                        border.width: windowRow.activeFocus || windowRow.modelData.active ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                    }

                    contentItem: Item {
                        Item {
                            id: previewFrame
                            anchors.centerIn: parent
                            width: taskPopupRoot.previewFrameWidth
                            height: taskPopupRoot.previewFrameHeight

                            Rectangle {
                                anchors.fill: parent
                                radius: taskPopupRoot.previewRadius
                                color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                    Kirigami.Theme.backgroundColor.g,
                                    Kirigami.Theme.backgroundColor.b, 0.18)
                                border.width: 1
                                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                    Kirigami.Theme.textColor.g,
                                    Kirigami.Theme.textColor.b, 0.14)
                            }

                            Item {
                                id: previewContent
                                anchors.fill: parent
                                anchors.margins: 1
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: taskPopupRoot.previewInnerRadius
                                    color: Qt.rgba(Kirigami.Theme.alternateBackgroundColor.r,
                                        Kirigami.Theme.alternateBackgroundColor.g,
                                        Kirigami.Theme.alternateBackgroundColor.b, 0.72)
                                }

                                Loader {
                                    id: pipewireLoader
                                    anchors.fill: parent
                                    active: false
                                    sourceComponent: liveThumbnailComponent

                                    function reloadPreview() {
                                        active = false
                                        previewReloadTimer.restart()
                                    }

                                    Component.onCompleted: reloadPreview()

                                    Connections {
                                        target: windowRow
                                        function onPreviewStreamActiveChanged() {
                                            pipewireLoader.reloadPreview()
                                        }
                                        function onPreviewWindowUuidChanged() {
                                            pipewireLoader.reloadPreview()
                                        }
                                    }

                                    Timer {
                                        id: previewReloadTimer
                                        interval: 0
                                        repeat: false
                                        onTriggered: pipewireLoader.active = windowRow.previewStreamActive
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: taskPopupRoot.cardOverlayHeight + 28
                                    radius: taskPopupRoot.previewInnerRadius
                                    z: 1
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.0) }
                                        GradientStop { position: 0.45; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.18) }
                                        GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.82) }
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    spacing: 6
                                    visible: !(pipewireLoader.item && pipewireLoader.item.hasThumbnail)

                                    Kirigami.Icon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: Math.min(48, Math.round(taskPopupRoot.previewFrameWidth * 0.24))
                                        height: width
                                        source: String(windowRow.modelData.icon || "window")
                                    }

                                    Controls.Label {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: !taskPopupRoot.showLiveThumbnails
                                            ? i18n("Preview disabled")
                                            : i18n("Preview unavailable")
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pixelSize: 11
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: taskPopupRoot.cardOverlayHeight
                                    z: 2
                                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                        Kirigami.Theme.backgroundColor.g,
                                        Kirigami.Theme.backgroundColor.b, 0.32)
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 8
                                    anchors.rightMargin: 8
                                    height: 34
                                    width: actionButtonsRow.implicitWidth + 10
                                    visible: presentWindowButton.visible || minimizeWindowButton.visible
                                        || maximizeWindowButton.visible || closeWindowButton.visible
                                    radius: taskPopupRoot.actionGroupRadius
                                    z: 4
                                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                        Kirigami.Theme.backgroundColor.g,
                                        Kirigami.Theme.backgroundColor.b, 0.78)
                                    border.width: 1
                                    border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                        Kirigami.Theme.textColor.g,
                                        Kirigami.Theme.textColor.b, 0.16)

                                    RowLayout {
                                        id: actionButtonsRow
                                        anchors.fill: parent
                                        anchors.leftMargin: 5
                                        anchors.rightMargin: 5
                                        spacing: 2

                                        Controls.ToolButton {
                                            id: presentWindowButton
                                            visible: !windowRow.isMinimized && !windowRow.modelData.active
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 28
                                            padding: 2
                                            focusPolicy: Qt.StrongFocus
                                            Accessible.name: i18n("Bring window to front")
                                            Controls.ToolTip.visible: hovered || activeFocus
                                            Controls.ToolTip.text: Accessible.name
                                            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                                            contentItem: Kirigami.Icon {
                                                source: "go-up"
                                                color: Kirigami.Theme.textColor
                                                implicitWidth: 16
                                                implicitHeight: 16
                                            }
                                            background: Rectangle {
                                                radius: taskPopupRoot.actionButtonRadius
                                                color: presentWindowButton.hovered || presentWindowButton.activeFocus
                                                    ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                                        Kirigami.Theme.highlightColor.g,
                                                        Kirigami.Theme.highlightColor.b, 0.24)
                                                    : "transparent"
                                                border.width: presentWindowButton.activeFocus ? 1 : 0
                                                border.color: presentWindowButton.activeFocus
                                                    ? Kirigami.Theme.textColor
                                                    : "transparent"
                                            }
                                            onClicked: taskPopupRoot.presentWindowRequested(windowRow.modelData.row)
                                        }

                                        Controls.ToolButton {
                                            id: minimizeWindowButton
                                            visible: windowRow.canMinimize
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 28
                                            padding: 2
                                            focusPolicy: Qt.StrongFocus
                                            Accessible.name: windowRow.isMinimized
                                                ? i18n("Restore from minimized state")
                                                : i18n("Minimize window")
                                            Controls.ToolTip.visible: hovered || activeFocus
                                            Controls.ToolTip.text: Accessible.name
                                            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                                            contentItem: Kirigami.Icon {
                                                source: windowRow.isMinimized ? "view-restore" : "go-down"
                                                color: Kirigami.Theme.textColor
                                                implicitWidth: 16
                                                implicitHeight: 16
                                            }
                                            background: Rectangle {
                                                radius: taskPopupRoot.actionButtonRadius
                                                color: minimizeWindowButton.hovered || minimizeWindowButton.activeFocus
                                                    ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                                        Kirigami.Theme.highlightColor.g,
                                                        Kirigami.Theme.highlightColor.b, 0.24)
                                                    : "transparent"
                                                border.width: minimizeWindowButton.activeFocus ? 1 : 0
                                                border.color: minimizeWindowButton.activeFocus
                                                    ? Kirigami.Theme.textColor
                                                    : "transparent"
                                            }
                                            onClicked: taskPopupRoot.minimizeWindowRequested(windowRow.modelData.row)
                                        }

                                        Controls.ToolButton {
                                            id: maximizeWindowButton
                                            visible: windowRow.canMaximize
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 28
                                            padding: 2
                                            focusPolicy: Qt.StrongFocus
                                            Accessible.name: windowRow.isMaximized
                                                ? i18n("Restore window size")
                                                : i18n("Maximize window")
                                            Controls.ToolTip.visible: hovered || activeFocus
                                            Controls.ToolTip.text: Accessible.name
                                            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                                            contentItem: Kirigami.Icon {
                                                source: windowRow.isMaximized ? "view-restore" : "view-fullscreen"
                                                color: Kirigami.Theme.textColor
                                                implicitWidth: 16
                                                implicitHeight: 16
                                            }
                                            background: Rectangle {
                                                radius: taskPopupRoot.actionButtonRadius
                                                color: maximizeWindowButton.hovered || maximizeWindowButton.activeFocus
                                                    ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                                        Kirigami.Theme.highlightColor.g,
                                                        Kirigami.Theme.highlightColor.b, 0.24)
                                                    : "transparent"
                                                border.width: maximizeWindowButton.activeFocus ? 1 : 0
                                                border.color: maximizeWindowButton.activeFocus
                                                    ? Kirigami.Theme.textColor
                                                    : "transparent"
                                            }
                                            onClicked: taskPopupRoot.maximizeWindowRequested(windowRow.modelData.row)
                                        }

                                        Controls.ToolButton {
                                            id: closeWindowButton
                                            visible: !!windowRow.modelData.closable
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 28
                                            padding: 2
                                            focusPolicy: Qt.StrongFocus
                                            Accessible.name: i18n("Close window")
                                            Controls.ToolTip.visible: hovered || activeFocus
                                            Controls.ToolTip.text: Accessible.name
                                            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                                            contentItem: Kirigami.Icon {
                                                source: "window-close"
                                                color: Kirigami.Theme.textColor
                                                implicitWidth: 16
                                                implicitHeight: 16
                                            }
                                            background: Rectangle {
                                                radius: taskPopupRoot.actionButtonRadius
                                                color: closeWindowButton.hovered || closeWindowButton.activeFocus
                                                    ? Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                                                        Kirigami.Theme.negativeTextColor.g,
                                                        Kirigami.Theme.negativeTextColor.b, 0.24)
                                                    : "transparent"
                                                border.width: closeWindowButton.activeFocus ? 1 : 0
                                                border.color: closeWindowButton.activeFocus
                                                    ? Kirigami.Theme.textColor
                                                    : "transparent"
                                            }
                                            onClicked: taskPopupRoot.closeWindowRequested(windowRow.modelData.row)
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    anchors.bottomMargin: 8
                                    spacing: 8
                                    z: 3

                                    Kirigami.Icon {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        source: String(windowRow.modelData.icon || "window")
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1

                                        Controls.Label {
                                            Layout.fillWidth: true
                                            text: windowRow.primaryText
                                            font.bold: !!windowRow.modelData.active
                                            elide: Text.ElideRight
                                        }

                                        Controls.Label {
                                            Layout.fillWidth: true
                                            text: windowRow.secondaryText
                                            elide: Text.ElideRight
                                            color: Kirigami.Theme.disabledTextColor
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Component {
                        id: liveThumbnailComponent

                        WindowLiveThumbnail {
                            anchors.fill: parent
                            windowUuid: windowRow.previewWindowUuid
                        }
                    }
                }
            }
        }
    }
}
