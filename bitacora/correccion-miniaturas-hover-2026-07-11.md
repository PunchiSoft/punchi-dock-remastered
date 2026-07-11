## 2026-07-11 - Correccion de miniaturas hover

### Hallazgo
- El hover preview de `DockItem.qml` habia quedado en un estado intermedio:
  - conservaba la configuracion `windowPreviewStyle`;
  - mantenia `taskPreviewWindowUuid`;
  - pero el tooltip ya no intentaba crear el stream real de la ventana.
- En la practica, eso degradaba siempre la vista a una tarjeta con icono.

### Correccion
- Se restauro `PipeWire.PipeWireSourceItem` en el tooltip de `DockItem.qml`.
- Se restauro `TaskManager.ScreencastingRequest` enlazado al `uuid` de la ventana activa.
- El fallback visual se mantiene:
  - si el modo es `card`, muestra la tarjeta con icono;
  - si el modo es `thumbnail` pero KWin/PipeWire no entregan stream, muestra `Preview unavailable`.

### Referencia tecnica
- `kde-sdk/plasma-workspace/libtaskmanager/screencastingrequest.h`
- `kde-sdk/plasma-workspace/libtaskmanager/screencastingrequest.cpp`
- `kde-sdk/plasma-workspace/libtaskmanager/waylandtasksmodel.cpp`

### Nota
- `TasksModel::WinIdList` en Wayland expone el `uuid` que necesita `ScreencastingRequest`, por lo que la fuente del dato en `main.qml` es correcta.

## Ajuste definitivo del flujo PipeWire

Se reemplazo la implementacion instrumentada de `WindowLiveThumbnail.qml` por el patron minimo usado tanto por el proyecto antiguo como por el Task Manager de Plasma:

```text
WinIdList -> ScreencastingRequest.uuid -> nodeId -> PipeWireSourceItem
```

- `PipeWireSourceItem` vuelve a ser el elemento raiz del componente.
- Se retiro el enlace adicional a `objectSerial` y el wrapper visual intermedio.
- Se retiraron las trazas temporales y la consulta a `IsExcludedFromCapture`.
- Tooltip y popup siguen compartiendo una unica implementacion de miniatura.
- Se creo un respaldo previo en `backup/punchi-dock-remastered-before-thumbnail-fix-2026-07-11.tar.gz`.
- `backup/` se agrego a `.kpackageignore` para que no forme parte del paquete distribuible.

La decision se contrasto con `kde-sdk/plasma-workspace/libtaskmanager/screencastingrequest.h` y con el componente oficial `PipeWireThumbnail.qml` conservado en el kit local del proyecto antiguo.
