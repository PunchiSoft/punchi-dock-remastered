import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

Item {
    id: dockItemContainer
    
    property string iconName: ""
    property string itemName: ""
    property string itemCommand: ""
    property int iconSize: 48

    property int itemIndex: -1
    property int hoveredIndex: -1
    
    // Variables de animación de la ola
    property real hoverZoomProgress: 0.0
    property int lastHoveredIndex: -1
    property real lastMouseOffset: 0.0

    // Configuración matemática idéntica al proyecto original con transiciones suaves
    property real hoverScaleSetting: 1.35
    property string hoverAnimationMode: "wave"
    property int highQualityIconSize: Math.min(512, Math.max(iconSize, Math.ceil(iconSize * Math.max(1, hoverScaleSetting) * 1.12)))
    property real highQualityIconScale: highQualityIconSize > 0 ? iconSize / highQualityIconSize : 1
    readonly property real hoverScaleDelta: Math.max(0.0001, hoverScaleSetting - 1.0)
    property real waveScale: {
        if (itemType === "calendar") {
            return 1.0
        }

        if (hoverAnimationMode === "none") {
            return 1.0
        }

        var activeIndex = hoveredIndex >= 0 ? hoveredIndex : lastHoveredIndex
        var activeOffset = hoveredIndex >= 0 ? dockItemContainer.parent.mouseOffset : lastMouseOffset

        if (activeIndex === -1 || hoverZoomProgress <= 0.0) {
            return 1.0
        }

        if (hoverAnimationMode === "single") {
            return itemIndex === activeIndex
                ? 1.0 + (hoverScaleSetting - 1.0) * hoverZoomProgress
                : 1.0
        }

        if (hoverAnimationMode === "paragraph") {
            var indexDistance = Math.abs(itemIndex - activeIndex)
            var paragraphInfluences = [1.0, 0.62, 0.28]
            if (indexDistance >= paragraphInfluences.length) {
                return 1.0
            }
            return 1.0 + (hoverScaleSetting - 1.0) * paragraphInfluences[indexDistance] * hoverZoomProgress
        }
        
        var step = iconSize + 8 // spacing
        var radius = Math.max(iconSize * 2.25, step * 1.85)
        
        var mousePos = (activeIndex * step) + (activeOffset * step)
        var itemPos = itemIndex * step
        
        var distance = Math.abs(itemPos - mousePos)
        if (distance >= radius) return 1.0
        
        var influence = 1.0 - (distance / radius)
        return 1.0 + (hoverScaleSetting - 1.0) * (influence * influence) * hoverZoomProgress
    }

    property bool inPanel: false
    // Elevación física (rise) que se desactiva en modo panel para no chocar/cortarse
    property real hoverRise: inPanel || waveScale <= 1.0 ? 0.0 : Math.round(iconSize * 0.32 * ((waveScale - 1.0) / hoverScaleDelta))

    property string itemType: "app"
    property string currentTime: "00:00"
    property string currentDate: "01/01"

    Timer {
        id: clockTimer
        interval: 1000
        running: itemType === "calendar"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date()
            var hh = String(date.getHours()).padStart(2, '0')
            var mm = String(date.getMinutes()).padStart(2, '0')
            var dd = String(date.getDate()).padStart(2, '0')
            var mo = String(date.getMonth() + 1).padStart(2, '0')
            currentTime = hh + ":" + mm
            currentDate = dd + "/" + mo
        }
    }

    signal itemClicked(string cmd)
    signal contextMenuRequested(var visualParent)

    // Medidas del contenedor del Layout TOTALMENTE ESTÁTICAS para evitar jitter
    implicitWidth: iconSize + 12
    implicitHeight: iconSize + 12

    Rectangle {
        id: hoverBackground
        anchors.fill: parent
        radius: 8
        color: Kirigami.Theme.highlightColor
        opacity: mouseArea.containsMouse && itemType !== "calendar" ? 0.2 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Kirigami.Icon {
        id: itemIcon
        anchors.centerIn: parent
        width: highQualityIconSize
        height: highQualityIconSize
        source: iconName
        visible: itemType !== "calendar"
        
        // Usar la escala combinada para renderizar en alta resolución y ajustar visualmente
        scale: highQualityIconScale * waveScale
        transform: Translate {
            y: -hoverRise
        }
    }

    Column {
        id: calendarText
        anchors.centerIn: parent
        visible: itemType === "calendar"
        spacing: 1
        
        scale: waveScale
        transform: Translate {
            y: -hoverRise
        }

        PlasmaComponents.Label {
            text: currentTime
            font.pixelSize: 14
            font.weight: Font.Normal
            color: Kirigami.Theme.textColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        PlasmaComponents.Label {
            text: currentDate
            font.pixelSize: 9
            color: Kirigami.Theme.textColor
            opacity: 0.68
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: itemName
        acceptedButtons: itemType === "trash" ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        
        onContainsMouseChanged: {
            if (itemType === "calendar") {
                if (!containsMouse && dockItemContainer.parent.hoveredIndex === itemIndex) {
                    dockItemContainer.parent.hoveredIndex = -1
                    dockItemContainer.parent.mouseOffset = 0.0
                }
                return
            }
            if (containsMouse) {
                dockItemContainer.parent.hoveredIndex = itemIndex
            } else if (dockItemContainer.parent.hoveredIndex === itemIndex) {
                dockItemContainer.parent.hoveredIndex = -1
                dockItemContainer.parent.mouseOffset = 0.0
            }
        }
        
        onPositionChanged: function(mouse) {
            if (itemType === "calendar") {
                return
            }
            if (containsMouse) {
                // Rango de -0.5 (izquierda) a 0.5 (derecha)
                dockItemContainer.parent.mouseOffset = (mouse.x - (width / 2)) / width
            }
        }
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                dockItemContainer.contextMenuRequested(dockItemContainer)
            } else {
                console.log("Item clickeado: " + itemName)
                dockItemContainer.itemClicked(itemCommand)
            }
        }
        Keys.onReturnPressed: dockItemContainer.itemClicked(itemCommand)
        Keys.onSpacePressed: dockItemContainer.itemClicked(itemCommand)
        Keys.onPressed: function(event) {
            if (itemType === "trash" && (event.key === Qt.Key_Menu
                    || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)))) {
                dockItemContainer.contextMenuRequested(dockItemContainer)
                event.accepted = true
            }
        }
    }

    DropArea {
        anchors.fill: parent
        enabled: itemType === "trash"
        onDropped: function(drop) {
            if (drop.hasUrls) {
                dockItemContainer.parent.trashUrlsDropped(drop.urls)
            }
        }
    }
    
    Controls.ToolTip {
        visible: mouseArea.containsMouse
        text: i18n(itemName)
        delay: 300
    }
}
