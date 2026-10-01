# Doctrina de movimiento compartida

Referencia común de `plasma-fluid-motion`, `plasma-liquid-effects`,
`plasma-animation-performance` y `plasma-motion-review`.

No sustituye a `AGENTS.md` ni a la skill `animations`, que conserva la política
del proyecto sobre **qué** animar. Este documento gobierna **cómo** debe
comportarse el movimiento cuando ya está decidido que existe.

## Principios compartidos

### Respuesta inmediata

La interfaz reacciona en el mismo fotograma en que recibe la entrada. Suave no
significa lento: una transición puede durar 240 ms y sentirse inmediata si
empieza sin retardo perceptible.

- No retrasar el inicio para "encadenar" animaciones decorativas.
- No usar una animación de entrada como sustituto de un estado ya calculado.
- Evitar cualquier espera artificial antes del primer cambio visible.

### Duraciones cortas

Los microestados son breves. Rangos de partida, no constantes obligatorias:

| Rol | Rango de partida |
|---|---|
| Press y release | 45–120 ms |
| Hover o foco | 70–160 ms |
| Cambio de icono o control | 100–180 ms |
| Popup o menú | 140–240 ms |
| Cambio de vista o superficie | 180–320 ms |

Las salidas deben ser más rápidas que las entradas. En acciones muy frecuentes,
usar el extremo bajo.

### Elasticidad contenida

Las animaciones físicas llevan amortiguación suficiente. Evitar rebote largo,
efecto gelatina y sobreoscilaciones repetidas. Si un resorte necesita más de una
oscilación visible, se ha elegido mal el amortiguamiento.

### Jerarquía de movimiento

No todo se anima a la vez. Prioridad:

1. elemento directamente manipulado;
2. elementos vecinos afectados por proximidad o por redistribución;
3. contenedor;
4. elementos decorativos.

Un elemento de prioridad inferior no debe adelantarse ni durar más que el
elemento que lo causó.

### Movimiento con propósito

Cada animación responde al menos a una función: feedback, continuidad,
orientación, cambio de estado, jerarquía o relación espacial. Una animación
puramente decorativa que además cuesta renderizado se reconsidera.

### Continuidad

> Un cambio continuo de entrada debe producir un cambio continuo de salida.

Entradas continuas: posición del cursor, su velocidad, distancia entre
elementos, desplazamiento, progreso de un gesto.

No convertir arbitrariamente una entrada continua en estados binarios cuando eso
produzca movimiento discontinuo.

```text
cursor entra:  scale = 1.5      // discontinuo
cursor sale:   scale = 1.0

preferido:     scale = f(distancia(cursor, centroDelIcono))
```

### Continuidad entre control y resultado

En una apertura contextual, identificar el control que la inicia y conservar su
relación espacial con el contenido revelado. Si la superficie nace junto a ese
control, la apertura y el cierre recorren la misma geometría en sentidos
opuestos; los vecinos afectados ceden y recuperan espacio de forma coordinada.
El origen debe seguir siendo reconocible si cambia el tamaño disponible o se
interrumpe la transición. Una expansión en línea puede inspirarse en el modo en
que los menús recientes de macOS se abren desde su control, sin adoptar por ello
su material óptico ni copiar sus métricas.

El reposo queda visualmente tranquilo y la respuesta a la entrada empieza de
inmediato. Una deformación o rebote breve al presionar puede reforzar un control
concreto si no retrasa la acción; no es el comportamiento general de superficies
ni listas. Con ratón o trackpad, mantener la respuesta más contenida que para
una interacción táctil directa cuando existan ambas modalidades.

### Anti-overanimation

No animar todo porque sea posible. En una microinteracción normal, coordinar
entre una y tres propiedades, no más.

Evitar combinar simultáneamente sobre un mismo elemento: `scale`, `rotation`,
`x`/`y`, `opacity`, `radius`, `blur`, `shadow` y `color`, salvo razón visual
clara y coste asumido. Cada propiedad adicional multiplica el trabajo de
composición y suele producir un movimiento embarullado en lugar de uno claro.

## Principios clásicos traducidos a interfaz

Usarlos como criterio, no como teoría cinematográfica.

| Principio | Traducción a interfaz |
|---|---|
| Slow in / slow out | Easing no lineal: la mayoría de los movimientos no empiezan ni terminan a velocidad máxima |
| Timing | Duración proporcional a la distancia y a la frecuencia de uso |
| Spacing | Separar en el tiempo elementos de la misma jerarquía para que se lean |
| Squash and stretch | Deformación sutil de presión, por ejemplo `scaleX: 1.03`, `scaleY: 0.97` |
| Follow-through | El elemento secundario termina después, con amplitud menor |
| Overlapping action | Elementos relacionados se solapan en lugar de encadenarse rígidamente |
| Arcs | El desplazamiento sigue una trayectoria curva cuando el espacio lo permite |
| Anticipation | Solo si prepara una acción cuyo efecto tarda; en UI casi nunca es necesaria |

Las deformaciones deben ser sutiles. No crear efectos caricaturescos.

## Árbol de decisión: animación

```text
¿La propiedad cambia una sola vez con un objetivo definido?
        |
        +-- Sí --> NumberAnimation / Behavior / Transition
        |
        +-- No
             |
             ¿El objetivo cambia continuamente (cursor, distancia, progreso)?
             |
             +-- Sí --> SmoothedAnimation (o cálculo continuo sin animación)
             |
             +-- No
                  |
                  ¿Debe comportarse físicamente?
                  |
                  +-- Sí --> SpringAnimation con amortiguación suficiente
                  |
                  +-- No --> NumberAnimation
```

Reglas derivadas:

- si el objetivo ya se está moviendo, no reiniciar desde velocidad cero;
- si la animación puede invertirse, debe cambiar de dirección desde el estado
  actual, no terminar, no reiniciarse y no saltar;
- si la entrada es continua, evaluar primero reevaluar la salida sin animación
  intermedia y reservar la animación para suavizar el ruido de la entrada.

## Árbol de decisión: efectos

```text
¿Puede lograrse con propiedades QML normales (transformación, opacidad, color,
radio, desplazamiento)?
        |
        +-- Sí --> usar QML normal
        |
        +-- No
             |
             ¿MultiEffect resuelve el caso (blur, sombra, máscara, colorización)?
             |
             +-- Sí --> MultiEffect, reutilizado y no superpuesto
             |
             +-- No
                  |
                  ¿La mejora justifica un ShaderEffect propio?
                  |
                  +-- Sí --> shader con coste medido, fallback y validación
                  |
                  +-- No --> simplificar el diseño
```

## Movimiento reducido

Cuando el entorno o la configuración reduzcan el movimiento:

- reducir duración antes que retirar el cambio de estado;
- eliminar deformaciones y efectos elásticos;
- conservar feedback esencial: cambio de color, borde, opacidad breve o estado
  final inmediato;
- no romper funcionalidad ni estados: el estado final debe alcanzarse siempre;
- no depender del movimiento como único indicador de estado.

Reglas de seguridad:

- una duración derivada del tema que pueda llegar a 0 no garantiza que un
  animador se dispare; llevar la propiedad a su valor final explícitamente;
- no imponer un mínimo fijo a una duración del tema: anula la preferencia del
  usuario;
- el criterio de detección de movimiento reducido debe ser único en el proyecto
  y verificarse en el entorno real; ver `docs/Referencias/referencia-motion-plasma-qt.md`.

## Compatibilidad

Antes de adoptar una API de animación o efecto:

1. comprobar desde qué versión de Qt existe y si está dentro del mínimo
   declarado del proyecto;
2. comprobar los imports necesarios y que el módulo esté instalado;
3. verificar en Fedora y Debian objetivo, en sesión Wayland;
4. definir el fallback cuando la API no exista o no esté soportada por el
   backend de renderizado;
5. documentar la incompatibilidad si no hay fallback razonable.

No introducir dependencias de X11 ni de `Xlib`/`XCB` específico de X11.

## References

- Qt Quick: `Behavior`, `Transition`, `PropertyAnimation`, `NumberAnimation`,
  `SmoothedAnimation`, `SpringAnimation`, `SequentialAnimation`,
  `ParallelAnimation`, Animator types y `Easing`.
- Qt Quick Effects: `MultiEffect` (Qt 6.5+) y `ShaderEffect`.
- Kirigami: `Units::veryShortDuration`, `shortDuration`, `longDuration`,
  `veryLongDuration` y su documentación de uso.
- KDE Plasma: `AnimationDurationFactor` y su aplicación en el estilo Plasma de
  Kirigami.
- Evidencia verificada del proyecto:
  `docs/Referencias/referencia-motion-plasma-qt.md`.
- Referencia conceptual (no de API): principios clásicos de animación, easing,
  curvas Bézier, tweening, squash and stretch.
- Inspiración de comportamiento (no de API ni de material para Plasma):
  [Apple, Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
  describe la apertura en línea desde el control y la continuidad entre formas;
  [Apple, Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
  distingue la respuesta al tacto y al trackpad;
  [Apple, Modernize your AppKit app](https://developer.apple.com/videos/play/wwdc2026/289/)
  limita el rebote de presión a controles interactivos concretos.
