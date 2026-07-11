---
name: ui-design
description: Diseñar o rediseñar interfaces, componentes, jerarquía visual y estados de interacción para Punchi Dock antes de implementarlos. Usar al definir distribución, densidad, navegación, apariencia nativa de KDE o especificaciones visuales; no usar para una auditoría de una interfaz ya terminada ni para escribir QML sin decisiones de diseño.
---

# Diseño de interfaz para Plasma

## Objetivo

Convertir una necesidad funcional en una especificación visual clara, adaptable y coherente con Plasma. Priorizar integración nativa, legibilidad y familiaridad sobre una estética llamativa.

## Entradas

1. Inspeccionar la interfaz y componentes existentes en `contents/ui/`.
2. Revisar configuraciones, estados y restricciones reales del plasmoide.
3. Consultar componentes equivalentes en `kde-sdk/plasma-workspace/` y Kirigami en `kde-sdk/frameworks/kirigami/` cuando la decisión dependa de un patrón KDE.
4. Consultar evidencia visual disponible en `docs/revisiones/`.

## Procedimiento

1. Definir el objetivo del usuario y la acción principal de la vista.
2. Enumerar estados: normal, hover, foco, presionado, seleccionado, deshabilitado, vacío, carga y error, según corresponda.
3. Establecer jerarquía: contenido principal, controles secundarios y detalles opcionales.
4. Diseñar primero el flujo y la distribución; después tipografía, color, iconos y movimiento.
5. Especificar comportamiento para panel horizontal y vertical, tamaños mínimos, escalado y textos largos.
6. Reutilizar componentes, métricas, colores e iconos del tema. Justificar cualquier excepción.
7. Entregar una especificación implementable: estructura, propiedades, estados, interacciones y criterios de aceptación.

## Reglas de diseño

- Evitar dimensiones y colores fijos cuando Plasma proporcione métricas o colores semánticos.
- Mantener una acción primaria reconocible y reducir controles simultáneos.
- No depender solo del color para comunicar estado.
- Reservar animaciones para explicar cambios, con duración breve y alternativa de movimiento reducido.
- Diseñar navegación por teclado, foco visible y nombres accesibles desde el inicio.
- No introducir patrones propios si Plasma o Kirigami ya ofrecen uno equivalente.

## Validación

- Comprobar todos los estados y orientaciones aplicables.
- Comprobar tema claro/oscuro, escalado y contenido traducido largo.
- Verificar que la propuesta puede implementarse con componentes disponibles en el objetivo Plasma declarado.
- Separar hallazgos confirmados de preferencias estéticas.

## Relación con otras skills

- Usar `qml-ui-creation` para implementar la especificación.
- Usar `visual-review` para revisar fidelidad, ritmo y consistencia después de implementarla.
- Usar `ux-review` para evaluar el flujo y la facilidad de uso.
- Usar `accessibility` para una auditoría especializada.

## Criterios de aceptación

- La propuesta explica qué problema resuelve y cómo responde en sus estados relevantes.
- Las decisiones son compatibles con Plasma, el tema y la arquitectura existente.
- La especificación permite implementar sin inventar decisiones visuales importantes durante la codificación.
