import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Controls.Dialog {
    id: root

    // Translation helpers are supplied by the KCM context.
    // qmllint disable unqualified
    property var applications: []
    property string selectedStorageId: ""
    property string mediaTextMode: "automatic"
    property bool openPlayerMinimized: false
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    property var playerOptions: []
    readonly property var textModeOptions: [
        {
            "text": i18nc("@option:media-track-information", "Automatic (recommended)"),
            "value": "automatic"
        },
        {
            "text": i18nc("@option:media-track-information", "Always show"),
            "value": "always"
        },
        {
            "text": i18nc("@option:media-track-information", "Hide"),
            "value": "hidden"
        }
    ]

    signal playerSelected(var application)
    signal mediaTextModeSelected(string mode)
    signal openPlayerMinimizedSelected(bool enabled)

    function rebuildOptions() {
        const discovered = []
        const source = applications || []
        const sourceLength = Math.max(0, Number(source.length || 0))
        for (let index = 0; index < sourceLength; index++) {
            discovered.push(source[index])
        }
        discovered.sort(function(left, right) {
            return String(left && left.name || "").localeCompare(
                String(right && right.name || ""))
        })

        const options = [{
            "text": i18nc("@option:media-player", "Automatic (active player)"),
            "storageId": "",
            "iconName": "applications-multimedia",
            "application": ({})
        }]
        const seen = {}
        for (let index = 0; index < discovered.length; index++) {
            const application = discovered[index] || {}
            const storageId = String(application.storageId || "").trim()
            if (storageId.length === 0 || seen[storageId]) {
                continue
            }
            seen[storageId] = true
            options.push({
                "text": String(application.name || storageId),
                "storageId": storageId,
                "iconName": String(application.icon || "applications-multimedia"),
                "application": application
            })
        }
        playerOptions = options
        Qt.callLater(root.syncSelection)
    }

    function syncSelection() {
        let nextIndex = 0
        for (let index = 0; index < playerOptions.length; index++) {
            if (String(playerOptions[index].storageId || "") === selectedStorageId) {
                nextIndex = index
                break
            }
        }
        playerCombo.currentIndex = nextIndex
    }

    function syncTextModeSelection() {
        let nextIndex = 0
        for (let index = 0; index < textModeOptions.length; index++) {
            if (String(textModeOptions[index].value || "") === mediaTextMode) {
                nextIndex = index
                break
            }
        }
        textModeCombo.currentIndex = nextIndex
    }

    onApplicationsChanged: rebuildOptions()
    onSelectedStorageIdChanged: syncSelection()
    onMediaTextModeChanged: syncTextModeSelection()
    Component.onCompleted: {
        rebuildOptions()
        syncTextModeSelection()
    }

    modal: true
    standardButtons: Controls.Dialog.Close

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Choose which application this item controls. If it is closed, use the play button or album cover to open it.")
            wrapMode: Text.WordWrap
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Default media player:")
            wrapMode: Text.WordWrap
        }

        Controls.ComboBox {
            id: playerCombo

            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            Layout.maximumWidth: root.selectorWidth
            model: root.playerOptions.length
            displayText: root.playerOptions[currentIndex]
                ? String(root.playerOptions[currentIndex].text || "")
                : ""
            Accessible.name: i18n("Default media player")
            Accessible.description: i18n("Select Automatic to control the active player, or choose an installed multimedia application.")

            delegate: Controls.ItemDelegate {
                required property int index

                width: playerCombo.width
                text: root.playerOptions[index]
                    ? String(root.playerOptions[index].text || "")
                    : ""
                icon.name: root.playerOptions[index]
                    ? String(root.playerOptions[index].iconName || "applications-multimedia")
                    : "applications-multimedia"
                highlighted: playerCombo.highlightedIndex === index
            }

            onActivated: function(index) {
                const option = root.playerOptions[index]
                if (!option) {
                    return
                }
                root.selectedStorageId = String(option.storageId || "")
                root.playerSelected(option.application || ({}))
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            visible: root.applications.length === 0
            text: i18n("No installed multimedia applications were found. Automatic selection remains available.")
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
        }

        Controls.CheckBox {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Open the selected player minimized")
            checked: root.openPlayerMinimized
            enabled: root.selectedStorageId.length > 0
            Accessible.description: i18n("Only applies when this dock item starts a closed application.")
            onClicked: root.openPlayerMinimizedSelected(checked)
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Track information:")
            wrapMode: Text.WordWrap
        }

        Controls.ComboBox {
            id: textModeCombo

            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            Layout.maximumWidth: root.selectorWidth
            model: root.textModeOptions
            textRole: "text"
            valueRole: "value"
            Accessible.name: i18n("Track information visibility")
            Accessible.description: i18n("Choose when artist, track, and playback time appear inside the dock item.")
            onActivated: root.mediaTextModeSelected(String(currentValue || "automatic"))
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Automatic hides inline information in narrow vertical panels. Full details remain available in the tooltip.")
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }
    // qmllint enable unqualified
}
