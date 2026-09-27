// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Options of a media element: the player it controls, the track information it
// shows, its display mode and when it collapses again.
//
// This is a passive visual component. It receives every value it shows through its
// properties—including the list of players, which arrives asynchronously from
// whoever discovers them—announces what the user asked for through its signals and
// writes nothing: it never touches the dock item list, the configuration values or
// the draft of the add dialog. The list of options it shows is derived here, from
// the applications it was given, and the caller owns every value.
//
// The form uses Kirigami's adaptive layout: labels and controls share a row when
// there is enough width and stack automatically in a narrow host. Controls stay
// capped at `selectorWidth`, while their explanatory text remains aligned with
// the value it describes.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Kirigami.FormLayout {
    id: root

    // Values the caller owns.
    property var applications: []
    property string selectedStorageId: ""
    property string mediaTextMode: "automatic"
    property string mediaDisplayMode: "normal"
    property bool openPlayerMinimized: false
    property int autoCollapseDelaySeconds: 3
    property real selectorWidth: Kirigami.Units.gridUnit * 16

    // Rows the selector shows: the automatic entry first and then the discovered
    // applications, sorted by name and without duplicates. The caller never builds
    // this list, so the rule that composes it exists once.
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
    readonly property var displayModeOptions: [
        {
            "text": i18nc("@option:media-display-mode", "Normal (recommended)"),
            "value": "normal"
        },
        {
            "text": i18nc("@option:media-display-mode", "Compact"),
            "value": "compact"
        }
    ]

    // Intentions of the user, announced as they are.
    signal playerSelected(var application)
    signal mediaTextModeSelected(string mode)
    signal mediaDisplayModeSelected(string mode)
    signal openPlayerMinimizedSelected(bool enabled)
    signal autoCollapseDelaySecondsSelected(int seconds)

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
        root.playerOptions = options
        Qt.callLater(root.syncSelection)
    }

    // The three synchronizations move the shown selection to the value that arrived
    // from outside and announce nothing: a list that arrives late or a value written
    // by another path is never read as a choice of the user.
    function syncSelection() {
        let nextIndex = 0
        for (let index = 0; index < root.playerOptions.length; index++) {
            if (String(root.playerOptions[index].storageId || "") === root.selectedStorageId) {
                nextIndex = index
                break
            }
        }
        if (playerCombo.currentIndex !== nextIndex) {
            playerCombo.currentIndex = nextIndex
        }
    }

    function syncTextModeSelection() {
        let nextIndex = 0
        for (let index = 0; index < root.textModeOptions.length; index++) {
            if (String(root.textModeOptions[index].value || "") === root.mediaTextMode) {
                nextIndex = index
                break
            }
        }
        if (textModeCombo.currentIndex !== nextIndex) {
            textModeCombo.currentIndex = nextIndex
        }
    }

    function syncDisplayModeSelection() {
        let nextIndex = 0
        for (let index = 0; index < root.displayModeOptions.length; index++) {
            if (String(root.displayModeOptions[index].value || "")
                    === root.mediaDisplayMode) {
                nextIndex = index
                break
            }
        }
        if (displayModeCombo.currentIndex !== nextIndex) {
            displayModeCombo.currentIndex = nextIndex
        }
    }

    function syncAutoCollapseSecondsSelection() {
        if (autoCollapseDelaySpin.value !== root.autoCollapseDelaySeconds) {
            autoCollapseDelaySpin.value = root.autoCollapseDelaySeconds
        }
    }

    onApplicationsChanged: root.rebuildOptions()
    onSelectedStorageIdChanged: root.syncSelection()
    onMediaTextModeChanged: root.syncTextModeSelection()
    onMediaDisplayModeChanged: root.syncDisplayModeSelection()
    onAutoCollapseDelaySecondsChanged: root.syncAutoCollapseSecondsSelection()
    Component.onCompleted: {
        root.rebuildOptions()
        root.syncTextModeSelection()
        root.syncDisplayModeSelection()
        root.syncAutoCollapseSecondsSelection()
    }

    Controls.Label {
        objectName: "mediaPlayerDescription"

        Layout.fillWidth: true
        Layout.maximumWidth: root.selectorWidth
        text: i18n("Choose which application this item controls. If it is closed, use the play button or album cover to open it.")
        wrapMode: Text.WordWrap
    }

    Controls.ComboBox {
        id: playerCombo

        objectName: "mediaPlayerSelector"

        Kirigami.FormData.label: i18n("Default media player:")
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
            root.playerSelected(option.application || ({}))
        }
    }

    Controls.Label {
        objectName: "mediaNoApplicationsMessage"

        Layout.fillWidth: true
        Layout.maximumWidth: root.selectorWidth
        leftPadding: Kirigami.Units.largeSpacing
        visible: (root.applications ? root.applications.length : 0) === 0
        text: i18n("No installed multimedia applications were found. Automatic selection remains available.")
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
    }

    Controls.CheckBox {
        id: openMinimizedCheckBox

        objectName: "openPlayerMinimizedCheckBox"

        Kirigami.FormData.label: ""
        Layout.fillWidth: true
        Layout.maximumWidth: root.selectorWidth
        text: i18n("Open the selected player minimized")
        checked: root.openPlayerMinimized
        enabled: root.selectedStorageId.length > 0
        Accessible.description: i18n("Only applies when this dock item starts a closed application.")
        onClicked: root.openPlayerMinimizedSelected(checked)
    }

    Controls.ComboBox {
        id: textModeCombo

        objectName: "mediaTextModeSelector"

        Kirigami.FormData.label: i18n("Track information:")
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
        objectName: "mediaTrackInformationHelp"

        Layout.fillWidth: true
        Layout.maximumWidth: root.selectorWidth
        leftPadding: Kirigami.Units.largeSpacing
        text: i18n("Automatic hides inline information in narrow vertical panels. Full details remain available in the tooltip.")
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }

    Controls.ComboBox {
        id: displayModeCombo

        objectName: "mediaDisplayModeSelector"

        Kirigami.FormData.label: i18n("Display mode:")
        Layout.fillWidth: true
        Layout.preferredWidth: root.selectorWidth
        Layout.maximumWidth: root.selectorWidth
        model: root.displayModeOptions
        textRole: "text"
        valueRole: "value"
        Accessible.name: i18n("Media item display mode")
        Accessible.description: i18n("Choose Compact to collapse to the player icon after inactivity, or Normal to keep the full controls visible.")
        onActivated: root.mediaDisplayModeSelected(String(currentValue || "normal"))
    }

    Controls.SpinBox {
        id: autoCollapseDelaySpin

        objectName: "mediaAutoCollapseDelaySpinBox"

        Kirigami.FormData.label: i18n("Collapse controls after:")
        from: 0
        to: 30
        visible: root.mediaDisplayMode === "compact"
        Layout.fillWidth: true
        Layout.preferredWidth: root.selectorWidth
        Layout.maximumWidth: root.selectorWidth
        Accessible.name: i18n("Media controls auto-collapse delay")
        Accessible.description: i18n("Choose how long the media controls stay expanded after interaction. Zero keeps them expanded.")
        textFromValue: function(value, locale) {
            return value === 0
                ? i18nc("@option:media-auto-collapse", "Never")
                : i18np("%1 second", "%1 seconds", value)
        }
        onValueModified: root.autoCollapseDelaySecondsSelected(value)
    }

    Controls.Label {
        objectName: "mediaItemScopeHelp"

        Layout.fillWidth: true
        Layout.maximumWidth: root.selectorWidth
        leftPadding: Kirigami.Units.largeSpacing
        text: i18n("This setting applies only to this media item.")
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }
}
// qmllint enable unqualified
