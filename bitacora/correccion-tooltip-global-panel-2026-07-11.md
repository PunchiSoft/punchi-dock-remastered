# Corrección de tooltip global en modo panel

Fecha: 2026-07-11

## Resumen

Se corrigió la competencia entre el tooltip global del plasmoide y el tooltip propio de los items del dock en modo panel.

## Cambio aplicado

- `contents/ui/main.qml` ahora fuerza tanto `toolTipMainText` como `toolTipSubText` a cadena vacía.

## Motivo técnico

- El runtime ya había silenciado el título del tooltip global, pero seguía dejando disponible el subtítulo.
- Eso permitía que Plasma mostrara la descripción general del plasmoide sobre el dock mientras el hover de los items mostraba su propio tooltip, generando una superposición molesta y potencialmente conflictiva con previews de ventanas.
