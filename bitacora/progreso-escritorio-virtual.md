# Bitácora de Progreso: Soporte para Escritorio Único o Múltiple

## Fecha
2026-07-10

## Objetivo
Permitir definir la visibilidad del plasmoide en un escritorio virtual específico o en todos los escritorios virtuales de KDE Plasma 6.

## Detalles Técnicos y Decisiones:
1. **Configuración Dinámica:** Se agregaron las opciones `virtualDesktopMode` ("all" / "single") y `targetVirtualDesktop` (UUID del escritorio virtual objetivo) en `main.xml`.
2. **Fuente nativa y reactiva:** `ConfigGeneral.qml` y `main.qml` usan `TaskManager.VirtualDesktopInfo`, expuesto por el módulo QML `org.kde.taskmanager`. La lista, los nombres y el escritorio activo reaccionan a las señales de Plasma sin Python, procesos externos ni consultas periódicas.
3. **Configuración robusta:** El selector se actualiza cuando cambia la lista de escritorios y muestra una advertencia si no hay escritorios o si el identificador guardado dejó de existir.
4. **Visibilidad y tamaño:** Cuando el escritorio activo no coincide con el configurado, la representación se oculta, se deshabilita y publica tamaño implícito cero para solicitar que el contenedor deje de reservar espacio.
5. **Referencia técnica:** La decisión se contrastó con `kde-sdk/plasma-workspace/libtaskmanager/virtualdesktopinfo.h` y el registro QML de `kde-sdk/plasma-workspace/libtaskmanager/CMakeLists.txt`.

## Estado de validación

Validación estática realizada:

- `qmllint` aceptó `contents/ui/main.qml` y `contents/ui/config/ConfigGeneral.qml` sin diagnósticos.
- `xmllint` aceptó `contents/config/main.xml`.
- `metadata.json` conserva JSON válido.
- `qmlimportscanner` encontró el módulo instalado `org.kde.taskmanager`, y su archivo `taskmanager.qmltypes` expone `VirtualDesktopInfo`.
- Se comprobó que esta función ya no contiene invocaciones a Python, `busctl` ni un temporizador de escritorios.

Queda pendiente validar en una sesión real de Plasma/Wayland el cambio reactivo de escritorio, la actualización del selector y si el panel respeta el tamaño implícito cero sin conservar un hueco mínimo. No se declara todavía validación runtime.
