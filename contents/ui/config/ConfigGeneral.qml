import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager
import "components"

KCM.SimpleKCM {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    // Variables prefijadas con "cfg_" para mapear automáticamente a KConfig (main.xml)
    property alias cfg_iconSize: iconSizeSlider.value
    property alias cfg_hoverScale: hoverScaleSlider.value
    property string cfg_virtualDesktopMode: "all"
    property string cfg_targetVirtualDesktop: ""
    property string cfg_panelLengthMode: "content"
    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property int detectedPanelThickness: {
        try {
            var containment = Plasmoid.containment
            if (!containment || !containment.screenGeometry || !containment.availableScreenRect) {
                return 0
            }

            var screenGeometry = containment.screenGeometry
            var availableScreenRect = containment.availableScreenRect
            var thickness = verticalPanel
                ? Math.max(0, screenGeometry.width - availableScreenRect.width)
                : Math.max(0, screenGeometry.height - availableScreenRect.height)
            return thickness > 0 ? thickness : 0
        } catch (error) {
            return 0
        }
    }
    readonly property int panelCrossAxisPadding: verticalPanel ? 36 : 24
    readonly property int safePanelIconSizeMax: detectedPanelThickness > 0
        ? Math.max(32, detectedPanelThickness - panelCrossAxisPadding - 12)
        : 96
    readonly property bool panelSeemsToFillEdge: {
        try {
            var containment = Plasmoid.containment
            if (!inPanel || !containment || !containment.availableScreenRect) {
                return false
            }
            if (verticalPanel) {
                return containment.height >= containment.availableScreenRect.height * 0.92
            }
            return containment.width >= containment.availableScreenRect.width * 0.92
        } catch (error) {
            return false
        }
    }
    readonly property var panelLengthOptions: [
        { "text": i18n("Fit content"), "value": "content" },
        { "text": i18n("Fill panel edge"), "value": "fill" }
    ]
    readonly property var virtualDesktopModel: {
        var result = []
        var ids = virtualDesktopInfo.desktopIds
        var names = virtualDesktopInfo.desktopNames
        for (var index = 0; index < ids.length; index++) {
            result.push({
                "id": String(ids[index]),
                "name": index < names.length ? names[index] : i18n("Desktop %1", index + 1)
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

    Kirigami.FormLayout {
        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            visible: true
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            type: Kirigami.MessageType.Warning
            showCloseButton: false
            text: !page.inPanel
                ? i18n("Current dock state: Floating mode. Panel-only sizing and integration options are unavailable.")
                : page.panelSeemsToFillEdge
                    ? i18n("Current dock state: Panel mode. The Plasma panel spans the full screen edge, so compact or full-edge length can be selected.")
                    : i18n("Current dock state: Panel mode. The current Plasma panel does not span the full screen edge, so the full-edge length option is unavailable.")
            Accessible.name: text
        }

        RowLayout {
            visible: page.inPanel && page.panelSeemsToFillEdge
            Kirigami.FormData.label: i18n("Panel length:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: panelLengthModeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.panelLengthOptions
                currentIndex: Math.max(0, indexOfValue(page.cfg_panelLengthMode))
                onActivated: page.cfg_panelLengthMode = currentValue

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        // Control del Tamaño de Iconos
        RowLayout {
            Kirigami.FormData.label: page.inPanel ? i18n("Panel icon size:") : i18n("Floating icon size:")
            Layout.maximumWidth: page.contentWidthHint
            
            Controls.Slider {
                id: iconSizeSlider
                from: 32
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

        Kirigami.InlineMessage {
            Kirigami.FormData.label: page.inPanel ? i18n("Limit:") : ""
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            visible: page.inPanel
            type: Kirigami.MessageType.Information
            text: page.detectedPanelThickness > 0
                ? i18n("Estimated panel-safe maximum: %1 px", page.safePanelIconSizeMax)
                : i18n("The real panel thickness is not available in this view, so a safe fallback limit is being used.")
        }

        // Control del Escala del Zoom de Ola
        RowLayout {
            Kirigami.FormData.label: i18n("Hover zoom scale:")
            Layout.maximumWidth: page.contentWidthHint
            
            Controls.Slider {
                id: hoverScaleSlider
                from: 1.0
                to: 2.0
                stepSize: 0.05
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 60

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: hoverScaleSlider.value.toFixed(2) + "x"
                font.bold: true
                Layout.preferredWidth: 50
            }
        }

        // Control de Visibilidad en Escritorios Virtuales
        RowLayout {
            Kirigami.FormData.label: i18n("Desktop visibility:")
            Layout.maximumWidth: page.contentWidthHint
            
            Controls.ComboBox {
                id: desktopModeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("All desktops"), "value": "all" },
                    { "text": i18n("Single desktop"), "value": "single" }
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

        // Control para elegir el Escritorio Virtual de Destino
        RowLayout {
            Kirigami.FormData.label: i18n("Target desktop:")
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
                ? i18n("No virtual desktops were found.")
                : i18n("The selected desktop no longer exists. Choose another desktop.")
        }

    }
}
