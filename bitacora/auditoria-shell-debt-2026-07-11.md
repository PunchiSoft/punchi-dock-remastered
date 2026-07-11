# Bitácora: auditoría puntual de deuda shell

Fecha: 2026-07-11

## Trabajo realizado

- Se revisaron los usos actuales de `sh -c`, `Plasma5Support.DataSource` y scripts de shell en runtime y configuración.
- Se contrastó la deuda shell con el adaptador nativo actual `SystemDiscovery`.
- Se clasificaron prioridades de migración y se dejó una recomendación concreta para el siguiente cambio.

## Resultado

- Se documentó la auditoría en [docs/revisiones/auditoria-shell-debt-2026-07-11.md](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/docs/revisiones/auditoria-shell-debt-2026-07-11.md:1).
- La prioridad técnica recomendada quedó enfocada en:
  - papelera;
  - sincronización de `dock_items.json`;
  - preview de sonido;
  - indexado de iconos, en ese orden.

## Siguiente paso sugerido

- Diseñar una ampliación nativa pequeña para la papelera antes de tocar la indexación de iconos.
