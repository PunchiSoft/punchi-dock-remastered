pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kwindowsystem
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
    readonly property string primaryText: windowData.title || windowData.name || i18n("Window") // qmllint disable unqualified
    readonly property string secondaryText: windowData.active
        ? i18n("Active window") // qmllint disable unqualified
        : (windowData.subtitle || windowData.name || i18n("Window preview")) // qmllint disable unqualified
    readonly property string windowUuid: String(windowData.windowUuid || "")
    readonly property var winId: windowData.winId !== undefined && windowData.winId !== null
        ? windowData.winId
        : 0
    readonly property bool canMinimize: !!windowData.minimizable
    readonly property bool minimized: !!windowData.minimized
    readonly property bool canMaximize: !!windowData.maximizable
    readonly property bool maximized: !!windowData.maximized
    readonly property bool canClose: !!windowData.closable
    readonly property int actionGroupRadius: Math.max(8, Math.min(16, previewRadius))
    readonly property int actionButtonRadius: Math.max(6, actionGroupRadius - 2)
    readonly property bool minimizedFallback:
        KWindowSystem.isPlatformX11 && minimized
    readonly property bool disabledPreviewFallback:
        !minimizedFallback && !liveThumbnailEnabled
    // Translation functions are provided by the plasmoid context.
    // qmllint disable unqualified
    readonly property string fallbackStatusText: minimizedFallback
        ? i18n("Window minimized")
        : (disabledPreviewFallback
            ? i18nc("@info Window live preview state", "Disabled")
            : i18n("Preview unavailable"))
    // qmllint enable unqualified
    readonly property int fallbackApplicationIconSize: {
        const shortSide = Math.min(previewWidth, previewHeight)
        const minimumSize = Kirigami.Units.iconSizes.huge
        const maximumSize = Math.round(minimumSize * 1.125)
        const proportionalSize = Number.isFinite(shortSide) && shortSide > 0
            ? shortSide * 0.38
            : minimumSize
        return Kirigami.Units.iconSizes.roundedIconSize(Math.round(Math.max(
            minimumSize, Math.min(maximumSize, proportionalSize))))
    }

    implicitHeight: previewHeight + (outerPadding * 2)
    height: implicitHeight
    padding: 0
    highlighted: !!windowData.active
    Accessible.name: primaryText
    Accessible.description: windowData.active ? i18n("Active window") : i18n("Activate window") // qmllint disable unqualified

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

            readonly property bool thumbnailReady: !!(thumbnailLoader.item && thumbnailLoader.item.hasThumbnail)

            Loader {
                id: thumbnailLoader
                anchors.fill: parent
                z: 2
                active: root.streamActive && root.liveThumbnailEnabled
                    && (root.windowUuid.length > 0 || Number(root.winId) > 0)
                sourceComponent: WindowLiveThumbnail {
                    windowUuid: root.windowUuid
                    winId: root.winId
                    minimized: root.minimized
                    cornerRadius: root.previewRadius
                }
            }

            Column {
                id: fallbackColumn
                anchors.centerIn: parent
                anchors.verticalCenterOffset: informationPlate.visible
                    ? -Math.round(informationPlate.height / 2)
                    : 0
                width: parent.width - 16
                spacing: 6
                z: 1
                visible: !previewFrame.thumbnailReady

                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.fallbackApplicationIconSize
                    height: width
                    source: String(root.windowData.icon || "window")
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        visible: root.disabledPreviewFallback
                        source: "view-hidden"
                        color: Kirigami.Theme.disabledTextColor
                        Accessible.ignored: true
                    }

                    Controls.Label {
                        text: root.fallbackStatusText
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: 11
                    }
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

                    WindowPreviewActionButton {
                        id: presentButton
                        visible: !root.windowData.active
                        enabled: !root.minimized
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        visualRadius: root.actionButtonRadius
                        text: i18n("Bring window to front") // qmllint disable unqualified
                        icon.name: "go-up"
                        icon.width: 16
                        icon.height: 16
                        onClicked: root.presentWindowRequested(root.taskRow)
                    }

                    WindowPreviewActionButton {
                        id: minimizeButton
                        enabled: root.canMinimize
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        visualRadius: root.actionButtonRadius
                        text: root.minimized
                            ? i18n("Restore from minimized state") // qmllint disable unqualified
                            : i18n("Minimize window") // qmllint disable unqualified
                        icon.name: root.minimized ? "view-restore" : "go-down"
                        icon.width: 16
                        icon.height: 16
                        onClicked: root.minimizeWindowRequested(root.taskRow)
                    }

                    WindowPreviewActionButton {
                        id: maximizeButton
                        enabled: root.canMaximize
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        visualRadius: root.actionButtonRadius
                        text: root.maximized
                            ? i18n("Restore window size") // qmllint disable unqualified
                            : i18n("Maximize window") // qmllint disable unqualified
                        icon.name: root.maximized ? "view-restore" : "view-fullscreen"
                        icon.width: 16
                        icon.height: 16
                        onClicked: root.maximizeWindowRequested(root.taskRow)
                    }

                    WindowPreviewActionButton {
                        id: closeButton
                        enabled: root.canClose
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        visualRadius: root.actionButtonRadius
                        destructive: true
                        text: i18n("Close window") // qmllint disable unqualified
                        icon.name: "window-close"
                        icon.width: 16
                        icon.height: 16
                        onClicked: root.closeWindowRequested(root.taskRow)
                    }
                }
            }

            Rectangle {
                id: informationPlate
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.bottomMargin: Kirigami.Units.smallSpacing
                readonly property int horizontalPadding:
                    Kirigami.Units.smallSpacing
                readonly property int verticalPadding: Math.max(2,
                    Math.round(Kirigami.Units.smallSpacing / 2))
                width: root.infoMode === "full"
                    ? parent.width - Kirigami.Units.smallSpacing * 2
                    : informationRow.implicitWidth + horizontalPadding * 2
                height: informationRow.implicitHeight + verticalPadding * 2
                radius: Math.min(height / 2, Math.max(
                    Kirigami.Units.cornerRadius, root.previewRadius))
                z: 3
                visible: root.infoMode !== "none"
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                    Kirigami.Theme.backgroundColor.g,
                    Kirigami.Theme.backgroundColor.b, 0.82)
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                    Kirigami.Theme.textColor.g,
                    Kirigami.Theme.textColor.b, 0.14)

                RowLayout {
                    id: informationRow
                    anchors.fill: parent
                    anchors.leftMargin: informationPlate.horizontalPadding
                    anchors.rightMargin: informationPlate.horizontalPadding
                    anchors.topMargin: informationPlate.verticalPadding
                    anchors.bottomMargin: informationPlate.verticalPadding
                    spacing: Kirigami.Units.smallSpacing

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
                            color: Kirigami.Theme.textColor
                            font.bold: !!root.windowData.active
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                        }

                        PlasmaExtras.ShadowedLabel {
                            Layout.fillWidth: true
                            text: root.secondaryText
                            renderShadow: root.textShadowsEnabled
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            opacity: 0.78
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
