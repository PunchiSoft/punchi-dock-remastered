import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.components as PlasmaComponents
import "../../org/punchi/dock" as Punchi

// qmllint disable unqualified
FocusScope {
    id: root

    required property var systemDiscovery
    required property var favorites
    property real applicationIconScale: 1.0
    property bool favoriteLimitReached: false
    property bool menuOpen: false
    property bool applicationsLoading: false
    property bool applicationLaunchPending: false
    property string applicationErrorMessage: ""
    property string activeCategoryKey: "Network"
    property string activeCategoryTitle: i18nc("@title:category", "Internet")
    property string pendingCategoryKey: ""
    property bool suppressSearchChange: false

    readonly property int columnCount: 6
    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property int openDuration: motionEnabled
        ? Math.max(160, Math.min(240, Kirigami.Units.longDuration))
        : 0
    readonly property int closeDuration: motionEnabled
        ? Math.max(100, Math.min(160, Kirigami.Units.shortDuration))
        : 0
    readonly property real safeApplicationIconScale: {
        const requestedScale = Number(applicationIconScale)
        return Number.isFinite(requestedScale)
            ? Math.max(0.75, Math.min(1.50, requestedScale))
            : 1.0
    }
    readonly property real surfaceOpacity: blurController.available ? 0.90 : 0.97
    readonly property bool favoritesSectionVisible: favorites.length > 0
        && searchField.text.length === 0
        && height >= Kirigami.Units.gridUnit * 24

    signal closeFinished()
    signal addFavoriteRequested(string storageId)
    signal removeFavoriteRequested(string storageId)

    function horizontalScrollLimit(view) {
        return Math.max(0, view.contentWidth - view.width)
    }

    function scrollHorizontalBy(view, animation, distance, velocity) {
        const currentPosition = Number(view.contentX)
        const pendingPosition = animation.running && !animation.edgeDriven
            ? Number(animation.to)
            : currentPosition
        const targetPosition = Math.max(0, Math.min(
            horizontalScrollLimit(view), pendingPosition + distance))

        animation.stop()
        animation.edgeDriven = false
        if (!motionEnabled || Math.abs(targetPosition - currentPosition) < 0.5) {
            view.contentX = targetPosition
            return
        }

        animation.velocity = velocity
        animation.to = targetPosition
        animation.start()
    }

    function updateHorizontalEdgeScroll(view, animation, direction, velocity) {
        animation.stop()
        if (!motionEnabled || direction === 0) {
            return
        }

        const targetPosition = direction < 0 ? 0 : horizontalScrollLimit(view)
        if (Math.abs(targetPosition - view.contentX) < 0.5) {
            view.contentX = targetPosition
            return
        }

        animation.edgeDriven = true
        animation.velocity = velocity
        animation.to = targetPosition
        animation.start()
    }

    function scrollCategoriesBy(distance) {
        scrollHorizontalBy(categoriesView, categoryScrollAnimation, distance,
            Kirigami.Units.gridUnit * 34)
    }

    function updateCategoryEdgeScroll() {
        const direction = categoryLeftEdge.hovered && categoryLeftEdge.canScroll
                && !categoryLeftEdge.autoScrollSuppressed
            ? -1
            : categoryRightEdge.hovered && categoryRightEdge.canScroll
                && !categoryRightEdge.autoScrollSuppressed ? 1 : 0
        updateHorizontalEdgeScroll(categoriesView, categoryScrollAnimation,
            direction, Kirigami.Units.gridUnit * 10)
    }

    function scrollFavoritesBy(distance) {
        scrollHorizontalBy(favoritesView, favoritesScrollAnimation, distance,
            Kirigami.Units.gridUnit * 28)
    }

    function updateFavoritesEdgeScroll() {
        const direction = favoritesLeftEdge.hovered && favoritesLeftEdge.canScroll
                && !favoritesLeftEdge.autoScrollSuppressed
            ? -1
            : favoritesRightEdge.hovered && favoritesRightEdge.canScroll
                && !favoritesRightEdge.autoScrollSuppressed ? 1 : 0
        updateHorizontalEdgeScroll(favoritesView, favoritesScrollAnimation,
            direction, Kirigami.Units.gridUnit * 7.5)
    }

    function stopHorizontalMotion() {
        categoryScrollAnimation.stop()
        favoritesScrollAnimation.stop()
    }

    onMenuOpenChanged: {
        if (!menuOpen) {
            stopHorizontalMotion()
        }
    }

    onMotionEnabledChanged: {
        if (!motionEnabled) {
            stopHorizontalMotion()
        }
    }

    onFavoritesSectionVisibleChanged: {
        if (!favoritesSectionVisible) {
            favoritesScrollAnimation.stop()
        }
    }

    function categoryIndexForKey(categoryKey) {
        const requestedKey = String(categoryKey || "")
        for (let index = 0; index < categoryModel.count; index++) {
            if (String(categoryModel.get(index).categoryKey || "") === requestedKey) {
                return index
            }
        }
        return categoryModel.count > 0 ? 0 : -1
    }

    function focusActiveCategory() {
        const index = categoryIndexForKey(activeCategoryKey)
        if (index < 0) {
            return
        }
        categoriesView.currentIndex = index
        categoriesView.positionViewAtIndex(index, ListView.Contain)
        categoriesView.forceActiveFocus()
    }

    function focusApplicationsGrid() {
        if (visibleApplicationsModel.count === 0) {
            return
        }
        if (applicationsGrid.currentIndex < 0
                || applicationsGrid.currentIndex >= visibleApplicationsModel.count) {
            applicationsGrid.currentIndex = 0
        }
        applicationsGrid.positionViewAtIndex(applicationsGrid.currentIndex, GridView.Contain)
        applicationsGrid.forceActiveFocus()
    }

    function focusFavorites() {
        if (!favoritesSectionVisible || favorites.length === 0) {
            return
        }
        if (favoritesView.currentIndex < 0
                || favoritesView.currentIndex >= favorites.length) {
            favoritesView.currentIndex = 0
        }
        favoritesView.positionViewAtIndex(favoritesView.currentIndex, ListView.Contain)
        favoritesView.forceActiveFocus()
    }

    function isFavorite(storageId) {
        const requestedId = String(storageId || "").toLocaleLowerCase()
        if (requestedId.length === 0) {
            return false
        }
        for (let index = 0; index < favorites.length; index++) {
            if (String(favorites[index].appStorageId || "").toLocaleLowerCase()
                    === requestedId) {
                return true
            }
        }
        return false
    }

    function openApplicationContextMenu(sourceItem, storageId, x, y) {
        const normalizedId = String(storageId || "")
        if (normalizedId.length === 0) {
            return
        }
        applicationContextMenu.targetStorageId = normalizedId
        applicationContextMenu.targetIsFavorite = isFavorite(normalizedId)
        applicationContextMenu.popup(sourceItem, x, y)
    }

    function openCurrentApplicationContextMenu() {
        const currentItem = applicationsGrid.currentItem
        const index = applicationsGrid.currentIndex
        if (!currentItem || index < 0 || index >= visibleApplicationsModel.count) {
            return
        }
        const application = visibleApplicationsModel.get(index)
        openApplicationContextMenu(currentItem,
            String(application.appStorageId || ""),
            currentItem.width / 2, currentItem.height / 2)
    }

    function openCurrentFavoriteContextMenu() {
        const currentItem = favoritesView.currentItem
        const index = favoritesView.currentIndex
        if (!currentItem || index < 0 || index >= favorites.length) {
            return
        }
        openApplicationContextMenu(currentItem,
            String(favorites[index].appStorageId || ""),
            currentItem.width / 2, currentItem.height / 2)
    }

    function appendApplication(model, application) {
        if (!application) {
            return
        }
        const name = String(application.name || "").trim()
        const storageId = String(application.storageId || "").trim()
        const command = String(application.command || "").trim()
        if (name.length === 0 || (storageId.length === 0 && command.length === 0)) {
            return
        }
        model.append({
            appName: name.substring(0, 256),
            appIcon: String(application.icon || "application-x-executable").substring(0, 512),
            appStorageId: storageId.substring(0, 512),
            appCommand: command.substring(0, 2048)
        })
    }

    function filterAllApplications() {
        if (!menuOpen) {
            return
        }
        const query = searchField.text.trim().toLocaleLowerCase()
        if (query.length === 0) {
            selectCategory(activeCategoryKey, activeCategoryTitle, false)
            return
        }

        visibleApplicationsModel.clear()
        for (let index = 0; index < allApplicationsModel.count; index++) {
            const application = allApplicationsModel.get(index)
            if (String(application.appName || "").toLocaleLowerCase().indexOf(query) >= 0) {
                visibleApplicationsModel.append(application)
            }
        }
        applicationsLoading = allApplicationsModel.count === 0 && pendingCategoryKey === "__all__"
        applicationsGrid.currentIndex = visibleApplicationsModel.count > 0 ? 0 : -1
        applicationsGrid.positionViewAtBeginning()
    }

    function requestAllApplications() {
        allApplicationsModel.clear()
        pendingCategoryKey = "__all__"
        systemDiscovery.requestApplications("")
    }

    function selectCategory(categoryKey, title, clearSearch) {
        if (clearSearch && searchField.text.length > 0) {
            suppressSearchChange = true
            searchField.clear()
            suppressSearchChange = false
        }
        activeCategoryKey = String(categoryKey)
        activeCategoryTitle = String(title)
        applicationErrorMessage = ""
        applicationLaunchPending = false

        applicationsLoading = true
        visibleApplicationsModel.clear()
        pendingCategoryKey = activeCategoryKey
        systemDiscovery.requestApplications(activeCategoryKey)
    }

    function launchApplication(storageId, command) {
        if (applicationLaunchPending) {
            return
        }
        applicationErrorMessage = ""
        if (storageId.length > 0) {
            applicationLaunchPending = true
            systemDiscovery.launchApplication(storageId)
            return
        }
        if (command.length > 0 && systemDiscovery.launchApplicationByCommand(command)) {
            forceClose()
            return
        }
        applicationErrorMessage = i18nc("@info:status", "This application could not be resolved safely.")
    }

    function launchCurrentApplication() {
        const index = applicationsGrid.currentIndex
        if (index < 0 || index >= visibleApplicationsModel.count) {
            return
        }
        const application = visibleApplicationsModel.get(index)
        launchApplication(String(application.appStorageId || ""),
            String(application.appCommand || ""))
    }

    function launchCurrentFavorite() {
        const index = favoritesView.currentIndex
        if (index < 0 || index >= favorites.length) {
            return
        }
        const favorite = favorites[index]
        launchApplication(String(favorite.appStorageId || ""), "")
    }

    function openMenu() {
        closeTimer.stop()
        menuOpen = true
        applicationErrorMessage = ""
        applicationLaunchPending = false
        activeCategoryKey = "Network"
        activeCategoryTitle = i18nc("@title:category", "Internet")
        categoriesView.currentIndex = categoryIndexForKey(activeCategoryKey)
        categoriesView.positionViewAtBeginning()
        suppressSearchChange = true
        searchField.clear()
        suppressSearchChange = false
        requestAllApplications()
        selectCategory(activeCategoryKey, activeCategoryTitle, false)
        searchField.forceActiveFocus()
    }

    function forceClose() {
        applicationContextMenu.close()
        closeTimer.stop()
        menuOpen = false
        applicationLaunchPending = false
        closeTimer.restart()
    }

    function resetMenu() {
        applicationContextMenu.close()
        closeTimer.stop()
        menuOpen = false
        applicationsLoading = false
        applicationLaunchPending = false
        applicationErrorMessage = ""
        pendingCategoryKey = ""
        suppressSearchChange = true
        searchField.clear()
        suppressSearchChange = false
        visibleApplicationsModel.clear()
        allApplicationsModel.clear()
    }

    Keys.onEscapePressed: function(event) {
        root.forceClose()
        event.accepted = true
    }

    Punchi.BlurBehindController {
        id: blurController
        window: root.Window.window
        fullWindow: true
        enabled: root.menuOpen
    }

    Timer {
        id: closeTimer
        interval: root.closeDuration
        repeat: false
        onTriggered: root.closeFinished()
    }

    ListModel {
        id: categoryModel
    }

    Component.onCompleted: {
        categoryModel.append({ categoryKey: "Network", titleName: i18nc("@title:category", "Internet") })
        categoryModel.append({ categoryKey: "Graphics", titleName: i18nc("@title:category", "Graphics") })
        categoryModel.append({ categoryKey: "AudioVideo", titleName: i18nc("@title:category", "Multimedia") })
        categoryModel.append({ categoryKey: "Office", titleName: i18nc("@title:category", "Office") })
        categoryModel.append({ categoryKey: "Development", titleName: i18nc("@title:category", "Development") })
        categoryModel.append({ categoryKey: "System", titleName: i18nc("@title:category", "System") })
        categoryModel.append({ categoryKey: "Utility", titleName: i18nc("@title:category", "Utilities") })
        categoryModel.append({ categoryKey: "Game", titleName: i18nc("@title:category", "Games") })
        categoryModel.append({ categoryKey: "Education", titleName: i18nc("@title:category", "Education") })
    }

    ListModel { id: allApplicationsModel }
    ListModel { id: visibleApplicationsModel }

    Punchi.SessionActionsController {
        id: sessionActions
    }

    Controls.Menu {
        id: applicationContextMenu

        property string targetStorageId: ""
        property bool targetIsFavorite: false

        Controls.MenuItem {
            text: applicationContextMenu.targetIsFavorite
                ? i18nc("@action:inmenu", "Remove from Favorites")
                : i18nc("@action:inmenu", "Add to Favorites")
            icon.name: applicationContextMenu.targetIsFavorite
                ? "list-remove-symbolic"
                : "favorite-symbolic"
            enabled: applicationContextMenu.targetIsFavorite
                || !root.favoriteLimitReached
            Accessible.name: text
            onTriggered: {
                const storageId = applicationContextMenu.targetStorageId
                if (applicationContextMenu.targetIsFavorite) {
                    const removingLastFavorite = root.favorites.length === 1
                    root.removeFavoriteRequested(storageId)
                    if (removingLastFavorite) {
                        Qt.callLater(root.focusApplicationsGrid)
                    }
                } else {
                    root.addFavoriteRequested(storageId)
                }
            }
        }
    }

    Connections {
        target: root.systemDiscovery
        ignoreUnknownSignals: true

        function onApplicationsReady(applications) {
            const list = applications || []
            if (root.pendingCategoryKey === "__all__") {
                allApplicationsModel.clear()
                for (let index = 0; index < list.length; index++) {
                    root.appendApplication(allApplicationsModel, list[index])
                }
                root.pendingCategoryKey = ""
                if (searchField.text.length > 0) {
                    root.filterAllApplications()
                }
                return
            }

            visibleApplicationsModel.clear()
            for (let index = 0; index < list.length; index++) {
                root.appendApplication(visibleApplicationsModel, list[index])
            }
            root.pendingCategoryKey = ""
            root.applicationsLoading = false
            applicationsGrid.currentIndex = visibleApplicationsModel.count > 0 ? 0 : -1
            applicationsGrid.positionViewAtBeginning()
        }

        function onApplicationLaunchFinished(succeeded, message) {
            if (!root.applicationLaunchPending) {
                return
            }
            root.applicationLaunchPending = false
            if (succeeded) {
                root.forceClose()
            } else {
                root.applicationErrorMessage = String(message || "")
            }
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius * 2
        color: Qt.alpha(Kirigami.Theme.backgroundColor, root.surfaceOpacity)
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.22)
        border.width: 1
        clip: true
        opacity: root.menuOpen ? 1.0 : 0.0
        transform: Translate {
            y: root.menuOpen ? 0 : Kirigami.Units.gridUnit * 0.65

            Behavior on y {
                enabled: root.motionEnabled
                NumberAnimation {
                    duration: root.menuOpen ? root.openDuration : root.closeDuration
                    easing.type: root.menuOpen ? Easing.OutCubic : Easing.InQuad
                }
            }
        }

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.menuOpen ? root.openDuration : root.closeDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InQuad
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.mediumSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: width
                    source: KCoreAddons.KOSRelease.logo.length > 0
                        ? KCoreAddons.KOSRelease.logo
                        : "start-here-kde"
                    Accessible.role: Accessible.Graphic
                    Accessible.name: KCoreAddons.KOSRelease.prettyName

                    Controls.ToolTip.visible: distributionHover.containsMouse
                    Controls.ToolTip.text: KCoreAddons.KOSRelease.prettyName
                    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

                    MouseArea {
                        id: distributionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                Kirigami.SearchField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: i18nc("@placeholder", "Search applications…")
                    Accessible.name: i18nc("@label", "Search applications")
                    KeyNavigation.tab: btnLogOut.enabled ? btnLogOut : (btnReboot.enabled ? btnReboot : (btnShutdown.enabled ? btnShutdown : btnClose))
                    onTextChanged: {
                        if (!root.suppressSearchChange) {
                            root.filterAllApplications()
                        }
                    }
                    Keys.onDownPressed: function(event) {
                        if (visibleApplicationsModel.count > 0) {
                            root.focusApplicationsGrid()
                            event.accepted = true
                        }
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnLogOut
                    icon.name: "system-log-out"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Log Out")
                    Accessible.name: text
                    Controls.ToolTip.visible: hovered || activeFocus
                    Controls.ToolTip.text: text
                    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                    enabled: sessionActions.canLogout
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.right: btnReboot.enabled ? btnReboot : (btnShutdown.enabled ? btnShutdown : btnClose)
                    KeyNavigation.down: categoriesView
                    onClicked: {
                        root.forceClose()
                        sessionActions.requestLogout()
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnReboot
                    icon.name: "system-reboot"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Restart")
                    Accessible.name: text
                    Controls.ToolTip.visible: hovered || activeFocus
                    Controls.ToolTip.text: text
                    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                    enabled: sessionActions.canReboot
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.left: btnLogOut.enabled ? btnLogOut : null
                    KeyNavigation.right: btnShutdown.enabled ? btnShutdown : btnClose
                    KeyNavigation.down: categoriesView
                    onClicked: {
                        root.forceClose()
                        sessionActions.requestReboot()
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnShutdown
                    icon.name: "system-shutdown"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Shut Down")
                    Accessible.name: text
                    Controls.ToolTip.visible: hovered || activeFocus
                    Controls.ToolTip.text: text
                    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                    enabled: sessionActions.canShutdown
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.left: btnReboot.enabled ? btnReboot : (btnLogOut.enabled ? btnLogOut : null)
                    KeyNavigation.right: btnClose
                    KeyNavigation.down: categoriesView
                    onClicked: {
                        root.forceClose()
                        sessionActions.requestShutdown()
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnClose
                    icon.name: "window-close-symbolic"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Close")
                    Accessible.name: text
                    Controls.ToolTip.visible: hovered || activeFocus
                    Controls.ToolTip.text: text
                    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.left: btnShutdown.enabled ? btnShutdown : (btnReboot.enabled ? btnReboot : (btnLogOut.enabled ? btnLogOut : null))
                    KeyNavigation.down: categoriesView
                    onClicked: root.forceClose()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.65

                RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.ToolButton {
                        id: categoryLeftEdge
                        readonly property bool canScroll:
                            categoriesView.contentWidth > categoriesView.width
                            && !categoriesView.atXBeginning
                        property bool autoScrollSuppressed: false

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.fillHeight: true
                        icon.name: "go-previous-symbolic"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll categories left")
                        Accessible.name: text
                        activeFocusOnTab: false
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateCategoryEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollCategoriesBy(-Kirigami.Units.gridUnit * 8.4)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }
                    }

                    ListView {
                        id: categoriesView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: ListView.Horizontal
                        spacing: Kirigami.Units.smallSpacing
                        clip: true
                        model: categoryModel
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationWraps: false
                        activeFocusOnTab: true
                        KeyNavigation.tab: applicationsGrid
                        KeyNavigation.backtab: btnClose

                        onDraggingChanged: {
                            if (dragging) {
                                categoryScrollAnimation.stop()
                            }
                        }

                        onFlickingChanged: {
                            if (flicking) {
                                categoryScrollAnimation.stop()
                            }
                        }

                        onActiveFocusChanged: {
                            if (activeFocus && currentIndex < 0) {
                                currentIndex = root.categoryIndexForKey(root.activeCategoryKey)
                            }
                            if (activeFocus && currentIndex >= 0) {
                                positionViewAtIndex(currentIndex, ListView.Contain)
                            }
                        }

                        onCurrentIndexChanged: {
                            if (activeFocus && currentIndex >= 0) {
                                positionViewAtIndex(currentIndex, ListView.Contain)
                            }
                        }

                        Keys.onDownPressed: function(event) {
                            if (visibleApplicationsModel.count > 0) {
                                root.focusApplicationsGrid()
                                event.accepted = true
                            }
                        }

                        Keys.onReturnPressed: function(event) {
                            if (currentIndex >= 0 && currentIndex < categoryModel.count) {
                                const category = categoryModel.get(currentIndex)
                                root.selectCategory(category.categoryKey, category.titleName, true)
                                event.accepted = true
                            }
                        }

                        Keys.onEnterPressed: function(event) {
                            if (currentIndex >= 0 && currentIndex < categoryModel.count) {
                                const category = categoryModel.get(currentIndex)
                                root.selectCategory(category.categoryKey, category.titleName, true)
                                event.accepted = true
                            }
                        }

                        Keys.onSpacePressed: function(event) {
                            if (currentIndex >= 0 && currentIndex < categoryModel.count) {
                                const category = categoryModel.get(currentIndex)
                                root.selectCategory(category.categoryKey, category.titleName, true)
                                event.accepted = true
                            }
                        }

                        delegate: Kirigami.Chip {
                            id: categoryChip
                            required property string categoryKey
                            required property string titleName
                            required property int index

                            width: Kirigami.Units.gridUnit * 8.2
                            height: Kirigami.Units.gridUnit * 2.25
                            text: titleName
                            display: Controls.AbstractButton.TextOnly
                            closable: false
                            checked: root.activeCategoryKey === categoryKey
                            scale: down ? 0.98 : hovered ? 1.015 : 1.0
                            Accessible.name: titleName
                            Accessible.checked: checked
                            Accessible.focused: categoriesView.activeFocus
                                && categoriesView.currentIndex === index
                            activeFocusOnTab: false
                            labelItem.wrapMode: Text.WordWrap
                            labelItem.maximumLineCount: 2
                            labelItem.elide: Text.ElideRight
                            onClicked: {
                                categoriesView.currentIndex = index
                                root.selectCategory(categoryKey, titleName, true)
                            }

                            Behavior on scale {
                                enabled: root.motionEnabled
                                NumberAnimation {
                                    duration: Math.max(90,
                                        Math.min(140, Kirigami.Units.shortDuration))
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.checked ? parent.width * 0.58 : 0
                                height: 2
                                radius: 1
                                color: Kirigami.Theme.highlightColor
                                visible: width > 0

                                Behavior on width {
                                    enabled: root.motionEnabled
                                    NumberAnimation {
                                        duration: Math.max(100,
                                            Math.min(160, Kirigami.Units.shortDuration))
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Math.max(0, Kirigami.Units.cornerRadius - 1)
                                color: "transparent"
                                border.color: Kirigami.Theme.highlightColor
                                border.width: 2
                                visible: categoriesView.activeFocus
                                    && categoriesView.currentIndex === index
                                Accessible.ignored: true
                            }
                        }
                    }

                    PlasmaComponents.ToolButton {
                        id: categoryRightEdge
                        readonly property bool canScroll:
                            categoriesView.contentWidth > categoriesView.width
                            && !categoriesView.atXEnd
                        property bool autoScrollSuppressed: false

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.fillHeight: true
                        icon.name: "go-next-symbolic"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll categories right")
                        Accessible.name: text
                        activeFocusOnTab: false
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateCategoryEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollCategoriesBy(Kirigami.Units.gridUnit * 8.4)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }
                    }
                }

                SmoothedAnimation {
                    id: categoryScrollAnimation

                    property bool edgeDriven: false

                    target: categoriesView
                    property: "contentX"
                    maximumEasingTime: 120
                    onFinished: root.updateCategoryEdgeScroll()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridView {
                    id: applicationsGrid
                    anchors.fill: parent
                    model: visibleApplicationsModel
                    cellWidth: width / root.columnCount
                    cellHeight: Math.max(Kirigami.Units.gridUnit * 7.5,
                        Kirigami.Units.iconSizes.large * root.safeApplicationIconScale
                            + Kirigami.Units.gridUnit * 3)
                    clip: true
                    focus: true
                    activeFocusOnTab: true
                    enabled: !root.applicationLaunchPending
                    keyNavigationWraps: false
                    KeyNavigation.backtab: categoriesView

                    onActiveFocusChanged: {
                        if (activeFocus && visibleApplicationsModel.count > 0) {
                            if (currentIndex < 0
                                    || currentIndex >= visibleApplicationsModel.count) {
                                currentIndex = 0
                            }
                            positionViewAtIndex(currentIndex, GridView.Contain)
                        }
                    }

                    PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
                        policy: PlasmaComponents.ScrollBar.AsNeeded
                    }

                    Keys.onReturnPressed: function(event) {
                        root.launchCurrentApplication()
                        event.accepted = true
                    }
                    Keys.onEnterPressed: function(event) {
                        root.launchCurrentApplication()
                        event.accepted = true
                    }
                    Keys.onSpacePressed: function(event) {
                        root.launchCurrentApplication()
                        event.accepted = true
                    }
                    Keys.onUpPressed: function(event) {
                        if (currentIndex >= 0 && currentIndex < root.columnCount) {
                            root.focusActiveCategory()
                            event.accepted = true
                        } else {
                            event.accepted = false
                        }
                    }
                    Keys.onDownPressed: function(event) {
                        if (root.favoritesSectionVisible
                                && currentIndex >= 0
                                && currentIndex + root.columnCount
                                    >= visibleApplicationsModel.count) {
                            root.focusFavorites()
                            event.accepted = true
                        } else {
                            event.accepted = false
                        }
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Menu
                                || (event.key === Qt.Key_F10
                                    && (event.modifiers & Qt.ShiftModifier))) {
                            root.openCurrentApplicationContextMenu()
                            event.accepted = true
                        }
                    }

                    delegate: Item {
                        id: applicationDelegate
                        required property string appName
                        required property string appIcon
                        required property string appStorageId
                        required property string appCommand
                        required property int index

                        width: applicationsGrid.cellWidth
                        height: applicationsGrid.cellHeight
                        readonly property bool keyboardFocused:
                            applicationsGrid.activeFocus
                            && applicationsGrid.currentIndex === index
                        readonly property bool selected: keyboardFocused
                            || applicationMouseArea.containsMouse
                        readonly property real iconSize: Math.max(
                            Kirigami.Units.iconSizes.medium,
                            Math.min(Kirigami.Units.iconSizes.huge * root.safeApplicationIconScale,
                                width * 0.58, height * 0.55))
                        Accessible.role: Accessible.Button
                        Accessible.name: appName
                        Accessible.focused: keyboardFocused
                        Accessible.onPressAction: launchApp()

                        function launchApp() {
                            applicationsGrid.currentIndex = index
                            root.launchApplication(appStorageId, appCommand)
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            radius: Kirigami.Units.cornerRadius * 1.5
                            color: applicationDelegate.selected
                                ? Qt.alpha(Kirigami.Theme.highlightColor, 0.24)
                                : "transparent"
                            border.color: applicationDelegate.selected
                                ? Kirigami.Theme.highlightColor
                                : "transparent"
                            border.width: applicationDelegate.selected ? 2 : 0
                            scale: applicationMouseArea.pressed
                                ? 0.97
                                : applicationDelegate.selected ? 1.018 : 1.0

                            Behavior on scale {
                                enabled: root.motionEnabled
                                NumberAnimation {
                                    duration: applicationMouseArea.pressed ? 80 : 130
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                enabled: root.motionEnabled
                                ColorAnimation {
                                    duration: Math.max(90,
                                        Math.min(150, Kirigami.Units.shortDuration))
                                }
                            }

                            Behavior on border.color {
                                enabled: root.motionEnabled
                                ColorAnimation {
                                    duration: Math.max(90,
                                        Math.min(150, Kirigami.Units.shortDuration))
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: applicationDelegate.iconSize
                                    Layout.preferredHeight: width
                                    source: applicationDelegate.appIcon
                                }

                                PlasmaComponents.Label {
                                    id: applicationLabel
                                    Layout.fillWidth: true
                                    text: applicationDelegate.appName
                                    horizontalAlignment: Text.AlignHCenter
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: applicationMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onEntered: applicationsGrid.currentIndex = applicationDelegate.index
                                onClicked: function(mouse) {
                                    applicationsGrid.currentIndex = applicationDelegate.index
                                    if (mouse.button === Qt.RightButton) {
                                        root.openApplicationContextMenu(
                                            applicationDelegate,
                                            applicationDelegate.appStorageId,
                                            mouse.x, mouse.y)
                                    } else {
                                        applicationDelegate.launchApp()
                                    }
                                }
                            }

                            Controls.ToolTip.visible: applicationMouseArea.containsMouse
                                && applicationLabel.truncated
                            Controls.ToolTip.text: applicationDelegate.appName
                            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
                        Kirigami.Units.gridUnit * 24)
                    visible: root.applicationsLoading
                        || (!root.applicationsLoading && visibleApplicationsModel.count === 0)
                    spacing: Kirigami.Units.mediumSpacing

                    Controls.BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.applicationsLoading
                        running: visible
                    }

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: width
                        visible: !root.applicationsLoading
                        source: searchField.text.length > 0 ? "edit-find" : "edit-none"
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: root.applicationsLoading
                            ? i18nc("@info:status", "Loading applications…")
                            : searchField.text.length > 0
                                ? i18nc("@info:status", "No applications match your search.")
                                : i18nc("@info:status", "No applications were found in this category.")
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Accessible.role: Accessible.StaticText
                        Accessible.name: text
                    }
                }

                Kirigami.InlineMessage {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, Kirigami.Units.gridUnit * 30)
                    visible: root.applicationErrorMessage.length > 0
                    type: Kirigami.MessageType.Error
                    text: i18nc("@info:status", "Application could not be opened: %1",
                        root.applicationErrorMessage)
                }
            }

            ColumnLayout {
                id: favoritesSection

                readonly property real reservedHeight:
                    Kirigami.Units.gridUnit * 7.1

                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.minimumHeight: visible ? reservedHeight : 0
                Layout.preferredHeight: visible ? reservedHeight : 0
                Layout.maximumHeight: visible ? reservedHeight : 0
                visible: root.favoritesSectionVisible
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: width
                        source: "favorite-symbolic"
                        Accessible.ignored: true
                    }

                    Kirigami.Heading {
                        level: 4
                        text: i18nc("@title:section", "Favorites")
                        Accessible.role: Accessible.Heading
                        Accessible.name: text
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.ToolButton {
                        id: favoritesLeftEdge
                        readonly property bool canScroll:
                            favoritesView.contentWidth > favoritesView.width
                            && !favoritesView.atXBeginning
                        property bool autoScrollSuppressed: false

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.fillHeight: true
                        icon.name: "go-previous-symbolic"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll favorites left")
                        Accessible.name: text
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateFavoritesEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollFavoritesBy(-favoritesView.delegateWidth)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }
                    }

                    ListView {
                        id: favoritesView

                        readonly property real delegateWidth:
                            Kirigami.Units.gridUnit * 6.6

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: ListView.Horizontal
                        spacing: Kirigami.Units.smallSpacing
                        clip: true
                        model: root.favorites
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationWraps: false
                        activeFocusOnTab: root.favoritesSectionVisible

                        onDraggingChanged: {
                            if (dragging) {
                                favoritesScrollAnimation.stop()
                            }
                        }

                        onFlickingChanged: {
                            if (flicking) {
                                favoritesScrollAnimation.stop()
                            }
                        }

                        onActiveFocusChanged: {
                            if (activeFocus && count > 0) {
                                if (currentIndex < 0 || currentIndex >= count) {
                                    currentIndex = 0
                                }
                                positionViewAtIndex(currentIndex, ListView.Contain)
                            }
                        }

                        onCurrentIndexChanged: {
                            if (activeFocus && currentIndex >= 0) {
                                positionViewAtIndex(currentIndex, ListView.Contain)
                            }
                        }

                        onCountChanged: {
                            if (count > 0 && currentIndex < 0) {
                                currentIndex = 0
                            } else if (currentIndex >= count) {
                                currentIndex = count - 1
                            }
                        }

                        Keys.onUpPressed: function(event) {
                            root.focusApplicationsGrid()
                            event.accepted = true
                        }
                        Keys.onReturnPressed: function(event) {
                            root.launchCurrentFavorite()
                            event.accepted = true
                        }
                        Keys.onEnterPressed: function(event) {
                            root.launchCurrentFavorite()
                            event.accepted = true
                        }
                        Keys.onSpacePressed: function(event) {
                            root.launchCurrentFavorite()
                            event.accepted = true
                        }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Menu
                                    || (event.key === Qt.Key_F10
                                        && (event.modifiers & Qt.ShiftModifier))) {
                                root.openCurrentFavoriteContextMenu()
                                event.accepted = true
                            }
                        }

                        delegate: Item {
                            id: favoriteDelegate

                            required property var modelData
                            required property int index

                            width: favoritesView.delegateWidth
                            height: favoritesView.height
                            readonly property string appName:
                                String(modelData.appName || "")
                            readonly property string appIcon:
                                String(modelData.appIcon || "application-x-executable")
                            readonly property string appStorageId:
                                String(modelData.appStorageId || "")
                            readonly property bool keyboardFocused:
                                favoritesView.activeFocus
                                && favoritesView.currentIndex === index
                            readonly property bool selected: keyboardFocused
                                || favoriteMouseArea.containsMouse
                            Accessible.role: Accessible.Button
                            Accessible.name: appName
                            Accessible.focused: keyboardFocused
                            Accessible.onPressAction: launchFavorite()

                            function launchFavorite() {
                                favoritesView.currentIndex = index
                                root.launchApplication(appStorageId, "")
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                radius: Kirigami.Units.cornerRadius * 1.5
                                color: favoriteDelegate.selected
                                    ? Qt.alpha(Kirigami.Theme.highlightColor, 0.24)
                                    : "transparent"
                                border.color: favoriteDelegate.selected
                                    ? Kirigami.Theme.highlightColor
                                    : "transparent"
                                border.width: favoriteDelegate.selected ? 2 : 0
                                scale: favoriteMouseArea.pressed
                                    ? 0.97
                                    : favoriteDelegate.selected ? 1.018 : 1.0

                                Behavior on scale {
                                    enabled: root.motionEnabled
                                    NumberAnimation {
                                        duration: favoriteMouseArea.pressed ? 80 : 130
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    enabled: root.motionEnabled
                                    ColorAnimation {
                                        duration: Math.max(90,
                                            Math.min(150, Kirigami.Units.shortDuration))
                                    }
                                }

                                Behavior on border.color {
                                    enabled: root.motionEnabled
                                    ColorAnimation {
                                        duration: Math.max(90,
                                            Math.min(150, Kirigami.Units.shortDuration))
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    Kirigami.Icon {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: Math.min(
                                            Kirigami.Units.iconSizes.large
                                                * root.safeApplicationIconScale,
                                            favoriteDelegate.height * 0.58)
                                        Layout.preferredHeight: width
                                        source: favoriteDelegate.appIcon
                                    }

                                    PlasmaComponents.Label {
                                        id: favoriteLabel
                                        Layout.fillWidth: true
                                        text: favoriteDelegate.appName
                                        horizontalAlignment: Text.AlignHCenter
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: favoriteMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: favoritesView.currentIndex = favoriteDelegate.index
                                    onClicked: function(mouse) {
                                        favoritesView.currentIndex = favoriteDelegate.index
                                        if (mouse.button === Qt.RightButton) {
                                            root.openApplicationContextMenu(
                                                favoriteDelegate,
                                                favoriteDelegate.appStorageId,
                                                mouse.x, mouse.y)
                                        } else {
                                            favoriteDelegate.launchFavorite()
                                        }
                                    }
                                }

                                Controls.ToolTip.visible: favoriteMouseArea.containsMouse
                                    && favoriteLabel.truncated
                                Controls.ToolTip.text: favoriteDelegate.appName
                                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                            }
                        }
                    }

                    PlasmaComponents.ToolButton {
                        id: favoritesRightEdge
                        readonly property bool canScroll:
                            favoritesView.contentWidth > favoritesView.width
                            && !favoritesView.atXEnd
                        property bool autoScrollSuppressed: false

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.fillHeight: true
                        icon.name: "go-next-symbolic"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll favorites right")
                        Accessible.name: text
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateFavoritesEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollFavoritesBy(favoritesView.delegateWidth)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }
                    }
                }

                SmoothedAnimation {
                    id: favoritesScrollAnimation

                    property bool edgeDriven: false

                    target: favoritesView
                    property: "contentX"
                    maximumEasingTime: 120
                    onFinished: root.updateFavoritesEdgeScroll()
                }
            }
        }
    }
}
// qmllint enable unqualified
