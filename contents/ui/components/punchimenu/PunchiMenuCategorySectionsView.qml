import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    property var categoryGroups: []
    property var folderNodes: []
    property bool showApplicationLabels: true
    property bool motionEnabled: true
    property bool hoverEnabled: true
    property string hoverAnimation: "pulse"
    property real iconScale: 1.0
    property real baseIconSize: Kirigami.Units.iconSizes.huge
    property int selectedSectionIndex: -1
    property int selectedItemIndex: -1

    property bool isDragActive: false
    property string dragSourceNodeId: ""
    property bool isDragFolder: false
    property string dragKey: "application/x-punchi-dock-node"
    property bool suppressDragReleaseClick: false

    readonly property real effectiveIconScale: Math.max(0.75,
        Math.min(1.5, Number(iconScale || 1.0)))
    readonly property real scrollBarReserve: sectionScrollBar.visible
        ? sectionScrollBar.implicitWidth + Kirigami.Units.smallSpacing : 0
    readonly property real availableWidth: Math.max(1,
        sectionList.width - scrollBarReserve)
    readonly property int targetCellWidth: Math.round(
        Kirigami.Units.gridUnit * 7)
    readonly property int columnCount: Math.max(4, Math.min(8,
        Math.floor(availableWidth / targetCellWidth)))
    readonly property int cellWidth: Math.max(1,
        Math.floor(availableWidth / columnCount))
    readonly property int iconSize: iconMetrics.effectiveSize
    readonly property int applicationLabelHeight: showApplicationLabels
        ? Math.ceil(applicationLabelFontMetrics.height * 2) : 0
    readonly property int cellHeight: Math.ceil(iconSize
        + applicationLabelHeight + Kirigami.Units.smallSpacing * 5)
    readonly property var sections: {
        const result = []
        const folders = folderNodes || []
        if (folders.length > 0) {
            result.push({
                categoryId: "Folders",
                folderSection: true,
                members: folders
            })
        }
        const groups = categoryGroups || []
        for (let index = 0; index < groups.length; index++) {
            const group = groups[index]
            const members = group ? group.members || [] : []
            if (members.length === 0) {
                continue
            }
            result.push({
                categoryId: String(group.categoryId || "Other"),
                folderSection: false,
                members: members
            })
        }
        return result
    }
    readonly property int sectionCount: sections.length

    signal launchRequested(string storageId)
    signal applicationContextRequested(var sourceItem, var application,
        real x, real y)
    signal folderOpenRequested(string folderId)
    signal folderContextRequested(var sourceItem, var folder, real x, real y)
    signal folderRenameRequested(string folderId)
    signal returnToSearchRequested()
    signal bottomReached()
    signal dragBeginRequested(var application, var sourceItem, real x, real y)
    signal dragUpdateRequested(var sourceItem, real x, real y)
    signal dragFinishRequested()
    signal dragCancelRequested()
    signal dropOntoNodeRequested(var targetNode)

    function isInternalLayoutDrag(event) {
        return root.isDragActive && event
            && event.keys && event.keys.indexOf(root.dragKey) >= 0
    }

    function categoryLabel(categoryId) {
        switch (String(categoryId || "Other")) {
        case "Folders":
            return i18nc("@title:application-category", "Folders")
        case "Network":
            return i18nc("@title:application-category", "Internet")
        case "Graphics":
            return i18nc("@title:application-category", "Graphics")
        case "AudioVideo":
            return i18nc("@title:application-category", "Multimedia")
        case "Office":
            return i18nc("@title:application-category", "Office")
        case "Development":
            return i18nc("@title:application-category", "Development")
        case "System":
            return i18nc("@title:application-category", "System")
        case "Utility":
            return i18nc("@title:application-category", "Utilities")
        case "Game":
            return i18nc("@title:application-category", "Games")
        case "Education":
            return i18nc("@title:application-category", "Education")
        default:
            return i18nc("@title:application-category", "Other")
        }
    }

    function applicationStorageId(application) {
        if (!application) {
            return ""
        }
        return String(application.appStorageId
            || application.storageId || "")
    }

    function applicationName(application) {
        if (!application) {
            return i18nc("@label", "Application")
        }
        return String(application.appName || application.name
            || applicationStorageId(application)
            || i18nc("@label", "Application"))
    }

    function applicationIcon(application) {
        if (!application) {
            return "application-x-executable"
        }
        return String(application.appIcon || application.icon
            || "application-x-executable")
    }

    function ensureItemVisible(sectionIndex, itemIndex) {
        if (sectionIndex < 0 || sectionIndex >= sectionList.count) {
            return
        }
        sectionList.positionViewAtIndex(sectionIndex, ListView.Contain)
    }

    function clearSelection() {
        root.selectedSectionIndex = -1
        root.selectedItemIndex = -1
    }

    function selectFirstItem() {
        if (root.sections.length === 0) {
            root.clearSelection()
            return
        }
        for (let s = 0; s < root.sections.length; s++) {
            const members = root.sections[s].members || []
            if (members.length > 0) {
                root.selectedSectionIndex = s
                root.selectedItemIndex = 0
                ensureItemVisible(s, 0)
                return
            }
        }
    }

    function selectLastItem() {
        if (root.sections.length === 0) {
            root.clearSelection()
            return
        }
        for (let s = root.sections.length - 1; s >= 0; s--) {
            const members = root.sections[s].members || []
            if (members.length > 0) {
                root.selectedSectionIndex = s
                root.selectedItemIndex = members.length - 1
                ensureItemVisible(s, members.length - 1)
                return
            }
        }
    }

    function moveHorizontal(step) {
        if (root.sections.length === 0) {
            return
        }
        if (root.selectedSectionIndex < 0 || root.selectedItemIndex < 0) {
            selectFirstItem()
            return
        }
        const s = root.selectedSectionIndex
        const i = root.selectedItemIndex + step
        const currentMembers = root.sections[s].members || []

        if (step > 0) {
            if (i < currentMembers.length) {
                root.selectedItemIndex = i
            } else {
                let nextSection = s + 1
                while (nextSection < root.sections.length
                    && (root.sections[nextSection].members || []).length === 0) {
                    nextSection++
                }
                if (nextSection < root.sections.length) {
                    root.selectedSectionIndex = nextSection
                    root.selectedItemIndex = 0
                }
            }
        } else {
            if (i >= 0) {
                root.selectedItemIndex = i
            } else {
                let prevSection = s - 1
                while (prevSection >= 0
                    && (root.sections[prevSection].members || []).length === 0) {
                    prevSection--
                }
                if (prevSection >= 0) {
                    const prevMembers = root.sections[prevSection].members || []
                    root.selectedSectionIndex = prevSection
                    root.selectedItemIndex = Math.max(0, prevMembers.length - 1)
                }
            }
        }
        ensureItemVisible(root.selectedSectionIndex, root.selectedItemIndex)
    }

    function moveVertical(step) {
        if (root.sections.length === 0) {
            return
        }
        if (root.selectedSectionIndex < 0 || root.selectedItemIndex < 0) {
            selectFirstItem()
            return
        }
        const cols = root.columnCount
        const s = root.selectedSectionIndex
        const i = root.selectedItemIndex
        const currentMembers = root.sections[s].members || []
        const currentColumn = i % cols
        const currentRow = Math.floor(i / cols)
        const totalRows = Math.ceil(currentMembers.length / cols)

        if (step > 0) {
            const nextRowIndex = i + cols * step
            if (nextRowIndex < currentMembers.length) {
                root.selectedItemIndex = nextRowIndex
            } else if (currentRow < totalRows - 1 && step === 1) {
                root.selectedItemIndex = currentMembers.length - 1
            } else {
                let nextSection = s + 1
                while (nextSection < root.sections.length
                    && (root.sections[nextSection].members || []).length === 0) {
                    nextSection++
                }
                if (nextSection < root.sections.length) {
                    const nextMembers = root.sections[nextSection].members || []
                    const targetIndex = Math.min(currentColumn,
                        nextMembers.length - 1)
                    root.selectedSectionIndex = nextSection
                    root.selectedItemIndex = Math.max(0, targetIndex)
                } else {
                    root.bottomReached()
                }
            }
        } else {
            const prevRowIndex = i + cols * step
            if (prevRowIndex >= 0) {
                root.selectedItemIndex = prevRowIndex
            } else {
                if (s === 0) {
                    root.selectedItemIndex = currentColumn
                    ensureItemVisible(0, root.selectedItemIndex)
                    return
                }
                let prevSection = s - 1
                while (prevSection >= 0
                    && (root.sections[prevSection].members || []).length === 0) {
                    prevSection--
                }
                if (prevSection >= 0) {
                    const prevMembers = root.sections[prevSection].members || []
                    const prevTotalRows = Math.ceil(prevMembers.length / cols)
                    const prevLastRowStart = (prevTotalRows - 1) * cols
                    const targetIndex = Math.min(
                        prevLastRowStart + currentColumn,
                        prevMembers.length - 1)
                    root.selectedSectionIndex = prevSection
                    root.selectedItemIndex = Math.max(0, targetIndex)
                }
            }
        }
        ensureItemVisible(root.selectedSectionIndex, root.selectedItemIndex)
    }

    function launchCurrentItem() {
        if (root.selectedSectionIndex < 0 || root.selectedItemIndex < 0) {
            return
        }
        const section = root.sections[root.selectedSectionIndex]
        if (!section) {
            return
        }
        const members = section.members || []
        const item = members[root.selectedItemIndex]
        if (!item) {
            return
        }
        if (section.folderSection) {
            root.folderOpenRequested(String(item.folderId || ""))
        } else {
            const storageId = root.applicationStorageId(item)
            if (storageId.length > 0) {
                root.launchRequested(storageId)
            }
        }
    }

    function openCurrentContextMenu() {
        if (root.selectedSectionIndex < 0 || root.selectedItemIndex < 0) {
            return
        }
        const section = root.sections[root.selectedSectionIndex]
        if (!section) {
            return
        }
        const members = section.members || []
        const item = members[root.selectedItemIndex]
        if (!item) {
            return
        }
        if (section.folderSection) {
            root.folderContextRequested(null, item,
                root.cellWidth / 2, root.cellHeight / 2)
        } else {
            root.applicationContextRequested(null, item,
                root.cellWidth / 2, root.cellHeight / 2)
        }
    }

    PunchiMenuIconMetrics {
        id: iconMetrics
        requestedScale: root.effectiveIconScale
        minimumScale: 0.75
        maximumScale: 1.5
        baseSize: root.baseIconSize
        minimumSize: Kirigami.Units.iconSizes.medium
        availableWidth: Math.max(0,
            root.cellWidth - Kirigami.Units.gridUnit * 2)
    }

    FontMetrics {
        id: applicationLabelFontMetrics
        font: Kirigami.Theme.smallFont
    }

    Accessible.role: Accessible.Grouping
    Accessible.name: i18nc("@info:accessible",
        "Applications grouped by category")

    ListView {
        id: sectionList
        anchors.fill: parent
        model: root.sections
        spacing: Kirigami.Units.largeSpacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: false
        activeFocusOnTab: false

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: sectionScrollBar
            policy: sectionList.contentHeight > sectionList.height
                ? Controls.ScrollBar.AsNeeded
                : Controls.ScrollBar.AlwaysOff
        }

        delegate: ColumnLayout {
            id: sectionDelegate

            required property var modelData
            required property int index

            readonly property var members: modelData.members || []
            readonly property bool folderSection: Boolean(
                modelData.folderSection)
            readonly property int rowCount: Math.ceil(
                members.length / root.columnCount)

            width: root.availableWidth
            height: implicitHeight
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: root.categoryLabel(
                        sectionDelegate.modelData.categoryId)
                    textFormat: Text.PlainText
                    font.weight: Font.DemiBold
                    Accessible.role: Accessible.Heading
                    Accessible.name: text
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Grid {
                id: sectionGrid
                Layout.fillWidth: true
                Layout.preferredHeight: sectionDelegate.rowCount
                    * root.cellHeight
                columns: root.columnCount
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: sectionDelegate.members

                    delegate: FocusScope {
                        id: launcherDelegate

                        required property var modelData
                        required property int index

                        readonly property bool isFolder:
                            sectionDelegate.folderSection
                        readonly property bool isHiddenApplication:
                            !isFolder && Boolean(modelData.appHidden)
                        readonly property bool isSelected:
                            root.selectedSectionIndex === sectionDelegate.index
                            && root.selectedItemIndex === launcherDelegate.index
                        readonly property bool isDragSource:
                            root.isDragActive
                            && root.dragSourceNodeId.length > 0
                            && root.dragSourceNodeId === String(modelData
                                ? modelData.nodeId || "" : "")
                        readonly property bool dropGroupingActive:
                            nodeDropTarget.containsDrag
                            && nodeDropTarget.dropIntent === "group"
                        readonly property bool highlighted: isSelected
                            || activeFocus
                            || (root.hoverEnabled
                                && applicationPointer.containsMouse)

                        width: root.cellWidth
                        height: root.cellHeight
                        activeFocusOnTab: !isFolder
                        opacity: isDragSource ? 0.34
                            : isHiddenApplication ? 0.58 : 1.0
                        Accessible.ignored: isFolder
                        Accessible.role: Accessible.Button
                        Accessible.name: root.applicationName(modelData)
                        Accessible.description: isHiddenApplication
                            ? i18nc("@info:accessibility",
                                "Hidden from the application listing")
                            : i18nc("@info:accessible",
                                "Launch this application")
                        Accessible.focused: isSelected || activeFocus
                        Accessible.onPressAction: launchApplication()

                        function launchApplication() {
                            const storageId = root.applicationStorageId(
                                modelData)
                            if (storageId.length > 0) {
                                root.launchRequested(storageId)
                            }
                        }

                        PunchiMenuFolderTile {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            visible: launcherDelegate.isFolder
                            enabled: visible
                            activeFocusOnTab: visible
                            folderId: String(launcherDelegate.modelData.folderId
                                || "")
                            folderLabel: String(launcherDelegate.modelData
                                .folderLabel || "")
                            previewIcons: launcherDelegate.modelData
                                .folderPreviewIcons || []
                            memberCount: Number(launcherDelegate.modelData
                                .folderMemberCount || 0)
                            selected: launcherDelegate.isSelected
                                || launcherDelegate.dropGroupingActive
                                || activeFocus || hovered
                            motionEnabled: root.motionEnabled
                            requestedIconSize: root.iconSize
                            hoverAnimation: root.hoverAnimation
                            onActivated: root.folderOpenRequested(folderId)
                            onContextRequested: function(sourceItem, x, y) {
                                root.folderContextRequested(sourceItem,
                                    launcherDelegate.modelData, x, y)
                            }
                            onRenameRequested: root.folderRenameRequested(
                                folderId)
                        }

                        PunchiMenuItemHighlight {
                            id: itemHighlight
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            visible: !launcherDelegate.isFolder
                            hovered: root.hoverEnabled
                                && applicationPointer.containsMouse
                            selected: launcherDelegate.isSelected
                                || launcherDelegate.dropGroupingActive
                            focused: launcherDelegate.isSelected
                                || launcherDelegate.activeFocus
                            pressed: applicationPointer.pressed
                                && !root.isDragActive
                            motionEnabled: root.motionEnabled
                            animationMode: root.hoverAnimation
                            transformSelf: false

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins:
                                    Kirigami.Units.smallSpacing * 2
                                anchors.topMargin: root.showApplicationLabels
                                    ? Kirigami.Units.smallSpacing * 2
                                    : Math.max(
                                        Kirigami.Units.smallSpacing * 2,
                                        (parent.height - root.iconSize) / 2)
                                anchors.bottomMargin: anchors.topMargin
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    Layout.preferredWidth: root.iconSize
                                    Layout.preferredHeight: root.iconSize
                                    Layout.alignment: Qt.AlignHCenter
                                    source: root.applicationIcon(
                                        launcherDelegate.modelData)
                                    Accessible.ignored: true
                                }

                                PlasmaComponents.Label {
                                    id: applicationLabel
                                    Layout.fillWidth: true
                                    visible: root.showApplicationLabels
                                    text: root.applicationName(
                                        launcherDelegate.modelData)
                                    textFormat: Text.PlainText
                                    horizontalAlignment: Text.AlignHCenter
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    font: applicationLabelFontMetrics.font
                                    Accessible.ignored: true
                                }
                            }

                            PlasmaCore.ToolTipArea {
                                anchors.fill: parent
                                active: !root.showApplicationLabels
                                    || applicationLabel.truncated
                                mainText: root.applicationName(
                                    launcherDelegate.modelData)
                            }

                            Kirigami.Icon {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins:
                                    Kirigami.Units.smallSpacing * 2
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                source: "view-hidden-symbolic"
                                visible: launcherDelegate
                                    .isHiddenApplication
                                Accessible.ignored: true
                            }
                        }

                        DropArea {
                            id: nodeDropTarget
                            property string dropIntent: "none"
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            keys: [root.dragKey]
                            z: 20

                            function updateDropIntent(drag) {
                                if (!root.isInternalLayoutDrag(drag)
                                        || root.dragSourceNodeId
                                            === String(launcherDelegate
                                                .modelData
                                                ? launcherDelegate.modelData
                                                    .nodeId || "" : "")) {
                                    dropIntent = "none"
                                    return false
                                }
                                dropIntent = root.isDragFolder ? "none" : "group"
                                return dropIntent !== "none"
                            }

                            onEntered: function(drag) {
                                drag.accepted = updateDropIntent(drag)
                            }
                            onPositionChanged: function(drag) {
                                drag.accepted = updateDropIntent(drag)
                            }
                            onExited: {
                                dropIntent = "none"
                            }
                            onDropped: function(drop) {
                                if (!root.isInternalLayoutDrag(drop)) {
                                    drop.accepted = false
                                    dropIntent = "none"
                                    return
                                }
                                drop.accepted = root.dropOntoNodeRequested(
                                    launcherDelegate.modelData)
                                dropIntent = "none"
                            }
                        }

                        Kirigami.Icon {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Kirigami.Units.smallSpacing
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            visible: nodeDropTarget.containsDrag
                                && nodeDropTarget.dropIntent === "group"
                            source: launcherDelegate.isFolder
                                ? "folder-add-symbolic"
                                : "folder-new-symbolic"
                            color: Kirigami.Theme.highlightColor
                            z: 30
                            Accessible.ignored: true
                        }

                        scale: root.motionEnabled
                            && applicationPointer.pressed
                            && !root.isDragActive
                            && root.hoverAnimation !== "none"
                            ? 0.97 : itemHighlight.visualScale

                        MouseArea {
                            id: applicationPointer
                            anchors.fill: parent
                            enabled: !launcherDelegate.isFolder
                            acceptedButtons:
                                Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            preventStealing: root.isDragActive
                            cursorShape: launcherDelegate.isDragSource
                                ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            z: 40

                            onPressAndHold: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.selectedSectionIndex
                                        = sectionDelegate.index
                                    root.selectedItemIndex
                                        = launcherDelegate.index
                                    root.dragBeginRequested(
                                        launcherDelegate.modelData,
                                        applicationPointer,
                                        mouse.x, mouse.y)
                                }
                            }
                            onPositionChanged: function(mouse) {
                                if (launcherDelegate.isDragSource) {
                                    root.dragUpdateRequested(
                                        applicationPointer,
                                        mouse.x, mouse.y)
                                }
                            }
                            onReleased: function(mouse) {
                                if (mouse.button === Qt.LeftButton
                                        && launcherDelegate.isDragSource) {
                                    root.dragFinishRequested()
                                }
                            }
                            onCanceled: {
                                if (launcherDelegate.isDragSource) {
                                    root.dragCancelRequested()
                                }
                            }
                            onClicked: function(mouse) {
                                if (root.suppressDragReleaseClick) {
                                    return
                                }
                                root.selectedSectionIndex = sectionDelegate.index
                                root.selectedItemIndex = launcherDelegate.index
                                launcherDelegate.forceActiveFocus()
                                if (mouse.button === Qt.RightButton) {
                                    root.applicationContextRequested(
                                        launcherDelegate,
                                        launcherDelegate.modelData,
                                        mouse.x, mouse.y)
                                    return
                                }
                                launcherDelegate.launchApplication()
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (launcherDelegate.isFolder) {
                                return
                            }
                            if (event.key === Qt.Key_Return
                                    || event.key === Qt.Key_Enter
                                    || event.key === Qt.Key_Space) {
                                launcherDelegate.launchApplication()
                                event.accepted = true
                                return
                            }
                            if (event.key === Qt.Key_Menu
                                    || (event.key === Qt.Key_F10
                                        && (event.modifiers
                                            & Qt.ShiftModifier))) {
                                root.applicationContextRequested(
                                    launcherDelegate,
                                    launcherDelegate.modelData,
                                    launcherDelegate.width / 2,
                                    launcherDelegate.height / 2)
                                event.accepted = true
                            }
                        }
                    }
                }
            }
        }
    }
}
// qmllint enable unqualified
