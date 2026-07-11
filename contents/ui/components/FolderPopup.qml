import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

Item {
    id: folderRoot
    width: circularMode ? 320 : 280
    height: circularMode ? 320 : 340
    
    // Plasma 6 Dialog requiere implicitWidth e implicitHeight para dimensionar la ventana
    implicitWidth: width
    implicitHeight: height

    // Propiedades inyectadas por la UI principal
    property var folderItem: ({})
    property string layoutMode: "grid" // "list", "grid", "detailed", "circular", "fan"
    property int virtualEdge: PlasmaCore.Types.BottomEdge
    property bool isOpen: false

    // Accesos rápidos
    property bool circularMode: layoutMode === "circular" || layoutMode === "fan"
    property var apps: folderItem.apps || []
    property int itemCount: apps.length

    // Animación de despliegue para circular/fan
    property real openProgress: isOpen ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutBack
            easing.overshoot: 0.8
        }
    }

    // Señales para ejecutar aplicaciones y cerrar el popup
    signal appLaunched(var app)
    signal closeRequested()

    // ── LÓGICA DE GEOMETRÍA CIRCULAR Y ABANICO (FAN) ──────────────────────
    function getOriginX() {
        if (layoutMode === "circular") return width / 2;
        if (virtualEdge === PlasmaCore.Types.LeftEdge) return 20;
        if (virtualEdge === PlasmaCore.Types.RightEdge) return width - 20;
        return width / 2;
    }

    function getOriginY() {
        if (layoutMode === "circular") return height / 2;
        if (virtualEdge === PlasmaCore.Types.TopEdge) return 20;
        if (virtualEdge === PlasmaCore.Types.BottomEdge) return height - 20;
        return height / 2;
    }

    function getStartAngle() {
        if (virtualEdge === PlasmaCore.Types.TopEdge) return 20;
        if (virtualEdge === PlasmaCore.Types.LeftEdge) return -70;
        if (virtualEdge === PlasmaCore.Types.RightEdge) return 110;
        return 200; // BottomEdge / default
    }

    function getSweepAngle() {
        return 140;
    }

    // Calcular posición del botón de cierre en abanico desplazado para no chocar el dock
    function getCloseX() {
        if (layoutMode === "circular") return getOriginX();
        var angleRad = (getStartAngle() + getSweepAngle() / 2) * Math.PI / 180;
        return getOriginX() + Math.cos(angleRad) * 44;
    }

    function getCloseY() {
        if (layoutMode === "circular") return getOriginY();
        var angleRad = (getStartAngle() + getSweepAngle() / 2) * Math.PI / 180;
        return getOriginY() + Math.sin(angleRad) * 44;
    }

    // ── INTERFAZ CLÁSICA (LISTA, REJILLA, DETALLADA) ─────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        visible: !circularMode
        spacing: 8

        // Título de la carpeta
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: folderItem.name || i18n("Folder")
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.Bold
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
            }
            // Botón de cerrar
            Rectangle {
                width: 20; height: 20; radius: 10
                color: closeMouse.containsMouse || closeMouse.activeFocus ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.backgroundColor
                PlasmaComponents.Label { text: "×"; anchors.centerIn: parent; color: Kirigami.Theme.textColor }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent; hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: i18n("Close")
                    onClicked: folderRoot.closeRequested()
                    Keys.onReturnPressed: folderRoot.closeRequested()
                    Keys.onSpacePressed: folderRoot.closeRequested()
                }
            }
        }

        // Vista de Rejilla/Lista
        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Corregir cellWidth para evitar scrollbars o recortes horizontales
            cellWidth: layoutMode === "list" || layoutMode === "detailed" ? gridView.width : 80
            cellHeight: layoutMode === "detailed" ? 56 : (layoutMode === "list" ? 40 : 72)
            model: folderRoot.apps
            clip: true

            delegate: Item {
                width: gridView.cellWidth
                height: gridView.cellHeight

                // Fondo interactivo
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 8
                    color: itemMouse.containsMouse || itemMouse.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    opacity: itemMouse.containsMouse || itemMouse.activeFocus ? 0.2 : 1
                    border.width: itemMouse.activeFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                }

                // Modo Lista y Modo Detalle (Icono a la izquierda, etiqueta al lado)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: layoutMode === "list" || layoutMode === "detailed"
                    spacing: 8

                    Kirigami.Icon {
                        width: 32; height: 32
                        source: modelData.icon || "application-x-executable"
                    }
                    Column {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: modelData.name
                            font.family: Kirigami.Theme.defaultFont.family
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        PlasmaComponents.Label {
                            text: modelData.command || ""
                            font.family: Kirigami.Theme.smallFont.family
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.textColor
                            opacity: 0.6
                            elide: Text.ElideRight
                            width: parent.width
                            visible: layoutMode === "detailed"
                        }
                    }
                }

                // Modo Grid Estándar (Icono arriba, etiqueta abajo)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: layoutMode === "grid"
                    spacing: 4

                    Kirigami.Icon {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignHCenter
                        source: modelData.icon || "application-x-executable"
                    }
                    PlasmaComponents.Label {
                        text: modelData.name
                        font.family: Kirigami.Theme.smallFont.family
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.textColor
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name || i18n("Aplicación")
                    onClicked: {
                        folderRoot.appLaunched(modelData)
                    }
                    Keys.onReturnPressed: folderRoot.appLaunched(modelData)
                    Keys.onSpacePressed: folderRoot.appLaunched(modelData)
                }
            }
        }
    }

    // ── INTERFAZ CIRCULAR / ABANICO (FAN) ────────────────────────────────
    Item {
        id: circularContainer
        anchors.fill: parent
        visible: circularMode

        // Fondo decorativo en modo circular completo
        Rectangle {
            anchors.centerIn: parent
            width: 180; height: 180; radius: 90
            color: Kirigami.Theme.backgroundColor
            opacity: 0.8 * openProgress
            border.width: 1
            border.color: Kirigami.Theme.textColor
            visible: layoutMode === "circular" && openProgress > 0.1
        }

        // Elementos flying out
        Repeater {
            model: folderRoot.apps
            delegate: Item {
                property real progress: folderRoot.itemCount <= 1 ? 0.5 : index / (folderRoot.itemCount - 1)
                property real angleDegrees: layoutMode === "circular" 
                    ? -90 + index * (360 / Math.max(1, folderRoot.itemCount))
                    : folderRoot.getStartAngle() + progress * folderRoot.getSweepAngle()
                property real angleRad: angleDegrees * Math.PI / 180
                
                // Distancia a expandirse
                property real radiusLength: layoutMode === "circular" ? 95 : 115

                // Coordenadas calculadas en vivo
                property real targetX: folderRoot.getOriginX() + Math.cos(angleRad) * radiusLength - width/2
                property real targetY: folderRoot.getOriginY() + Math.sin(angleRad) * radiusLength - height/2

                width: 52
                height: 52
                
                // Animar el vuelo de los elementos de forma fluida desde el origen
                x: folderRoot.getOriginX() - width/2 + (targetX - (folderRoot.getOriginX() - width/2)) * folderRoot.openProgress
                y: folderRoot.getOriginY() - height/2 + (targetY - (folderRoot.getOriginY() - height/2)) * folderRoot.openProgress
                opacity: folderRoot.openProgress
                scale: 0.6 + 0.4 * folderRoot.openProgress

                Rectangle {
                    anchors.fill: parent
                    radius: 26
                    color: itemCircMouse.containsMouse || itemCircMouse.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: itemCircMouse.activeFocus ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: modelData.icon || "application-x-executable"
                    }
                }

                // Tooltip básico para el icono circular
                Controls.ToolTip {
                    visible: itemCircMouse.containsMouse
                    text: modelData.name
                    delay: 200
                }

                MouseArea {
                    id: itemCircMouse
                    anchors.fill: parent; hoverEnabled: true
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name || i18n("Aplicación")
                    onClicked: folderRoot.appLaunched(modelData)
                    Keys.onReturnPressed: folderRoot.appLaunched(modelData)
                    Keys.onSpacePressed: folderRoot.appLaunched(modelData)
                }
            }
        }

        // Botón central para cerrar en modo circular o abanico
        Rectangle {
            width: 38; height: 38; radius: 19
            color: circCloseMouse.containsMouse || circCloseMouse.activeFocus ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Kirigami.Theme.textColor
            x: folderRoot.getCloseX() - width/2
            y: folderRoot.getCloseY() - height/2
            opacity: openProgress

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 18; height: 18
                source: "window-close-symbolic"
            }

            MouseArea {
                id: circCloseMouse
                anchors.fill: parent; hoverEnabled: true
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: i18n("Close")
                onClicked: folderRoot.closeRequested()
                Keys.onReturnPressed: folderRoot.closeRequested()
                Keys.onSpacePressed: folderRoot.closeRequested()
            }
        }
    }
}
