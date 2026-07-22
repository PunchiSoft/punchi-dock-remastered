import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// qmllint disable unqualified
Item {
    id: root

    property string operationState: "idle"
    property int progressPercent: -1
    property bool progressDeterminate: false
    property int processedItems: 0
    property int totalItems: 0
    property string errorMessage: ""
    property int rowHeight: 46
    property int iconSize: 26
    property bool busyIndicatorReady: false
    readonly property bool emptying: operationState === "emptying"
    readonly property bool succeeded: operationState === "succeeded"
    readonly property bool failed: operationState === "failed"
    readonly property int effectiveRowHeight: Math.max(32, Math.min(64,
        Number(rowHeight || 46)))
    readonly property int effectiveIconSize: Math.max(24, Math.min(48,
        Number(iconSize || 26) + 8))
    readonly property string primaryText: {
        if (emptying) {
            return i18n("Emptying trash…")
        }
        if (succeeded) {
            return i18n("Trash emptied successfully.")
        }
        if (failed) {
            return i18n("The trash could not be emptied.")
        }
        return i18n("Do you want to empty the trash?")
    }
    readonly property string secondaryText: {
        if (operationState === "idle") {
            return i18n("This action cannot be undone.")
        }
        if (succeeded) {
            return i18n("All items were permanently removed.")
        }
        return ""
    }

    implicitWidth: 300
    implicitHeight: contentColumn.implicitHeight
    Accessible.role: Accessible.Grouping
    Accessible.name: primaryText

    signal confirmRequested()
    signal cancelRequested()
    signal dismissRequested()

    function focusPrimaryAction() {
        if (operationState === "idle") {
            cancelButton.forceActiveFocus(Qt.TabFocusReason)
        } else if (operationState === "failed") {
            closeButton.forceActiveFocus(Qt.TabFocusReason)
        } else if (operationState === "succeeded") {
            closeButton.forceActiveFocus(Qt.TabFocusReason)
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
    onOperationStateChanged: {
        if (succeeded || failed) {
            Qt.callLater(root.focusPrimaryAction)
        }
    }

    Timer {
        id: busyIndicatorDelay
        interval: 180
        repeat: false
        onTriggered: root.busyIndicatorReady = root.emptying
            && !root.progressDeterminate
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Controls.BusyIndicator {
                visible: root.emptying && !root.progressDeterminate
                    && root.busyIndicatorReady
                running: visible
                Layout.preferredWidth: root.effectiveIconSize
                Layout.preferredHeight: root.effectiveIconSize
                Accessible.name: i18n("Emptying trash")
            }

            Kirigami.Icon {
                visible: !(root.emptying && !root.progressDeterminate
                    && root.busyIndicatorReady)
                source: root.succeeded
                    ? "dialog-ok-symbolic"
                    : (root.failed
                        ? "dialog-error-symbolic"
                        : (root.emptying ? "user-trash-full" : "user-trash"))
                color: root.succeeded
                    ? Kirigami.Theme.positiveTextColor
                    : (root.failed
                        ? Kirigami.Theme.negativeTextColor
                        : Kirigami.Theme.textColor)
                Layout.preferredWidth: root.effectiveIconSize
                Layout.preferredHeight: root.effectiveIconSize
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 4
                    wrapMode: Text.WordWrap
                    text: root.primaryText
                }

                PlasmaComponents.Label {
                    visible: root.secondaryText.length > 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: root.secondaryText
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }

        Controls.ProgressBar {
            visible: root.emptying && root.progressDeterminate
            from: 0
            to: 100
            value: Math.max(0, root.progressPercent)
            Layout.fillWidth: true
            Accessible.name: i18n("Trash emptying progress")
            Accessible.description: i18n("%1% completed",
                Math.max(0, root.progressPercent))
        }

        PlasmaComponents.Label {
            visible: root.emptying && root.totalItems > 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("%1 of %2 items", root.processedItems, root.totalItems)
            color: Kirigami.Theme.disabledTextColor
        }

        PlasmaComponents.Label {
            visible: root.failed && root.errorMessage.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 4
            text: root.errorMessage
            color: Kirigami.Theme.negativeTextColor
            Accessible.role: Accessible.StaticText
            Accessible.name: i18n("Trash error: %1", root.errorMessage)
        }

        RowLayout {
            visible: !root.emptying
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
            }

            Controls.Button {
                id: cancelButton
                visible: root.operationState === "idle"
                Layout.preferredHeight: root.effectiveRowHeight
                text: i18n("Cancel")
                onClicked: root.cancelRequested()
            }

            Controls.Button {
                visible: root.operationState === "idle"
                Layout.preferredHeight: root.effectiveRowHeight
                text: i18n("Empty Trash")
                icon.name: "trash-empty"
                icon.color: Kirigami.Theme.negativeTextColor
                palette.buttonText: Kirigami.Theme.negativeTextColor
                Accessible.description: i18n("Permanently remove all trashed items")
                onClicked: root.confirmRequested()
            }

            Controls.Button {
                id: closeButton
                visible: root.succeeded || root.failed
                Layout.preferredHeight: root.effectiveRowHeight
                text: i18n("Close")
                onClicked: root.dismissRequested()
            }

            Controls.Button {
                visible: root.failed
                Layout.preferredHeight: root.effectiveRowHeight
                text: i18n("Try Again")
                icon.name: "view-refresh"
                onClicked: root.confirmRequested()
            }
        }
    }
}
// qmllint enable unqualified
