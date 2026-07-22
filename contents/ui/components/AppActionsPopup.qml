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
    property int rowHeight: 46
    property int iconSize: 26
    property int targetWidth: 360
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    property bool embedded: false
    property bool returnToMedia: false
    readonly property int effectiveRowHeight: Math.max(32, Math.min(64,
        Number(rowHeight || 46)))
    readonly property int effectiveIconSize: Math.max(16, Math.min(40,
        Number(iconSize || 26)))
    readonly property int chromeHeight: 80
    readonly property int rowsAllowedByHeight: maximumAvailableHeight > chromeHeight
        ? Math.max(1, Math.floor((maximumAvailableHeight - chromeHeight)
            / effectiveRowHeight))
        : 1
    readonly property int visibleRows: Math.max(1, Math.min(maxVisibleRows,
        rowsAllowedByHeight, actions.length > 0 ? actions.length : 1))

    implicitWidth: Math.max(240, Math.min(520, Number(targetWidth || 360),
        Number(maximumAvailableWidth || 752)))
    implicitHeight: chromeHeight + (visibleRows * effectiveRowHeight)
    width: implicitWidth
    height: implicitHeight

    signal actionTriggered(var action)
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 12

            PlasmaExtras.ShadowedLabel {
                Layout.fillWidth: true
                text: appActionsRoot.itemName.length > 0 ? appActionsRoot.itemName : i18n("Application")
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
            }

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
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
                        ? (appActionsRoot.returnToMedia
                            ? i18n("Back to media controls")
                            : i18n("Back to window previews"))
                        : i18n("Close")
                    onClicked: appActionsRoot.closeRequested()
                }
            }
        }

        Controls.ScrollView {
            id: actionScroll
            Layout.fillWidth: true
            Layout.fillHeight: appActionsRoot.embedded
            Layout.preferredHeight: appActionsRoot.visibleRows
                * appActionsRoot.effectiveRowHeight
            Layout.leftMargin: 12
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: 12
            clip: true

            ListView {
                id: actionList
                model: appActionsRoot.actions || []
                implicitWidth: actionScroll.availableWidth
                width: actionScroll.availableWidth
                implicitHeight: contentHeight
                boundsBehavior: Flickable.StopAtBounds

                delegate: Controls.ItemDelegate {
                    id: actionDelegate
                    required property var modelData

                    width: actionList.width
                    height: appActionsRoot.effectiveRowHeight
                    text: modelData && modelData.name ? modelData.name : i18n("Custom action")
                    icon.name: modelData && modelData.icon ? modelData.icon : "system-run"
                    // qmllint disable unqualified
                    icon.width: appActionsRoot.effectiveIconSize
                    icon.height: appActionsRoot.effectiveIconSize
                    // qmllint enable unqualified
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
