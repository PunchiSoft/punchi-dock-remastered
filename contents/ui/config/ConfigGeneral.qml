import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

KCM.SimpleKCM {
    id: page

    // Variables prefijadas con "cfg_" para mapear automáticamente a KConfig (main.xml)
    property alias cfg_iconSize: iconSizeSlider.value
    property alias cfg_hoverScale: hoverScaleSlider.value
    property string cfg_hoverAnimation: "wave"
    property string cfg_virtualDesktopMode: "all"
    property string cfg_targetVirtualDesktop: ""
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
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
        Item {
            Kirigami.FormData.isSection: true
            implicitHeight: 1
        }

        Controls.Label {
            Kirigami.FormData.label: page.inPanel ? i18n("Mode:") : i18n("Mode:")
            text: page.inPanel ? i18n("Panel mode") : i18n("Floating mode")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.bold: true
        }

        Controls.Label {
            Kirigami.FormData.label: i18n("Behavior:")
            text: page.inPanel
                ? i18n("Icon size is adapted for the current panel thickness to avoid visual overflow.")
                : i18n("Floating mode uses a freer icon size because it is not constrained by panel thickness.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Control del Tamaño de Iconos
        RowLayout {
            Kirigami.FormData.label: page.inPanel ? i18n("Panel icon size:") : i18n("Floating icon size:")
            
            Controls.Slider {
                id: iconSizeSlider
                from: 32
                to: page.inPanel ? page.safePanelIconSizeMax : 96
                stepSize: 2
                Layout.fillWidth: true
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
            visible: page.inPanel
            type: Kirigami.MessageType.Information
            text: page.detectedPanelThickness > 0
                ? i18n("Estimated panel-safe maximum: %1 px", page.safePanelIconSizeMax)
                : i18n("The real panel thickness is not available in this view, so a safe fallback limit is being used.")
        }

        // Control del Escala del Zoom de Ola
        RowLayout {
            Kirigami.FormData.label: i18n("Hover zoom scale:")
            
            Controls.Slider {
                id: hoverScaleSlider
                from: 1.0
                to: 2.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            
            Controls.Label {
                text: hoverScaleSlider.value.toFixed(2) + "x"
                font.bold: true
                Layout.preferredWidth: 50
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Hover animation:")

            Controls.ComboBox {
                id: hoverAnimationCombo
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("None"), "value": "none" },
                    { "text": i18n("Wave"), "value": "wave" },
                    { "text": i18n("Single"), "value": "single" },
                    { "text": i18n("Paragraph"), "value": "paragraph" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_hoverAnimation))
                Layout.fillWidth: true
                onActivated: page.cfg_hoverAnimation = currentValue
            }
        }

        // Control de Visibilidad en Escritorios Virtuales
        RowLayout {
            Kirigami.FormData.label: i18n("Desktop visibility:")
            
            Controls.ComboBox {
                id: desktopModeCombo
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
            }
        }

        // Control para elegir el Escritorio Virtual de Destino
        RowLayout {
            Kirigami.FormData.label: i18n("Target desktop:")
            visible: page.cfg_virtualDesktopMode === "single"
            
            Controls.ComboBox {
                id: desktopCombo
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
            }
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            visible: page.cfg_virtualDesktopMode === "single"
                && (page.virtualDesktopModel.length === 0 || !page.targetVirtualDesktopAvailable)
            type: Kirigami.MessageType.Warning
            text: page.virtualDesktopModel.length === 0
                ? i18n("No virtual desktops were found.")
                : i18n("The selected desktop no longer exists. Choose another desktop.")
        }

    }
}
