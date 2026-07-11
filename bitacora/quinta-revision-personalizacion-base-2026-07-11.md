# Quinta revisión: base de personalización

Fecha: 2026-07-11

## Resumen

Se inició la quinta revisión con una versión recortada y mantenible del alcance: nuevas categorías de configuración para ratón y aspecto, etiquetas persistentes opcionales en el dock, extracción del indicador activo a un subcomponente y efectos de click ligeros para los items del dock.

## Cambios

- `contents/config/main.xml` ahora separa opciones nuevas en grupos `Appearance` y `Mouse`.
- `contents/config/config.qml` registra `ConfigAspect.qml` y `ConfigMouse.qml`.
- `contents/ui/config/ConfigMouse.qml` concentra `hoverAnimation`, `clickEffect` y el modo de cursor interactivo para la ventana de ajustes.
- `contents/ui/config/ConfigAspect.qml` añade visibilidad de etiquetas y opciones base del indicador activo.
- `contents/ui/config/components/ConfigCursorBehavior.qml` centraliza cursores interactivos para controles de configuración.
- `contents/ui/components/TaskIndicator.qml` extrae el indicador activo del `DockItem`.
- `contents/ui/components/DockItem.qml` soporta:
  - etiquetas persistentes opcionales;
  - indicador configurable (`line`, `dot`, `ring`, `square`, `none`);
  - efectos de click livianos (`none`, `pulse`, `press`, `bounce`).
- `contents/ui/main.qml` propaga estas nuevas preferencias al runtime del dock y ajusta el tamaño de item para etiquetas persistentes.

## Decisiones

- Las etiquetas se limitaron en esta fase a mostrar/ocultar nombres de items con estilo compacto de una línea.
- La personalización avanzada de fuente, chip, sombra y color personalizado del indicador se pospone para una fase posterior para no volver a sobrecargar `DockItem.qml`.
- El cursor interactivo se integró primero en las páginas principales de configuración (`General`, `Windows`, `Mouse`, `Appearance`) como base reusable.
