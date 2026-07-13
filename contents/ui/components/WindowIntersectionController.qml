import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kwindowsystem
import org.kde.taskmanager as TaskManager

Item {
    id: root

    property Item targetItem: null
    property rect screenGeometry: Qt.rect(0, 0, 0, 0)
    property rect regionGeometry: Qt.rect(0, 0, 0, 0)
    property bool monitoringEnabled: true
    property bool touchingWindow: false

    readonly property bool touchingWindowDirect: monitoringEnabled
        && regionGeometry.width > 0
        && regionGeometry.height > 0
        && visibleWindowsModel.count > 0
    readonly property bool showingDesktop: KWindowSystem.showingDesktop

    visible: false

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManager.TasksModel {
        id: visibleWindowsModel

        filterByCurrentVirtualDesktop: true
        filterByActivity: true
        filterByScreen: false
        filterByRegion: root.monitoringEnabled
            ? TaskManager.RegionFilterMode.Intersect
            : TaskManager.RegionFilterMode.Disabled
        filterHidden: true
        filterMinimized: true
        screenGeometry: root.screenGeometry
        regionGeometry: root.regionGeometry
        activity: activityInfo.currentActivity
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    Timer {
        id: regionUpdateTimer
        interval: 0
        repeat: false
        onTriggered: root.updateRegionGeometry()
    }

    Timer {
        id: touchingWindowDebounceTimer
        interval: 10
        repeat: false
        onTriggered: root.touchingWindow = root.monitoringEnabled
            && !root.showingDesktop
            && root.touchingWindowDirect
    }

    Connections {
        target: root.targetItem
        enabled: target !== null

        function onWidthChanged() {
            root.scheduleRegionUpdate()
        }

        function onHeightChanged() {
            root.scheduleRegionUpdate()
        }

        function onVisibleChanged() {
            root.scheduleRegionUpdate()
        }
    }

    Connections {
        target: root.targetItem ? root.targetItem.Kirigami.ScenePosition : null
        enabled: target !== null

        function onXChanged() {
            root.scheduleRegionUpdate()
        }

        function onYChanged() {
            root.scheduleRegionUpdate()
        }
    }

    onTargetItemChanged: scheduleRegionUpdate()
    onMonitoringEnabledChanged: {
        scheduleRegionUpdate()
        scheduleTouchingWindowUpdate()
    }
    onTouchingWindowDirectChanged: scheduleTouchingWindowUpdate()
    onShowingDesktopChanged: scheduleTouchingWindowUpdate()

    Component.onCompleted: scheduleRegionUpdate()

    function scheduleRegionUpdate() {
        regionUpdateTimer.restart()
    }

    function scheduleTouchingWindowUpdate() {
        touchingWindowDebounceTimer.restart()
    }

    function updateRegionGeometry() {
        if (!monitoringEnabled || !targetItem || !targetItem.visible
                || targetItem.width <= 0 || targetItem.height <= 0) {
            regionGeometry = Qt.rect(0, 0, 0, 0)
            return
        }

        const globalPosition = targetItem.mapToGlobal(0, 0)
        regionGeometry = Qt.rect(
            Math.round(globalPosition.x),
            Math.round(globalPosition.y),
            Math.round(targetItem.width),
            Math.round(targetItem.height)
        )
    }
}
