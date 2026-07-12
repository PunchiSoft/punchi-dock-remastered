# Revisión del plasmoide

Fecha: 2026-07-11

## Contexto

Esta revisión recoge observaciones realizadas durante pruebas reales del plasmoide en Plasma, complementadas con ajustes implementados en la misma jornada.

El objetivo de estas notas es dejar constancia de:

- problemas detectados en runtime;
- mejoras ya resueltas;
- puntos que aún conviene revisar en próximas sesiones.

## Primera revisión

### 1. Geometría base del plasmoide en panel

El plasmoide no gestionaba correctamente su geometría base al acoplarse a un panel.

Observación:

- el espacio de dibujo o reserva que Plasma le asignaba se comportaba como un cuadro mínimo, cercano al tamaño de un solo ítem del dock;
- ese tamaño no representaba el ancho real del dock cuando había varios ítems;
- la altura tampoco reflejaba adecuadamente el tamaño configurado de iconos ni la composición visual completa del dock.

Impacto:

- el dock podía verse desalineado dentro del panel;
- el marco de edición de Plasma no coincidía con la superficie visual real del plasmoide.

### 2. Estado de la papelera

La actualización del estado de la papelera era lenta y no parecía automática.

Observación:

- la ruta anterior dependía de sondeo periódico y shell;
- el cambio visual entre papelera vacía y con contenido no era inmediato.

Conclusión:

- este comportamiento debía migrarse a una integración más nativa, tomando como referencia el comportamiento del ecosistema Plasma/KIO.

### 3. Hover no deseado en calendario/reloj

El ítem de calendario/reloj reaccionaba al `hover` como si fuera un lanzador más del dock.

Observación:

- activaba la ola de zoom;
- recibía tratamiento visual de ítem interactivo tipo aplicación.

Criterio esperado:

- su interacción principal debía ser por clic;
- no debía disparar una animación de `hover` equivalente a la de aplicaciones o carpetas.

## Segunda revisión

### Avances ya observados

Durante esta sesión se confirmaron mejoras importantes en el comportamiento del plasmoide:

- la ejecución de aplicaciones, apertura de carpetas y papelera avanzó hacia rutas más nativas;
- en varios casos ya se aprecia la animación visual de lanzamiento propia de KDE/Plasma;
- el `bounding box` del plasmoide en modo edición mejoró respecto al estado anterior y quedó funcional, aunque aún conviene seguir afinando su correspondencia exacta con la cápsula visual completa del dock.

### 1. Cierre de popups

Los popups del dock no deberían depender únicamente de un botón de cierre manual.

Comportamiento esperado:

- deben cerrarse al hacer clic fuera de ellos;
- también deberían cerrarse al abrir otro popup incompatible o al cambiar el foco hacia otra acción del entorno.

### 2. Dirección y anclaje de popups

El dock debe respetar mejor la orientación real del panel al mostrar menús y popups.

Observación:

- cuando el plasmoide está en horizontal o vertical, los popups deben nacer desde el ítem correcto;
- además deben aparecer en una dirección coherente con la ubicación real del panel en pantalla.

Criterio esperado:

- cada popup debe quedar anclado al ítem que lo invoca;
- su orientación debe seguir la ubicación del panel (`top`, `bottom`, `left`, `right`).

### 3. Popup de notas

El ítem de tipo nota requería una implementación específica de popup en runtime.

Comportamiento esperado:

- apertura mediante clic izquierdo sobre el ítem;
- popup flotante de tamaño medio;
- límite máximo de 2000 caracteres;
- apariencia adaptada al tema activo de Plasma;
- colores, fondo, tipografía y legibilidad coherentes con el tema;
- acciones visibles para limpiar y cerrar.

Resultado de la sesión:

- el popup de nota quedó implementado y funcional;
- el problema principal no estaba en la creación del ítem `note`, sino en el ciclo de vida del popup y en el guardado durante la escritura.

### 4. Confirmación para vaciar papelera

La acción de vaciar la papelera no debería ejecutarse sin confirmación previa.

Comportamiento esperado:

- mostrar un popup o diálogo breve antes de vaciarla;
- respetar colores, contraste y estilo del tema Plasma activo;
- ofrecer una decisión clara entre confirmar y cancelar.

Ejemplo funcional esperado:

- “¿Desea vaciar la papelera?”
- acciones: `Sí` y `Cancelar`

## Estado al cierre de la sesión

### Resuelto o muy avanzado

- mejora de geometría base del dock;
- papelera con integración más nativa;
- calendario sin `hover` tipo launcher;
- popups runtime con mejor infraestructura de apertura/cierre;
- popup de nota implementado y funcional;
- lanzamiento más nativo de varias aplicaciones.

### Pendiente recomendado

- seguir afinando el tamaño reportado del plasmoide en modo edición para que coincida con total precisión con la cápsula visual completa del dock;
- seguir observando el comportamiento de popups en panel, especialmente en orientaciones menos comunes;
- validar en más casos el lanzamiento nativo de aplicaciones y Flatpak.

## Cierre documental 2026-07-12

Estado: cerrada.

- esta revision conserva el diagnostico y las recomendaciones de la primera jornada;
- el trabajo posterior y el cierre de las fases de ventanas continuaron en `revision_11-07-26-2.md`;
- las recomendaciones de observacion que no tienen un defecto reproducible confirmado no se trasladan automaticamente como pendientes a la nueva revision.
