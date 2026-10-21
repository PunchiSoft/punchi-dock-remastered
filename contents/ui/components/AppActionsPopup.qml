pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Item {
    id: appActionsRoot
    objectName: "appActionsRoot"

    // This content is rendered over a widgets/background popup surface. Keep
    // its palette independent from the panel so text follows the popup theme.
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    property string itemName: ""
    property var actions: []
    // Zero follows Plasma's available-height behavior; positive values are a
    // user-selected cap for the number of action rows.
    property int maxVisibleRows: 0
    property int rowHeight: 46
    property int iconSize: 26
    property int targetWidth: 360
    property bool autoSize: false
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    property real minimumAnchorWidth: 0
    property var surfaceMargins: null
    property bool embedded: false
    property bool returnToMedia: false
    property bool textShadowsEnabled: false
    property var subMenuActions: []
    property string subMenuTitle: ""
    property var subMenuStack: []
    readonly property bool subMenuOpen: subMenuActions instanceof Array
        && subMenuActions.length > 0
    readonly property bool hasCheckableActions: {
        for (let index = 0; index < displayedActions.length; index++) {
            const action = displayedActions[index]
            if (action && action.checked !== undefined
                    && action.kind !== "separator"
                    && action.kind !== "section") {
                return true
            }
        }
        return false
    }
    readonly property var displayedActions: {
        const rows = subMenuOpen ? subMenuActions : (actions || [])
        if (subMenuOpen || embedded) {
            // qmllint disable unqualified
            const backLabel = subMenuOpen
                ? i18n("Back to menu")
                : returnToMedia
                    ? i18n("Back to media controls")
                    : i18n("Back to window previews")
            // qmllint enable unqualified
            return [{
                "name": backLabel,
                "icon": "go-previous",
                "kind": "back",
                "enabled": true
            }].concat(rows)
        }
        return rows
    }
    readonly property int automaticIconSize: Kirigami.Units.iconSizes.small
    readonly property int effectiveRowHeight: Math.max(32, Math.min(64,
        autoSize
            ? Math.max(Math.ceil(Kirigami.Units.gridUnit * 1.8),
                automaticIconSize + Kirigami.Units.smallSpacing * 2)
            : Number(rowHeight || 46)))
    readonly property int effectiveIconSize: autoSize
        ? automaticIconSize
        : Math.max(16, Math.min(40, Number(iconSize || 26)))
    readonly property int separatorRowHeight: Math.max(8,
        Kirigami.Units.smallSpacing * 2 + 1)
    // QMenu section headings sit slightly tighter than an action row so the
    // grouping reads as a label, not as another command.
    readonly property int sectionRowHeight: Math.max(
        Math.ceil(sectionTextMetrics.height) + Kirigami.Units.smallSpacing * 2,
        Math.ceil(Kirigami.Units.gridUnit * 1.4))
    readonly property real chromeHeight: effectiveSurfaceMarginTop
        + effectiveSurfaceMarginBottom
    readonly property real effectiveSurfaceMarginLeft: surfaceMargins
        && Number.isFinite(Number(surfaceMargins.left))
        ? Math.max(0, Number(surfaceMargins.left)) : Kirigami.Units.smallSpacing
    readonly property real effectiveSurfaceMarginTop: surfaceMargins
        && Number.isFinite(Number(surfaceMargins.top))
        ? Math.max(0, Number(surfaceMargins.top)) : Kirigami.Units.smallSpacing
    readonly property real effectiveSurfaceMarginRight: surfaceMargins
        && Number.isFinite(Number(surfaceMargins.right))
        ? Math.max(0, Number(surfaceMargins.right)) : Kirigami.Units.smallSpacing
    readonly property real effectiveSurfaceMarginBottom: surfaceMargins
        && Number.isFinite(Number(surfaceMargins.bottom))
        ? Math.max(0, Number(surfaceMargins.bottom)) : Kirigami.Units.smallSpacing
    readonly property int displayedActionCount: {
        let count = 0
        for (let index = 0; index < displayedActions.length; index++) {
            const kind = displayedActions[index] ? displayedActions[index].kind : ""
            if (!displayedActions[index] || (kind !== "separator"
                    && kind !== "section")) {
                count++
            }
        }
        return count
    }
    readonly property int rowsAllowedByHeight: maximumAvailableHeight > chromeHeight
        ? actionCapacityForHeight(maximumAvailableHeight - chromeHeight)
        : 1
    readonly property int effectiveMaximumVisibleRows: maxVisibleRows > 0
        ? Math.max(1, Math.min(15, maxVisibleRows))
        : displayedActionCount
    readonly property int visibleRows: Math.max(1, Math.min(
        effectiveMaximumVisibleRows, rowsAllowedByHeight,
        displayedActionCount > 0 ? displayedActionCount : 1))
    readonly property int actionViewportHeight: viewportHeightForRows(visibleRows)
    // Task Manager derives its minimum width from the visual parent. Punchi
    // also keeps a theme-scaled floor close to the native menu's natural width.
    readonly property int minimumMenuWidth: Math.min(
        Math.max(1, Number(maximumAvailableWidth || 752)),
        Math.max(Kirigami.Units.gridUnit * 18,
            Number(minimumAnchorWidth || 0)))
    readonly property int automaticWidth: {
        let widestAction = 0
        for (let index = 0; index < actionWidthMeasurements.count; index++) {
            const measurement = actionWidthMeasurements.objectAt(index)
            if (measurement) {
                widestAction = Math.max(widestAction,
                    // qmllint disable missing-property
                    // Instantiator.objectAt() returns QObject; its delegate exposes naturalWidth.
                    Number(measurement["naturalWidth"] || 0))
                    // qmllint enable missing-property
            }
        }
        const availableWidth = Math.max(1,
            Number(maximumAvailableWidth || 752))
        return Math.min(availableWidth, Math.max(minimumMenuWidth,
            Math.ceil(widestAction + effectiveSurfaceMarginLeft
                + effectiveSurfaceMarginRight)))
    }

    implicitWidth: autoSize ? automaticWidth
        : Math.min(Math.max(1, Number(maximumAvailableWidth || 752)),
            Math.max(minimumMenuWidth, 240,
                Math.min(520, Number(targetWidth || 360))))
    implicitHeight: chromeHeight + actionViewportHeight
    width: implicitWidth
    height: implicitHeight

    signal actionTriggered(var action)
    signal closeRequested()

    KSvg.FrameSvgItem {
        id: menuItemPaddingMetrics
        imagePath: "widgets/viewitem"
        prefix: "hover"
        width: 0
        height: 0
        visible: false
        Accessible.ignored: true
    }

    function actionCapacityForHeight(availableHeight) {
        let visibleActionCount = 0
        let usedHeight = 0
        const actionLimit = maxVisibleRows > 0
            ? Math.max(1, Math.min(15, maxVisibleRows))
            : displayedActionCount
        for (let index = 0; index < displayedActions.length; index++) {
            const action = displayedActions[index]
            if (action && action.kind === "separator") {
                if (visibleActionCount > 0 && visibleActionCount < actionLimit
                        && usedHeight + separatorRowHeight <= availableHeight) {
                    usedHeight += separatorRowHeight
                }
                continue
            }
            if (action && action.kind === "section") {
                if (visibleActionCount < actionLimit
                        && usedHeight + sectionRowHeight <= availableHeight) {
                    usedHeight += sectionRowHeight
                }
                continue
            }
            if (visibleActionCount >= actionLimit
                    || usedHeight + effectiveRowHeight > availableHeight) {
                break
            }
            usedHeight += effectiveRowHeight
            visibleActionCount++
        }
        return Math.max(1, visibleActionCount)
    }

    function viewportHeightForRows(actionRows) {
        let visibleActionCount = 0
        let usedHeight = 0
        for (let index = 0; index < displayedActions.length; index++) {
            const action = displayedActions[index]
            if (action && action.kind === "separator") {
                if (visibleActionCount > 0 && visibleActionCount < actionRows) {
                    usedHeight += separatorRowHeight
                }
                continue
            }
            if (action && action.kind === "section") {
                if (visibleActionCount < actionRows) {
                    usedHeight += sectionRowHeight
                }
                continue
            }
            if (visibleActionCount >= actionRows) {
                break
            }
            usedHeight += effectiveRowHeight
            visibleActionCount++
        }
        return Math.max(effectiveRowHeight, usedHeight)
    }

    function openSubMenu(action) {
        const children = action && action.children instanceof Array
            ? action.children : []
        if (children.length === 0) {
            return
        }
        // Keep every level so Places can return to its group list before the
        // root menu. The root state is represented by an empty title/actions.
        subMenuStack = subMenuStack.concat([{
            "title": subMenuTitle,
            "actions": subMenuActions
        }])
        subMenuTitle = String(action.name || "")
        subMenuActions = children
        actionList.positionViewAtBeginning()
        actionList.forceActiveFocus()
    }

    function closeSubMenu() {
        if (subMenuStack.length > 0) {
            const stack = subMenuStack.slice()
            const previous = stack.pop()
            subMenuStack = stack
            subMenuTitle = String(previous.title || "")
            subMenuActions = previous.actions instanceof Array
                ? previous.actions : []
            actionList.positionViewAtBeginning()
            actionList.forceActiveFocus()
            return
        }
        resetSubMenu()
    }

    function resetSubMenu() {
        subMenuStack = []
        subMenuActions = []
        subMenuTitle = ""
        actionList.positionViewAtBeginning()
    }

    function selectableAction(action) {
        return !!action && action.kind !== "separator"
            && action.kind !== "section"
    }

    function moveSelection(fromIndex, delta) {
        let index = fromIndex + delta
        while (index >= 0 && index < displayedActions.length) {
            if (selectableAction(displayedActions[index])) {
                actionList.currentIndex = index
                const item = actionList.itemAtIndex(index)
                if (item) {
                    item.forceActiveFocus()
                }
                actionList.positionViewAtIndex(index, ListView.Contain)
                return
            }
            index += delta
        }
    }

    TextMetrics {
        id: sectionTextMetrics
        font.family: Kirigami.Theme.defaultFont.family
        font.pointSize: Kirigami.Theme.defaultFont.pointSize
        font.weight: Font.DemiBold
        text: "Ag"
    }

    onActionsChanged: resetSubMenu()

    Instantiator {
        id: actionWidthMeasurements
        model: appActionsRoot.displayedActions

        delegate: Item {
            id: actionWidthMeasurement
            required property var modelData
            visible: false
            width: 0
            height: 0

            readonly property bool isSection: !!modelData
                && modelData.kind === "section"
            readonly property real naturalWidth: isSection
                ? (appActionsRoot.hasCheckableActions
                    ? Kirigami.Units.iconSizes.small
                    : Kirigami.Units.smallSpacing)
                    + sectionWidthMetrics.advanceWidth
                    + Kirigami.Units.largeSpacing * 2
                    + Kirigami.Units.smallSpacing * 2
                : (appActionsRoot.hasCheckableActions
                    ? Kirigami.Units.iconSizes.small
                    : Kirigami.Units.smallSpacing)
                    + appActionsRoot.effectiveIconSize
                    + mainTextMetrics.advanceWidth
                    + (detailTextMetrics.text.length > 0
                        ? detailTextMetrics.advanceWidth + Kirigami.Units.largeSpacing
                        : 0)
                    + (modelData && modelData.children instanceof Array
                        && modelData.children.length > 0
                        ? Kirigami.Units.iconSizes.small + Kirigami.Units.largeSpacing
                        : 0)
                    + Kirigami.Units.largeSpacing * 2
                    + Kirigami.Units.smallSpacing * 2

            TextMetrics {
                id: mainTextMetrics
                font: Kirigami.Theme.defaultFont
                text: actionWidthMeasurement.modelData
                    && actionWidthMeasurement.modelData.name
                    ? String(actionWidthMeasurement.modelData.name) : ""
            }

            TextMetrics {
                id: sectionWidthMetrics
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.DemiBold
                text: actionWidthMeasurement.isSection
                    && actionWidthMeasurement.modelData
                    ? String(actionWidthMeasurement.modelData.name || "") : ""
            }

            TextMetrics {
                id: detailTextMetrics
                font: Kirigami.Theme.smallFont
                text: actionWidthMeasurement.modelData
                    && !(actionWidthMeasurement.modelData.children instanceof Array
                        && actionWidthMeasurement.modelData.children.length > 0)
                    && actionWidthMeasurement.modelData.detail
                    ? String(actionWidthMeasurement.modelData.detail) : ""
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Controls.ScrollView {
            id: actionScroll
            Layout.fillWidth: true
            Layout.fillHeight: appActionsRoot.embedded
            Layout.minimumHeight: appActionsRoot.actionViewportHeight
            Layout.preferredHeight: appActionsRoot.actionViewportHeight
            Layout.maximumHeight: appActionsRoot.actionViewportHeight
            Layout.leftMargin: appActionsRoot.effectiveSurfaceMarginLeft
            Layout.rightMargin: appActionsRoot.effectiveSurfaceMarginRight
            Layout.topMargin: appActionsRoot.effectiveSurfaceMarginTop
            Layout.bottomMargin: appActionsRoot.effectiveSurfaceMarginBottom
            clip: true

            ListView {
                id: actionList
                objectName: "appActionsActionList"
                model: appActionsRoot.displayedActions
                implicitWidth: actionScroll.availableWidth
                width: actionScroll.availableWidth
                implicitHeight: contentHeight
                boundsBehavior: Flickable.StopAtBounds

                Keys.onUpPressed: function(event) {
                    appActionsRoot.moveSelection(
                        actionList.currentIndex < 0 ? 0 : actionList.currentIndex, -1)
                    event.accepted = true
                }

                Keys.onDownPressed: function(event) {
                    appActionsRoot.moveSelection(
                        actionList.currentIndex < 0 ? -1 : actionList.currentIndex, 1)
                    event.accepted = true
                }

                delegate: PlasmaComponents.MenuItem {
                    id: actionDelegate
                    objectName: "appActionsActionDelegate"
                    required property var modelData
                    required property int index
                    readonly property string actionText: modelData && modelData.name
                        ? modelData.name
                        : i18n("Custom action") // qmllint disable unqualified
                    readonly property string detailText: modelData && modelData.detail
                        && !hasChildren
                        ? String(modelData.detail)
                        : ""
                    readonly property bool hasChildren: !!modelData
                        && modelData.children instanceof Array
                        && modelData.children.length > 0
                    readonly property bool isSeparator: !!modelData
                        && modelData.kind === "separator"
                    readonly property bool isSection: !!modelData
                        && modelData.kind === "section"
                    Accessible.ignored: isSeparator || isSection

                    width: actionList.width
                    height: isSection
                        ? appActionsRoot.sectionRowHeight
                        : isSeparator
                            ? appActionsRoot.separatorRowHeight
                            : appActionsRoot.effectiveRowHeight
                    text: actionText
                    icon.name: !isSection && modelData && modelData.icon
                        ? modelData.icon : ""
                    // qmllint disable unqualified
                    icon.width: appActionsRoot.effectiveIconSize
                    icon.height: appActionsRoot.effectiveIconSize
                    // qmllint enable unqualified
                    enabled: !isSeparator && !isSection && !!modelData
                        && modelData.enabled !== false
                        && (String(modelData.kind || "").length > 0
                            || String(modelData.command || "").length > 0
                            || hasChildren)
                    checkable: !hasChildren && !!modelData
                        && modelData.checked !== undefined
                    checked: checkable && !!modelData.checked
                    autoExclusive: checkable && modelData.exclusive === true
                    leftPadding: menuItemPaddingMetrics.margins.left
                    rightPadding: menuItemPaddingMetrics.margins.right
                    topPadding: menuItemPaddingMetrics.margins.top
                    bottomPadding: menuItemPaddingMetrics.margins.bottom
                    onClicked: {
                        if (enabled) {
                            if (modelData.kind === "back") {
                                if (appActionsRoot.subMenuOpen) {
                                    appActionsRoot.closeSubMenu()
                                } else {
                                    appActionsRoot.closeRequested()
                                }
                            } else if (hasChildren) {
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
                        } else if (actionDelegate.modelData.kind === "back") {
                            appActionsRoot.closeRequested()
                            event.accepted = true
                        }
                    }

                    Keys.onRightPressed: function(event) {
                        if (hasChildren) {
                            appActionsRoot.openSubMenu(modelData)
                            event.accepted = true
                        }
                    }

                    Keys.onUpPressed: function(event) {
                        appActionsRoot.moveSelection(index, -1)
                        event.accepted = true
                    }

                    Keys.onDownPressed: function(event) {
                        appActionsRoot.moveSelection(index, 1)
                        event.accepted = true
                    }

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        opacity: actionDelegate.enabled || actionDelegate.isSection
                            ? 1 : 0.45
                        visible: !actionDelegate.isSeparator

                        Item {
                            Layout.preferredWidth: appActionsRoot.hasCheckableActions
                                ? Kirigami.Units.iconSizes.small
                                : Kirigami.Units.smallSpacing
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }

                        Kirigami.Icon {
                            Layout.preferredWidth: appActionsRoot.effectiveIconSize
                            Layout.preferredHeight: appActionsRoot.effectiveIconSize
                            visible: !actionDelegate.isSection
                            source: actionDelegate.icon.name
                        }

                        PlasmaExtras.ShadowedLabel {
                            Layout.fillWidth: true
                            text: actionDelegate.actionText
                            color: Kirigami.Theme.textColor
                            renderShadow: appActionsRoot.textShadowsEnabled
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.bold: actionDelegate.isSection
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }

                        PlasmaExtras.ShadowedLabel {
                            Layout.preferredWidth: appActionsRoot.autoSize
                                ? Math.min(actionDetailMetrics.advanceWidth,
                                    actionDelegate.width * 0.5)
                                : Math.max(0, actionDelegate.width * 0.34)
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

                    background: Item {
                        InteractiveActionBackground {
                            anchors.fill: parent
                            anchors.leftMargin: actionDelegate.leftPadding
                            anchors.rightMargin: actionDelegate.rightPadding
                            anchors.topMargin: actionDelegate.topPadding
                            anchors.bottomMargin: actionDelegate.bottomPadding
                            visible: !actionDelegate.isSeparator
                                && !actionDelegate.isSection
                            hovered: actionDelegate.hovered
                            focused: actionDelegate.visualFocus
                            pressed: actionDelegate.down
                            visualRadius: height / 2
                        }

                        Rectangle {
                            visible: actionDelegate.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Kirigami.Units.largeSpacing
                            anchors.rightMargin: Kirigami.Units.largeSpacing
                            height: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.2
                        }

                        // QMenu draws the section divider as part of the
                        // heading, so no explicit separator row is needed.
                        Rectangle {
                            visible: actionDelegate.isSection
                                && actionDelegate.index > 0
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Kirigami.Units.largeSpacing
                            anchors.rightMargin: Kirigami.Units.largeSpacing
                            height: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.2
                        }
                    }

                    TextMetrics {
                        id: actionDetailMetrics
                        font: Kirigami.Theme.smallFont
                        text: actionDelegate.detailText
                    }
                }
            }
        }
    }
}
