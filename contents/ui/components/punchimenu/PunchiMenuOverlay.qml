import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../org/punchi/dock" as Punchi

// qmllint disable import
// qmllint disable unqualified
FocusScope {
    id: root

    // Z: 1 to ensure the Overlay renders BEHIND the Dock (which is on Z: 10)
    z: 1
    visible: menuOpen || backdropContainer.opacity > 0.01
    enabled: menuOpen

    required property var systemDiscovery
    property real applicationIconScale: 1.0
    property bool menuOpen: false
    property string activeCategoryTitle: ""
    property bool inGridView: false
    property bool applicationsLoading: false
    property bool applicationLaunchPending: false
    property string applicationErrorMessage: ""
    property bool categoryNavigationActive: false
    property int pendingCategoryStep: 0
    onInGridViewChanged: {
        if (inGridView) {
            appsGridView.currentIndex = 0
            appsGridView.forceActiveFocus()
        } else {
            root.forceActiveFocus()
        }
    }

    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property int categoryMoveDuration: motionEnabled
        ? Math.max(Kirigami.Units.shortDuration,
            Math.min(320, Math.round(Kirigami.Units.longDuration * 1.25)))
        : 0
    readonly property int categoryInputWindow: motionEnabled
        ? categoryMoveDuration
        : 120
    readonly property real backdropOpacity: nativeBlurController.available ? 0.50 : 0.72
    readonly property real safeApplicationIconScale: {
        const requestedScale = Number(applicationIconScale)
        return Number.isFinite(requestedScale)
            ? Math.max(0.75, Math.min(1.50, requestedScale))
            : 1.0
    }
    readonly property real responsiveApplicationIconBase: Math.max(
        Kirigami.Units.iconSizes.large,
        Math.min(Kirigami.Units.iconSizes.huge, Math.min(width, height) / 16))

    Punchi.BlurBehindController {
        id: nativeBlurController
        window: root.Window.window
        fullWindow: true
        enabled: root.menuOpen
    }

    signal closeFinished()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (root.inGridView) {
                root.inGridView = false
            } else {
                root.forceClose()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            if (root.inGridView) {
                if (appsGridView.count > 0) {
                    appsGridView.currentIndex = Math.max(0, appsGridView.currentIndex - 1)
                }
                event.accepted = true
            } else {
                root.requestCategoryStep(-1)
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Right) {
            if (root.inGridView) {
                if (appsGridView.count > 0) {
                    appsGridView.currentIndex = Math.min(appsGridView.count - 1, appsGridView.currentIndex + 1)
                }
                event.accepted = true
            } else {
                root.requestCategoryStep(1)
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Up) {
            if (root.inGridView && appsGridView.count > 0) {
                var colsUp = Math.max(1, Math.floor(appsGridView.width / appsGridView.cellWidth))
                appsGridView.currentIndex = Math.max(0, appsGridView.currentIndex - colsUp)
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Down) {
            if (root.inGridView && appsGridView.count > 0) {
                var colsDown = Math.max(1, Math.floor(appsGridView.width / appsGridView.cellWidth))
                appsGridView.currentIndex = Math.min(appsGridView.count - 1, appsGridView.currentIndex + colsDown)
                event.accepted = true
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.inGridView) {
                var curAppItem = appsGridView.currentItem
                if (curAppItem && curAppItem["launchApp"]) {
                    curAppItem["launchApp"]()
                    event.accepted = true
                }
            } else {
                var curCatItem = pathView.currentItem
                if (curCatItem && curCatItem["selectCategory"]) {
                    curCatItem["selectCategory"]()
                    event.accepted = true
                }
            }
        } else if (event.key === Qt.Key_Backspace) {
            if (root.inGridView) {
                root.inGridView = false
                event.accepted = true
            }
        }
    }

    Shortcut {
        sequences: ["Escape", "Back"]
        enabled: root.menuOpen
        onActivated: {
            if (root.inGridView) {
                root.inGridView = false
            } else {
                root.forceClose()
            }
        }
    }

    function openOverlay() {
        closeTimer.stop()
        resetCategoryNavigation()
        menuOpen = true
        inGridView = false
        activeCategoryTitle = ""
        applicationsLoading = false
        applicationLaunchPending = false
        applicationErrorMessage = ""
        root.forceActiveFocus()
    }

    function forceClose() {
        closeTimer.stop()
        resetCategoryNavigation()
        inGridView = false
        menuOpen = false
        applicationsLoading = false
        applicationLaunchPending = false
        closeTimer.restart()
    }

    function resetOverlay() {
        closeTimer.stop()
        resetCategoryNavigation()
        inGridView = false
        menuOpen = false
        applicationsLoading = false
        applicationLaunchPending = false
        applicationErrorMessage = ""
    }

    function applyCategoryStep(step) {
        if (step < 0) {
            pathView.decrementCurrentIndex()
        } else {
            pathView.incrementCurrentIndex()
        }
    }

    function requestCategoryStep(step) {
        if (!menuOpen || inGridView || pathView.count <= 1) {
            return
        }

        var normalizedStep = step < 0 ? -1 : 1
        if (categoryNavigationActive) {
            // Keep only the most recent intent. This bounds residual movement
            // and prevents repeated input from increasing animation speed.
            pendingCategoryStep = normalizedStep
            return
        }

        categoryNavigationActive = true
        pendingCategoryStep = 0
        applyCategoryStep(normalizedStep)
        categoryNavigationTimer.restart()
    }

    function resetCategoryNavigation() {
        categoryNavigationTimer.stop()
        categoryNavigationActive = false
        pendingCategoryStep = 0
    }

    readonly property int animOpenDuration: Math.round(Kirigami.Units.longDuration * 1.1)
    readonly property int animCloseDuration: Math.round(Kirigami.Units.shortDuration * 1.4)

    Timer {
        id: closeTimer
        interval: root.animCloseDuration
        repeat: false
        onTriggered: root.closeFinished()
    }

    Timer {
        id: categoryNavigationTimer
        interval: root.categoryInputWindow
        repeat: false
        onTriggered: {
            if (!root.menuOpen || root.inGridView) {
                root.resetCategoryNavigation()
                return
            }

            if (root.pendingCategoryStep !== 0) {
                var nextStep = root.pendingCategoryStep
                root.pendingCategoryStep = 0
                root.applyCategoryStep(nextStep)
                restart()
                return
            }

            root.categoryNavigationActive = false
        }
    }

    ListModel {
        id: appsListModel
    }

    Connections {
        target: root.systemDiscovery
        ignoreUnknownSignals: true
        function onApplicationsReady(applications) {
            appsListModel.clear()
            var list = applications || []
            for (var i = 0; i < list.length; ++i) {
                var app = list[i]
                appsListModel.append({
                    appName: String(app.name || ""),
                    appIcon: String(app.icon || "application-x-executable"),
                    appStorageId: String(app.storageId || "")
                })
            }
            root.applicationsLoading = false
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

    ListModel {
        id: categoryModel
    }

    Component.onCompleted: {
        categoryModel.append({ categoryKey: "Network", titleName: i18nc("@title:category", "Internet"), categoryDesc: i18nc("@info:category", "Network"), iconName: "applications-internet", activeBadge: i18nc("@info:status", "Browser & Web") })
        categoryModel.append({ categoryKey: "Graphics", titleName: i18nc("@title:category", "Graphics"), categoryDesc: i18nc("@info:category", "Design"), iconName: "applications-graphics", activeBadge: i18nc("@info:status", "Draw & Photo") })
        categoryModel.append({ categoryKey: "AudioVideo", titleName: i18nc("@title:category", "Multimedia"), categoryDesc: i18nc("@info:category", "Media"), iconName: "applications-multimedia", activeBadge: i18nc("@info:status", "Music & Video") })
        categoryModel.append({ categoryKey: "Office", titleName: i18nc("@title:category", "Office"), categoryDesc: i18nc("@info:category", "Productivity"), iconName: "applications-office", activeBadge: i18nc("@info:status", "Documents & Sheets") })
        categoryModel.append({ categoryKey: "Development", titleName: i18nc("@title:category", "Development"), categoryDesc: i18nc("@info:category", "Code"), iconName: "applications-development", activeBadge: i18nc("@info:status", "IDEs & Tools") })
        categoryModel.append({ categoryKey: "System", titleName: i18nc("@title:category", "System"), categoryDesc: i18nc("@info:category", "OS"), iconName: "applications-system", activeBadge: i18nc("@info:status", "KDE Plasma 6") })
        categoryModel.append({ categoryKey: "Utility", titleName: i18nc("@title:category", "Utilities"), categoryDesc: i18nc("@info:category", "Tools"), iconName: "applications-utilities", activeBadge: i18nc("@info:status", "System Utilities") })
        categoryModel.append({ categoryKey: "Game", titleName: i18nc("@title:category", "Games"), categoryDesc: i18nc("@info:category", "Entertainment"), iconName: "applications-games", activeBadge: i18nc("@info:status", "Play & Steam") })
        categoryModel.append({ categoryKey: "Education", titleName: i18nc("@title:category", "Education"), categoryDesc: i18nc("@info:category", "Science"), iconName: "applications-science", activeBadge: i18nc("@info:status", "Learn & Study") })
    }

    // 1. Fullscreen Backdrop & Blur Layer
    Item {
        id: backdropContainer
        anchors.fill: parent
        opacity: root.menuOpen ? 1.0 : 0.0

        Behavior on opacity {
            enabled: Kirigami.Units.longDuration > 0
            NumberAnimation {
                duration: root.menuOpen ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InQuad
            }
        }

        // Lightweight themed fallback. KWin provides blur when available;
        // otherwise this translucent scrim preserves contrast without
        // decoding or filtering a wallpaper image.
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            opacity: root.backdropOpacity
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.forceClose()
        }
    }

    // 2. Main Content Container
    ColumnLayout {
        id: mainContentContainer
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing
        opacity: root.menuOpen ? 1.0 : 0.0
        scale: root.menuOpen ? 1.0 : 0.96
        transformOrigin: Item.Center

        Behavior on opacity {
            enabled: Kirigami.Units.longDuration > 0
            NumberAnimation {
                duration: root.menuOpen ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        Behavior on scale {
            enabled: Kirigami.Units.longDuration > 0
            NumberAnimation {
                duration: root.menuOpen ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.menuOpen ? Easing.OutBack : Easing.InCubic
            }
        }

        // Top Navigation Header
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.mediumSpacing

            PlasmaComponents.ToolButton {
                visible: root.inGridView
                icon.name: "go-previous-symbolic"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18nc("@action:button", "Back to Categories")
                Accessible.name: text
                onClicked: root.inGridView = false
            }

            Kirigami.Heading {
                level: 2
                text: root.inGridView && root.activeCategoryTitle.length > 0
                    ? root.activeCategoryTitle
                    : i18nc("@title:menu", "PunchiMenu")
            }

            PlasmaComponents.ToolButton {
                icon.name: "window-close-symbolic"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18nc("@action:button", "Close")
                Accessible.name: text
                onClicked: root.forceClose()
            }
        }

        // CAROUSEL VIEW WITH GLASSMORPHIC FRAME AND ARROWS
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0) {
                        root.requestCategoryStep(-1)
                    } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0) {
                        root.requestCategoryStep(1)
                    }
                }
            }

            // Glassmorphic Framed Container Behind Cards (Exactly from punchi-control-center)
            Rectangle {
                id: carouselFrame
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Kirigami.Units.gridUnit * 4
                anchors.rightMargin: Kirigami.Units.gridUnit * 4
                anchors.verticalCenter: parent.verticalCenter
                height: Kirigami.Units.gridUnit * 32
                radius: Kirigami.Units.cornerRadius * 3.5
                color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.45)
                border.color: Qt.alpha(Kirigami.Theme.textColor, 0.16)
                border.width: 1
                visible: !root.inGridView

                // Inner Scrim
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(Kirigami.Theme.highlightColor, 0.05)
                    border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.20)
                    border.width: 1
                }
            }

            // PathView Carousel
            PathView {
                id: pathView
                anchors.fill: parent
                model: categoryModel
                pathItemCount: 5
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightMoveDuration: root.categoryMoveDuration
                focus: !root.inGridView
                visible: !root.inGridView

                path: Path {
                    startX: Kirigami.Units.gridUnit * 5
                    startY: pathView.height / 2

                    PathLine {
                        x: pathView.width - (Kirigami.Units.gridUnit * 5)
                        y: pathView.height / 2
                    }
                }

                delegate: Item {
                    id: delegateItem
                    required property string categoryKey
                    required property string titleName
                    required property string categoryDesc
                    required property string iconName
                    required property string activeBadge
                    required property int index

                    width: Kirigami.Units.gridUnit * 19
                    height: Kirigami.Units.gridUnit * 25

                    function selectCategory() {
                        hoverTimer.stop()
                        root.resetCategoryNavigation()
                        pathView.currentIndex = delegateItem.index
                        root.activeCategoryTitle = delegateItem.titleName
                        root.applicationErrorMessage = ""
                        root.applicationLaunchPending = false
                        root.applicationsLoading = true
                        appsListModel.clear()
                        root.inGridView = true
                        root.systemDiscovery.requestApplications(delegateItem.categoryKey)
                    }

                    readonly property real baseScale: PathView.onPath ? Math.max(0.72, 1.0 - Math.abs(PathView.view.currentIndex - index) * 0.14) : 0.72
                    readonly property real hoverBoost: hoverArea.containsMouse ? 1.06 : 1.0
                    scale: baseScale * hoverBoost
                    opacity: PathView.onPath ? Math.max(0.45, 1.0 - Math.abs(PathView.view.currentIndex - index) * 0.22) : 0.45
                    z: PathView.view.currentIndex === index ? 10 : 1
                    Accessible.role: Accessible.Button
                    Accessible.name: titleName
                    Accessible.description: categoryDesc
                    Accessible.focused: PathView.view.currentIndex === index
                    Accessible.onPressAction: selectCategory()

                    Behavior on scale {
                        enabled: root.motionEnabled
                        NumberAnimation {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.OutBack
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.cornerRadius * 3
                        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.94)
                        border.color: delegateItem.PathView.view.currentIndex === delegateItem.index ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.18)
                        border.width: delegateItem.PathView.view.currentIndex === delegateItem.index ? 3 : 1
                        clip: true

                        // Wave Pulse Hover Effect
                        Rectangle {
                            id: wavePulse
                            anchors.centerIn: parent
                            width: Math.max(parent.width, parent.height) * 1.5
                            height: width
                            radius: width / 2
                            color: Qt.alpha(Kirigami.Theme.highlightColor, hoverArea.containsMouse ? 0.22 : 0.0)
                            scale: hoverArea.containsMouse ? 1.0 : 0.15
                            opacity: hoverArea.containsMouse ? 1.0 : 0.0

                            Behavior on scale {
                                enabled: root.motionEnabled
                                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                            }
                            Behavior on opacity {
                                enabled: root.motionEnabled
                                NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Math.round(Kirigami.Units.largeSpacing * 2)
                            spacing: Kirigami.Units.largeSpacing

                            // Top Circle Icon Container
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                                Layout.preferredHeight: width
                                radius: width / 2
                                color: Kirigami.Theme.highlightColor
                                scale: hoverArea.containsMouse ? 1.10 : 1.0

                                Behavior on scale {
                                    enabled: root.motionEnabled
                                    NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutBack }
                                }

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Kirigami.Units.iconSizes.huge
                                    height: width
                                    source: delegateItem.iconName
                                    color: Kirigami.Theme.highlightedTextColor
                                }
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: delegateItem.titleName
                                font.weight: Font.DemiBold
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.40
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: Kirigami.Theme.textColor
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: delegateItem.categoryDesc
                                font.pointSize: Kirigami.Theme.smallFont.pointSize * 1.15
                                color: Kirigami.Theme.disabledTextColor
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            // Bottom Status Pill Badge
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: parent.width * 0.85
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8
                                radius: Kirigami.Units.cornerRadius * 1.5
                                color: Qt.alpha(Kirigami.Theme.highlightColor, hoverArea.containsMouse ? 0.35 : 0.20)

                                Behavior on color {
                                    enabled: root.motionEnabled
                                    ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
                                }

                                PlasmaComponents.Label {
                                    anchors.centerIn: parent
                                    text: delegateItem.activeBadge
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                                    color: Kirigami.Theme.highlightColor
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }

                    Timer {
                        id: hoverTimer
                        interval: 220
                        repeat: false
                        onTriggered: {
                            if (hoverArea.containsMouse && !root.categoryNavigationActive) {
                                pathView.currentIndex = delegateItem.index
                            }
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            if (!root.categoryNavigationActive) {
                                hoverTimer.restart()
                            }
                        }
                        onExited: hoverTimer.stop()
                        onClicked: delegateItem.selectCategory()
                    }
                }
            }

            // Left Interactive Arrow Control
            MouseArea {
                id: leftEdgeArea
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.gridUnit * 1.5
                anchors.verticalCenter: parent.verticalCenter
                width: Kirigami.Units.gridUnit * 4
                height: width
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                visible: !root.inGridView
                z: 20
                onClicked: root.requestCategoryStep(-1)
                Accessible.role: Accessible.Button
                Accessible.name: i18nc("@action:button", "Previous category")
                Accessible.onPressAction: root.requestCategoryStep(-1)

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: leftEdgeArea.containsMouse ? Qt.alpha(Kirigami.Theme.backgroundColor, 0.90) : Qt.alpha(Kirigami.Theme.backgroundColor, 0.50)
                    border.color: leftEdgeArea.containsMouse ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.20)
                    border.width: 1

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                        source: "go-previous-symbolic"
                        color: leftEdgeArea.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    }
                }
            }

            // Right Interactive Arrow Control
            MouseArea {
                id: rightEdgeArea
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.gridUnit * 1.5
                anchors.verticalCenter: parent.verticalCenter
                width: Kirigami.Units.gridUnit * 4
                height: width
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                visible: !root.inGridView
                z: 20
                onClicked: root.requestCategoryStep(1)
                Accessible.role: Accessible.Button
                Accessible.name: i18nc("@action:button", "Next category")
                Accessible.onPressAction: root.requestCategoryStep(1)

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: rightEdgeArea.containsMouse ? Qt.alpha(Kirigami.Theme.backgroundColor, 0.90) : Qt.alpha(Kirigami.Theme.backgroundColor, 0.50)
                    border.color: rightEdgeArea.containsMouse ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.20)
                    border.width: 1

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                        source: "go-next-symbolic"
                        color: rightEdgeArea.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    }
                }
            }

            // Applications Grid View when a category is selected
            Item {
                id: gridContainer
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.gridUnit * 3
                anchors.rightMargin: Kirigami.Units.gridUnit * 3
                anchors.topMargin: Kirigami.Units.gridUnit * 1.5
                anchors.bottomMargin: Kirigami.Units.gridUnit * 4
                visible: opacity > 0.01 && root.inGridView
                opacity: root.inGridView ? 1.0 : 0.0
                z: 15

                Behavior on opacity {
                    enabled: Kirigami.Units.longDuration > 0
                    NumberAnimation { duration: 250; easing.type: root.inGridView ? Easing.OutCubic : Easing.InQuad }
                }

                GridView {
                    id: appsGridView
                    anchors.fill: parent
                    cellWidth: Kirigami.Units.gridUnit * 11
                    cellHeight: Kirigami.Units.gridUnit * 10
                    clip: true
                    focus: root.inGridView
                    model: appsListModel
                    enabled: !root.applicationLaunchPending

                    PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
                    }

                    onModelChanged: positionViewAtIndex(0, GridView.Beginning)

                    delegate: Item {
                        id: appDelegate
                        required property string appName
                        required property string appIcon
                        required property string appStorageId
                        required property int index

                        width: appsGridView.cellWidth
                        height: appsGridView.cellHeight

                        readonly property bool isSelected: appsGridView.currentIndex === appDelegate.index || appMouseArea.containsMouse
                        readonly property real safeIconSize: Math.max(
                            Kirigami.Units.iconSizes.medium,
                            Math.min(
                                root.responsiveApplicationIconBase * root.safeApplicationIconScale,
                                appsGridView.cellWidth * 0.55,
                                appsGridView.cellHeight * 0.52))
                        Accessible.role: Accessible.Button
                        Accessible.name: appName
                        Accessible.focused: appsGridView.currentIndex === appDelegate.index
                        Accessible.onPressAction: launchApp()

                        function launchApp() {
                            if (appDelegate.appStorageId.length > 0) {
                                root.applicationErrorMessage = ""
                                root.applicationLaunchPending = true
                                root.systemDiscovery.launchApplication(appDelegate.appStorageId)
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            radius: Kirigami.Units.cornerRadius * 2
                            color: appDelegate.isSelected ? Qt.alpha(Kirigami.Theme.highlightColor, 0.35) : Qt.alpha(Kirigami.Theme.backgroundColor, 0.70)
                            border.color: appDelegate.isSelected ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.20)
                            border.width: appDelegate.isSelected ? 2 : 1
                            scale: appDelegate.isSelected ? 1.05 : 1.0

                            Behavior on scale {
                                enabled: root.motionEnabled
                                NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - Kirigami.Units.gridUnit
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: appDelegate.safeIconSize
                                    Layout.preferredHeight: appDelegate.safeIconSize
                                    source: appDelegate.appIcon.length > 0 ? appDelegate.appIcon : "application-x-executable"
                                }

                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    text: appDelegate.appName
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize * 1.10
                                    color: Kirigami.Theme.textColor
                                }
                            }

                            MouseArea {
                                id: appMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: appsGridView.currentIndex = appDelegate.index
                                onClicked: appDelegate.launchApp()
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
                        Kirigami.Units.gridUnit * 28)
                    spacing: Kirigami.Units.largeSpacing
                    visible: root.applicationsLoading
                        || (!root.applicationsLoading && appsListModel.count === 0)
                    z: 20

                    Controls.BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        running: visible
                        visible: root.applicationsLoading
                    }

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: width
                        source: "edit-none"
                        visible: !root.applicationsLoading
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: root.applicationsLoading
                            ? i18nc("@info:status", "Loading applications…")
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
                    width: Math.min(parent.width, Kirigami.Units.gridUnit * 34)
                    visible: root.applicationErrorMessage.length > 0
                    type: Kirigami.MessageType.Error
                    text: i18nc("@info:status", "Application could not be opened: %1",
                        root.applicationErrorMessage)
                    z: 25
                }
            }
        }
    }
}
// qmllint enable unqualified
