# Bitácora de Progreso: Menú Contextual para la Papelera

## Fecha
2026-07-10

## Objetivo Cumplido
Se implementó un menú contextual interactivo de clic derecho para el ítem de la Papelera en el dock, permitiendo abrirla o vaciarla directamente.

## Detalles Técnicos y Decisiones:
1. **Componente Modular (`TrashMenuPopup.qml`):** Se creó un nuevo componente exclusivo para el menú de la papelera, manteniendo la misma estructura y estética visual premium del resto de popups (como el de carpetas).
2. **Soporte de Clic Derecho (`DockItem.qml`):** Se configuró el `MouseArea` del elemento para aceptar tanto clics izquierdos como derechos (`acceptedButtons: Qt.LeftButton | Qt.RightButton`). Al hacer clic derecho, si el ítem es de tipo papelera, se delega al contenedor principal la apertura del menú.
3. **Comando de Vaciar (`main.qml`):** Al hacer clic en "Vaciar papelera", se ejecuta de forma segura el comando nativo `gio trash --empty` a través de nuestro DataSource `executable`. Esto es compatible con la especificación de papelera de Freedesktop y funciona sin dependencias pesadas ni llamadas externas a Python.
4. **Comando de Abrir:** Al hacer clic en "Abrir papelera", se ejecuta el comando seguro autodetectado (`kioclient6` o `gio open`) para abrir la ubicación virtual `trash:/`.
5. **Corrección de Alcance (Scope):** Se reubicó la función `openTrashMenu` al nivel de `mainContainer` (dentro de `fullRepresentation`) y se conectó como `mainContainer.openTrashMenu(visualParent)` desde el delegado de `DockItem` en `main.qml`, resolviendo el `ReferenceError` debido a la separación de ámbitos en QML.

## Estado
Funcionalidad y corrección completadas y validadas.
