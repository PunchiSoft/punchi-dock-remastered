## 2026-07-11 - Lazy loading de miniaturas PipeWire

### Cambio
- Se refactorizó la renderización de miniaturas en `DockItem.qml` y `TaskWindowsPopup.qml`.
- Las miniaturas en vivo ahora se solicitan con `Loader` solo cuando el tooltip o popup están visibles.

### Detalle técnico
- `DockItem.qml`:
  - mantiene una tarjeta base permanente;
  - activa `TaskManager.ScreencastingRequest` y `PipeWireSourceItem` solo mientras `tooltipDialog.visible` y `thumbnailPreviewEnabled` sean verdaderos.
- `TaskWindowsPopup.qml`:
  - mantiene fallback visual permanente por fila;
  - monta el stream solo para delegados visibles dentro del `ListView`.

### Motivo
- Reducir consumo de CPU/memoria.
- Evitar streams persistentes cuando no hay preview visible.
- Mantener una degradación visual limpia cuando KWin/PipeWire no entregan el stream.
