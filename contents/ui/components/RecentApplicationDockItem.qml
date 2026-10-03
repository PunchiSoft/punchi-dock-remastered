pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

DockItem {
    id: root
    required property DockConfigurationState configState
    required property DockGeometryState geometryState
    property var descriptor: ({})
    itemType: String(root.descriptor.type || "app")
    iconName: String(root.descriptor.icon || "application-x-executable")
    itemName: String(root.descriptor.name || "")
    iconSize: root.geometryState.effectiveIconSize
    inPanel: root.configState.inPanel
    panelLocation: root.geometryState.effectivePanelLocation
    hoverScaleSetting: root.geometryState.effectivePanelHoverScale
    dockMotionSpeedPercent: root.configState.dockMotionSpeedPercent
    clickEffect: root.configState.dockClickEffect
    showItemHoverBackground: root.configState.dockShowItemHoverBackground
    showPersistentLabel: root.configState.dockShowLabels
    textShadowsEnabled: root.configState.dockTextShadowsEnabled
    labelFontSize: root.configState.dockLabelFontSize
    iconReflectionEnabled: root.configState.dockIconReflectionsEnabled
    iconReflectionOpacity: root.configState.dockIconReflectionOpacity
    iconReflectionAvailableExtent: root.geometryState.panelReflectionAvailableExtent
    customSeparatorEnabled: root.configState.customDockSeparatorActive
    separatorTheme: root.configState.customDockSeparatorTheme
    persistentReorderEnabled: false
    pinnedApplicationLauncher: false
    recentApplicationLauncher: root.descriptor.entryRole === "recent"
    Layout.preferredWidth: root.inPanel && !root.separatorItem
        ? root.geometryState.panelItemWidth : implicitWidth
    Layout.preferredHeight: root.inPanel && !root.separatorItem
        ? root.geometryState.panelItemHeight : implicitHeight
}
