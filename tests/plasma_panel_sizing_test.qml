import QtQuick
import QtTest
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../contents/ui/components"

TestCase {
    id: testCase
    name: "PlasmaPanelSizing"
    DockGeometryState {
        id: geometry
        inPanel: true
        configuredIconSize: 48
        panelHoverScale: 2
    }
    QtObject {
        id: panelWindow
        property int width: 64
        property int height: 64
    }
    function init() {
        failOnWarning(/.?/)
        geometry.customThemeActive = false
        geometry.verticalPanel = false
        geometry.horizontalPanel = true
        geometry.dockShowLabels = false
        geometry.configuredIconSize = 48
        geometry.configuredPanelThickness = 0
        geometry.panelHoverScale = 2
        geometry.unlockPanelIconSizeLimit = false
        geometry.inPanel = true
        geometry.panelWindow = null
        geometry.panelIconGeometries = []
        geometry.panelHoverAnimation = "wave"
        panelWindow.width = 64
        panelWindow.height = 64
    }
    function test_orientation_data() {
        return [{tag: "horizontal", vertical: false}, {tag: "vertical", vertical: true}]
    }
    function test_orientation(data) {
        geometry.verticalPanel = data.vertical
        geometry.horizontalPanel = !data.vertical
        compare(geometry.effectiveIconSize, 48)
        compare(geometry.effectivePanelHoverScale, 1.65)
        const automaticExtent = geometry.plasmaThemeCrossAxisExtent
        verify(automaticExtent >= 48 * 1.65 + Kirigami.Units.smallSpacing * 3)
        geometry.configuredPanelThickness = 64
        compare(geometry.effectiveIconSize, 48)
        compare(geometry.effectivePanelHoverScale, 1.65)
        verify(geometry.effectivePanelHoverScale >= 1)
        verify(geometry.plasmaThemeCrossAxisExtent <= 64)
        geometry.configuredPanelThickness = 32
        verify(geometry.effectiveIconSize < 48)
        compare(geometry.effectivePanelHoverScale, 1.65)
        verify(geometry.plasmaThemeCrossAxisExtent <= 32)
        geometry.unlockPanelIconSizeLimit = true
        verify(geometry.plasmaThemeCrossAxisExtent <= 32)
        geometry.configuredPanelThickness = 0
        compare(geometry.effectiveIconSize, 48)
        compare(geometry.plasmaThemeCrossAxisExtent, automaticExtent)
    }
    function test_labels_data() {
        return [{tag: "horizontal-labels", vertical: false}, {tag: "vertical-labels", vertical: true}]
    }
    function test_labels(data) {
        geometry.verticalPanel = data.vertical
        geometry.horizontalPanel = !data.vertical
        geometry.dockShowLabels = true
        geometry.configuredPanelThickness = 48
        verify(geometry.plasmaThemeCrossAxisExtent <= 48)
        verify(geometry.effectiveIconSize < 48)
        geometry.configuredPanelThickness = 0
        compare(geometry.effectiveIconSize, 48)
        verify(geometry.plasmaThemeCrossAxisExtent >= 48 * 1.65)
    }
    function test_jsonAndFloatingRemainIndependent_data() {
        return [{tag: "json-horizontal", vertical: false}, {tag: "json-vertical", vertical: true}]
    }
    function test_jsonAndFloatingRemainIndependent(data) {
        geometry.verticalPanel = data.vertical
        geometry.horizontalPanel = !data.vertical
        geometry.customThemeActive = true
        compare(geometry.effectivePanelHoverScale, 2)
        geometry.configuredPanelThickness = 32
        geometry.unlockPanelIconSizeLimit = true
        compare(geometry.effectiveIconSize, 48)
        compare(geometry.effectivePanelHoverScale, 2)
        geometry.customThemeActive = false
        verify(geometry.effectiveIconSize < 48)
        geometry.inPanel = false
        compare(geometry.effectiveIconSize, 48)
        compare(geometry.effectivePanelHoverScale, 2)
    }
    function test_actualWindowBounds_data() {
        return [
            {tag: "left", edge: PlasmaCore.Types.LeftEdge, vertical: true, origin: 6},
            {tag: "right", edge: PlasmaCore.Types.RightEdge, vertical: true, origin: 26},
            {tag: "top", edge: PlasmaCore.Types.TopEdge, vertical: false, origin: 6},
            {tag: "bottom", edge: PlasmaCore.Types.BottomEdge, vertical: false, origin: 26}
        ]
    }
    function test_actualWindowBounds(data) {
        geometry.verticalPanel = data.vertical
        geometry.horizontalPanel = !data.vertical
        geometry.panelLocation = data.edge
        geometry.configuredIconSize = 32
        geometry.configuredPanelThickness = 48
        geometry.panelWindow = panelWindow
        geometry.panelIconGeometries = [data.vertical
            ? Qt.rect(data.origin, 0, 32, 32) : Qt.rect(0, data.origin, 32, 32)]
        // A 48-pixel panel can provide a larger client window when floating.
        compare(geometry.effectiveIconSize, 32)
        compare(geometry.effectivePanelHoverScale, 1.65)
        geometry.configuredPanelThickness = 47
        compare(geometry.effectivePanelHoverScale, 1.65)
        // Changing the real client boundary must constrain the same instance.
        panelWindow.width = 48
        panelWindow.height = 48
        verify(geometry.effectivePanelHoverScale < 1.65)
        const scale = geometry.effectivePanelHoverScale
        const center = data.origin + 16
        const forward = data.edge === PlasmaCore.Types.LeftEdge
            || data.edge === PlasmaCore.Types.TopEdge
        const shift = (forward ? 1 : -1) * 16 * (scale - 1)
        if (center - 16 >= 0 && center + 16 <= 48) {
            verify(center + shift - 16 * scale >= -0.001)
            verify(center + shift + 16 * scale <= 48.001)
        }
        panelWindow.width = 64
        panelWindow.height = 64
        compare(geometry.effectivePanelHoverScale, 1.65)
        geometry.panelHoverAnimation = "axisZoom"
        compare(geometry.effectivePanelHoverScale, 1.375)
    }

}
