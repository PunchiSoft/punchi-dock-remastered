pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: appActionsRoot
    objectName: "appActionsRoot"

    // This content is rendered over a widgets/background popup surface. Keep
    // its palette independent from the panel so text follows the popup theme.
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

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
    property bool textShadowsEnabled: false
    property var subMenuActions: []
    property string subMenuTitle: ""
    readonly property bool subMenuOpen: subMenuActions instanceof Array
        && subMenuActions.length > 0
    readonly property var displayedActions: subMenuOpen
        ? subMenuActions
        : (actions || [])
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
        rowsAllowedByHeight, displayedActions.length > 0
            ? displayedActions.length : 1))
    readonly property int actionViewportHeight: visibleRows * effectiveRowHeight

    implicitWidth: Math.max(240, Math.min(520, Number(targetWidth || 360),
        Number(maximumAvailableWidth || 752)))
    implicitHeight: chromeHeight + actionViewportHeight
    width: implicitWidth
    height: implicitHeight

    signal actionTriggered(var action)
    signal closeRequested()

    function openSubMenu(action) {
        const children = action && action.children instanceof Array
            ? action.children : []
        if (children.length === 0) {
            return
        }
        subMenuTitle = String(action.name || "")
        subMenuActions = children
        actionList.positionViewAtBeginning()
        actionList.forceActiveFocus()
    }

    function closeSubMenu() {
        subMenuActions = []
        subMenuTitle = ""
        actionList.positionViewAtBeginning()
    }

    onActionsChanged: closeSubMenu()

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
                text: appActionsRoot.subMenuOpen
                    ? appActionsRoot.subMenuTitle
                    : (appActionsRoot.itemName.length > 0
                        ? appActionsRoot.itemName
                        : i18n("Application")) // qmllint disable unqualified
                color: Kirigami.Theme.textColor
                renderShadow: appActionsRoot.textShadowsEnabled
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
                    source: appActionsRoot.subMenuOpen || appActionsRoot.embedded
                        ? "go-previous" : "window-close"
                    color: Kirigami.Theme.textColor
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: appActionsRoot.subMenuOpen
                        ? i18n("Back to menu") // qmllint disable unqualified
                        : appActionsRoot.embedded
                        ? (appActionsRoot.returnToMedia
                            ? i18n("Back to media controls") // qmllint disable unqualified
                            : i18n("Back to window previews")) // qmllint disable unqualified
                        : i18n("Close") // qmllint disable unqualified
                    onClicked: {
                        if (appActionsRoot.subMenuOpen) {
                            appActionsRoot.closeSubMenu()
                        } else {
                            appActionsRoot.closeRequested()
                        }
                    }
                }
            }
        }

        Controls.ScrollView {
            id: actionScroll
            Layout.fillWidth: true
            Layout.fillHeight: appActionsRoot.embedded
            Layout.minimumHeight: appActionsRoot.actionViewportHeight
            Layout.preferredHeight: appActionsRoot.actionViewportHeight
            Layout.maximumHeight: appActionsRoot.actionViewportHeight
            Layout.leftMargin: 12
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: 12
            clip: true

            ListView {
                id: actionList
                objectName: "appActionsActionList"
                model: appActionsRoot.displayedActions
                implicitWidth: actionScroll.availableWidth
                width: actionScroll.availableWidth
                implicitHeight: contentHeight
                boundsBehavior: Flickable.StopAtBounds

                delegate: Controls.ItemDelegate {
                    id: actionDelegate
                    objectName: "appActionsActionDelegate"
                    required property var modelData
                    readonly property string actionText: modelData && modelData.name
                        ? modelData.name
                        : i18n("Custom action") // qmllint disable unqualified
                    readonly property string detailText: modelData && modelData.detail
                        ? String(modelData.detail)
                        : ""
                    readonly property bool hasChildren: !!modelData
                        && modelData.children instanceof Array
                        && modelData.children.length > 0

                    width: actionList.width
                    height: appActionsRoot.effectiveRowHeight
                    text: actionText
                    icon.name: modelData && modelData.icon ? modelData.icon : "system-run"
                    // qmllint disable unqualified
                    icon.width: appActionsRoot.effectiveIconSize
                    icon.height: appActionsRoot.effectiveIconSize
                    // qmllint enable unqualified
                    enabled: !!modelData && modelData.enabled !== false
                        && (String(modelData.kind || "").length > 0
                            || String(modelData.command || "").length > 0
                            || hasChildren)
                    checkable: !hasChildren && !!modelData
                        && modelData.checked !== undefined
                    checked: checkable && !!modelData.checked

                    onClicked: {
                        if (enabled) {
                            if (hasChildren) {
                                appActionsRoot.openSubMenu(modelData)
                            } else {
                                appActionsRoot.actionTriggered(modelData)
                            }
                        }
                    }

                    Keys.onLeftPressed: function(event) {
                        if (appActionsRoot.subMenuOpen) {
                            appActionsRoot.closeSubMenu()
                            event.accepted = true
                        }
                    }

                    Keys.onRightPressed: function(event) {
                        if (hasChildren) {
                            appActionsRoot.openSubMenu(modelData)
                            event.accepted = true
                        }
                    }

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        opacity: actionDelegate.enabled ? 1 : 0.45

                        Kirigami.Icon {
                            Layout.preferredWidth: appActionsRoot.effectiveIconSize
                            Layout.preferredHeight: appActionsRoot.effectiveIconSize
                            source: actionDelegate.icon.name
                        }

                        PlasmaExtras.ShadowedLabel {
                            Layout.fillWidth: true
                            text: actionDelegate.actionText
                            color: Kirigami.Theme.textColor
                            renderShadow: appActionsRoot.textShadowsEnabled
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }

                        PlasmaExtras.ShadowedLabel {
                            Layout.preferredWidth: Math.max(0,
                                actionDelegate.width * 0.34)
                            visible: actionDelegate.detailText.length > 0
                            text: actionDelegate.detailText
                            color: Kirigami.Theme.textColor
                            renderShadow: appActionsRoot.textShadowsEnabled
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Math.max(8,
                                Kirigami.Theme.smallFont.pointSize)
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            opacity: 0.68
                            horizontalAlignment: Text.AlignRight
                        }

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            visible: actionDelegate.hasChildren
                            source: "go-next"
                            Accessible.ignored: true
                        }
                    }
                }
            }
        }
    }
}
