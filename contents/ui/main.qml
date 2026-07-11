import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.taskmanager as TaskManager
import "org/punchi/dock" as Punchi
import "components"
import "../code/logic.js" as Logic

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    compactRepresentation: fullRepresentation

    // Propiedad base, inicia vacía hasta que leamos la configuración
    property var dockItems: []
    
    // Detector de entorno (Panel vs Flotante)
    property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool trashHasItems: false

    // Visibilidad por Escritorios Virtuales
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }
    Punchi.SystemDiscovery {
        id: systemDiscovery
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
    }
    readonly property string currentVirtualDesktopId: String(virtualDesktopInfo.currentDesktop || "")
    readonly property bool singleVirtualDesktopMode: Plasmoid.configuration.virtualDesktopMode === "single"
        && Plasmoid.configuration.targetVirtualDesktop !== ""
    readonly property bool hiddenByVirtualDesktop: singleVirtualDesktopMode
        && currentVirtualDesktopId !== Plasmoid.configuration.targetVirtualDesktop
    readonly property int visibleDockItemCount: dockItems ? dockItems.length : 0
    readonly property int dockSpacing: 8
    readonly property int dockBackgroundHorizontalPadding: 18
    readonly property int dockBackgroundVerticalPadding: 12
    readonly property int floatingExtraWidth: 48
    readonly property int floatingExtraHeight: 32
    readonly property real panelHoverScale: Math.max(1.0, Number(Plasmoid.configuration.hoverScale || 1.0))
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
    readonly property int panelCrossAxisPadding: verticalPanel ? (dockBackgroundHorizontalPadding * 2) : (dockBackgroundVerticalPadding * 2)
    readonly property int effectivePanelIconLimit: detectedPanelThickness > 0
        ? Math.max(32, detectedPanelThickness - panelCrossAxisPadding - 12)
        : Math.max(32, Number(Plasmoid.configuration.iconSize || 48))
    readonly property int effectiveIconSize: inPanel
        ? Math.min(Number(Plasmoid.configuration.iconSize || 48), effectivePanelIconLimit)
        : Number(Plasmoid.configuration.iconSize || 48)
    readonly property int panelItemWidth: Math.ceil(effectiveIconSize + 12)
    readonly property int panelItemHeight: Math.ceil(effectiveIconSize + 12)
    readonly property int panelContentWidth: visibleDockItemCount > 0
        ? (visibleDockItemCount * panelItemWidth) + (Math.max(0, visibleDockItemCount - 1) * dockSpacing)
        : panelItemWidth
    readonly property int panelContentHeight: panelItemHeight
    readonly property int panelPreferredWidth: hiddenByVirtualDesktop
        ? 0
        : Math.ceil(panelContentWidth + (dockBackgroundHorizontalPadding * 2))
    readonly property int panelPreferredHeight: hiddenByVirtualDesktop
        ? 0
        : Math.ceil(Math.max(panelContentHeight, effectiveIconSize * panelHoverScale) + (dockBackgroundVerticalPadding * 2))

    implicitWidth: inPanel ? panelPreferredWidth : 0
    implicitHeight: inPanel ? panelPreferredHeight : 0
    switchWidth: inPanel ? panelPreferredWidth : Math.ceil(panelItemWidth)
    switchHeight: inPanel ? panelPreferredHeight : Math.ceil(panelItemHeight)

    Layout.minimumWidth: inPanel ? panelPreferredWidth : -1
    Layout.minimumHeight: inPanel ? panelPreferredHeight : -1
    Layout.preferredWidth: inPanel ? panelPreferredWidth : -1
    Layout.preferredHeight: inPanel ? panelPreferredHeight : -1

    Plasma5Support.DataSource {
        id: executableDataSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, _data) {
            disconnectSource(sourceName)
        }
    }
    Punchi.TrashIntegration {
        id: trashIntegration
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
        onStateChanged: function(hasItems) {
            root.updateTrashState(hasItems)
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onDockItemsJsonChanged() {
            var raw = Plasmoid.configuration.dockItemsJson || ""
            if (raw.trim().length > 0) {
                root.dockItems = Logic.loadItems(raw)
                // Sincronizar el archivo externo para scripts externos
                var writeCmd = "configDir=\"${XDG_CONFIG_HOME:-$HOME/.config}/punchi-dock-remastered\" && mkdir -p \"$configDir\" && printf %s " + Logic.shellQuote(raw) + " > \"$configDir/dock_items.json\""
                executableDataSource.connectSource(writeCmd)
            } else {
                root.dockItems = []
                var clearCmd = "configDir=\"${XDG_CONFIG_HOME:-$HOME/.config}/punchi-dock-remastered\" && mkdir -p \"$configDir\" && printf %s '[]' > \"$configDir/dock_items.json\""
                executableDataSource.connectSource(clearCmd)
            }
            trashIntegration.refresh()
        }
    }

    Component.onCompleted: {
        var raw = Plasmoid.configuration.dockItemsJson || ""
        if (raw.trim().length > 0) {
            root.dockItems = Logic.loadItems(raw)
        } else {
            root.dockItems = Logic.loadItems("")
        }
        trashIntegration.refresh()
    }

    // Función puente para ejecutar comandos con doble escape seguro
    function runCommand(command) {
        var detachedCmd = Logic.detachedCommand(command)
        if (detachedCmd.length === 0) return
        
        console.log("Dock ejecutando nativamente:", detachedCmd)
        executableDataSource.connectSource(detachedCmd)
    }

    function launchDockItem(item) {
        if (item && item.storageId) {
            systemDiscovery.launchApplication(item.storageId)
        } else if (item && item.type === "app" && item.command && systemDiscovery.launchApplicationByCommand(item.command)) {
            return
        } else if (item && item.url) {
            systemDiscovery.openUrl(item.url)
        } else {
            Logic.launchItem(item, root.runCommand)
        }
    }

    function updateTrashState(hasItems) {
        root.trashHasItems = hasItems
    }

    function syncDockItemsConfiguration() {
        var raw = JSON.stringify(root.dockItems)
        Plasmoid.configuration.dockItemsJson = raw
        var writeCmd = "configDir=\"${XDG_CONFIG_HOME:-$HOME/.config}/punchi-dock-remastered\" && mkdir -p \"$configDir\" && printf %s " + Logic.shellQuote(raw) + " > \"$configDir/dock_items.json\""
        executableDataSource.connectSource(writeCmd)
    }

    function updateNoteItem(noteItem, noteText, popupWidth, popupHeight) {
        if (!noteItem) {
            return
        }

        var updatedItems = []
        var changed = false
        for (var i = 0; i < root.dockItems.length; i++) {
            var item = root.dockItems[i]
            if (item === noteItem) {
                item = Object.assign({}, item, {
                    "note": noteText,
                    "popupWidth": popupWidth,
                    "popupHeight": popupHeight
                })
                changed = true
                root.activeNoteData = item
            }
            updatedItems.push(item)
        }

        if (changed) {
            root.dockItems = updatedItems
            syncDockItemsConfiguration()
        }
    }

    fullRepresentation: Item {
        id: mainContainer
        visible: !root.hiddenByVirtualDesktop
        enabled: visible
        implicitWidth: visible ? dockWrapper.width : 0
        implicitHeight: visible ? dockWrapper.height : 0
        width: implicitWidth
        height: implicitHeight
        Layout.minimumWidth: root.panelPreferredWidth
        Layout.minimumHeight: root.panelPreferredHeight
        Layout.preferredWidth: root.panelPreferredWidth
        Layout.preferredHeight: root.panelPreferredHeight

        function closeAllPopups(exceptDialog) {
            if (folderPopupDialog !== exceptDialog) {
                folderPopupDialog.visible = false
            }
            if (calendarPopupDialog !== exceptDialog) {
                calendarPopupDialog.visible = false
            }
            if (trashMenuDialog !== exceptDialog) {
                trashMenuDialog.visible = false
            }
            if (notePopupDialog !== exceptDialog) {
                notePopupDialog.visible = false
            }
            if (trashConfirmDialog !== exceptDialog) {
                trashConfirmDialog.visible = false
            }
        }

        function openTrashMenu(visualParent) {
            mainContainer.closeAllPopups(trashMenuDialog)
            trashMenuDialog.visualParent = visualParent
            trashConfirmDialog.visualParent = visualParent
            trashMenuDialog.visible = !trashMenuDialog.visible
        }

        function openFolderPopup(itemData, itemIndex, visualParent) {
            mainContainer.closeAllPopups(folderPopupDialog)
            root.activeFolderData = itemData
            root.activeFolderIndex = itemIndex
            folderPopupDialog.visualParent = visualParent
            folderPopupDialog.visible = !folderPopupDialog.visible
        }

        function openCalendarPopup(visualParent) {
            mainContainer.closeAllPopups(calendarPopupDialog)
            calendarPopupDialog.visualParent = visualParent
            calendarPopupDialog.visible = !calendarPopupDialog.visible
        }

        function openNotePopup(itemData, visualParent) {
            mainContainer.closeAllPopups(null)
            root.activeNoteData = itemData
            notePopupDialog.visualParent = visualParent
            notePopupDialog.visible = true
            Qt.callLater(function() {
                notePopupContent.focusEditor()
            })
        }

        Item {
            id: dockWrapper
            anchors.centerIn: parent
            implicitWidth: root.inPanel ? (dockLayout.implicitWidth + (root.dockBackgroundHorizontalPadding * 2)) : (dockLayout.implicitWidth + root.floatingExtraWidth)
            implicitHeight: root.inPanel ? (dockLayout.implicitHeight + (root.dockBackgroundVerticalPadding * 2)) : (dockLayout.implicitHeight + root.floatingExtraHeight)
            width: root.inPanel ? root.panelPreferredWidth : dockLayout.implicitWidth + root.floatingExtraWidth
            height: root.inPanel ? root.panelPreferredHeight : dockLayout.implicitHeight + root.floatingExtraHeight

            DockBackground {
                anchors.fill: parent
                radius: 12
                opacity: 0.85
                visible: !root.inPanel
            }

            RowLayout {
                id: dockLayout
                anchors.centerIn: parent
                spacing: root.dockSpacing
                
                property int hoveredIndex: -1
                property real mouseOffset: 0.0

                // Variables para transición suave al entrar/salir del dock
                property int lastHoveredIndex: -1
                property real lastMouseOffset: 0.0
                property real hoverZoomProgress: hoveredIndex >= 0 ? 1.0 : 0.0

                onHoveredIndexChanged: {
                    if (hoveredIndex >= 0) {
                        lastHoveredIndex = hoveredIndex
                    }
                }
                onMouseOffsetChanged: {
                    if (hoveredIndex >= 0) {
                        lastMouseOffset = mouseOffset
                    }
                }

                Behavior on hoverZoomProgress {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                signal trashUrlsDropped(var urls)
                onTrashUrlsDropped: function(urls) {
                    var cmd = Logic.trashUrlsScript(urls)
                    root.runCommand(cmd)
                }

                Repeater {
                    model: root.dockItems
                    delegate: DockItem {
                        id: dockItemDelegate
                        itemIndex: index
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        iconSize: root.effectiveIconSize
                        hoverScaleSetting: Plasmoid.configuration.hoverScale
                        hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                        
                        // Variables de animación de la ola
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset
                        
                        itemType: modelData.type || "app"
                        iconName: modelData.type === "trash" && modelData.showState !== false
                            ? (root.trashHasItems ? (modelData.fullIcon || "user-trash-full") : (modelData.icon || "user-trash"))
                            : (modelData.icon || "")
                        itemName: modelData.name || ""
                        itemCommand: modelData.command || ""
                        
                        onItemClicked: function(cmd) {
                            if (modelData.type === "folder") {
                                mainContainer.openFolderPopup(modelData, index, dockItemDelegate)
                            } else if (modelData.type === "calendar") {
                                mainContainer.openCalendarPopup(dockItemDelegate)
                            } else if (modelData.type === "note") {
                                mainContainer.openNotePopup(modelData, dockItemDelegate)
                            } else {
                                mainContainer.closeAllPopups(null)
                                root.launchDockItem(modelData)
                            }
                        }
                        onContextMenuRequested: function(visualParent) {
                            if (modelData.type === "trash") {
                                mainContainer.openTrashMenu(visualParent)
                            }
                        }
                    }
                }
            }
        }

        // Diálogo emergente para Carpetas (FolderPopup)
        PlasmaCore.Dialog {
            id: folderPopupDialog
            location: Plasmoid.location
            visible: false
            hideOnWindowDeactivate: true
            // Si es circular/abanico desactivamos el fondo nativo para el vuelo de iconos.
            // Si es lista/grid/detalle, usamos el fondo nativo estándar del tema de KDE (tipo Kickoff)
            backgroundHints: (root.activeFolderData.layout === "circular" || root.activeFolderData.layout === "fan") 
                ? PlasmaCore.Types.NoBackground 
                : PlasmaCore.Types.StandardBackground

            mainItem: FolderPopup {
                id: folderPopupContent
                folderItem: root.activeFolderData
                layoutMode: root.activeFolderData.layout || "grid"
                virtualEdge: Plasmoid.location
                isOpen: folderPopupDialog.visible

                onAppLaunched: function(app) {
                    folderPopupDialog.visible = false
                    root.launchDockItem(app)
                }

                onCloseRequested: {
                    folderPopupDialog.visible = false
                }
            }
        }

        // Diálogo emergente para el Calendario (CalendarPopup)
        PlasmaCore.Dialog {
            id: calendarPopupDialog
            location: Plasmoid.location
            visible: false
            hideOnWindowDeactivate: true
            // El calendario siempre utiliza el fondo nativo del tema de KDE (Kickoff)
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: CalendarPopup {
                // El popup se reinicia a la fecha actual al mostrarse
                Component.onCompleted: {
                    displayedDate = new Date()
                    updateGrid()
                }
                onCloseRequested: {
                    calendarPopupDialog.visible = false
                }
            }
        }

        // Diálogo emergente para el Menú Contextual de la Papelera (TrashMenuPopup)
        PlasmaCore.Dialog {
            id: trashMenuDialog
            location: Plasmoid.location
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: TrashMenuPopup {
                id: trashMenuContent
                onOpenTrashClicked: {
                    console.log("main.qml: onOpenTrashClicked received")
                    trashMenuDialog.visible = false
                    trashIntegration.openTrash()
                }
                onEmptyTrashClicked: {
                    console.log("main.qml: onEmptyTrashClicked received")
                    trashMenuDialog.visible = false
                    trashConfirmDialog.visible = true
                }
                onCloseRequested: {
                    console.log("main.qml: onCloseRequested received")
                    trashMenuDialog.visible = false
                }
            }
        }

        PlasmaCore.Dialog {
            id: notePopupDialog
            location: Plasmoid.location
            visible: false
            hideOnWindowDeactivate: false
            backgroundHints: PlasmaCore.Types.StandardBackground
            onVisibleChanged: {
                if (!visible && notePopupContent.currentText !== notePopupContent.initialText) {
                    root.updateNoteItem(root.activeNoteData, notePopupContent.currentText, notePopupContent.activeWidth, notePopupContent.activeHeight)
                }
            }

            mainItem: NotePopup {
                id: notePopupContent
                noteItem: root.activeNoteData
                onCloseRequested: {
                    notePopupDialog.visible = false
                }
                onClearRequested: function(noteText, popupWidth, popupHeight) {
                    notePopupContent.initialText = noteText
                    root.updateNoteItem(root.activeNoteData, noteText, popupWidth, popupHeight)
                }
            }
        }

        PlasmaCore.Dialog {
            id: trashConfirmDialog
            location: Plasmoid.location
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: ConfirmTrashEmptyPopup {
                onConfirmRequested: {
                    trashConfirmDialog.visible = false
                    trashIntegration.emptyTrash()
                }
                onCancelRequested: {
                    trashConfirmDialog.visible = false
                }
            }
        }
    }

    // Datos del popup de carpeta activo
    property var activeFolderData: ({})
    property int activeFolderIndex: -1
    property var activeNoteData: ({})
}
