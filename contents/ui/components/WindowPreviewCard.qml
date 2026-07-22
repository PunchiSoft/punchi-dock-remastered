pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

Controls.ItemDelegate {
    id: root

    property var windowData: ({})
    property bool liveThumbnailEnabled: false
    property bool streamActive: false
    property string infoMode: "full"
    property bool textShadowsEnabled: true
    property int previewWidth: 276
    property int previewHeight: 173
    property int previewRadius: 4
    property int outerPadding: 2
    readonly property int taskRow: Number(windowData.row)
    readonly property string primaryText: windowData.title || windowData.name || i18n("Window")
    readonly property string secondaryText: windowData.active
        ? i18n("Active window")
        : (windowData.subtitle || windowData.name || i18n("Window preview"))
    readonly property string windowUuid: String(windowData.windowUuid || "")
    readonly property bool canMinimize: !!windowData.minimizable
    readonly property bool minimized: !!windowData.minimized
    readonly property bool canMaximize: !!windowData.maximizable
    readonly property bool maximized: !!windowData.maximized
    readonly property bool canClose: !!windowData.closable
    readonly property int actionGroupRadius: Math.max(8, Math.min(16, previewRadius))
    readonly property int actionButtonRadius: Math.max(6, actionGroupRadius - 2)

    implicitHeight: previewHeight + (outerPadding * 2)
    height: implicitHeight
    padding: 0
    highlighted: !!windowData.active
    Accessible.name: primaryText
    Accessible.description: windowData.active ? i18n("Active window") : i18n("Activate window")

    signal activateRequested(int taskRow)
    signal presentWindowRequested(int taskRow)
    signal minimizeWindowRequested(int taskRow)
    signal maximizeWindowRequested(int taskRow)
    signal closeWindowRequested(int taskRow)

    onClicked: activateRequested(taskRow)

    background: Rectangle {
        radius: root.previewRadius + root.outerPadding
        color: root.hovered || root.activeFocus
            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                Kirigami.Theme.highlightColor.g,
                Kirigami.Theme.highlightColor.b, 0.08)
            : "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Kirigami.Theme.highlightColor
    }

    contentItem: Item {
        Item {
            id: previewFrame
            anchors.centerIn: parent
            width: root.previewWidth
            height: root.previewHeight
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: root.previewRadius
                color: Qt.rgba(Kirigami.Theme.alternateBackgroundColor.r,
                    Kirigami.Theme.alternateBackgroundColor.g,
                    Kirigami.Theme.alternateBackgroundColor.b, 0.72)
            }

            Loader {
                id: thumbnailLoader
                anchors.fill: parent
                active: root.streamActive && root.liveThumbnailEnabled
                    && root.windowUuid.length > 0
                sourceComponent: WindowLiveThumbnail {
                    windowUuid: root.windowUuid
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 16
                spacing: 6
                // Loader.item is intentionally dynamic; the loaded component exposes
                // hasThumbnail through WindowLiveThumbnail.
                // qmllint disable missing-property
                visible: !(thumbnailLoader.item && thumbnailLoader.item.hasThumbnail)
                // qmllint enable missing-property

                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(48, Math.round(root.previewWidth * 0.24))
                    height: width
                    source: String(root.windowData.icon || "window")
                }

                Controls.Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: !root.liveThumbnailEnabled
                        ? i18n("Preview disabled")
                        : i18n("Preview unavailable")
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 11
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.rightMargin: 8
                height: 34
                width: actionButtons.implicitWidth + 10
                radius: root.actionGroupRadius
                z: 4
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                    Kirigami.Theme.backgroundColor.g,
                    Kirigami.Theme.backgroundColor.b, 0.78)

                RowLayout {
                    id: actionButtons
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    spacing: 2

                    Controls.ToolButton {
                        id: presentButton
                        visible: !root.windowData.active
                        enabled: !root.minimized
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
                            radius: root.actionButtonRadius
                            color: presentButton.hovered || presentButton.activeFocus
                                ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                    Kirigami.Theme.highlightColor.g,
                                    Kirigami.Theme.highlightColor.b, 0.24)
                                : "transparent"
                            border.width: presentButton.activeFocus ? 1 : 0
                            border.color: presentButton.activeFocus
                                ? Kirigami.Theme.textColor
                                : "transparent"
                        }
                        onClicked: root.presentWindowRequested(root.taskRow)
                    }

                    Controls.ToolButton {
                        id: minimizeButton
                        enabled: root.canMinimize
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        padding: 2
                        focusPolicy: Qt.StrongFocus
                        Accessible.name: root.minimized
                            ? i18n("Restore from minimized state")
                            : i18n("Minimize window")
                        Controls.ToolTip.visible: hovered || activeFocus
                        Controls.ToolTip.text: Accessible.name
                        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                        contentItem: Kirigami.Icon {
                            source: root.minimized ? "view-restore" : "go-down"
                            color: Kirigami.Theme.textColor
                            implicitWidth: 16
                            implicitHeight: 16
                        }
                        background: Rectangle {
                            radius: root.actionButtonRadius
                            color: minimizeButton.hovered || minimizeButton.activeFocus
                                ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                    Kirigami.Theme.highlightColor.g,
                                    Kirigami.Theme.highlightColor.b, 0.24)
                                : "transparent"
                            border.width: minimizeButton.activeFocus ? 1 : 0
                            border.color: minimizeButton.activeFocus
                                ? Kirigami.Theme.textColor
                                : "transparent"
                        }
                        onClicked: root.minimizeWindowRequested(root.taskRow)
                    }

                    Controls.ToolButton {
                        id: maximizeButton
                        enabled: root.canMaximize
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        padding: 2
                        focusPolicy: Qt.StrongFocus
                        Accessible.name: root.maximized
                            ? i18n("Restore window size")
                            : i18n("Maximize window")
                        Controls.ToolTip.visible: hovered || activeFocus
                        Controls.ToolTip.text: Accessible.name
                        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                        contentItem: Kirigami.Icon {
                            source: root.maximized ? "view-restore" : "view-fullscreen"
                            color: Kirigami.Theme.textColor
                            implicitWidth: 16
                            implicitHeight: 16
                        }
                        background: Rectangle {
                            radius: root.actionButtonRadius
                            color: maximizeButton.hovered || maximizeButton.activeFocus
                                ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                    Kirigami.Theme.highlightColor.g,
                                    Kirigami.Theme.highlightColor.b, 0.24)
                                : "transparent"
                            border.width: maximizeButton.activeFocus ? 1 : 0
                            border.color: maximizeButton.activeFocus
                                ? Kirigami.Theme.textColor
                                : "transparent"
                        }
                        onClicked: root.maximizeWindowRequested(root.taskRow)
                    }

                    Controls.ToolButton {
                        id: closeButton
                        enabled: root.canClose
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
                            radius: root.actionButtonRadius
                            color: closeButton.hovered || closeButton.activeFocus
                                ? Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                                    Kirigami.Theme.negativeTextColor.g,
                                    Kirigami.Theme.negativeTextColor.b, 0.24)
                                : "transparent"
                            border.width: closeButton.activeFocus ? 1 : 0
                            border.color: closeButton.activeFocus
                                ? Kirigami.Theme.textColor
                                : "transparent"
                        }
                        onClicked: root.closeWindowRequested(root.taskRow)
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
                visible: root.infoMode !== "none"

                Kirigami.Icon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    source: String(root.windowData.icon || "window")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    visible: root.infoMode === "full"

                    PlasmaExtras.ShadowedLabel {
                        Layout.fillWidth: true
                        text: root.primaryText
                        renderShadow: root.textShadowsEnabled
                        font.bold: !!root.windowData.active
                        elide: Text.ElideRight
                    }

                    PlasmaExtras.ShadowedLabel {
                        Layout.fillWidth: true
                        text: root.secondaryText
                        renderShadow: root.textShadowsEnabled
                        elide: Text.ElideRight
                        opacity: 0.78
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
