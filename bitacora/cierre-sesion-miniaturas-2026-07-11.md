## 2026-07-11 - Cierre de sesion: miniaturas en vivo

### Resumen ejecutivo
- Se cerro la integracion estructural de miniaturas en vivo para hover y popup de multiples ventanas.
- La interfaz ya no depende de hacks de tooltip simples: usa una tarjeta estable con fallback visual y una capa superior para PipeWire.
- El resultado visible al final de la sesion sigue siendo `Preview unavailable`.

### Que si quedo hecho
- `main.qml` entrega `windowUuid` desde `WinIdList`.
- `DockItem.qml` solicita miniatura viva con `TaskManager.ScreencastingRequest` y `PipeWireSourceItem`.
- `TaskWindowsPopup.qml` replica el mismo patron.
- Se aplico `lazy loading` para reducir streams persistentes y consumo innecesario.
- La configuracion permite elegir entre:
  - miniatura real;
  - tarjeta con icono solamente.

### Que no quedo validado
- No se confirmo recepcion efectiva de frames reales desde KWin/PipeWire.
- No se puede declarar la funcionalidad como terminada solo porque el fallback visual aparece correctamente.

### Diagnostico mas probable
- El QML ya alcanza el punto de solicitar el stream.
- La falla restante parece estar en el runtime del screencast de ventana bajo Wayland:
  - permisos/contexto del host;
  - disponibilidad real del stream;
  - o necesidad de validar exclusivamente en panel real de Plasma y no en `plasmoidviewer`.

### Decision tecnica
- No seguir rehaciendo layout, tooltips o popup cards sin evidencia nueva.
- La siguiente iteracion debe ser de observabilidad y diagnostico:
  - logs temporales de `uuid`, `nodeId` y estado del loader;
  - prueba en panel real instalado;
  - confirmacion de si KWin entrega o no el stream.

### Archivos clave al cierre
- `contents/ui/main.qml`
- `contents/ui/components/DockItem.qml`
- `contents/ui/components/TaskWindowsPopup.qml`
- `contents/ui/config/ConfigWindows.qml`
- `docs/revisiones/revision_11-07-26-2.md`
