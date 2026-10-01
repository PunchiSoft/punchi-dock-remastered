---
name: animations
description: "Diseñar, implementar y revisar motion UI en Punchi Dock: microinteracciones, transiciones QML, estados animados, entrada/salida de popups, continuidad espacial, feedback visual, reduccion de movimiento y coste de renderizado. Usar cuando una tarea pida mejorar animaciones, suavidad, fluidez, movimiento, transiciones, hover, focus, press, apertura/cierre, reordenamiento visual o ritmo de interfaz en Plasma 6."
---

# Motion UI para Plasma

## Objetivo

Convertir cambios de estado e interacciones en movimiento breve, claro y barato de renderizar. No agregar animaciones solo por estetica: cada movimiento debe mejorar comprension, feedback, orientacion espacial, continuidad visual o percepcion de respuesta.

## Coordinacion

- Usar `ui-design` antes de implementar cuando falten decisiones de jerarquia, flujo o estados.
- Usar `qml-ui-creation` para escribir o refactorizar QML.
- Usar `accessibility` cuando el movimiento afecte foco, teclado, comprension de estado o reduccion de movimiento.
- Usar `performance` cuando haya muchas instancias, delegates, sombras, blur, shaders, timers o animaciones concurrentes.
- Usar `qml-runtime-load-review` si el cambio toca componentes alcanzables desde `main.qml`, loaders, delegates, popups, imports o configuracion leida al cargar.
- Consultar `kde-sdk/` solo si se introduce o cambia una API, patron o componente KDE/Qt cuya disponibilidad o comportamiento no este claro.

## Diagnostico

Antes de proponer o editar, identificar:

1. Elemento afectado.
2. Evento disparador: hover, focus, press, selection, model update, popup open/close, drag, reorder, loading o error.
3. Estado inicial y final.
4. Objetivo UX concreto.
5. Frecuencia de uso.
6. Orientacion del panel, tamano disponible y escalado.
7. Coste esperado con varias instancias del plasmoide.
8. Alternativa cuando el usuario reduzca o desactive movimiento.

Clasificar la animacion como:

- `necessary`: comunica o preserva una transicion que de otro modo seria confusa.
- `useful`: mejora feedback o continuidad sin ser imprescindible.
- `decorative`: no aporta claridad; recomendar no implementarla salvo peticion explicita.
- `harmful`: retrasa, distrae, reduce accesibilidad o aumenta coste sin beneficio.

## Reglas De Movimiento

- Preferir microinteracciones discretas: el dock es una herramienta frecuente, no una escena permanente.
- Mantener entradas ligeramente mas lentas que salidas.
- Evitar rebote, elasticidad o loops continuos como comportamiento por defecto.
- No animar texto con escala si puede perder nitidez o legibilidad.
- Evitar animar propiedades que provoquen relayout continuo cuando una transformacion visual equivalente resuelva el caso.
- Permitir interrupcion: cambios rapidos de hover, press o modelo no deben dejar estados visuales incoherentes.
- No bloquear acciones mientras una animacion termina.
- Mantener coherencia con Plasma: tema, metricas, orientacion horizontal/vertical, paneles estrechos y multiples instancias.

### Apertura contextual con continuidad espacial

Cuando una baldosa, botón o acción abre una sección, menú o selector próximo,
tratar el control y el resultado como una misma interacción: la superficie se
revela desde el lugar de activación, y los elementos vecinos afectados ceden
espacio de forma legible. El cierre devuelve el espacio y el foco al origen.
Este patrón es apropiado para navegación contextual y secciones expandibles;
decidir su uso por la relación real entre control y contenido, no por semejanza
visual con una plataforma externa. Ver la [doctrina compartida](../plasma-fluid-motion/references/motion-doctrine.md)
para la inspiración de macOS y sus límites.

- El estado de reposo debe ser tranquilo; el primer cambio visible responde sin
  demora al clic, tecla o gesto.
- La forma, posición, recorte y aparición que representan una sola acción deben
  avanzar juntas y poder invertirse desde cualquier punto.
- Una presión puede tener una deformación breve y discreta en controles elegidos;
  no aplicar rebote a todas las superficies ni a cada delegate.
- No perder el foco, la acción disponible ni la relación espacial cuando el
  panel cambia de tamaño o se reduce el movimiento.

## Duraciones Iniciales

Ajustar segun contexto; no tratarlas como constantes obligatorias.

- Feedback inmediato: 80-140 ms.
- Hover o foco: 100-180 ms.
- Botones y controles: 120-200 ms.
- Popup o menu: 160-240 ms.
- Cambio de vista: 200-320 ms.
- Desplazamiento mayor: 250-400 ms.

Usar salidas cerca del extremo rapido. Para acciones muy frecuentes, preferir el rango bajo.

## Easing

- Usar ease-out para elementos que aparecen o llegan a destino.
- Usar ease-in para elementos que salen o pierden presencia.
- Usar ease-in-out para transiciones entre estados equivalentes.
- Usar curvas firmes para controles precisos.
- Usar springs solo cuando haya una razon funcional y amortiguacion suficiente.
- No usar bounce o elastic como valor por defecto.

## QML Y Qt Quick

Preferir herramientas nativas:

- `Behavior` para cambios simples de propiedades ya existentes.
- `State` y `Transition` cuando el componente tenga estados nombrados.
- `NumberAnimation` o `PropertyAnimation` para cambios acotados.
- `ParallelAnimation` y `SequentialAnimation` solo cuando la secuencia sea legible y necesaria.
- `OpacityAnimator`, `ScaleAnimator`, `XAnimator` y `YAnimator` cuando sean adecuados para ejecutarse en el hilo de renderizado.
- `SmoothedAnimation` para seguir valores continuos sin saltos.
- `SpringAnimation` solo con justificacion funcional.

Evitar:

- `Timer` para simular animaciones declarables.
- Animaciones permanentes en delegates visibles sin condicion clara.
- Crear objetos dinamicamente solo para efectos de transicion si un estado o loader existente basta.
- Animar muchas propiedades por delegate sin medir o limitar el alcance.
- `ShaderEffect`, blur o sombras animadas salvo beneficio claro, fallback y validacion visual.

## Movimiento Reducido

Cuando el entorno o configuracion del plasmoide indique movimiento reducido:

- Reemplazar desplazamientos amplios por opacidad breve o cambio instantaneo.
- Mantener feedback esencial sin movimiento espacial complejo.
- Evitar parpadeos, pulsos repetidos y loops.
- No depender de la animacion como unico indicador de estado.

Si no existe una preferencia ya expuesta en el codigo, dejar la implementacion preparada para centralizarla en una propiedad o servicio de configuracion antes de extender el patron.

## Rendimiento

Revisar antes de aprobar:

- Cantidad de animaciones concurrentes y delegates animados.
- Cambios de geometria que disparen relayout.
- Binding loops y bindings costosos.
- Timers permanentes.
- Blur, sombras, shaders y capas offscreen.
- Comportamiento con puntero moviendose rapido.
- Varias instancias del plasmoide y paneles de distinto grosor.

No proponer OpenGL, Vulkan o shaders si Qt Quick estandar resuelve el caso. Si un shader parece necesario, explicar necesidad, beneficio, coste, fallback y validacion en Wayland.

## Validacion

Elegir pruebas proporcionales al riesgo:

1. Revisar sintaxis QML o ejecutar `qmllint` si esta disponible.
2. Probar estados normal, hover, focus, press, selected, disabled, loading y empty cuando apliquen.
3. Revisar panel horizontal y vertical cuando el componente dependa de orientacion.
4. Probar tema claro/oscuro y escalado si hay transformaciones o opacidad sobre texto/iconos.
5. Revisar movimiento reducido o, si no se puede probar, declarar que quedo pendiente.
6. Para popups, loaders, delegates o `main.qml`, aplicar revision de carga runtime antes de cerrar.

## Respuesta Final

Informar solo lo necesario:

- Que se modifico.
- Por que el movimiento elegido aporta claridad o feedback.
- Validaciones ejecutadas y limites reales.
- Riesgos pendientes si los hay.

Usar una explicacion mas detallada solo si el usuario pidio diseno, auditoria o comparacion de alternativas.
