---
name: plasma-fluid-motion
description: "Implementar la mecánica de movimiento fluido en QML para Punchi Dock: elección entre NumberAnimation, SmoothedAnimation, SpringAnimation, Behavior, Transition, SequentialAnimation y ParallelAnimation, easing, retargeting, continuidad de velocidad, reversibilidad, interrupción, movimiento continuo ligado al cursor y magnificación del dock. Usar al escribir o corregir una animación concreta de Plasma 6, Qt 6 y Wayland. No usar para decidir qué animar (usar `animations`), para auditar movimiento existente (usar `plasma-motion-review`) ni para medir coste por fotograma (usar `plasma-animation-performance`)."
---

# Movimiento fluido en Qt Quick

## Objetivo

Convertir un cambio de estado o una entrada continua en movimiento continuo,
interrumpible y reversible, usando el sistema de animaciones de Qt Quick en lugar
de lógica imperativa.

Leer [la doctrina compartida](../plasma-fluid-motion/references/motion-doctrine.md)
antes de decidir el tipo de animación. Este archivo no repite sus principios.

## Coordinación

- `animations` decide qué se anima y con qué intención en este proyecto; esta
  skill decide con qué mecanismo.
- `plasma-motion-review` audita primero cuando se refactoriza movimiento
  existente.
- `plasma-animation-performance` revisa el coste cuando la animación afecte a
  delegates, superficies grandes o muchas instancias.
- `plasma-liquid-effects` cuando el efecto sea material, blur, morphing o
  shader.
- `accessibility` cuando el movimiento afecte foco, teclado o comprensión de
  estado, y `qml-ui-creation` para el resto del componente.
- `kde-sdk-reference` cuando se introduzca una API de animación nueva para el
  proyecto.

## Selección del mecanismo

| Situación | Mecanismo |
|---|---|
| Cambio simple de una propiedad existente | `Behavior on <propiedad>` |
| Componente con estados nombrados | `State` + `Transition` |
| Cambio acotado con destino conocido | `NumberAnimation` / `PropertyAnimation` |
| Objetivo que cambia continuamente | `SmoothedAnimation` o cálculo continuo |
| Respuesta física con amortiguación | `SpringAnimation` |
| Varias propiedades del mismo elemento | `ParallelAnimation` |
| Propiedades relacionadas o encadenadas | `ParallelAnimation` / `SequentialAnimation` |
| Animación que debe correr en el hilo de renderizado | `OpacityAnimator`, `ScaleAnimator`, `XAnimator`, `YAnimator` |
| Entrada continua que ya calcula el valor por fotograma | asignación directa, sin animación intermedia |

## Expansión desde el control de origen

Para una sección contextual que se despliega desde una baldosa o botón, animar
un único progreso de apertura y derivar de él la geometría del control, la
superficie revelada y el desplazamiento de sus vecinos. Así las partes no
compiten por duración o easing y el cierre puede retomar el progreso actual.
Conservar el contenido junto al lugar de activación y restaurar el foco al
control al terminar el cierre. Si la ventana o el panel cambia de tamaño,
recalcular los destinos desde su geometría actual en vez de fijar coordenadas
observadas en una captura.

- Usar `Behavior` sobre el progreso cuando hay un cambio simple entre abierto y
  cerrado; usar `State` y `Transition` si existen varios estados nombrados.
- No iniciar animaciones independientes para ancho, posición y opacidad cuando
  todas describen la misma expansión.
- El cambio de tamaño de un layout puede ser necesario para empujar contenido:
  acotarlo a la sección afectada y medir su coste antes de adoptarlo.
- Desactivar el interpolador cuando el movimiento esté reducido y alcanzar de
  inmediato el mismo estado final, incluido el foco.
- Reservar una ligera deformación de presión para controles donde aporte
  feedback; una respuesta elástica no debe gobernar la apertura completa.

## Reglas de implementación

### Continuidad de velocidad

Un elemento que ya se mueve no reinicia su movimiento desde velocidad cero
cuando cambia el objetivo.

- objetivo que cambia de forma continua → evaluar primero `SmoothedAnimation`;
- `SmoothedAnimation` sigue el valor con una velocidad máxima y suaviza los
  cambios de objetivo en lugar de reiniciar la curva;
- para conservar continuidad cuando el objetivo se invierte, revisar
  `reversingMode` en lugar de reconstruir la animación;
- no encadenar `NumberAnimation` nuevas por cada cambio de objetivo: producen
  saltos de velocidad perceptibles.

### Reversibilidad e interrupción

Hover, press, expansión y contracción deben poder invertirse de inmediato, desde
el estado actual:

- el usuario entra y sale rápido → la animación cambia de dirección sin
  terminar, sin reiniciarse y sin saltar;
- no usar `stop()` seguido de `start()` para invertir: reinicia desde el valor
  inicial;
- no usar temporizadores para "dejar terminar" una animación antes de la
  contraria;
- el estado final debe alcanzarse siempre, incluso si la animación se interrumpe
  varias veces;
- cuando el movimiento está desactivado, aplicar el valor final sin animación y
  emitir igualmente la señal de finalización si existe.

### Estados discretos

Para estados claramente definidos (`rest`, `hovered`, `pressed`, `active`,
`hidden`, `expanded`) puede usarse `NumberAnimation` con easing apropiado,
preferiblemente declarado dentro de un `Transition` para que el estado sea la
única fuente de verdad.

### Easing

- `OutQuad`/`OutCubic`: elementos que aparecen, llegan a destino o responden a
  una acción.
- `InQuad`/`InCubic`: elementos que salen o pierden presencia.
- `InOutQuad`/`InOutCubic`: transiciones entre estados equivalentes.
- `OutBack`, `OutElastic`, `OutBounce`: solo con justificación funcional y
  amplitud pequeña; por defecto, evitar.
- `Easing.Linear`: solo cuando el movimiento representa un valor continuo
  (progreso, arrastre, seguimiento de cursor) y no una transición de estado.

### Propiedades preferidas

Animar propiedades que no provoquen relayout:

- `scale`, `x`, `y`, `opacity`, `rotation`, `transform`, `radius` y color;
- el `width`/`height` de un elemento con hijos en layout provoca recálculo de
  posiciones; si el efecto buscado es visual, evaluar recorte o escala;
- si hay que animar el tamaño de un contenedor, mantener estable el layout
  interno y mover el efecto al exterior.

### Sincronización

- `ParallelAnimation` para propiedades que deben percibirse como una sola
  deformación;
- `SequentialAnimation` solo cuando el orden sea perceptible y necesario;
- evitar más de tres propiedades coordinadas por microinteracción; ver
  Anti-overanimation en la doctrina;
- si varias animaciones comparten un mismo disparador, sincronizarlas por el
  mismo estado o señal en lugar de por temporizadores independientes.

### Movimiento continuo ligado al cursor

Cuando la entrada es la posición del puntero, la salida debe ser una función
continua de esa posición. Ver
[el modelo de magnificación del dock](references/dock-magnification.md), que ya
existe en `contents/ui/components/DockItem.qml` y no debe reimplementarse como
`hovered ? 1.5 : 1.0`.

## Duraciones

Usar las duraciones del tema antes que valores propios:

- `Kirigami.Units.veryShortDuration`, `shortDuration`, `longDuration` y
  `veryLongDuration`; su semántica está documentada en
  `kde-sdk/frameworks/kirigami/src/platform/units.h`;
- escalarlas multiplicativamente cuando una animación necesite ser algo más
  larga o más corta que su rol (`Math.round(Kirigami.Units.longDuration * 1.1)`);
- no imponer un mínimo fijo con `Math.max(...)` a una duración del tema: anula la
  preferencia de velocidad del usuario;
- un valor propio solo con razón técnica clara, y documentada junto al código.

La relación entre estas duraciones, la preferencia del usuario y los riesgos
conocidos está verificada en
`docs/Referencias/referencia-motion-plasma-qt.md`.

## Ejemplos

### GOOD — hover con duración del tema y reversión natural

```qml
Rectangle {
    scale: hoverHandler.hovered ? 1.03 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutQuad
        }
    }
}
```

Cambiar el objetivo a mitad de animación la continúa desde el valor actual.

### GOOD — objetivo continuo sin reinicios

```qml
Item {
    property real targetOffset: 0

    x: targetOffset
    Behavior on x {
        SmoothedAnimation {
            velocity: Kirigami.Units.gridUnit * 12
        }
    }
}
```

### GOOD — presión breve con deformación contenida

```qml
Rectangle {
    scaleX: pressed ? 1.03 : 1.0
    scaleY: pressed ? 0.97 : 1.0

    Behavior on scaleX { NumberAnimation { duration: Kirigami.Units.veryShortDuration } }
    Behavior on scaleY { NumberAnimation { duration: Kirigami.Units.veryShortDuration } }
}
```

### BAD — hover lento y lineal

```qml
Behavior on scale {
    NumberAnimation {
        duration: 500
        easing.type: Easing.Linear
    }
}
```

Demasiado lento para un hover y sin aceleración perceptible.

### BAD — reinicio por cada cambio de objetivo

```qml
onPointerMoved: {
    animation.stop()
    animation.from = currentValue
    animation.to = computedTarget
    animation.start()
}
```

Provoca saltos de velocidad y descarta la continuidad que el usuario percibe.

### BAD — entrada continua convertida en binaria

```qml
onPositionChanged: {
    icon.scale = mouseX / width
}
```

Sin radio de influencia, sin normalización y sin límites: produce escalas
arbitrarias, discontinuas y sin relación con la distancia real al icono.

## Verificación

Proporcional al riesgo:

1. `qmllint` sobre los archivos modificados.
2. Recorrer el puntero despacio y rápido sobre el elemento y sus vecinos.
3. Interrumpir a mitad de animación en ambos sentidos.
4. Comprobar el estado final tras interrupciones repetidas.
5. Comprobar que el origen, los vecinos y el contenido mantienen su relación
   espacial al abrir, cerrar, invertir a mitad y cambiar el tamaño disponible.
6. Comprobar con movimiento reducido: estado final alcanzado, sin deformaciones.
7. Comprobar en la orientación y el tamaño de panel reales.
8. Si la animación toca popups, delegates o `main.qml`, revisar la carga en
   runtime antes de cerrar.

## Respuesta final

Informar del mecanismo elegido, por qué mantiene continuidad o reversibilidad,
qué duración del tema se usó y qué quedó pendiente de validación visual.
