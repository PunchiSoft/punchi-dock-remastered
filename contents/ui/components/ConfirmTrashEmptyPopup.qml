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
    property bool canConfirm: false
    property int rowHeight: 46
    property int iconSize: 26
    property bool busyIndicatorReady: false
    readonly property bool emptying: operationState === "emptying"
    readonly property int effectiveRowHeight: Math.max(32, Math.min(36,
        Number(rowHeight || 46)))
    readonly property int effectiveIconSize: Kirigami.Units.iconSizes.huge
    readonly property string primaryText: emptying
        ? i18n("Emptying trash…")
        : i18n("Do you want to empty the trash?")
    readonly property string secondaryText: operationState === "idle"
        ? i18n("This action cannot be undone.") : ""

    implicitWidth: 300
    implicitHeight: contentColumn.implicitHeight
    Accessible.role: Accessible.Grouping
    Accessible.name: primaryText

    signal confirmRequested()
    signal cancelRequested()

    function focusPrimaryAction() {
        if (operationState === "idle") {
            cancelButton.forceActiveFocus(Qt.TabFocusReason)
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
        onTriggered: root.busyIndicatorReady = root.emptying
            && !root.progressDeterminate
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.largeSpacing

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.effectiveIconSize

            Controls.BusyIndicator {
                visible: root.emptying && !root.progressDeterminate
                    && root.busyIndicatorReady
                running: visible
                width: root.effectiveIconSize
                height: root.effectiveIconSize
                anchors.centerIn: parent
                Accessible.name: i18n("Emptying trash")
            }

            Kirigami.Icon {
                visible: !(root.emptying && !root.progressDeterminate
                    && root.busyIndicatorReady)
                anchors.centerIn: parent
                source: root.emptying ? "user-trash-full" : "user-trash"
                color: Kirigami.Theme.textColor
                width: root.effectiveIconSize
                height: root.effectiveIconSize
            }
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.primaryText
        }

        PlasmaComponents.Label {
            visible: root.secondaryText.length > 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.secondaryText
            color: Kirigami.Theme.disabledTextColor
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

        RowLayout {
            visible: !root.emptying
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: Kirigami.Units.smallSpacing

            Controls.Button {
                id: cancelButton
                Layout.fillWidth: true
                Layout.preferredHeight: root.effectiveRowHeight
                text: i18n("Cancel")
                onClicked: root.cancelRequested()
            }

            Controls.Button {
                Layout.fillWidth: true
                Layout.preferredHeight: root.effectiveRowHeight
                text: i18n("Empty Trash")
                icon.name: "edit-delete"
                icon.color: Kirigami.Theme.negativeTextColor
                palette.buttonText: Kirigami.Theme.negativeTextColor
                enabled: root.canConfirm
                Accessible.description: i18n("Permanently remove all trashed items")
                onClicked: root.confirmRequested()
            }
        }
    }
}
// qmllint enable unqualified
