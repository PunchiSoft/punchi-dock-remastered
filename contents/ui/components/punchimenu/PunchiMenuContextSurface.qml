pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
// Importing PlasmaCore initializes Plasma theme resolution for FrameSvgItem.
// qmllint disable unused-imports
import org.kde.plasma.core as PlasmaCore
// qmllint enable unused-imports
import ".." as PunchiComponents

FocusScope {
    id: root

    property var entries: []
    property Item sourceItem: null
    property real requestedX: 0
    property real requestedY: 0
    property int currentIndex: -1
    property string targetKind: ""
    property string targetStorageId: ""
    property string targetAppCommand: ""
    property string targetAppName: ""
    property string targetAppIcon: ""
    property string targetContainingFolderId: ""
    property string targetFolderId: ""
    property bool targetIsFavorite: false
    property bool targetIsPinnedToDock: false
    property bool targetIsHidden: false
    property bool active: false

    readonly property real edgeMargin: Kirigami.Units.smallSpacing
    readonly property real preferredPanelWidth: Kirigami.Units.gridUnit * 18
    readonly property real availablePanelWidth: Math.max(0,
        width - edgeMargin * 2)

    signal actionTriggered(var entry)
    signal closeRequested(bool restoreFocus)
    signal focusFallbackRequested()

    visible: active
    enabled: active
    activeFocusOnTab: false
    Accessible.role: Accessible.PopupMenu
    Accessible.name: targetAppName

    function targetApplication() {
        return {
            appStorageId: targetStorageId,
            appName: targetAppName,
            appIcon: targetAppIcon
        }
    }

    // Menu surfaces share the dock popup renderer, so the entry contract grows
    // to the same shape: text/iconName stay for existing callers, while section,
    // children and checked enable native grouping and submenus.
    readonly property var popupActions: root.buildActionRows(root.entries)

    function buildActionRows(values) {
        const rows = []
        if (!(values instanceof Array)) {
            return rows
        }
        for (let index = 0; index < values.length; index++) {
            rows.push(root.buildActionRow(values[index]))
        }
        return rows
    }

    function buildActionRow(entry) {
        const source = entry || {}
        const row = {
            "name": String(source.text !== undefined ? source.text : (source.name || "")),
            "icon": String(source.iconName !== undefined ? source.iconName : (source.icon || "")),
            "enabled": source.enabled !== false,
            "source": source
        }
        if (source.separator === true || source.kind === "separator") {
            row.kind = "separator"
            row.enabled = false
            return row
        }
        if (source.section === true || source.kind === "section") {
            row.kind = "section"
            row.enabled = false
            return row
        }
        if (source.children instanceof Array && source.children.length > 0) {
            row.kind = "submenu"
            row.children = root.buildActionRows(source.children)
        } else {
            row.kind = String(source.kind || "action")
        }
        if (source.checked !== undefined) {
            row.checked = !!source.checked
        }
        if (source.exclusive === true) {
            row.exclusive = true
        }
        if (source.detail) {
            row.detail = String(source.detail)
        }
        return row
    }

    function entryFor(action) {
        return action && action.source ? action.source : action
    }

    function restoreSourceFocus(targetItem) {
        if (targetItem && targetItem.visible && targetItem.enabled) {
            targetItem.forceActiveFocus(Qt.OtherFocusReason)
            return
        }
        focusFallbackRequested()
    }

    function openAt(targetItem, localX, localY, menuEntries, context) {
        if (!targetItem || !menuEntries || menuEntries.length === 0) {
            return false
        }
        const mappedPoint = targetItem.mapToItem(root,
            Number(localX), Number(localY))
        sourceItem = targetItem
        requestedX = mappedPoint.x + Kirigami.Units.smallSpacing
        requestedY = mappedPoint.y + Kirigami.Units.smallSpacing
        currentIndex = -1
        entries = menuEntries
        targetKind = String(context && context.kind || "")
        targetStorageId = String(context && context.storageId || "")
        targetAppCommand = String(context && context.appCommand || "")
        targetAppName = String(context && context.appName || "")
        targetAppIcon = String(context && context.appIcon || "")
        targetContainingFolderId = String(
            context && context.containingFolderId || "")
        targetFolderId = String(context && context.folderId || "")
        targetIsFavorite = !!(context && context.isFavorite)
        targetIsPinnedToDock = !!(context && context.isPinnedToDock)
        targetIsHidden = !!(context && context.isHidden)
        active = true
        Qt.callLater(function() {
            if (root.active) {
                actionsPopup.takeKeyboardFocus()
            }
        })
        return true
    }

    function close(restoreFocus) {
        if (!active) {
            return
        }
        const focusTarget = sourceItem
        active = false
        currentIndex = -1
        entries = []
        sourceItem = null
        if (restoreFocus) {
            Qt.callLater(function() {
                root.restoreSourceFocus(focusTarget)
            })
        }
    }

    function triggerIndex(index) {
        if (!actionsPopup.activateActionAt(index)) {
            return
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true
        onClicked: function(mouse) {
            root.closeRequested(true)
            mouse.accepted = false
        }
    }

    Item {
        id: panel

        x: Math.max(root.edgeMargin, Math.min(root.requestedX,
            root.width - width - root.edgeMargin))
        y: Math.max(root.edgeMargin, Math.min(root.requestedY,
            root.height - height - root.edgeMargin))
        width: Math.min(actionsPopup.implicitWidth,
            root.availablePanelWidth)
        height: Math.min(Math.max(0,
            root.height - root.edgeMargin * 2),
            actionsPopup.implicitHeight)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onClicked: function(mouse) {
                mouse.accepted = true
            }
            onWheel: function(wheel) {
                wheel.accepted = true
            }
        }

        KSvg.FrameSvgItem {
            id: menuBackground
            anchors.fill: parent
            imagePath: "widgets/background"
            Accessible.ignored: true
        }

        PunchiComponents.AppActionsPopup {
            id: actionsPopup
            anchors.fill: parent
            actions: root.popupActions
            // PunchiMenu rows follow the native menu density instead of the
            // dock context menu defaults.
            rowHeight: Math.max(32, Math.round(Kirigami.Units.gridUnit * 1.5))
            iconSize: Kirigami.Units.iconSizes.small
            autoSize: true
            maximumAvailableWidth: root.availablePanelWidth
            maximumAvailableHeight: Math.max(0,
                root.height - root.edgeMargin * 2)
            surfaceMargins: ({
                "left": menuBackground.margins.left
                    + Kirigami.Units.smallSpacing,
                "top": menuBackground.margins.top
                    + Kirigami.Units.smallSpacing,
                "right": menuBackground.margins.right
                    + Kirigami.Units.smallSpacing,
                "bottom": menuBackground.margins.bottom
                    + Kirigami.Units.smallSpacing
            })
            onActionTriggered: function(action) {
                root.actionTriggered(root.entryFor(action))
            }
            onCloseRequested: root.closeRequested(true)
        }
    }

    Keys.priority: Keys.AfterItem
    Keys.onPressed: function(event) {
        if (!root.active) {
            return
        }
        if (event.key === Qt.Key_Escape) {
            if (actionsPopup.subMenuOpen) {
                actionsPopup.closeSubMenu()
            } else {
                root.closeRequested(true)
            }
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            actionsPopup.moveSelection(
                actionsPopup.currentActionIndex,
                event.key === Qt.Key_Up ? -1 : 1)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            const backwards = event.key === Qt.Key_Backtab
                || (event.modifiers & Qt.ShiftModifier)
            actionsPopup.moveSelection(
                actionsPopup.currentActionIndex,
                backwards ? -1 : 1)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Left) {
            if (actionsPopup.subMenuOpen) {
                actionsPopup.closeSubMenu()
                event.accepted = true
            }
            return
        }
        if (event.key === Qt.Key_Right) {
            actionsPopup.activateActionAt(
                actionsPopup.currentActionIndex)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            actionsPopup.activateActionAt(
                actionsPopup.currentActionIndex)
            event.accepted = true
        }
    }
}
