# Tercera revisión: base visual de popups y primer salto a gestor de tareas

Fecha: 2026-07-11

## Resumen

Se inició la tercera revisión con un alcance incremental: reforzar la legibilidad de popups, mejorar fidelidad visual al tema Plasma en modos circular/abanico y montar la primera integración funcional con `TaskManager.TasksModel` sin introducir todavía un adaptador C++ dedicado para ventanas.

## Cambios aplicados

- `contents/ui/components/FolderPopup.qml`
  - Se añadieron `PlasmaExtras.ShadowedLabel` en títulos y nombres de apps.
  - Se empezó a reemplazar fondo plano por `KSvg.FrameSvgItem` en los modos circular y abanico.
- `contents/ui/components/NotePopup.qml`
  - El título principal ahora usa etiqueta con sombra.
- `contents/ui/components/TrashMenuPopup.qml`
  - El título principal ahora usa etiqueta con sombra.
- `contents/config/main.xml`
  - Se agregaron `showActiveTasks` y `showTasksCurrentDesktopOnly`.
- `contents/config/config.qml`
  - Se registró la nueva categoría `Windows`.
- `contents/ui/config/ConfigWindows.qml`
  - Nueva página de configuración base para tareas activas y filtro por escritorio virtual actual.
- `src/systemdiscovery.h`
  - Se añadió `applicationIdForCommand(const QString &command) const`.
- `src/systemdiscovery.cpp`
  - Implementación nativa para resolver `AppId` desde un comando reutilizando la lógica de descubrimiento existente.
- `contents/ui/main.qml`
  - Se integró `TaskManager.TasksModel` directamente en QML.
  - Se calcula una lista de tareas visibles no duplicadas respecto de lanzadores fijados.
  - Los lanzadores fijados muestran indicador de ventana abierta y, cuando corresponde, activan/minimizan la ventana existente.
  - Las ventanas no fijadas se renderizan al final del dock como entradas dinámicas.
- `contents/ui/components/DockItem.qml`
  - Se añadieron propiedades para indicador de tarea y estado activo/atención.

## Decisiones técnicas

- Se evitó añadir por ahora un modelo C++ propio para ventanas porque el SDK local de KDE confirma que `TaskManager.TasksModel` es usable directamente desde QML.
- La relación entre lanzadores fijos y ventanas se resolvió mediante `AppId`/`storageId` normalizado, con apoyo de `SystemDiscovery`, para no duplicar lógica de matching en scripts.
- La integración es deliberadamente fase 1: hay soporte visible y comportamiento básico de task manager, pero todavía no hay menú contextual de ventanas ni agrupación avanzada por múltiples instancias.

## Validación ejecutada

- `cmake --build build --target stage_plasmoid_module`
- `ctest --test-dir build --output-on-failure`
- `qmllint -I build/bin -I contents/ui -I contents -I /usr/lib64/qt6/qml contents/ui/main.qml contents/ui/components/DockItem.qml contents/ui/components/FolderPopup.qml contents/ui/components/NotePopup.qml contents/ui/components/TrashMenuPopup.qml contents/ui/config/ConfigWindows.qml contents/ui/config/ConfigGeneral.qml contents/ui/config/ConfigFiles.qml contents/config/config.qml`

## Pendiente natural de la siguiente fase

- Afinar la estética circular/abanico si se quiere más “burbuja Plasma” en cada slot radial.
- Extender el comportamiento cuando exista más de una ventana para el mismo lanzador fijo.
- Evaluar si el matching debe persistir `storageId` también desde la configuración de items descubiertos para reforzar consistencia de largo plazo.

## Actualización fase 2

- Se corrigió el fallo de runtime donde las tareas dinámicas quedaban sin icono porque `Qt.DecorationRole` entrega `QIcon` y `DockItem` espera `QString`.
- `main.qml` ahora resuelve el icono de tarea vía `AppId` y `SystemDiscovery::iconForApplication()`.
- Se eliminó el uso problemático de `index` en el delegate dinámico y se sustituyó por un índice derivado de `visibleTaskRows`.
- Se añadió `contents/ui/components/TaskWindowsPopup.qml` para seleccionar entre múltiples ventanas del mismo launcher fijado.
- Si un launcher fijado tiene más de una ventana activa, el click abre el popup selector en lugar de activar ciegamente la primera coincidencia.

## Actualización soporte Flatpak / identidad persistente

- `SystemDiscovery` ahora expone `appId` junto a `storageId` en las apps descubiertas.
- `ActionDialog` conserva `appStorageId` y `appApplicationId` durante la edición del item.
- `configItemsFormHelper.js` persiste `storageId` y `appId` en los items tipo `app`.
- `configItems.js` ahora normaliza `appId` y deduce identidad de aplicación desde comandos `flatpak run`, `gtk-launch` y ejecutables directos.
- `main.qml` prioriza `storageId`, luego `appId`, y solo después cae al resolvedor por comando para emparejar lanzadores con tareas activas.

## Actualización fase 3 temprana

- `TaskWindowsPopup.qml` ahora permite cerrar una ventana específica además de activarla.
- `main.qml` incorpora `closeTaskRow()` usando `TaskManager.TasksModel.requestClose()`.
- El popup de ventanas muestra subtítulo con `GenericName` cuando existe y solo enseña acción de cierre si la tarea es realmente cerrable.
- `configItems.js` sincroniza identidad derivada también en acciones y apps internas de carpetas, evitando que quede `storageId/appId` obsoleto si el comando cambia.
