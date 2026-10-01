---
name: ui-ux-motion-design
description: "Coordinar diagnóstico, diseño y revisión de interacciones animadas de Punchi Dock cuando UX y movimiento deban resolverse juntos. Usar para carruseles, navegación repetida, acumulación de clics o teclas, retargeting de animaciones, gestos, hover que compite con selección, transiciones interrumpibles y continuidad entre estados; combinar las skills especializadas del proyecto y no usar para una animación visual aislada ni para una auditoría UX sin movimiento."
---

# Diseño coordinado de UX y movimiento

## Objetivo

Resolver el comportamiento interactivo y su representación animada como un
solo sistema. Evitar que la animación oculte una política de entrada defectuosa
y que una corrección de eventos produzca una interfaz lenta, bloqueada o
inaccesible.

## Coordinación obligatoria

Usar esta skill como orquestadora y activar únicamente las skills especializadas
que correspondan:

- `ux-review` para reconstruir el flujo, la intención y la fricción;
- `animations` para duración, easing, interrupción y coste de renderizado;
- `accessibility` cuando intervengan teclado, foco, lectores de pantalla o
  movimiento reducido;
- `ui-design` cuando falte decidir el comportamiento deseado;
- `qml-ui-creation` al implementar cambios QML;
- `qml-runtime-load-review` si el componente es alcanzable desde `main.qml`, un
  popup, un delegado o una ventana;
- `performance` si existen muchos delegates, efectos, timers o animaciones
  concurrentes;
- `kde-sdk-reference` solo cuando la decisión dependa de una API KDE o Plasma.

No duplicar dentro de esta skill las reglas detalladas de esas skills.

## Procedimiento

1. Recuperar el contexto del repositorio y preservar modificaciones existentes.
2. Identificar el componente, el evento disparador, el estado inicial, el estado
   final y el resultado que espera la persona.
3. Inventariar todas las fuentes que pueden cambiar el mismo estado: ratón,
   rueda, touchpad, teclado, repetición automática, hover, timers, gestos,
   bindings, modelo y señales externas.
   Si un control abre contenido en línea, identificar además el control de
   origen, qué vecinos ceden espacio y dónde debe quedar el foco al abrir y
   cerrar. Comprobar que los controles desplazados fuera del área visible no
   sigan siendo alcanzables por teclado o accesibilidad.
4. Separar la política de interacción de la transición visual:
   - la política decide qué intención se acepta, agrupa o descarta;
   - la transición decide cómo representar el cambio aceptado.
5. Determinar si el síntoma es acumulación de entradas, doble despacho,
   retargeting, wrap involuntario, competencia entre hover y selección, duración
   excesiva o trabajo de renderizado.
6. Proponer el cambio mínimo con comportamiento explícito para ratón, teclado,
   rueda/touchpad y movimiento reducido.
7. Si el usuario pidió solo diagnóstico o prohibió aplicar código, detenerse
   después de presentar evidencia, causa probable, alternativas y prueba capaz
   de distinguirlas.
8. Si la implementación está autorizada, aplicar el ciclo y las validaciones
   exigidas por `AGENTS.md` y por las skills especializadas activadas.

## Navegación repetida y carruseles

Al revisar navegación frecuente:

- comprobar si cada evento cambia inmediatamente el índice aunque la transición
  anterior siga activa;
- comprobar si una nueva selección retargetea la animación hacia un destino cada
  vez más lejano y aumenta la velocidad aparente;
- tratar de forma coherente clic repetido, tecla mantenida, rueda y touchpad;
- distinguir un clic real de repetición automática o de dos manejadores que
  procesan el mismo gesto;
- impedir que el hover seleccione elementos que se desplazan bajo un puntero
  estacionario durante una navegación iniciada por otro control;
- decidir explícitamente si el carrusel debe envolver del último al primero;
- preferir agrupación, limitación breve o avance controlado antes que bloquear la
  interacción durante toda la animación;
- evitar colas largas de pasos que continúen moviendo la interfaz después de que
  la persona dejó de interactuar;
- mantener la respuesta inmediata y hacer que la posición final sea predecible.

## Criterios de decisión

Elegir una política según la intención del control:

- `throttle breve`: apropiado para botones y rueda cuando se necesita conservar
  rapidez sin aceptar ráfagas accidentales;
- `coalescing`: apropiado cuando varias entradas rápidas expresan un único
  destino más reciente;
- `cola acotada`: apropiada cuando cada paso importa, limitando cuánto movimiento
  puede quedar pendiente;
- `interrupción y retargeting`: apropiada cuando el seguimiento continuo es
  deliberado y mantiene velocidad y destino previsibles.

No elegir una duración o un temporizador sin explicar qué conducta de entrada
protege. No usar el final de una animación como único desbloqueo si eso vuelve el
control artificialmente lento.

## Validación

Comprobar, según corresponda:

1. un clic o pulsación produce exactamente un paso;
2. una ráfaga corta termina en una posición predecible;
3. mantener una tecla no provoca aceleración descontrolada;
4. la rueda y el touchpad no generan saltos por deltas acumulados;
5. mover o dejar quieto el puntero no cambia la selección accidentalmente;
6. los extremos respetan la política de wrap definida;
7. cerrar, cambiar de vista o reducir movimiento cancela estado pendiente;
8. foco, semántica accesible y activación por teclado siguen funcionando;
9. una apertura contextual mantiene el contenido cerca del control que la
   inició, incluso si se invierte o cambia el tamaño de la vista;
10. `qmllint` y la revisión de carga runtime aplicable no reportan regresiones.

Separar siempre revisión estática, prueba automatizada y validación manual en
Plasma real. No afirmar que la sensación de movimiento quedó corregida sin una
prueba visual o confirmación del usuario.
