pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents
// Importing PlasmaCore initializes Plasma theme resolution for FrameSvgItem.
// qmllint disable unused-imports
import org.kde.plasma.core as PlasmaCore
// qmllint enable unused-imports

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

    signal actionTriggered(string actionId)
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

    function isActionable(index) {
        if (index < 0 || index >= entries.length) {
            return false
        }
        const entry = entries[index]
        return entry && entry.separator !== true && entry.enabled !== false
    }

    function firstActionableIndex() {
        for (let index = 0; index < entries.length; index++) {
            if (isActionable(index)) {
                return index
            }
        }
        return -1
    }

    function adjacentActionableIndex(direction) {
        if (entries.length === 0) {
            return -1
        }
        let candidate = currentIndex
        for (let offset = 0; offset < entries.length; offset++) {
            candidate = (candidate + direction + entries.length)
                % entries.length
            if (isActionable(candidate)) {
                return candidate
            }
        }
        return -1
    }

    function focusEntry(index) {
        if (!isActionable(index)) {
            return false
        }
        currentIndex = index
        forceActiveFocus(Qt.TabFocusReason)
        return true
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
        currentIndex = firstActionableIndex()
        active = true
        Qt.callLater(function() {
            if (root.active && !root.focusEntry(root.currentIndex)) {
                root.forceActiveFocus(Qt.PopupFocusReason)
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
        if (!isActionable(index)) {
            return
        }
        const entry = entries[index]
        actionTriggered(String(entry.actionId || ""))
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

        readonly property real frameVerticalMargins:
            menuBackground.margins.top + menuBackground.margins.bottom

        x: Math.max(root.edgeMargin, Math.min(root.requestedX,
            root.width - width - root.edgeMargin))
        y: Math.max(root.edgeMargin, Math.min(root.requestedY,
            root.height - height - root.edgeMargin))
        width: Math.min(root.preferredPanelWidth,
            root.availablePanelWidth)
        height: Math.min(Math.max(0,
            root.height - root.edgeMargin * 2),
            menuColumn.implicitHeight + frameVerticalMargins
                + Kirigami.Units.smallSpacing * 2)

        KSvg.FrameSvgItem {
            id: menuBackground
            anchors.fill: parent
            imagePath: "widgets/background"
        }

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

        Column {
            id: menuColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: menuBackground.margins.left
                + Kirigami.Units.smallSpacing
            anchors.rightMargin: menuBackground.margins.right
                + Kirigami.Units.smallSpacing
            anchors.topMargin: menuBackground.margins.top
                + Kirigami.Units.smallSpacing

            Repeater {
                id: menuRepeater
                model: root.entries

                delegate: Loader {
                    id: rowLoader

                    required property int index
                    required property var modelData

                    width: menuColumn.width
                    sourceComponent: modelData.separator === true
                        ? separatorComponent : actionComponent

                    onLoaded: {
                        if (!item) {
                            return
                        }
                        item.menuEntry = modelData
                        item.menuEntryIndex = index
                    }
                }
            }
        }
    }

    Component {
        id: actionComponent

        PlasmaComponents.MenuItem {
            id: menuItem

            property var menuEntry: ({})
            property int menuEntryIndex: -1

            width: menuColumn.width
            text: String(menuEntry.text || "")
            icon.name: String(menuEntry.iconName || "")
            enabled: menuEntry.enabled !== false
            highlighted: root.currentIndex === menuEntryIndex
            Accessible.name: text
            onHoveredChanged: {
                if (hovered && enabled) {
                    root.currentIndex = menuEntryIndex
                }
            }
            onClicked: root.triggerIndex(menuEntryIndex)

            HoverHandler {
                cursorShape: menuItem.enabled
                    ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    Component {
        id: separatorComponent

        PlasmaComponents.MenuSeparator {
            property var menuEntry: ({})
            property int menuEntryIndex: -1
            width: menuColumn.width
        }
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function(event) {
        if (!root.active) {
            return
        }
        if (event.key === Qt.Key_Escape) {
            root.closeRequested(true)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Up) {
            root.focusEntry(root.adjacentActionableIndex(-1))
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Down) {
            root.focusEntry(root.adjacentActionableIndex(1))
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            const backwards = event.key === Qt.Key_Backtab
                || (event.modifiers & Qt.ShiftModifier)
            root.focusEntry(root.adjacentActionableIndex(backwards ? -1 : 1))
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.triggerIndex(root.currentIndex)
            event.accepted = true
        }
    }
}
