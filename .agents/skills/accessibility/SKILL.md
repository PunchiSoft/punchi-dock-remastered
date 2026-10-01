---
name: accessibility
description: "Diseñar, implementar o auditar accesibilidad en interfaces QML de Punchi Dock: navegación 2D por teclado, ciclo de foco, semántica accesible, lectores de pantalla, contraste, escalado, tamaño de objetivos y movimiento reducido. Usar cuando una tarea mencione accesibilidad o cuando una modificación visual cambie interacción, foco, menús, listas o comprensión; no sustituye una revisión general de UX."
---

# Accesibilidad de la interfaz y navegación por teclado

## Procedimiento general

1. Identificar controles interactivos, información visual y cambios dinámicos de estado.
2. Verificar orden de tabulación, operación completa por teclado, foco inicial y foco visible.
3. Proporcionar nombre, rol, descripción y estado accesibles cuando el componente no los exponga adecuadamente.
4. Comprobar que iconos, color y animación no sean el único medio de comunicar información.
5. Revisar contraste, escalado, textos largos, objetivos de interacción y reducción de movimiento.
6. Probar estados normal, deshabilitado, error, vacío y actualización dinámica.

---

## Contrato de navegación espacial 2D y ciclo de foco QML

Este protocolo es obligatorio para todas las vistas de menús, grillas, listas paginadas y vistas por secciones (PunchiMenu FullScreen, PunchiMenu Normal, popups de tareas, carpetas y ventanas):

### 1. Navegación bidimensional en grillas y listas paginadas
- **Navegación horizontal (`←` / `→`)**:
  - `→`: Avanzar un ítem (`index + 1`). Al sobrepasar el límite de la página o sección, transicionar de forma continua al primer ítem de la página o sección siguiente.
  - `←`: Retroceder un ítem (`index - 1`). Al retroceder desde el primer elemento de una página o sección, transicionar al último elemento de la página o sección anterior.
- **Navegación vertical (`↑` / `↓`)**:
  - `↓`: Salto de fila sumando las columnas (`index + columns`). Al sobrepasar la última fila de una página, saltar a la página siguiente conservando exactamente la **misma columna** visual donde el usuario estaba navegando.
  - `↑`: Salto de fila restando las columnas (`index - columns`). Si se está en la primera fila de la grilla y se presiona `↑`, devolver el foco de forma limpia al campo de búsqueda o control superior.
- **Prohibición de reseteo involuntario de selección**:
  - Las funciones auxiliares de cambio o alineación de página (como `goToPage` o `alignCurrentPage`) **nunca deben forzar o resetear la selección** al primer elemento (`firstIndex`) cuando el cambio de página fue disparado por una navegación direccional intencional del usuario.

### 2. Navegación continua en vistas por secciones / categorías
- **Transición entre categorías**:
  - Al presionar `→` en el último ítem de una categoría, saltar automáticamente al primer ítem de la siguiente categoría.
  - Al presionar `←` en el primer ítem de una categoría, saltar al último ítem de la categoría anterior.
  - Al presionar `↓` en la última fila de una categoría, saltar a la primera fila de la siguiente categoría buscando la columna más cercana.
  - Al presionar `↑` en la primera fila de una categoría, saltar a la última fila de la categoría anterior.
- **Auto-scroll vertical reactivo**:
  - Al cambiar de ítem enfocado mediante teclado, la vista con scroll debe posicionar automáticamente el contenedor (`positionViewAtIndex` o ajuste de `contentY`) garantizando que el elemento activo y su encabezado de categoría queden dentro del viewport visible.

### 3. Ciclo de foco entre campos de entrada y grillas
- **Foco inicial predecible**:
  - Cuando una vista abra con foco en el campo de búsqueda (`searchField`), presionar `↓` (o `Tab`) debe transferir inmediatamente el foco a la grilla, inicializando la selección en el primer elemento (`index 0`), no en un valor huérfano (`-1`).
- **Ciclo completo con `Tab` / `Shift+Tab`**:
  - La secuencia de tabulación debe ser cíclica y predecible: `Buscador → Botones de acción/herramientas → Grilla/Secciones de aplicaciones → Controles de pie/sesión → Buscador`.
  - La grilla no debe quedar excluida del orden de tabulación.

### 4. Acciones y menús contextuales
- `Enter` / `Return` / `Space`: Ejecutar o abrir el ítem seleccionado.
- `Menu` / `Shift+F10`: Abrir el menú contextual del ítem actualmente seleccionado en la posición de su delegado.
- `Escape`: Cancelar drag activo, cerrar carpetas abiertas, limpiar búsqueda o cerrar el menú según la jerarquía modal activa.

---

## Reglas generales de accesibilidad

- Preferir controles Plasma/Kirigami con semántica incorporada antes que controles personalizados.
- Mantener etiqueta visible y nombre accesible coherentes.
- Verificar que la etiqueta, descripción accesible y valor visible usen unidades comprensibles y coherentes: `px` para medidas físicas o trazos, `%` para escalas, opacidad, intensidad y proporciones.
- No capturar teclas globalmente si un control o acción estándar resuelve la interacción.
- Preservar el foco al actualizar modelos; si se elimina el elemento enfocado, moverlo a un destino predecible.
- No declarar compatibilidad con lectores de pantalla sin una prueba real; diferenciar inspección estática y validación runtime.

---

## Checklist de validación obligatoria

Antes de dar por completada cualquier modificación o componente visual interactivo:

- [ ] ¿El flujo completo se puede operar únicamente con teclado sin necesidad del ratón?
- [ ] ¿Las flechas `←`, `→`, `↑` y `↓` navegan en 2D sin perder columnas ni descalibrar el índice?
- [ ] ¿El cambio entre páginas o entre secciones/categorías preserva la continuidad del foco?
- [ ] ¿La entrada y salida de foco entre campos de texto (búsqueda) y la grilla es bidireccional y fluida?
- [ ] ¿El foco visual es claramente distinguible en temas claros y oscuros?
- [ ] ¿`Enter`, `Espacio`, `Menú`, `Shift+F10` y `Escape` responden adecuadamente en todos los estados?
- [ ] ¿Se probó la navegación en los tres modos de ordenamiento (Normal, Alfabético y Categorías)?

---

## Criterios de aceptación

- Toda acción esencial es operable por teclado y tiene semántica comprensible.
- Ningún estado depende exclusivamente de color, icono o animación.
- El foco se mantiene predecible durante cambios dinámicos, filtros de búsqueda y transiciones de vista.
- Los resultados distinguen validación automática, inspección y prueba manual en Plasma real.
