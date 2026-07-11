import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
Item {
    id: taskPopupRoot
    width: 420
    height: Math.max(160, Math.min(420, contentLayout.implicitHeight + 24))
    implicitWidth: width
    implicitHeight: height

    property string appName: ""
    property var windows: []
    property string previewStyle: "thumbnail"
    readonly property bool showLiveThumbnails: previewStyle === "thumbnail"
    readonly property bool containsMouse: popupHover.hovered

    signal activateRequested(int taskRow)
    signal closeWindowRequested(int taskRow)
    signal closeRequested()

    HoverHandler {
        id: popupHover
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            PlasmaExtras.ShadowedLabel {
                Layout.fillWidth: true
                text: taskPopupRoot.appName.length > 0 ? taskPopupRoot.appName : i18n("Open windows")
                font.bold: true
                elide: Text.ElideRight
            }

            Controls.ToolButton {
                icon.name: "window-close-symbolic"
                display: Controls.AbstractButton.IconOnly
                onClicked: taskPopupRoot.closeRequested()
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            visible: taskPopupRoot.windows.length > 1
            text: i18n("%1 windows detected", taskPopupRoot.windows.length)
            color: Kirigami.Theme.disabledTextColor
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: windowList
                model: taskPopupRoot.windows
                spacing: 8

                delegate: RowLayout {
                    id: windowRow
                    required property var modelData
                    readonly property string primaryText: modelData.title || modelData.name || i18n("Window")
                    readonly property string secondaryText: modelData.subtitle || modelData.name || ""
                    readonly property bool previewStreamActive: taskPopupRoot.visible
                        && taskPopupRoot.showLiveThumbnails
                        && (windowRow.y + windowRow.height >= windowList.contentY - 8)
                        && (windowRow.y <= windowList.contentY + windowList.height + 8)

                    width: windowList.width
                    spacing: 8

                    Controls.ItemDelegate {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 116
                        padding: 10
                        highlighted: !!modelData.active
                        onClicked: taskPopupRoot.activateRequested(modelData.row)

                        background: Rectangle {
                            radius: 10
                            color: windowRow.modelData.active
                                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.16)
                                : Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.42)
                            border.width: windowRow.modelData.active ? 1 : 0
                            border.color: windowRow.modelData.active ? Kirigami.Theme.highlightColor : "transparent"
                        }

                        contentItem: RowLayout {
                            spacing: 10

                            Item {
                                Layout.preferredWidth: 148
                                Layout.preferredHeight: 92

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: Qt.rgba(0, 0, 0, 0.16)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.08)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: 7
                                    color: Qt.rgba(Kirigami.Theme.alternateBackgroundColor.r,
                                        Kirigami.Theme.alternateBackgroundColor.g,
                                        Kirigami.Theme.alternateBackgroundColor.b, 0.72)
                                }

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    spacing: 6
                                    // Ocultar si PipeWire logró conectar y está mostrando imagen
                                    visible: !(pipewireLoader.item && pipewireLoader.item.hasThumbnail)

                                    Kirigami.Icon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 28
                                        height: 28
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

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: primaryText
                                    font.bold: !!modelData.active
                                    elide: Text.ElideRight
                                }

                                Controls.Label {
                                    Layout.fillWidth: true
                                    visible: secondaryText.length > 0 && secondaryText !== primaryText
                                    text: secondaryText
                                    color: Kirigami.Theme.disabledTextColor
                                    elide: Text.ElideRight
                                }

                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: modelData.active ? i18n("Active window") : i18n("Click to focus")
                                    color: modelData.active ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                    elide: Text.ElideRight
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    Controls.ToolButton {
                        visible: !!modelData.closable
                        icon.name: "window-close-symbolic"
                        display: Controls.AbstractButton.IconOnly
                        Accessible.name: i18n("Close window")
                        onClicked: taskPopupRoot.closeWindowRequested(modelData.row)
                    }
                }
            }
        }
    }
}
