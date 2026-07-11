---
name: accessibility
description: "Diseñar, implementar o auditar accesibilidad en interfaces QML de Punchi Dock: teclado, foco, semántica accesible, lectores de pantalla, contraste, escalado, tamaño de objetivos y movimiento reducido. Usar cuando una tarea mencione accesibilidad o cuando una modificación visual cambie interacción, foco o comprensión; no sustituye una revisión general de UX."
---

# Accesibilidad de la interfaz

## Procedimiento

1. Identificar controles interactivos, información visual y cambios dinámicos de estado.
2. Verificar orden de tabulación, operación completa por teclado, foco inicial y foco visible.
3. Proporcionar nombre, rol, descripción y estado accesibles cuando el componente no los exponga adecuadamente.
4. Comprobar que iconos, color y animación no sean el único medio de comunicar información.
5. Revisar contraste, escalado, textos largos, objetivos de interacción y reducción de movimiento.
6. Probar estados normal, deshabilitado, error, vacío y actualización dinámica.

## Reglas

- Preferir controles Plasma/Kirigami con semántica incorporada antes que controles personalizados.
- Mantener etiqueta visible y nombre accesible coherentes.
- No capturar teclas globalmente si un control o acción estándar resuelve la interacción.
- Preservar el foco al actualizar modelos; si se elimina el elemento enfocado, moverlo a un destino predecible.
- No declarar compatibilidad con lectores de pantalla sin una prueba real; diferenciar inspección estática y validación runtime.

## Validación

- Recorrer el flujo sin ratón.
- Verificar foco visible y orden lógico en ambas orientaciones del panel.
- Inspeccionar nombres, roles, estados y anuncios dinámicos con herramientas disponibles.
- Probar escalado y preferencia de movimiento reducido cuando el entorno lo permita.
- Documentar barreras restantes y el alcance real de las pruebas.

## Criterios de aceptación

- Toda acción esencial es operable por teclado y tiene semántica comprensible.
- Ningún estado depende exclusivamente de color, icono o animación.
- El foco se mantiene predecible durante cambios dinámicos.
- Los resultados distinguen validación automática, inspección y prueba manual.
