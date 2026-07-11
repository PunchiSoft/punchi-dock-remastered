# Debounce para tareas dinámicas

Fecha: 2026-07-11

## Resumen

Se redujo el lag de las tareas dinámicas en `contents/ui/main.qml` separando el refresco estructural del refresco visual del `TaskManager.TasksModel`.

## Problema

Cada `dataChanged` del modelo disparaba `refreshVisibleTaskRows()` y además incrementaba una revisión global. Durante minimizar, restaurar o cambios rápidos de foco, eso provocaba recalcular la lista de tareas y reevaluar delegados demasiadas veces por segundo.

## Cambio aplicado

- Se añadió `refreshTasksTimer` con debounce de 50 ms.
- Se introdujo `taskVisualRevision` para refrescos visuales baratos.
- El recálculo de `visibleTaskRows` ahora se agenda solo cuando cambian filas o el conteo del modelo.
- `refreshVisibleTaskRows()` ya no incrementa una revisión visual y además evita reasignar el array si el contenido no cambió.

## Efecto esperado

- Menos trabajo por cada tormenta de señales de KWin.
- Menos jitter al minimizar, restaurar o activar ventanas.
- Mejor base para eliminar en una fase posterior más dependencias del revision hack.
