# Tooltip con miniatura simulada

Fecha: 2026-07-11

## Resumen

Se reemplazó el `Controls.ToolTip` básico de `DockItem.qml` por un tooltip enriquecido con una vista de miniatura simulada para items de aplicación con ventanas activas o asociadas.

## Cambio aplicado

- Los items `app` con `taskIsActive` o `taskIndicatorCount > 0` ahora muestran un tooltip enriquecido.
- El tooltip enriquecido incluye:
  - nombre de la aplicación;
  - tarjeta visual 16:9;
  - icono centrado de `48x48`;
  - fondo semitransparente y borde adaptado al tema.
- Items simples como papelera siguen mostrando tooltip de texto.
- Separadores y espaciadores siguen sin tooltip.
- El tooltip ya no queda bloqueado por `inPanel`, lo que permite verlo también cuando el dock está en panel.

## Motivo

Esto crea una previsualización visual consistente aunque el stream real de miniaturas de Wayland no esté disponible o siga en afinación.
