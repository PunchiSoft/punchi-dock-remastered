## 2026-07-11 - Hover popup de ventanas estilo proyecto madre

### Cambio
- Se reintrodujo un flujo de hover controlado para abrir `TaskWindowsPopup.qml` automaticamente.
- `DockItem.qml` vuelve a emitir `hoverEntered` y `hoverExited`.
- `main.qml` ahora gobierna el popup con timers de apertura/cierre y lo mantiene vivo mientras el cursor siga en el item o dentro del popup.

### Motivo
- Alinear el comportamiento con el proyecto madre, donde la sensacion de "miniatura al pasar el mouse" en realidad viene del popup de ventanas y no del tooltip simple.

### Detalles
- El tooltip del item fuente se suprime mientras el popup de ventanas asociado esta abierto.
- Los items fijados con ventanas activas y las tareas dinamicas pueden disparar el popup por hover.
- El click conserva su comportamiento actual.

### Estado
- El patron de interaccion correcto ya quedo implementado.
- La validacion pendiente sigue siendo la misma: confirmar si KWin/PipeWire entrega frames reales o si el popup continua cayendo en `Preview unavailable`.
