pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami


ColumnLayout {
    id: root

    property var actionModel
    property int selectedActionIndex: -1
    property int selectedItemIndex: -1
    property string selectedItemType: "app"
    property string itemModeValue: "app"
    property string appIconText: ""
    property bool applicationLauncherDropEnabled: false
    property var applicationLauncherDropValidator: null
    property string applicationLauncherDropMessage: ""
    property bool applicationLauncherDropMessageIsError: false
    property string applicationLauncherDropState: "none"
    property real rowHeight: Kirigami.Units.gridUnit * 2.4
    property real footerHeight: Kirigami.Units.gridUnit * 2.4
    property real framePadding: Kirigami.Units.largeSpacing * 2
    property real scrollGutter: Kirigami.Units.gridUnit * 1.6
    property bool canMoveActionDown: false
    property alias actionsEnabledChecked: actionMenuEnabled.checked
    property alias actionPopupLimitRowsChecked: actionPopupLimitRows.checked
    property alias actionPopupMaxVisibleRowsValue: actionPopupMaxVisibleRows.value
    property alias actionNameText: actionName.text
    property alias actionIconText: actionIcon.text
    property alias actionCommandText: actionCommand.text
    property int actionCount: actionList.count

    property string rightClickCommandsText: "Right-click commands"
    property string containerApplicationsText: "Container applications"
    property string enableRightClickMenuText: "Enable right-click menu"
    property string limitContextMenuRowsText: "Limit menu rows"
    property string rowsText: i18n("rows") // qmllint disable unqualified
    property string rowsValueText: i18n("%1 rows") // qmllint disable unqualified
    property string actionNameLabel: "Action name:"
    property string actionIconLabel: "Action icon:"
    property string actionCommandLabel: "Action command:"
    property string chooseIconText: "Choose icon"
    property string dropApplicationsHereText: "Drop applications here"
    property string addApplicationText: "Add application"
    property string addActionText: "Add action"

    signal actionsEnabledToggled(bool checked)
    signal actionSelected(int index)
    signal addActionRequested()
    signal moveActionRequested(int delta)
    signal removeActionRequested()
    signal actionFormChanged()
    signal iconPickerRequested(string target)
    signal applicationLauncherDropped(var urls)

    function positionActionAtIndex(index) {
        if (index >= 0 && actionList.count > 0) {
            actionList.positionViewAtIndex(index, ListView.Contain)
        }
    }

    function iconPreview(value, fallback) {
        var text = String(value || "")
        return text.length > 0 ? text : fallback
    }

    function validateApplicationLauncherUrls(urls) {
        if (!root.applicationLauncherDropEnabled
                || typeof root.applicationLauncherDropValidator
                    !== "function") {
            return { "accepted": false }
        }
        try {
            const result = root.applicationLauncherDropValidator(urls || [])
            return result && result.accepted === true
                ? result : { "accepted": false }
        } catch (error) {
            return { "accepted": false }
        }
    }

    function beginApplicationLauncherDrop(urls) {
        root.applicationLauncherDropMessage = ""
        const validation = root.validateApplicationLauncherUrls(urls)
        root.applicationLauncherDropState = validation.accepted
            ? "acceptable" : "rejected"
        return validation.accepted
    }

    function finishApplicationLauncherDrop(urls) {
        const validation = root.validateApplicationLauncherUrls(urls)
        root.applicationLauncherDropState = "none"
        if (!validation.accepted) {
            return false
        }
        root.applicationLauncherDropped(urls || [])
        return true
    }

    function resetApplicationLauncherDrop() {
        root.applicationLauncherDropState = "none"
    }

    onApplicationLauncherDropEnabledChanged: {
        if (!root.applicationLauncherDropEnabled) {
            root.resetApplicationLauncherDrop()
            root.applicationLauncherDropMessage = ""
        }
    }

    visible: root.itemModeValue === "app" || root.itemModeValue === "container"
    spacing: Kirigami.Units.smallSpacing

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    Kirigami.Heading {
        Layout.fillWidth: true
        text: root.itemModeValue === "container" ? root.containerApplicationsText : root.rightClickCommandsText
        level: 3
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: root.itemModeValue === "container"
            && root.applicationLauncherDropMessage.length > 0
        text: root.applicationLauncherDropMessage
        type: root.applicationLauncherDropMessageIsError
            ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
    }

    Controls.CheckBox {
        id: actionMenuEnabled
        Layout.fillWidth: true
        visible: root.itemModeValue === "app"
        enabled: root.selectedItemType === "app"
        text: root.enableRightClickMenuText
        onClicked: root.actionsEnabledToggled(checked)
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.itemModeValue === "app" && actionMenuEnabled.checked
        enabled: root.selectedItemType === "app" && actionMenuEnabled.checked
        spacing: Kirigami.Units.smallSpacing

        Controls.CheckBox {
            id: actionPopupLimitRows
            text: root.limitContextMenuRowsText
        }

        Controls.SpinBox {
            id: actionPopupMaxVisibleRows
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            visible: actionPopupLimitRows.checked
            enabled: actionPopupLimitRows.checked
            from: 1
            to: 32
            textFromValue: function(value) {
                return i18n("%1 rows", value) // qmllint disable unqualified
            }
            valueFromText: function(text) {
                var valueText = String(text)
                return Number.fromLocaleString(Qt.locale(), valueText.replace(root.rowsText, ""))
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.rowHeight * 4 + root.footerHeight + root.framePadding
        Layout.maximumHeight: root.rowHeight * 4 + root.footerHeight + root.framePadding
        enabled: root.itemModeValue === "container" || actionMenuEnabled.checked

        Item {
            id: actionListFrame
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                visible: root.applicationLauncherDropState !== "none"
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(root.applicationLauncherDropState
                    === "acceptable" ? Kirigami.Theme.highlightColor
                    : Kirigami.Theme.negativeTextColor, 0.10)
                border.width: 2
                border.color: root.applicationLauncherDropState
                    === "acceptable" ? Kirigami.Theme.highlightColor
                    : Kirigami.Theme.negativeTextColor
                z: 0
            }

            ListView {
                id: actionList
                anchors.fill: parent
                clip: true
                model: root.actionModel
                currentIndex: root.selectedActionIndex
                boundsBehavior: Flickable.StopAtBounds
                z: 1
                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }

                delegate: Controls.ItemDelegate {
                    id: actionDelegate
                    required property int index
                    required property string title
                    required property string subtitle
                    required property string iconName

                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    property bool hasVerticalScroll: actionList.contentHeight > actionList.height

                    width: actionList.width
                    height: root.rowHeight
                    rightPadding: width * 0.42 + Kirigami.Units.largeSpacing + (hasVerticalScroll ? root.scrollGutter : 0)
                    text: title
                    icon.name: iconName
                    icon.source: root.iconPreview(iconName, "application-x-executable")
                    highlighted: index === root.selectedActionIndex
                    onClicked: root.actionSelected(index)

                    Controls.Label {
                        anchors.right: parent.right
                        anchors.rightMargin: Kirigami.Units.largeSpacing + (actionDelegate.hasVerticalScroll ? root.scrollGutter : 0)
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.38
                        text: actionDelegate.subtitle
                        elide: Text.ElideRight
                        opacity: 0.7
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
                    Kirigami.Units.gridUnit * 18)
                visible: root.applicationLauncherDropEnabled
                    && actionList.count === 0
                spacing: Kirigami.Units.smallSpacing
                z: 1

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Layout.preferredWidth
                    source: root.applicationLauncherDropState === "rejected"
                        ? "dialog-cancel" : "folder-add-symbolic"
                    Accessible.ignored: true
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: root.dropApplicationsHereText
                    color: root.applicationLauncherDropState === "rejected"
                        ? Kirigami.Theme.negativeTextColor
                        : (root.applicationLauncherDropState === "acceptable"
                            ? Kirigami.Theme.highlightColor
                            : Kirigami.Theme.disabledTextColor)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            DropArea {
                id: containerApplicationDropArea
                objectName: "containerApplicationDropArea"
                anchors.fill: parent
                enabled: root.applicationLauncherDropEnabled
                z: 2

                onEntered: function(drag) {
                    drag.accepted = root.beginApplicationLauncherDrop(
                        drag.hasUrls ? drag.urls : [])
                }
                onPositionChanged: function(drag) {
                    drag.accepted = root.applicationLauncherDropState
                        === "acceptable"
                }
                onExited: root.resetApplicationLauncherDrop()
                onDropped: function(drop) {
                    drop.accepted = root.finishApplicationLauncherDrop(
                        drop.hasUrls ? drop.urls : [])
                }
                onContainsDragChanged: {
                    if (!containerApplicationDropArea.containsDrag) {
                        root.resetApplicationLauncherDrop()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Controls.Button {
                objectName: "addActionButton"
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "list-add-symbolic"
                enabled: root.selectedItemIndex >= 0
                onClicked: root.addActionRequested()
                Accessible.name: root.itemModeValue === "container"
                    ? root.addApplicationText : root.addActionText
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "go-up-symbolic"
                enabled: root.selectedActionIndex > 0
                onClicked: root.moveActionRequested(-1)
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "go-down-symbolic"
                enabled: root.canMoveActionDown
                onClicked: root.moveActionRequested(1)
            }

            Item {
                Layout.fillWidth: true
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-delete-symbolic"
                enabled: root.selectedActionIndex >= 0
                onClicked: root.removeActionRequested()
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        enabled: root.itemModeValue === "container" || actionMenuEnabled.checked
        columns: 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
            text: root.actionNameLabel
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.TextField {
                id: actionName
                Layout.fillWidth: true
                enabled: root.selectedActionIndex >= 0
                placeholderText: root.actionNameLabel
                onTextEdited: root.actionFormChanged()
                onEditingFinished: root.actionFormChanged()
            }

            Controls.Label {
                text: root.actionIconLabel
                opacity: 0.75
                verticalAlignment: Text.AlignVCenter
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: root.iconPreview(actionIcon.text, root.iconPreview(root.appIconText, "application-x-executable"))
                icon.source: root.iconPreview(actionIcon.text, root.iconPreview(root.appIconText, "application-x-executable"))
                display: Controls.AbstractButton.IconOnly
                enabled: root.selectedActionIndex >= 0
                onClicked: root.iconPickerRequested("action")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: root.chooseIconText
            }

            Controls.TextField {
                id: actionIcon
                visible: false
                enabled: root.selectedActionIndex >= 0
                placeholderText: root.actionIconLabel
                onEditingFinished: root.actionFormChanged()
            }
        }

        Controls.Label {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
            text: root.actionCommandLabel
            horizontalAlignment: Text.AlignLeft
            opacity: 0.75
        }

        Controls.TextField {
            id: actionCommand
            Layout.fillWidth: true
            enabled: root.selectedActionIndex >= 0
            placeholderText: root.actionCommandLabel
            onTextEdited: root.actionFormChanged()
            onEditingFinished: root.actionFormChanged()
        }
    }
}
