import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "../org/punchi/dock" as Punchi
import org.kde.taskmanager as TaskManager
import "components"

KCM.SimpleKCM {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    // Variables prefixed with "cfg_" map automatically to KConfig (main.xml).
    property alias cfg_iconSize: iconSizeSlider.value
    property alias cfg_iconSpacing: iconSpacingSlider.value
    property string cfg_virtualDesktopMode: "all"
    property string cfg_targetVirtualDesktop: ""
    property string cfg_panelLengthMode: "system"
    property string cfg_panelAlignmentMode: "system"
    property string cfg_panelFloatingMode: "system"
    property string cfg_panelVisibilityMode: "system"
    property int cfg_panelThickness: 0
    property string cfg_panelOpacityMode: "system"
    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    // Plasma::Containment exposes its visual geometry at runtime, although the
    // generated QML type metadata does not declare width/height.
    // qmllint disable missing-property
    readonly property int detectedPanelThickness: {
        if (panelLengthModeBridge.panelThickness > 0) {
            return panelLengthModeBridge.panelThickness
        }
        try {
            var containment = Plasmoid.containment
            if (!containment) {
                return 0
            }

            var thickness = verticalPanel
                ? Math.max(0, Number(containment["width"] || 0))
                : Math.max(0, Number(containment["height"] || 0))
            return thickness > 0 ? thickness : 0
        } catch (error) {
            return 0
        }
    }
    // qmllint enable missing-property
    readonly property real currentHoverScale: {
        const scale = Number(Plasmoid.configuration.hoverScale || 1.65)
        return Number.isFinite(scale) && scale >= 1.0 ? scale : 1.65
    }
    readonly property int safePanelIconSizeMax: {
        if (detectedPanelThickness <= 0) {
            return 96
        }
        const headroom = 10
        const availableHeight = Math.max(24, detectedPanelThickness - headroom)
        const calculatedMax = Math.floor(availableHeight / currentHoverScale)
        return Math.max(24, Math.min(96, calculatedMax))
    }
    // qmllint disable unqualified
    readonly property var panelLengthOptions: [
        { "text": i18n("Fit content (Recommended)"), "value": "content" },
        { "text": verticalPanel ? i18n("Fill height") : i18n("Fill width"), "value": "fill" },
        { "text": i18n("Custom"), "value": "custom" }
    ]
    readonly property var panelAlignmentOptions: verticalPanel ? [
        { "text": i18n("Top"), "value": "start" },
        { "text": i18n("Center (Recommended)"), "value": "center" },
        { "text": i18n("Bottom"), "value": "end" }
    ] : [
        { "text": i18n("Left"), "value": "start" },
        { "text": i18n("Center (Recommended)"), "value": "center" },
        { "text": i18n("Right"), "value": "end" }
    ]
    readonly property var panelFloatingOptions: [
        { "text": i18n("Disabled"), "value": "disabled" },
        { "text": i18n("Applets only"), "value": "appletsOnly" },
        { "text": i18n("Panel and applets (Recommended)"), "value": "panelAndApplets" }
    ]
    readonly property var panelVisibilityOptions: [
        { "text": i18n("Always visible"), "value": "alwaysVisible" },
        { "text": i18n("Auto hide"), "value": "autoHide" },
        { "text": i18n("Dodge windows (Recommended)"), "value": "dodgeWindows" },
        { "text": i18n("Windows go below"), "value": "windowsGoBelow" }
    ]
    readonly property var panelOpacityOptions: [
        { "text": i18n("Adaptive"), "value": "adaptive" },
        { "text": i18n("Opaque"), "value": "opaque" },
        { "text": i18n("Translucent"), "value": "translucent" }
    ]
    // qmllint enable unqualified
    readonly property var virtualDesktopModel: {
        var result = []
        var ids = virtualDesktopInfo.desktopIds
        var names = virtualDesktopInfo.desktopNames
        for (var index = 0; index < ids.length; index++) {
            result.push({
                "id": String(ids[index]),
                "name": index < names.length ? names[index] : i18n("Desktop %1", index + 1) // qmllint disable unqualified
            })
        }
        return result
    }
    readonly property string defaultTargetVirtualDesktopId: {
        if (virtualDesktopModel.length === 0) {
            return ""
        }

        var currentDesktopId = String(virtualDesktopInfo.currentDesktop || "")
        if (currentDesktopId.length > 0) {
            for (var index = 0; index < virtualDesktopModel.length; index++) {
                if (virtualDesktopModel[index].id === currentDesktopId) {
                    return currentDesktopId
                }
            }
        }

        return virtualDesktopModel[0].id
    }
    readonly property bool targetVirtualDesktopAvailable: cfg_targetVirtualDesktop === ""
        || virtualDesktopInfo.desktopIds.map(function(desktopId) { return String(desktopId) }).indexOf(cfg_targetVirtualDesktop) !== -1

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }
    Punchi.PanelLengthModeBridge {
        id: panelLengthModeBridge
        containmentId: Plasmoid.containment ? Plasmoid.containment.id : 0
    }

    Connections {
        target: virtualDesktopInfo

        function ensureTargetDesktopSelection() {
            if (page.cfg_virtualDesktopMode === "single"
                    && page.cfg_targetVirtualDesktop === ""
                    && page.defaultTargetVirtualDesktopId !== "") {
                page.cfg_targetVirtualDesktop = page.defaultTargetVirtualDesktopId
            }
        }

        function onDesktopIdsChanged() {
            ensureTargetDesktopSelection()
        }

        function onCurrentDesktopChanged() {
            ensureTargetDesktopSelection()
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.fillWidth: true

        Kirigami.FormLayout {
            Layout.fillWidth: true

            // qmllint disable unqualified
            RowLayout {
                visible: page.inPanel
                Kirigami.FormData.label: page.verticalPanel ? i18n("Panel height:") : i18n("Panel width:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.ComboBox {
                    id: panelLengthModeCombo
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    textRole: "text"
                    valueRole: "value"
                    model: page.panelLengthOptions
                    currentIndex: {
                        const cfg = page.cfg_panelLengthMode
                        if (cfg === "fill" || cfg === "fillAvailable") {
                            return 1
                        }
                        if (cfg === "custom") {
                            return 2
                        }
                        if (cfg === "content" || cfg === "fitContent" || cfg === "fit") {
                            return 0
                        }
                        if (panelLengthModeBridge.panelLengthMode === 0) {
                            return 1
                        }
                        if (panelLengthModeBridge.panelLengthMode === 2) {
                            return 2
                        }
                        return 0
                    }
                    onActivated: page.cfg_panelLengthMode = currentValue
                    Accessible.name: page.verticalPanel ? i18n("Panel height") : i18n("Panel width")

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }

            RowLayout {
                visible: page.inPanel
                Kirigami.FormData.label: i18n("Panel alignment:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.ComboBox {
                    id: panelAlignmentModeCombo
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    textRole: "text"
                    valueRole: "value"
                    model: page.panelAlignmentOptions
                    currentIndex: {
                        const cfg = page.cfg_panelAlignmentMode
                        if (cfg === "start" || cfg === "left" || cfg === "top") {
                            return 0
                        }
                        if (cfg === "end" || cfg === "right" || cfg === "bottom") {
                            return 2
                        }
                        if (cfg === "center") {
                            return 1
                        }
                        if (panelLengthModeBridge.panelAlignment === 0) {
                            return 0
                        }
                        if (panelLengthModeBridge.panelAlignment === 2) {
                            return 2
                        }
                        return 1
                    }
                    onActivated: page.cfg_panelAlignmentMode = currentValue
                    Accessible.name: i18n("Panel alignment")

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }

            RowLayout {
                visible: page.inPanel
                Kirigami.FormData.label: i18n("Panel floating mode:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.ComboBox {
                    id: panelFloatingModeCombo
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    textRole: "text"
                    valueRole: "value"
                    model: page.panelFloatingOptions
                    currentIndex: {
                        const cfg = page.cfg_panelFloatingMode
                        if (cfg === "disabled") {
                            return 0
                        }
                        if (cfg === "appletsOnly") {
                            return 1
                        }
                        if (cfg === "panelAndApplets") {
                            return 2
                        }
                        if (panelLengthModeBridge.panelFloatingMode === 0) {
                            return 0
                        }
                        if (panelLengthModeBridge.panelFloatingMode === 1) {
                            return 1
                        }
                        return 2
                    }
                    onActivated: page.cfg_panelFloatingMode = currentValue
                    Accessible.name: i18n("Panel floating mode")

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }

            RowLayout {
                visible: page.inPanel
                Kirigami.FormData.label: i18n("Panel visibility:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.ComboBox {
                    id: panelVisibilityModeCombo
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    textRole: "text"
                    valueRole: "value"
                    model: page.panelVisibilityOptions
                    currentIndex: {
                        const cfg = page.cfg_panelVisibilityMode
                        if (cfg === "alwaysVisible") {
                            return 0
                        }
                        if (cfg === "autoHide") {
                            return 1
                        }
                        if (cfg === "dodgeWindows") {
                            return 2
                        }
                        if (cfg === "windowsGoBelow") {
                            return 3
                        }
                        if (panelLengthModeBridge.panelVisibilityMode === 0) {
                            return 0
                        }
                        if (panelLengthModeBridge.panelVisibilityMode === 1) {
                            return 1
                        }
                        if (panelLengthModeBridge.panelVisibilityMode === 2) {
                            return 2
                        }
                        if (panelLengthModeBridge.panelVisibilityMode === 3) {
                            return 3
                        }
                        return 0
                    }
                    onActivated: page.cfg_panelVisibilityMode = currentValue
                    Accessible.name: i18n("Panel visibility")

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }

            RowLayout {
                visible: page.inPanel
                Kirigami.FormData.label: i18n("Panel opacity:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.ComboBox {
                    id: panelOpacityModeCombo
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    textRole: "text"
                    valueRole: "value"
                    model: page.panelOpacityOptions
                    currentIndex: {
                        const cfg = page.cfg_panelOpacityMode
                        if (cfg === "adaptive") {
                            return 0
                        }
                        if (cfg === "opaque") {
                            return 1
                        }
                        if (cfg === "translucent") {
                            return 2
                        }
                        if (panelLengthModeBridge.panelOpacityMode === 0) {
                            return 0
                        }
                        if (panelLengthModeBridge.panelOpacityMode === 1) {
                            return 1
                        }
                        if (panelLengthModeBridge.panelOpacityMode === 2) {
                            return 2
                        }
                        return 0
                    }
                    onActivated: page.cfg_panelOpacityMode = currentValue
                    Accessible.name: i18n("Panel opacity")

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }

            RowLayout {
                visible: page.inPanel
                Kirigami.FormData.label: page.verticalPanel ? i18n("Panel width:") : i18n("Panel height:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.SpinBox {
                    id: panelThicknessSpinBox
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    from: 24
                    to: 256
                    stepSize: 2
                    editable: true
                    value: page.cfg_panelThickness > 0
                        ? page.cfg_panelThickness
                        : (page.detectedPanelThickness > 0 ? page.detectedPanelThickness : 64)
                    onValueModified: page.cfg_panelThickness = value
                    textFromValue: function(value) {
                        return value + " px"
                    }
                    valueFromText: function(text) {
                        return parseInt(text, 10) || 24
                    }
                    Accessible.name: page.verticalPanel ? i18n("Panel width") : i18n("Panel height")

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }
            // qmllint enable unqualified

            // Icon size control.
            RowLayout {
                Kirigami.FormData.label: page.inPanel ? i18n("Panel icon size:") : i18n("Floating icon size:") // qmllint disable unqualified
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: iconSizeSlider
                    from: 24
                    to: page.inPanel ? page.safePanelIconSizeMax : 96
                    stepSize: 2
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint - 60

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    text: iconSizeSlider.value + " px"
                    font.bold: true
                    Layout.preferredWidth: 50
                }
            }

            // qmllint disable unqualified
            RowLayout {
                Kirigami.FormData.label: i18n("Icon spacing:")
                Layout.maximumWidth: page.contentWidthHint

                Controls.Slider {
                    id: iconSpacingSlider
                    from: 0
                    to: 24
                    stepSize: 1
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.contentWidthHint - 60
                    Accessible.name: i18n("Icon spacing")
                    Accessible.description: i18n("Adjusts the spacing between dock icons from 0 to 24 pixels.")

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                        role: "slider"
                    }
                }

                Controls.Label {
                    text: Math.round(iconSpacingSlider.value) + " px"
                    font.bold: true
                    Layout.preferredWidth: 50
                }
            }
            // qmllint enable unqualified

            Kirigami.InlineMessage {
                Kirigami.FormData.label: page.inPanel ? i18n("Limit:") : "" // qmllint disable unqualified
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: page.inPanel
                type: Kirigami.MessageType.Information
                text: page.detectedPanelThickness > 0
                    ? i18n("Estimated panel-safe maximum: %1 px", page.safePanelIconSizeMax) // qmllint disable unqualified
                    : i18n("The real panel thickness is not available in this view, so a safe fallback limit is being used.") // qmllint disable unqualified
            }

            // Virtual desktop visibility control.
            RowLayout {
                Kirigami.FormData.label: i18n("Desktop visibility:") // qmllint disable unqualified
                Layout.maximumWidth: page.contentWidthHint

                Controls.ComboBox {
                    id: desktopModeCombo
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    textRole: "text"
                    valueRole: "value"
                    model: [
                        { "text": i18n("All desktops"), "value": "all" }, // qmllint disable unqualified
                        { "text": i18n("Single desktop"), "value": "single" } // qmllint disable unqualified
                    ]

                    currentIndex: Math.max(0, indexOfValue(page.cfg_virtualDesktopMode))
                    onActivated: {
                        page.cfg_virtualDesktopMode = currentValue
                        if (currentValue === "single"
                                && page.cfg_targetVirtualDesktop === ""
                                && page.defaultTargetVirtualDesktopId !== "") {
                            page.cfg_targetVirtualDesktop = page.defaultTargetVirtualDesktopId
                        }
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }

            // Target virtual desktop selector.
            RowLayout {
                Kirigami.FormData.label: i18n("Target desktop:") // qmllint disable unqualified
                visible: page.cfg_virtualDesktopMode === "single"
                Layout.maximumWidth: page.contentWidthHint

                Controls.ComboBox {
                    id: desktopCombo
                    Layout.preferredWidth: page.selectorWidthHint
                    Layout.maximumWidth: page.selectorWidthHint
                    textRole: "name"
                    valueRole: "id"
                    model: page.virtualDesktopModel
                    enabled: count > 0
                    currentIndex: {
                        if (count === 0) {
                            return -1
                        }
                        var targetDesktopId = page.cfg_targetVirtualDesktop || page.defaultTargetVirtualDesktopId
                        return indexOfValue(targetDesktopId)
                    }
                    onActivated: {
                        page.cfg_targetVirtualDesktop = currentValue
                    }

                    ConfigCursorBehavior {
                        cursorEnabled: page.interactiveCursorEnabled
                    }
                }
            }

            Kirigami.InlineMessage {
                Kirigami.FormData.isSection: true
                Layout.fillWidth: true
                Layout.maximumWidth: page.contentWidthHint
                visible: page.cfg_virtualDesktopMode === "single"
                    && (page.virtualDesktopModel.length === 0 || !page.targetVirtualDesktopAvailable)
                type: Kirigami.MessageType.Warning
                text: page.virtualDesktopModel.length === 0
                    ? i18n("No virtual desktops were found.") // qmllint disable unqualified
                    : i18n("The selected desktop no longer exists. Choose another desktop.") // qmllint disable unqualified
            }
        }

        Kirigami.InlineMessage {
            id: statusInlineMessage
            visible: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            type: Kirigami.MessageType.Information
            showCloseButton: false
            text: !page.inPanel
                ? i18nc("@info:status <b> marks the current dock mode", "Current dock state: <b>Floating mode</b>.<br>Panel-only sizing and integration options are unavailable.") // qmllint disable unqualified
                : page.verticalPanel
                    ? i18nc("@info:status <b> marks the current dock mode", "Current dock state: <b>Vertical panel</b>.<br>Fill free panel space is active only when the Plasma panel is set to Fill available; otherwise Punchi Dock remains compact.") // qmllint disable unqualified
                    : i18nc("@info:status <b> marks the current dock mode", "Current dock state: <b>Horizontal panel</b>.<br>Fill free panel space is active only when the Plasma panel is set to Fill available; otherwise Punchi Dock remains compact.") // qmllint disable unqualified
            Accessible.name: text.replace("<br>", " ").replace("<b>", "").replace("</b>", "")
        }
    }
}
