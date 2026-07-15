import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: appActionsRoot

    property string itemName: ""
    property var actions: []
    property int maxVisibleRows: 6
    property bool embedded: false
    readonly property int rowHeight: 40
    readonly property int visibleRows: Math.max(1, Math.min(maxVisibleRows, actions.length > 0 ? actions.length : 1))

    implicitWidth: 280
    implicitHeight: 64 + 16 + (visibleRows * rowHeight)
    width: implicitWidth
    height: implicitHeight

    signal actionTriggered(var action)
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            PlasmaExtras.ShadowedLabel {
                Layout.fillWidth: true
                text: appActionsRoot.itemName.length > 0 ? appActionsRoot.itemName : i18n("Application")
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
            }

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: closeMouse.containsMouse || closeMouse.activeFocus
                    ? Kirigami.Theme.negativeTextColor
                    : Kirigami.Theme.backgroundColor

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: appActionsRoot.embedded ? "go-previous" : "window-close"
                    color: Kirigami.Theme.textColor
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: appActionsRoot.embedded
                        ? i18n("Back to window previews")
                        : i18n("Close")
                    onClicked: appActionsRoot.closeRequested()
                }
            }
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: appActionsRoot.embedded
            Layout.preferredHeight: appActionsRoot.visibleRows * appActionsRoot.rowHeight
            clip: true

            ListView {
                id: actionList
                model: appActionsRoot.actions || []
                implicitWidth: appActionsRoot.implicitWidth - 24
                implicitHeight: contentHeight
                boundsBehavior: Flickable.StopAtBounds

                delegate: Controls.ItemDelegate {
                    id: actionDelegate
                    required property var modelData

                    width: actionList.width
                    height: appActionsRoot.rowHeight
                    text: modelData && modelData.name ? modelData.name : i18n("Custom action")
                    icon.name: modelData && modelData.icon ? modelData.icon : "system-run"
                    enabled: !!modelData && modelData.enabled !== false
                        && (String(modelData.kind || "").length > 0
                            || String(modelData.command || "").length > 0)
                    checkable: !!modelData && modelData.checked !== undefined
                    checked: checkable && !!modelData.checked

                    onClicked: {
                        if (enabled) {
                            appActionsRoot.actionTriggered(modelData)
                        }
                    }

                    Controls.Label {
                        anchors.right: parent.right
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.42
                        visible: text.length > 0
                        text: actionDelegate.modelData && actionDelegate.modelData.detail
                            ? String(actionDelegate.modelData.detail)
                            : ""
                        elide: Text.ElideRight
                        opacity: 0.68
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
