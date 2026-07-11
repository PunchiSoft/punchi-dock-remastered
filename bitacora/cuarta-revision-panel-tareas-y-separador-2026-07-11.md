# Cuarta revisión: panel, tareas estables y separadores reales

Fecha: 2026-07-11

## Resumen

Se aplicó una tanda enfocada en problemas clásicos de panel rígido en Plasma: hover que chocaba con el borde superior/lateral, tareas dinámicas reordenándose por foco, tooltip global del plasmoide compitiendo con los tooltips del dock y separadores tratados como iconos normales.

## Cambios aplicados

- `contents/ui/main.qml`
  - Se forzó `Plasmoid.toolTipMainText: ""` y `Plasmoid.toolTipSubText: ""`.
  - `TaskManager.TasksModel` cambió de `SortLastActivated` a `SortDisabled` para estabilizar el orden visual.
  - Se añadió lógica para longitud del panel con `panelLengthMode`.
  - El cálculo de icono base en panel ahora deja margen para el hover.
- `contents/ui/components/DockItem.qml`
  - El desplazamiento hover ahora responde a `panelLocation`.
  - El hover en panel se orienta hacia el interior del escritorio según borde superior, inferior, izquierdo o derecho.
  - Se implementó un separador real con ancho reducido y línea semitransparente.
  - Separadores y spacers dejaron de comportarse como botones interactivos normales.
- `contents/ui/config/ConfigWindows.qml`
  - Nueva opción para longitud del panel:
    - `Fit content`
    - `Fill panel edge`
  - La opción solo se muestra cuando el panel parece ocupar el borde completo.
- `contents/config/main.xml`
  - Se añadió `panelLengthMode`.

## Decisiones técnicas

- No se eliminó el modo `fan`; se conserva para una revisión futura más profunda.
- No se endureció todavía el caso aislado reportado con Konsole/Comfy, porque se consideró un falso positivo menor frente a los problemas de panel y orden visual.
- Para el orden de tareas se eligió `SortDisabled` en lugar de otro modo semántico para evitar reordenamientos por activación sin introducir nuevas reglas implícitas.

## Validación ejecutada

- `qmllint -I build/bin -I contents/ui -I contents -I /usr/lib64/qt6/qml contents/ui/main.qml contents/ui/components/DockItem.qml contents/ui/config/ConfigWindows.qml`
- `cmake --build build --target stage_plasmoid_module`
- `ctest --test-dir build --output-on-failure`
