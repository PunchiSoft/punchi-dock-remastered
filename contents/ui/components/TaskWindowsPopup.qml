import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
Item {
    id: taskPopupRoot
    implicitWidth: Math.max(196, previewFrameWidth + 56)
    implicitHeight: verticalPadding * 2 + headerHeight + contentSpacing + listViewportHeight
    width: implicitWidth
    height: implicitHeight

    property string appName: ""
    property var windows: []
    property string previewStyle: "thumbnail"
    property real previewScale: 1.0
    property int popupDirection: Qt.BottomEdge
    property bool inPanel: false
    property int maxVisibleRows: 4
    property int maximumAvailableHeight: 640
    readonly property bool showLiveThumbnails: previewStyle === "thumbnail"
    readonly property bool containsMouse: popupHover.hovered
    readonly property real effectivePreviewScale: Math.max(0.5, Math.min(2.0, previewScale))
    readonly property int previewFrameWidth: Math.round(184 * effectivePreviewScale)
    readonly property int previewFrameHeight: Math.round(previewFrameWidth / 1.6)
    readonly property int horizontalPadding: 12
    readonly property int verticalPadding: 12
    readonly property int headerHeight: 28
    readonly property int contentSpacing: 8
    readonly property int cardHeight: previewFrameHeight + 54
    readonly property int listSpacing: 8
    readonly property int listContentHeight: windows.length > 0
        ? windows.length * cardHeight + (windows.length - 1) * listSpacing
        : 0
    readonly property int configuredRowsHeight: Math.max(1, Math.min(8, maxVisibleRows)) * cardHeight
        + (Math.max(1, Math.min(8, maxVisibleRows)) - 1) * listSpacing
    readonly property int availableListHeight: Math.max(cardHeight,
        maximumAvailableHeight - verticalPadding * 2 - headerHeight - contentSpacing)
    readonly property int listViewportHeight: Math.min(listContentHeight,
        configuredRowsHeight, availableListHeight)
    Layout.maximumHeight: maximumAvailableHeight

    signal activateRequested(int taskRow)
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

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: taskPopupRoot.headerHeight

            PlasmaExtras.ShadowedLabel {
                Layout.fillWidth: true
                text: taskPopupRoot.appName.length > 0 ? taskPopupRoot.appName : i18n("Open windows")
                font.bold: true
                elide: Text.ElideRight
            }

            Controls.ToolButton {
                icon.name: "window-close-symbolic"
                display: Controls.AbstractButton.IconOnly
                Accessible.name: i18n("Close window previews")
                onClicked: taskPopupRoot.closeRequested()
            }
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: taskPopupRoot.listViewportHeight
            clip: true
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
            Controls.ScrollBar.vertical.policy: taskPopupRoot.listContentHeight > taskPopupRoot.listViewportHeight
                ? Controls.ScrollBar.AsNeeded
                : Controls.ScrollBar.AlwaysOff

            ListView {
                id: windowList
                model: taskPopupRoot.windows
                spacing: taskPopupRoot.listSpacing

                delegate: Controls.ItemDelegate {
                    id: windowRow
                    required property var modelData
                    readonly property string primaryText: modelData.title || modelData.name || i18n("Window")
                    readonly property bool previewStreamActive: taskPopupRoot.visible
                        && taskPopupRoot.showLiveThumbnails
                        && (windowRow.y + windowRow.height >= windowList.contentY - 8)
                        && (windowRow.y <= windowList.contentY + windowList.height + 8)

                    width: windowList.width
                    height: taskPopupRoot.cardHeight
                    padding: 8
                    highlighted: !!modelData.active
                    Accessible.name: primaryText
                    Accessible.description: modelData.active ? i18n("Active window") : i18n("Activate window")
                    onClicked: taskPopupRoot.activateRequested(modelData.row)

                    background: Rectangle {
                        radius: 8
                        color: windowRow.hovered || windowRow.activeFocus || windowRow.modelData.active
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                Kirigami.Theme.highlightColor.g,
                                Kirigami.Theme.highlightColor.b,
                                windowRow.modelData.active ? 0.16 : 0.10)
                            : "transparent"
                        border.width: windowRow.activeFocus || windowRow.modelData.active ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                    }

                    contentItem: ColumnLayout {
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Kirigami.Icon {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                source: String(windowRow.modelData.icon || "window")
                            }

                            Controls.Label {
                                Layout.fillWidth: true
                                text: windowRow.primaryText
                                font.bold: !!windowRow.modelData.active
                                elide: Text.ElideRight
                            }

                            Controls.ToolButton {
                                id: closeWindowButton
                                visible: !!windowRow.modelData.closable
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                padding: 2
                                display: Controls.AbstractButton.IconOnly
                                icon.name: "window-close-symbolic"
                                focusPolicy: Qt.StrongFocus
                                Accessible.name: i18n("Close window")
                                background: Rectangle {
                                    radius: width / 2
                                    color: closeWindowButton.hovered || closeWindowButton.activeFocus
                                        ? Kirigami.Theme.negativeTextColor
                                        : "transparent"
                                    border.width: closeWindowButton.activeFocus ? 2 : 0
                                    border.color: Kirigami.Theme.textColor
                                }
                                onClicked: taskPopupRoot.closeWindowRequested(windowRow.modelData.row)
                            }
                        }

                        Item {
                            id: previewFrame
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: taskPopupRoot.previewFrameWidth
                            Layout.preferredHeight: taskPopupRoot.previewFrameHeight

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: Qt.rgba(0, 0, 0, 0.16)
                                border.width: 1
                                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                    Kirigami.Theme.textColor.g,
                                    Kirigami.Theme.textColor.b, 0.18)
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 5
                                color: Qt.rgba(Kirigami.Theme.alternateBackgroundColor.r,
                                    Kirigami.Theme.alternateBackgroundColor.g,
                                    Kirigami.Theme.alternateBackgroundColor.b, 0.72)
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

                            Loader {
                                id: pipewireLoader
                                anchors.fill: parent
                                active: windowRow.previewStreamActive
                                sourceComponent: liveThumbnailComponent
                            }

                            Component {
                                id: liveThumbnailComponent

                                WindowLiveThumbnail {
                                    anchors.fill: parent
                                    windowUuid: String(windowRow.modelData.windowUuid || "")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
