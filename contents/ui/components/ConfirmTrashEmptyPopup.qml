import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// qmllint disable unqualified
Item {
    id: confirmRoot
    property string operationState: "idle"
    property int progressPercent: -1
    property bool progressDeterminate: false
    property int processedItems: 0
    property int totalItems: 0
    property string errorMessage: ""
    property bool busyIndicatorReady: false
    readonly property bool emptying: operationState === "emptying"
    readonly property bool finished: operationState === "succeeded"
        || operationState === "failed"
    implicitWidth: 260
    implicitHeight: operationState === "failed" ? 188 : 152
    width: implicitWidth
    height: implicitHeight

    signal confirmRequested()
    signal cancelRequested()
    signal dismissRequested()

    function focusPrimaryAction() {
        if (operationState === "idle") {
            cancelButton.forceActiveFocus()
        } else {
            closeButton.forceActiveFocus()
        }
    }

    onEmptyingChanged: {
        busyIndicatorDelay.stop()
        busyIndicatorReady = false
        if (emptying && !progressDeterminate) {
            busyIndicatorDelay.restart()
        }
    }
    onProgressDeterminateChanged: {
        if (progressDeterminate) {
            busyIndicatorDelay.stop()
            busyIndicatorReady = false
        } else if (emptying) {
            busyIndicatorDelay.restart()
        }
    }

    Timer {
        id: busyIndicatorDelay
        interval: 180
        repeat: false
        onTriggered: confirmRoot.busyIndicatorReady = confirmRoot.emptying
            && !confirmRoot.progressDeterminate
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.BusyIndicator {
                visible: confirmRoot.emptying && !confirmRoot.progressDeterminate
                    && confirmRoot.busyIndicatorReady
                running: visible
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                Accessible.name: i18n("Emptying trash")
            }

            Kirigami.Icon {
                visible: !(confirmRoot.emptying && !confirmRoot.progressDeterminate
                    && confirmRoot.busyIndicatorReady)
                source: {
                    if (confirmRoot.operationState === "succeeded") {
                        return "dialog-ok-symbolic"
                    }
                    if (confirmRoot.operationState === "failed") {
                        return "dialog-error-symbolic"
                    }
                    return confirmRoot.emptying ? "user-trash-full" : "user-trash"
                }
                color: confirmRoot.operationState === "succeeded"
                    ? Kirigami.Theme.positiveTextColor
                    : confirmRoot.operationState === "failed"
                        ? Kirigami.Theme.negativeTextColor
                        : Kirigami.Theme.textColor
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: implicitWidth
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: {
                    if (confirmRoot.operationState === "emptying") {
                        return i18n("Emptying trash…")
                    }
                    if (confirmRoot.operationState === "succeeded") {
                        return i18n("Trash emptied successfully.")
                    }
                    if (confirmRoot.operationState === "failed") {
                        return i18n("The trash could not be emptied.")
                    }
                    return i18n("Do you want to empty the trash?")
                }
                color: Kirigami.Theme.textColor
            }
        }

        Controls.ProgressBar {
            visible: confirmRoot.emptying && confirmRoot.progressDeterminate
            from: 0
            to: 100
            value: Math.max(0, confirmRoot.progressPercent)
            Layout.fillWidth: true
            Accessible.name: i18n("Trash emptying progress")
            Accessible.description: i18n("%1% completed", Math.max(0, confirmRoot.progressPercent))
        }

        PlasmaComponents.Label {
            visible: confirmRoot.emptying && confirmRoot.totalItems > 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("%1 of %2 items", confirmRoot.processedItems, confirmRoot.totalItems)
            color: Kirigami.Theme.disabledTextColor
        }

        PlasmaComponents.Label {
            visible: confirmRoot.operationState === "failed"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 3
            text: confirmRoot.errorMessage
            color: Kirigami.Theme.negativeTextColor
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8

            Controls.Button {
                id: cancelButton
                visible: confirmRoot.operationState === "idle"
                text: i18n("Cancel")
                onClicked: confirmRoot.cancelRequested()
            }

            Controls.Button {
                visible: confirmRoot.operationState === "idle"
                text: i18n("Yes")
                icon.name: "trash-empty"
                onClicked: confirmRoot.confirmRequested()
            }

            Controls.Button {
                id: closeButton
                visible: confirmRoot.operationState !== "idle"
                text: i18n("Close")
                onClicked: confirmRoot.dismissRequested()
            }
        }
    }
}
// qmllint enable unqualified
