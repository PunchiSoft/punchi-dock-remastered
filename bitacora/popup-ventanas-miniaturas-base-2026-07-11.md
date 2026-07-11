# Popup de ventanas con miniaturas base

Fecha: 2026-07-11

## Resumen

Se añadió una primera implementación de miniaturas de ventanas en el popup de selección de múltiples ventanas, con fallback a icono y una opción de configuración para desactivar la vista en vivo manteniendo la estructura de tarjeta.

## Referencia técnica

- `TaskManager.AbstractTasksModel.WinIdList` desde `kde-sdk/plasma-workspace/libtaskmanager/abstracttasksmodel.h`
- `TaskManager.ScreencastingRequest` desde `kde-sdk/plasma-workspace/libtaskmanager/screencastingrequest.h`
- `org.kde.pipewire/PipeWireSourceItem 1.0` desde `/usr/lib64/qt6/qml/org/kde/pipewire/KPipeWire.qmltypes`

## Cambios

- `contents/config/main.xml` suma `showWindowThumbnails`.
- `contents/ui/config/ConfigWindows.qml` expone un checkbox para mostrar u ocultar miniaturas vivas.
- `contents/ui/main.qml` ahora pasa `windowUuid` e icono a cada entrada del popup de ventanas.
- `contents/ui/components/TaskWindowsPopup.qml` cambia a una tarjeta tipo preview con:
  - miniatura viva vía `ScreencastingRequest + PipeWireSourceItem`;
  - fallback a icono cuando no hay preview o el usuario la desactiva;
  - estructura fija similar a selector de miniaturas clásico.

## Decisión

La estructura visual del popup se mantiene incluso cuando las miniaturas están desactivadas, para conservar el flujo tipo preview-card y permitir afinar estilos después sin cambiar la arquitectura base.
