---
name: qml-ui-creation
description: Crear, modificar o refactorizar componentes visuales QML de Punchi Dock para Plasma 6, incluidos layouts, delegados, estados, interacciones y animaciones. Usar al implementar UI; complementar con `ui-design` cuando falten decisiones de diseño y con `accessibility` cuando cambien controles, foco o semántica.
---

# Implementación de interfaz QML

## Procedimiento

1. Leer `AGENTS.md`, el QML afectado y sus consumidores.
2. Identificar propiedades de entrada, señales de salida, estados y restricciones de tamaño/orientación.
3. Consultar ejemplos equivalentes en `kde-sdk/plasma-workspace/`, `kde-sdk/frameworks/plasma-framework/` o `kde-sdk/frameworks/kirigami/` si se introduce una API o patrón KDE.
4. Implementar el cambio más pequeño con bindings declarativos y componentes Plasma/Kirigami apropiados.
5. Extraer un componente solo cuando tenga responsabilidad o reutilización clara.
6. Mantener lógica de negocio, procesos y acceso al sistema fuera de la vista.

## Reglas

- Usar layouts y tamaños implícitos; evitar posicionamiento absoluto salvo necesidad demostrable.
- Usar métricas, colores, tipografía e iconos del tema; no asumir nombres de API sin verificarlos en el SDK objetivo.
- Exponer una interfaz pequeña de propiedades, señales y funciones; no depender de `id` internos desde el exterior.
- Diseñar estados de foco, hover, selección, deshabilitado, vacío y error cuando apliquen.
- Evitar bindings circulares, temporizadores continuos y animaciones que mantengan trabajo permanente.
- Mantener textos visibles traducibles y operación por teclado.

## Validación

1. Ejecutar `qmllint` u otra validación QML disponible sobre los archivos modificados.
2. Probar en Plasma o `plasmawindowed` cuando el cambio visual lo justifique.
3. Revisar orientación horizontal/vertical, tamaños extremos, temas y escalado aplicables.
4. Declarar con precisión qué se validó estática y visualmente.

## Criterios de aceptación

- El QML parsea sin errores detectados y no añade advertencias conocidas sin justificar.
- La vista representa estado y emite intención sin asumir lógica de negocio.
- El componente responde a tamaño, tema, teclado y estados relevantes.
