import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var taskModelController: null
    property Item targetItem: null
    property var taskRows: []

    visible: false

    Timer {
        id: publishTimer
        interval: 0
        repeat: false
        onTriggered: root.publishGeometry()
    }

    Connections {
        target: root.targetItem
        enabled: target !== null

        function onWidthChanged() {
            root.schedulePublish()
        }

        function onHeightChanged() {
            root.schedulePublish()
        }

        function onVisibleChanged() {
            root.schedulePublish()
        }
    }

    // Qt 6.8 qmllint cannot infer the x/y signals exposed by the
    // Kirigami.ScenePosition attached object. The same public pattern is used
    // by WindowIntersectionController and is validated at runtime by Plasma.
    // qmllint disable missing-property
    Connections {
        target: root.targetItem ? root.targetItem.Kirigami.ScenePosition : null
        enabled: target !== null

        function onXChanged() {
            root.schedulePublish()
        }

        function onYChanged() {
            root.schedulePublish()
        }
    }
    // qmllint enable missing-property

    onTaskModelControllerChanged: schedulePublish()
    onTargetItemChanged: schedulePublish()
    onTaskRowsChanged: schedulePublish()

    Component.onCompleted: schedulePublish()

    function schedulePublish() {
        publishTimer.restart()
    }

    function publishGeometry() {
        if (!taskModelController || !targetItem || !targetItem.visible
                || targetItem.width <= 0 || targetItem.height <= 0) {
            return
        }

        taskModelController.publishDelegateGeometry(taskRows, targetItem)
    }
}
