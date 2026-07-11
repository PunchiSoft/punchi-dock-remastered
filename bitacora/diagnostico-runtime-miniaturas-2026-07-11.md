# Diagnóstico runtime de miniaturas

Fecha: 2026-07-11

## Resumen

Se instrumentó el flujo de miniaturas vivas para validar en el panel real de Plasma si el fallo ocurre en la asociación de tarea, en la exclusión de captura o en la creación del stream de PipeWire.

## Cambios

- Se creó `contents/ui/components/WindowLiveThumbnail.qml` como componente mínimo compartido para tooltip y popup.
- `DockItem.qml` y `TaskWindowsPopup.qml` ahora reutilizan ese componente en lugar de mantener dos implementaciones divergentes.
- `main.qml` agrega trazas temporales para registrar:
  - filas asociadas al hover;
  - `windowUuid`;
  - estado `IsExcludedFromCapture`;
  - apertura del popup de ventanas.
- El popup de ventanas ahora diferencia visualmente entre `Preview unavailable` y `Capture blocked`.

## Motivo técnico

- El proyecto antiguo y el task manager upstream usan un componente PipeWire muy pequeño, con menos variables en juego.
- Remastered tenía dos caminos separados para tooltip y popup; eso dificultaba aislar si el problema era del stream o de la integración.
- `AbstractTasksModel` ya expone `IsExcludedFromCapture`, por lo que convenía incorporarlo al diagnóstico en runtime.
