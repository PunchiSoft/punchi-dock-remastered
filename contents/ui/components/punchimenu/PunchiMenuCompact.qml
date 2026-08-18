// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import "../../org/punchi/dock" as Punchi

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    required property var systemDiscovery
    property var applicationCatalog: []
    property var favorites: []
    property bool favoriteLimitReached: false
    property var dockItemsController: null
    property bool showApplicationLabels: true
    property string hoverAnimation: "pulse"
    property bool sortApplicationsAlphabetically: false
    property bool backgroundBlurEnabled: true
    property real backgroundOpacity: 0.85
    property bool compactShowQuickLaunchers: true
    property int normalPanelGap: 0
    property real themeFrameLeftMargin: 0
    property real themeFrameTopMargin: 0
    property real themeFrameRightMargin: 0
    property real themeFrameBottomMargin: 0

    property bool menuOpen: false
    property string activeCategoryKey: ""
    property string activeCategoryTitle: ""
    property var activeCategoryApps: []
    property int selectedCategoryIndex: -1
    property string searchQuery: ""
    property bool settingsViewActive: false
    property string applicationErrorMessage: ""

    readonly property real nativeFrameThickness: 2
    readonly property real safeThemeFrameLeftMargin: {
        const requestedMargin = Number(themeFrameLeftMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real safeThemeFrameTopMargin: {
        const requestedMargin = Number(themeFrameTopMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real safeThemeFrameRightMargin: {
        const requestedMargin = Number(themeFrameRightMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real safeThemeFrameBottomMargin: {
        const requestedMargin = Number(themeFrameBottomMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real themeFrameOverlapLeft: Math.max(0,
        safeThemeFrameLeftMargin - nativeFrameThickness)
    readonly property real themeFrameOverlapTop: Math.max(0,
        safeThemeFrameTopMargin - nativeFrameThickness)
    readonly property real themeFrameOverlapRight: Math.max(0,
        safeThemeFrameRightMargin - nativeFrameThickness)
    readonly property real themeFrameOverlapBottom: Math.max(0,
        safeThemeFrameBottomMargin - nativeFrameThickness)

    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property real themeMarginLeft: compactBackground ? compactBackground.margins.left : 0
    readonly property real themeMarginTop: compactBackground ? compactBackground.margins.top : 0
    readonly property real themeMarginRight: compactBackground ? compactBackground.margins.right : 0
    readonly property real themeMarginBottom: compactBackground ? compactBackground.margins.bottom : 0

    readonly property real baseFrameMargins: themeMarginLeft + themeMarginRight + Kirigami.Units.smallSpacing * 2
    readonly property real baseHeightMargins: themeMarginTop + themeMarginBottom + Kirigami.Units.smallSpacing * 2

    readonly property real itemHeight: Math.round(Kirigami.Units.gridUnit * 2.0)
    readonly property real mainColumnWidth: Math.round(Kirigami.Units.gridUnit * 16)
    readonly property real flyoutWidth: Math.round(Kirigami.Units.gridUnit * 20)
    readonly property bool flyoutVisible: !settingsViewActive
        && (root.activeCategoryKey.length > 0 || root.searchQuery.length > 0)
    readonly property real totalContentWidth: flyoutVisible
        ? mainColumnWidth + flyoutWidth + Kirigami.Units.smallSpacing * 2 + baseFrameMargins
        : mainColumnWidth + baseFrameMargins

    readonly property real safeBackgroundOpacity: {
        const requestedOpacity = Number(backgroundOpacity)
        return Number.isFinite(requestedOpacity)
            ? Math.max(0.50, Math.min(1.0, requestedOpacity))
            : 0.85
    }

    readonly property var backgroundBlurMaskSource: compactBackground
    readonly property point backgroundBlurMaskOffset: {
        const scenePosition = compactBackground.mapToItem(null, Qt.point(0, 0))
        return Qt.point(Math.round(scenePosition.x), Math.round(scenePosition.y))
    }

    signal applicationLaunched()
    signal menuCloseRequested()
    signal settingChangeRequested(string fieldName, var value)
    signal applicationContextRequested(var sourceItem, var application, real x, real y)

    onMenuOpenChanged: {
        if (!menuOpen) {
            closeApplicationContextMenu(false)
        }
    }

    onVisibleChanged: {
        if (!visible) {
            closeApplicationContextMenu(false)
        }
    }
    signal addFavoriteRequested(string storageId)
    signal removeFavoriteRequested(string storageId)
    signal pinToDockRequested(string storageId, string appName, string appIcon, string appCommand)
    signal addToDesktopRequested(string storageId, string appCommand)
    signal setApplicationHiddenRequested(string storageId, bool hidden)

    readonly property bool favoritesRowActive: compactShowQuickLaunchers
        && searchQuery.length === 0
        && favorites !== null
        && favorites !== undefined
        && favorites.length > 0
    readonly property real compactHeightWithoutQuickLaunchers: Math.round(Kirigami.Units.gridUnit * 21.6)
    readonly property real compactHeightWithQuickLaunchers: Math.round(Kirigami.Units.gridUnit * 24.2)
    readonly property real desiredMenuHeight: favoritesRowActive
        ? compactHeightWithQuickLaunchers + baseHeightMargins
        : compactHeightWithoutQuickLaunchers + baseHeightMargins

    width: totalContentWidth
    implicitWidth: totalContentWidth
    implicitHeight: desiredMenuHeight

    Punchi.SessionActionsController {
        id: sessionController
    }

    Punchi.PunchiMenuLayoutModel {
        id: layoutModel
        applications: root.applicationCatalog || []
        alphabeticalSortingEnabled: root.sortApplicationsAlphabetically
    }

    readonly property var categoryOrder: [
        "Network",
        "Graphics",
        "AudioVideo",
        "Office",
        "Development",
        "System",
        "Utility",
        "Game",
        "Education",
        "Settings"
    ]

    function categoryTitle(categoryId) {
        switch (categoryId) {
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
        case "Settings":
            return i18nc("@title:application-category", "Settings")
        case "All":
            return i18nc("@title:application-category", "All Applications")
        default:
            return i18nc("@title:application-category", "Other")
        }
    }

    function categoryIcon(categoryId) {
        if (categoryId === "All") {
            return "applications-all"
        }
        if (root.systemDiscovery && typeof root.systemDiscovery.iconForCategory === "function") {
            const icon = root.systemDiscovery.iconForCategory(categoryId)
            if (icon && icon.length > 0) {
                return icon
            }
        }
        switch (categoryId) {
        case "Network": return "applications-internet"
        case "Graphics": return "applications-graphics"
        case "AudioVideo": return "applications-multimedia"
        case "Office": return "applications-office"
        case "Development": return "applications-development"
        case "System": return "applications-system"
        case "Utility": return "applications-utilities"
        case "Game": return "applications-games"
        case "Education": return "applications-science"
        case "Settings": return "preferences-system"
        default: return "applications-other"
        }
    }

    readonly property var availableCategories: {
        const groups = layoutModel.categoryGroups || []
        const result = []
        const groupsByKey = {}
        for (let i = 0; i < groups.length; i++) {
            const grp = groups[i]
            if (grp && grp.categoryId) {
                groupsByKey[grp.categoryId] = grp
            }
        }
        for (let j = 0; j < categoryOrder.length; j++) {
            const key = categoryOrder[j]
            if (groupsByKey[key] && groupsByKey[key].members && groupsByKey[key].members.length > 0) {
                result.push({
                    "categoryId": key,
                    "title": root.categoryTitle(key),
                    "icon": root.categoryIcon(key),
                    "members": groupsByKey[key].members
                })
            }
        }
        if (root.applicationCatalog && root.applicationCatalog.length > 0) {
            result.push({
                "categoryId": "All",
                "title": root.categoryTitle("All"),
                "icon": root.categoryIcon("All"),
                "members": root.applicationCatalog
            })
        }
        return result
    }

    function openCategory(index) {
        if (index >= 0 && index < availableCategories.length) {
            root.closeApplicationContextMenu(false)
            root.selectedCategoryIndex = index
            const cat = availableCategories[index]
            root.activeCategoryKey = cat.categoryId
            root.activeCategoryTitle = cat.title
            root.activeCategoryApps = cat.members || []
        }
    }

    function closeFlyout() {
        root.closeApplicationContextMenu(false)
        root.activeCategoryKey = ""
        root.activeCategoryTitle = ""
        root.activeCategoryApps = []
        root.selectedCategoryIndex = -1
    }

    function openMenu() {
        root.closeApplicationContextMenu(false)
        root.menuOpen = true
        root.settingsViewActive = false
        root.searchQuery = ""
        searchField.text = ""
        root.closeFlyout()
        searchField.forceActiveFocus()
    }

    function resetMenu() {
        root.closeApplicationContextMenu(false)
        root.menuOpen = false
        root.settingsViewActive = false
        root.searchQuery = ""
        searchField.text = ""
        root.closeFlyout()
    }

    function closeMenu() {
        root.closeApplicationContextMenu(false)
        resetMenu()
        root.menuCloseRequested()
    }

    function launchApplication(storageId) {
        if (!storageId || storageId.length === 0) {
            return
        }
        if (root.systemDiscovery && typeof root.systemDiscovery.launchApplication === "function") {
            root.systemDiscovery.launchApplication(storageId)
            root.applicationLaunched()
            root.closeMenu()
        }
    }

    function launchCommand(command) {
        if (!command || command.length === 0) {
            return
        }
        if (root.systemDiscovery && typeof root.systemDiscovery.launchApplicationByCommand === "function") {
            root.systemDiscovery.launchApplicationByCommand(command)
            root.applicationLaunched()
            root.closeMenu()
        }
    }

    function isFavorite(storageId) {
        const id = String(storageId || "").trim()
        if (id.length === 0 || !root.favorites) {
            return false
        }
        for (let i = 0; i < root.favorites.length; i++) {
            const fav = root.favorites[i]
            const favId = typeof fav === "string"
                ? fav
                : String((fav && (fav.appStorageId || fav.storageId || fav.id)) || "")
            if (favId === id) {
                return true
            }
        }
        return false
    }

    function contextEntry(actionId, text, iconName, enabled) {
        return {
            actionId: actionId,
            text: text,
            iconName: iconName,
            enabled: enabled !== false,
            separator: false
        }
    }

    function standaloneApplicationContextEntries(context) {
        return [
            contextEntry("toggleFavorite", context.isFavorite
                    ? i18nc("@action:inmenu", "Remove from Favorites")
                    : i18nc("@action:inmenu", "Add to Favorites"),
                context.isFavorite ? "favorite-favorited" : "favorite",
                context.isFavorite || !root.favoriteLimitReached),
            contextEntry("toggleDockPin", context.isPinnedToDock
                    ? i18nc("@action:inmenu", "Remove from Dock")
                    : i18nc("@action:inmenu", "Pin to Dock"),
                context.isPinnedToDock ? "window-unpin" : "window-pin", true),
            contextEntry("addToDesktop",
                i18nc("@action:inmenu", "Add to Desktop"),
                "user-desktop", true)
        ]
    }

    function openApplicationContextMenu(sourceItem, appData, x, y) {
        if (!appData) {
            return
        }
        const normalizedId = String(appData.storageId || appData.id || "").trim()
        const normalizedCmd = String(appData.command || appData.exec || "").trim()
        const appName = String(appData.appName || appData.name || "")
        const appIcon = String(appData.appIcon || appData.icon || "")
        const primaryId = normalizedId.length > 0 ? normalizedId : normalizedCmd
        const localX = Number(x)
        const localY = Number(y)
        if (!sourceItem || primaryId.length === 0
                || !Number.isFinite(localX) || !Number.isFinite(localY)) {
            return
        }
        closeApplicationContextMenu(false)
        const context = {
            storageId: normalizedId,
            appCommand: normalizedCmd,
            appName: appName,
            appIcon: appIcon,
            isFavorite: isFavorite(primaryId),
            isPinnedToDock: root.dockItemsController
                ? root.dockItemsController.isAppPinnedToDock(
                    normalizedId, normalizedCmd)
                : false
        }
        const entries = standaloneApplicationContextEntries(context)
        applicationContextMenuSurface.openAt(sourceItem,
            localX, localY, entries, context)
    }

    function closeApplicationContextMenu(restoreFocus) {
        if (applicationContextMenuSurface && applicationContextMenuSurface.active) {
            applicationContextMenuSurface.close(restoreFocus !== false)
        }
    }

    function activateContextMenuAction(actionId) {
        const storageId = String(applicationContextMenuSurface.targetStorageId || "")
        const appName = String(applicationContextMenuSurface.targetAppName || "")
        const appIcon = String(applicationContextMenuSurface.targetAppIcon || "")
        const appCommand = String(applicationContextMenuSurface.targetAppCommand || "")
        const isFav = applicationContextMenuSurface.targetIsFavorite

        closeApplicationContextMenu(true)

        if (actionId === "toggleFavorite") {
            if (isFav) {
                root.removeFavoriteRequested(storageId)
            } else {
                root.addFavoriteRequested(storageId)
            }
        } else if (actionId === "toggleDockPin") {
            root.pinToDockRequested(storageId, appName, appIcon, appCommand)
        } else if (actionId === "addToDesktop") {
            root.addToDesktopRequested(storageId, appCommand)
        }
    }

    Timer {
        id: categoryHoverTimer
        interval: 100
        repeat: false
        property int pendingIndex: -1
        onTriggered: {
            if (pendingIndex >= 0) {
                root.openCategory(pendingIndex)
            }
        }
    }

    KSvg.FrameSvgItem {
        id: compactBackground
        anchors.fill: parent
        anchors.leftMargin: -root.themeFrameOverlapLeft
        anchors.topMargin: -root.themeFrameOverlapTop
        anchors.rightMargin: -root.themeFrameOverlapRight
        anchors.bottomMargin: -root.themeFrameOverlapBottom
        imagePath: "widgets/background"
        opacity: root.safeBackgroundOpacity
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.themeMarginLeft + Kirigami.Units.smallSpacing
        anchors.topMargin: root.themeMarginTop + Kirigami.Units.smallSpacing
        anchors.rightMargin: root.themeMarginRight + Kirigami.Units.smallSpacing
        anchors.bottomMargin: root.themeMarginBottom + Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        // Main Column
        Item {
            Layout.preferredWidth: root.mainColumnWidth
            Layout.fillHeight: true

            // Flip: Normal Menu View vs Settings View
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                visible: !root.settingsViewActive

                // Search Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.SearchField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: i18nc("@info:placeholder", "Search applications…")
                        Accessible.name: i18nc("@label", "Search applications")
                        background: PunchiMenuSearchBackground {
                            fieldActiveFocus: searchField.activeFocus
                            fieldHovered: searchField.hovered
                        }

                        onTextChanged: {
                            root.searchQuery = text.trim()
                            if (root.searchQuery.length > 0) {
                                // Filter catalog
                                const query = root.searchQuery.toLowerCase()
                                const matches = []
                                const catalog = root.applicationCatalog || []
                                for (let i = 0; i < catalog.length; i++) {
                                    const app = catalog[i]
                                    const name = String(app.appName || app.name || "").toLowerCase()
                                    const generic = String(app.genericName || "").toLowerCase()
                                    const comment = String(app.comment || app.description || "").toLowerCase()
                                    if (name.includes(query) || generic.includes(query) || comment.includes(query)) {
                                        matches.push(app)
                                    }
                                }
                                root.activeCategoryKey = "Search"
                                root.activeCategoryTitle = i18nc("@title:category", "Search Results")
                                root.activeCategoryApps = matches
                            } else {
                                root.closeFlyout()
                            }
                        }

                        Keys.onDownPressed: function(event) {
                            if (categoryListView.count > 0) {
                                categoryListView.forceActiveFocus()
                                categoryListView.currentIndex = 0
                                event.accepted = true
                            }
                        }

                        Keys.onEscapePressed: function(event) {
                            if (text.length > 0) {
                                text = ""
                            } else {
                                root.closeMenu()
                            }
                            event.accepted = true
                        }
                    }
                }

                // Favorites Row (Dynamic)
                Item {
                    id: favoritesRowContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.favoritesRowActive
                        ? Math.round(Kirigami.Units.gridUnit * 2.2) : 0
                    visible: root.favoritesRowActive

                    ListView {
                        id: compactFavoritesListView
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        orientation: ListView.Horizontal
                        spacing: Kirigami.Units.smallSpacing
                        clip: true
                        model: root.favorites
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            id: favoriteItemDelegate
                            required property var modelData
                            required property int index

                            readonly property var favApp: modelData
                            readonly property string favStorageId: String((favApp && (favApp.appStorageId || favApp.storageId || favApp.id)) || "")
                            readonly property string favName: String((favApp && (favApp.appName || favApp.name)) || "")
                            readonly property string favIcon: String((favApp && (favApp.appIcon || favApp.icon)) || "application-x-executable")
                            readonly property string favCommand: String((favApp && (favApp.appCommand || favApp.command || favApp.exec)) || "")

                            width: height
                            height: compactFavoritesListView.height

                            PunchiMenuItemHighlight {
                                anchors.fill: parent
                                anchors.margins: 1
                                hovered: favMouseArea.containsMouse
                                pressed: favMouseArea.pressed
                                motionEnabled: root.motionEnabled
                                animationMode: root.hoverAnimation

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Kirigami.Units.iconSizes.smallMedium
                                    height: Kirigami.Units.iconSizes.smallMedium
                                    source: favoriteItemDelegate.favIcon
                                    fallback: "application-x-executable"
                                    smooth: true
                                }
                            }

                            MouseArea {
                                id: favMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        root.openApplicationContextMenu(
                                            favoriteItemDelegate,
                                            {
                                                storageId: favoriteItemDelegate.favStorageId,
                                                appName: favoriteItemDelegate.favName,
                                                appIcon: favoriteItemDelegate.favIcon,
                                                appCommand: favoriteItemDelegate.favCommand
                                            },
                                            mouse.x, mouse.y)
                                    } else {
                                        if (favoriteItemDelegate.favStorageId.length > 0) {
                                            root.launchApplication(favoriteItemDelegate.favStorageId)
                                        } else if (favoriteItemDelegate.favCommand.length > 0) {
                                            root.launchCommand(favoriteItemDelegate.favCommand)
                                        }
                                    }
                                }
                            }

                            Accessible.role: Accessible.Button
                            Accessible.name: favoriteItemDelegate.favName
                        }
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: root.favoritesRowActive
                }

                // Categories List
                Controls.ScrollView {
                    id: categoryScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: root.searchQuery.length === 0

                    ListView {
                        id: categoryListView
                        width: categoryScrollView.availableWidth
                        model: root.availableCategories
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        currentIndex: root.selectedCategoryIndex

                        delegate: Item {
                            id: categoryDelegate
                            required property int index
                            required property var modelData

                            readonly property var categoryItem: modelData
                            readonly property bool isSelected: root.selectedCategoryIndex === index

                            width: categoryListView.width
                            height: root.itemHeight

                            PunchiMenuItemHighlight {
                                anchors.fill: parent
                                anchors.leftMargin: Kirigami.Units.smallSpacing
                                anchors.rightMargin: Kirigami.Units.smallSpacing
                                hovered: catMouseArea.containsMouse
                                selected: categoryDelegate.isSelected
                                focused: categoryDelegate.isSelected && categoryListView.activeFocus
                                pressed: catMouseArea.pressed
                                motionEnabled: root.motionEnabled
                                animationMode: root.hoverAnimation

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                                    anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                                    spacing: Kirigami.Units.smallSpacing * 2

                                    Kirigami.Icon {
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                        source: categoryDelegate.categoryItem.icon
                                        fallback: "applications-other"
                                        smooth: true
                                    }

                                    Controls.Label {
                                        Layout.fillWidth: true
                                        text: categoryDelegate.categoryItem.title
                                        color: Kirigami.Theme.textColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Kirigami.Icon {
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                        source: "go-next-symbolic"
                                        opacity: 0.6
                                    }
                                }
                            }

                            MouseArea {
                                id: catMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: {
                                    categoryHoverTimer.pendingIndex = categoryDelegate.index
                                    categoryHoverTimer.restart()
                                }

                                onClicked: {
                                    root.openCategory(categoryDelegate.index)
                                    if (flyoutPanel.visible) {
                                        flyoutPanel.selectFirstItem()
                                    }
                                }
                            }

                            Accessible.role: Accessible.MenuItem
                            Accessible.name: categoryDelegate.categoryItem.title
                        }

                        Keys.onRightPressed: function(event) {
                            if (root.activeCategoryApps && root.activeCategoryApps.length > 0) {
                                flyoutPanel.selectFirstItem()
                                event.accepted = true
                            }
                        }

                        Keys.onReturnPressed: function(event) {
                            if (root.activeCategoryApps && root.activeCategoryApps.length > 0) {
                                flyoutPanel.selectFirstItem()
                                event.accepted = true
                            }
                        }

                        Keys.onUpPressed: function(event) {
                            if (currentIndex > 0) {
                                currentIndex--
                                root.openCategory(currentIndex)
                                event.accepted = true
                            } else {
                                searchField.forceActiveFocus()
                                event.accepted = true
                            }
                        }

                        Keys.onDownPressed: function(event) {
                            if (currentIndex < count - 1) {
                                currentIndex++
                                root.openCategory(currentIndex)
                                event.accepted = true
                            }
                        }

                        Keys.onEscapePressed: function(event) {
                            root.closeMenu()
                            event.accepted = true
                        }
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                // Footer Actions Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 2.0)
                    spacing: Kirigami.Units.smallSpacing

                    Controls.ToolButton {
                        icon.name: "preferences-system"
                        text: i18nc("@action:button", "Settings")
                        display: Controls.AbstractButton.IconOnly
                        Accessible.name: text
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        onClicked: {
                            root.closeFlyout()
                            root.settingsViewActive = true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Controls.ToolButton {
                        icon.name: "system-lock-screen"
                        text: i18nc("@action:button", "Lock")
                        display: Controls.AbstractButton.IconOnly
                        Accessible.name: text
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        onClicked: {
                            root.launchCommand("loginctl lock-session")
                        }
                    }

                    Controls.ToolButton {
                        icon.name: "system-log-out"
                        text: i18nc("@action:button", "Log Out")
                        display: Controls.AbstractButton.IconOnly
                        Accessible.name: text
                        visible: sessionController.canLogout
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        onClicked: {
                            sessionController.requestLogout()
                            root.closeMenu()
                        }
                    }

                    Controls.ToolButton {
                        icon.name: "system-shutdown"
                        text: i18nc("@action:button", "Shut Down")
                        display: Controls.AbstractButton.IconOnly
                        Accessible.name: text
                        visible: sessionController.canShutdown
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        onClicked: {
                            sessionController.requestShutdown()
                            root.closeMenu()
                        }
                    }
                }
            }

            // Inline Settings View
            PunchiMenuCompactSettingsView {
                anchors.fill: parent
                visible: root.settingsViewActive
                backgroundBlurEnabled: root.backgroundBlurEnabled
                backgroundOpacityPercent: Math.round(root.safeBackgroundOpacity * 100)
                sortApplicationsAlphabetically: root.sortApplicationsAlphabetically
                compactShowQuickLaunchers: root.compactShowQuickLaunchers
                normalPanelGap: root.normalPanelGap
                hoverAnimation: root.hoverAnimation
                showApplicationLabels: root.showApplicationLabels
                applicationIconScalePercent: 100
                favoriteIconScalePercent: 100
                folderMaximumColumns: 3
                folderMaximumRows: 3

                onSettingChanged: function(fieldName, value) {
                    root.settingChangeRequested(fieldName, value)
                }

                onReturnToMenuRequested: {
                    root.settingsViewActive = false
                    searchField.forceActiveFocus()
                }
            }
        }

        // Vertical Separator between Main column and Flyout
        Kirigami.Separator {
            Layout.fillHeight: true
            visible: root.flyoutVisible
        }

        // Submenu Flyout Panel
        PunchiMenuCompactFlyout {
            id: flyoutPanel
            Layout.preferredWidth: root.flyoutWidth
            Layout.fillHeight: true
            visible: root.flyoutVisible
            applicationList: root.activeCategoryApps
            categoryTitle: root.activeCategoryTitle
            motionEnabled: root.motionEnabled
            hoverAnimation: root.hoverAnimation
            backgroundOpacity: root.safeBackgroundOpacity
            backgroundBlurEnabled: root.backgroundBlurEnabled

            onApplicationActivated: function(storageId) {
                root.launchApplication(storageId)
            }

            onApplicationContextRequested: function(sourceItem, application, x, y) {
                root.openApplicationContextMenu(sourceItem, application, x, y)
                root.applicationContextRequested(sourceItem, application, x, y)
            }

            onReturnToParentRequested: {
                categoryListView.forceActiveFocus()
            }
        }
    }

    PunchiMenuContextSurface {
        id: applicationContextMenuSurface
        anchors.fill: parent
        z: 300

        onActionTriggered: function(actionId) {
            root.activateContextMenuAction(actionId)
        }
        onCloseRequested: function(restoreFocus) {
            root.closeApplicationContextMenu(restoreFocus)
        }
        onFocusFallbackRequested: {
            if (flyoutPanel.visible) {
                flyoutPanel.forceActiveFocus()
            }
        }
    }
}
