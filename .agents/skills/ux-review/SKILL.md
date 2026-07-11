---
name: ux-review
description: Auditar una interfaz o flujo existente de Punchi Dock para detectar fricción, acciones ambiguas, estados incompletos y problemas de usabilidad. Usar al revisar cómo una persona descubre, ejecuta y recupera una acción; no usar para valorar únicamente alineación o estética ni para diseñar desde cero.
---

# Revisión de experiencia de usuario

## Procedimiento

1. Definir el objetivo del usuario y el punto de entrada del flujo.
2. Recorrer el camino normal, estados vacíos, errores, cancelación y recuperación.
3. Evaluar descubribilidad, claridad de etiquetas, retroalimentación, consistencia y cantidad de pasos.
4. Revisar uso con ratón, teclado y panel táctil cuando aplique.
5. Clasificar hallazgos por impacto: bloqueante, alto, medio o menor.
6. Para cada hallazgo, aportar evidencia, consecuencia y una recomendación concreta; distinguir hechos de preferencias.

## Comprobaciones

- La acción principal es reconocible y su resultado es predecible.
- Hover, foco, selección y activación no se confunden.
- Los errores explican qué ocurrió y cómo continuar.
- El usuario puede cancelar o deshacer acciones riesgosas cuando corresponda.
- La interfaz no exige precisión excesiva ni memoria innecesaria.
- El comportamiento es coherente entre orientaciones y tamaños del panel.

## Validación y salida

Entregar los hallazgos ordenados por severidad, con ubicación reproducible y recomendación. Si no hubo prueba en runtime, declarar que la revisión fue estática.

Usar `visual-review` para defectos puramente visuales, `accessibility` para barreras de acceso y `ui-design` si la solución requiere replantear la interfaz.
