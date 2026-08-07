import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Translation helpers are supplied by the plasmoid context.
// qmllint disable unqualified
FocusScope {
    id: root

    property string mode: ""
    property string title: ""
    property string description: ""
    property string primaryActionText: ""
    property string errorMessage: ""
    property string sourceStorageId: ""
    property var applicationCandidates: []
    property var selectedStorageIds: []
    property var availableFolders: []
    property string selectedFolderId: ""
    property string createLabel: ""
    property string renameLabel: ""
    property bool busy: false
    property bool waitingForCommit: false
    property bool submitEnabled: false
    property int maximumFolderMembers: 128

    readonly property int selectedApplicationCount:
        selectedStorageIds ? selectedStorageIds.length : 0
    readonly property string selectionSummary: i18nc("@label",
        "%1 of %2 applications selected", selectedApplicationCount,
        maximumFolderMembers)

    signal cancelRequested()
    signal submitRequested()
    signal createLabelEdited(string value)
    signal renameLabelEdited(string value)
    signal storageSelectionRequested(string storageId, bool selected)
    signal folderSelectionRequested(string folderId)

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
        return application.appIcon || application.icon
            || "application-x-executable"
    }

    function containsStorageId(storageId) {
        return selectedStorageIds.indexOf(storageId) >= 0
    }

    function focusInitial() {
        if (mode === "create") {
            createLabelField.forceActiveFocus()
        } else if (mode === "move" && folderList.count > 0) {
            folderList.currentIndex = 0
            folderList.forceActiveFocus()
        } else if (mode === "rename") {
            renameField.forceActiveFocus()
            renameField.selectAll()
        } else {
            primaryButton.forceActiveFocus()
        }
    }

    function focusPrimaryAction() {
        primaryButton.forceActiveFocus()
    }

    Accessible.role: Accessible.Grouping
    Accessible.name: title

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.ToolButton {
                id: cancelButton
                icon.name: LayoutMirroring.enabled
                    ? "go-next" : "go-previous"
                text: i18nc("@action:button", "Back")
                display: PlasmaComponents.AbstractButton.IconOnly
                enabled: !root.waitingForCommit
                Accessible.name: text
                onClicked: root.cancelRequested()

                HoverHandler {
                    enabled: cancelButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.title
                textFormat: Text.PlainText
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
                elide: Text.ElideRight
                Accessible.role: Accessible.Heading
                Accessible.name: text
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: root.description
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Kirigami.Theme.textColor
            opacity: 0.78
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Kirigami.Theme.negativeTextColor
            Accessible.role: Accessible.AlertMessage
            Accessible.name: text
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "create"
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.TextField {
                id: createLabelField
                Layout.fillWidth: true
                text: root.createLabel
                placeholderText: i18nc("@label:textbox", "Folder name")
                maximumLength: 80
                enabled: !root.busy
                Accessible.name: placeholderText
                onTextEdited: root.createLabelEdited(text)
                onAccepted: {
                    if (root.submitEnabled) {
                        root.submitRequested()
                    }
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.selectionSummary
                textFormat: Text.PlainText
                opacity: 0.72
                Accessible.name: text
            }

            ListView {
                id: applicationList
                readonly property real scrollBarReserve:
                    applicationScrollBar.implicitWidth
                        + Kirigami.Units.smallSpacing
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.applicationCandidates
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: true

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    id: applicationScrollBar
                    policy: applicationList.contentHeight
                        > applicationList.height
                            ? Controls.ScrollBar.AsNeeded
                            : Controls.ScrollBar.AlwaysOff
                }

                delegate: PlasmaComponents.CheckDelegate {
                    required property var modelData

                    readonly property string storageId:
                        root.applicationStorageId(modelData)
                    readonly property bool selected:
                        root.containsStorageId(storageId)
                    readonly property bool selectionBlocked:
                        !selected && root.selectedApplicationCount
                            >= root.maximumFolderMembers

                    width: Math.max(0, applicationList.width
                        - applicationList.scrollBarReserve)
                    enabled: !root.busy
                        && storageId !== root.sourceStorageId
                        && !selectionBlocked
                    checked: selected
                    Accessible.name: root.applicationName(modelData)
                    Accessible.description: selectionBlocked
                        ? root.selectionSummary
                        : checked
                        ? i18nc("@info:accessible",
                            "Selected for the new folder")
                        : i18nc("@info:accessible",
                            "Not selected for the new folder")

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth:
                                Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: width
                            source: root.applicationIcon(modelData)
                            Accessible.ignored: true
                        }

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: root.applicationName(modelData)
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            Accessible.ignored: true
                        }
                    }

                    onClicked: {
                        root.storageSelectionRequested(storageId, !selected)
                    }
                }
            }
        }

        ListView {
            id: folderList
            readonly property real scrollBarReserve:
                folderScrollBar.implicitWidth
                    + Kirigami.Units.smallSpacing
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "move"
            model: root.availableFolders
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: folderScrollBar
                policy: folderList.contentHeight > folderList.height
                    ? Controls.ScrollBar.AsNeeded
                    : Controls.ScrollBar.AlwaysOff
            }

            delegate: PlasmaComponents.RadioDelegate {
                required property var modelData

                width: Math.max(0, folderList.width
                    - folderList.scrollBarReserve)
                enabled: !root.busy
                checked: root.selectedFolderId
                    === String(modelData.folderId || "")
                Accessible.name: String(modelData.label
                    || i18nc("@label", "Applications folder"))

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth:
                            Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: width
                        source: "folder"
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: String(modelData.label
                            || i18nc("@label", "Applications folder"))
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        text: i18np("%1 application", "%1 applications",
                            Number(modelData.visibleMemberCount || 0))
                        textFormat: Text.PlainText
                        opacity: 0.72
                        Accessible.ignored: true
                    }
                }

                onClicked: root.folderSelectionRequested(
                    String(modelData.folderId || ""))
            }

            PlasmaComponents.Label {
                anchors.centerIn: parent
                width: Math.min(parent.width,
                    Kirigami.Units.gridUnit * 20)
                visible: folderList.count === 0
                text: i18nc("@info",
                    "There are no available folders for this application.")
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "rename"

            PlasmaComponents.TextField {
                id: renameField
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                text: root.renameLabel
                placeholderText: i18nc("@label:textbox", "Folder name")
                maximumLength: 80
                enabled: !root.busy
                Accessible.name: placeholderText
                onTextEdited: root.renameLabelEdited(text)
                onAccepted: {
                    if (root.submitEnabled) {
                        root.submitRequested()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "dissolve"
                || root.mode === "remove"

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                source: root.mode === "dissolve"
                    ? "folder-remove" : "edit-cut"
                opacity: 0.78
                Accessible.ignored: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
            }

            PlasmaComponents.BusyIndicator {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: width
                visible: root.waitingForCommit
                running: visible
                Accessible.name: i18nc("@info:accessible",
                    "Saving folder change")
            }

            PlasmaComponents.Button {
                id: secondaryButton
                text: i18nc("@action:button", "Cancel")
                enabled: !root.waitingForCommit
                onClicked: root.cancelRequested()

                HoverHandler {
                    enabled: secondaryButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }
            }

            PlasmaComponents.Button {
                id: primaryButton
                text: root.primaryActionText
                enabled: root.submitEnabled
                icon.name: root.mode === "dissolve"
                    || root.mode === "remove"
                        ? "edit-delete" : "dialog-ok-apply"
                onClicked: root.submitRequested()

                HoverHandler {
                    enabled: primaryButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    Keys.onEscapePressed: function(event) {
        if (!root.waitingForCommit) {
            root.cancelRequested()
        }
        event.accepted = true
    }
}
// qmllint enable unqualified
