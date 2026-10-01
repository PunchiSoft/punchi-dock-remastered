---
name: visual-review
description: Auditar una interfaz ya implementada de Punchi Dock para detectar problemas de alineación, espaciado, escala, jerarquía, iconografía, color, estados visuales y adaptación al tema. Usar con capturas o una vista ejecutable; no usar para evaluar el flujo de tareas ni para diseñar una interfaz desde cero.
---

# Revisión visual

## Entradas

Revisar capturas, interfaz ejecutable y QML relacionado. Consultar `docs/revisiones/` cuando contenga evidencia del problema.

## Procedimiento

1. Comparar estructura y jerarquía antes de revisar detalles decorativos.
2. Revisar alineación, ritmo de espacios, tamaños, tipografía, iconos y contraste.
3. Comparar estados normal, hover, foco, presionado, seleccionado y deshabilitado.
4. Comprobar panel horizontal/vertical, tamaños extremos, escalado y temas claro/oscuro.
5. Registrar cada hallazgo con ubicación, evidencia, impacto y corrección propuesta.
6. Separar defectos objetivos de preferencias estéticas y evitar rediseños no solicitados.

## Criterios de aceptación

- Los hallazgos están priorizados y pueden reproducirse.
- Las recomendaciones usan métricas, colores y componentes del tema cuando existen.
- Se declara qué combinaciones de tema, escala, orientación y estado fueron realmente revisadas.

Complementar con `ux-review` si el defecto afecta el flujo, con `accessibility` si afecta percepción u operación y con `qml-ui-creation` si se autoriza implementar la corrección.
