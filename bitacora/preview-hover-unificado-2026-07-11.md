## 2026-07-11 - Preview hover unificado y selector de estilo

### Cambios
- Se eliminó el flujo hover heredado basado en `TaskPreviewPopup.qml`, timers manuales y `PlasmaCore.Dialog`.
- `DockItem.qml` ahora usa un único `PlasmaCore.ToolTipArea` enriquecido para previews de tareas.
- Se añadió soporte directo en `DockItem.qml` para dos modos de preview:
  - `thumbnail`: intenta mostrar miniatura real con `TaskManager.ScreencastingRequest` y `PipeWireSourceItem`.
  - `card`: fuerza la tarjeta simulada con icono.
- `ConfigWindows.qml` y `contents/config/main.xml` quedaron alineados con la nueva preferencia `windowPreviewStyle`.
- `TaskWindowsPopup.qml` ahora respeta el mismo modo de preview que el hover.

### Motivo técnico
- Había dos sistemas de preview compitiendo entre sí:
  - tooltip enriquecido en `DockItem.qml`
  - popup hover separado en `TaskPreviewPopup.qml`
- Esa duplicidad producía tiempos inconsistentes y comportamiento menos parecido al task manager nativo.
- El flujo viejo quedó como `dead code` y fue erradicado.

### Resultado esperado
- Hover más estable y natural en iconos dinámicos.
- Una sola fuente de verdad para decidir si mostrar miniatura real o tarjeta con icono.
- Menor complejidad para futuras revisiones de previews de ventanas.
