---
name: plasma-liquid-effects
description: "Evaluar e implementar material y efectos visuales en Punchi Dock: sensación líquida, vidrio, morphing, cápsulas, fusión de formas, blur, sombras, highlights, transparencia, refracción simulada y profundidad, por niveles de coste (QML barato, QtQuick.Effects/MultiEffect, ShaderEffect). Usar al decidir cómo representar un material o un efecto de acabado en Plasma 6 y Wayland. No usar para movimiento sin material (usar `plasma-fluid-motion`), ni para medir rendimiento global (usar `plasma-animation-performance`), ni para una auditoría de movimiento (usar `plasma-motion-review`)."
---

# Efectos líquidos y material

## Objetivo

Elegir el nivel técnico más bajo que consiga el acabado pedido, con coste
conocido, degradación segura y sin convertir el efecto en el comportamiento por
defecto de todos los elementos.

La referencia al movimiento con el que estos efectos se coordinan es la
[doctrina compartida](../plasma-fluid-motion/references/motion-doctrine.md).

## Coordinación

- `plasma-fluid-motion` para el movimiento del efecto.
- `plasma-animation-performance` antes de aprobar cualquier efecto animado sobre
  superficies grandes o repetidas por delegate.
- `performance` para el diagnóstico de rendimiento del plasmoide completo.
- `accessibility` cuando el efecto afecte contraste, legibilidad o comprensión de
  estado.
- `visual-review` para juzgar el resultado visual una vez implementado.
- `qml-runtime-load-review` si el efecto toca superficies alcanzables desde
  `main.qml`.

## Los tres niveles

Detalle operativo, criterios de admisión y fallbacks en
[references/effect-levels.md](references/effect-levels.md).

### Nivel 1 — líquido simulado, preferido

La sensación de material líquido se consigue con propiedades baratas:
`scale`, `scaleX`, `scaleY`, `opacity`, `radius`, `x`, `y`, `translation`,
`shadow` y `highlight` del tema.

Es el nivel por defecto. Debe justificarse pasar al nivel 2.

### Nivel 2 — efectos Qt Quick

`QtQuick.Effects` y `MultiEffect` para blur, sombra, máscara, colorización y
composición. Disponible desde Qt 6.5; el mínimo declarado del proyecto es Qt 6.6.

Requisitos antes de usarlo:

- el efecto aporta algo que el nivel 1 no consigue;
- no se superponen varios efectos sobre la misma superficie;
- no se aplica a todos los delegates del dock;
- no se animan propiedades que obliguen a recompilar el efecto cada fotograma;
- existe un comportamiento aceptable si el efecto no está disponible.

### Nivel 3 — shaders

`ShaderEffect` solo cuando exista una mejora que no pueda resolverse
razonablemente con QML normal: metaballs, campos de distancia con signo, fusión
entre formas, distorsión, refracción, desplazamiento o morphing de formas.

Antes de introducir un shader, comprobar y reportar:

1. si podía lograrse con QML normal y por qué no basta;
2. coste de renderizado esperado;
3. número de instancias simultáneas;
4. compatibilidad con la versión de Qt objetivo;
5. compatibilidad con Plasma 6;
6. comportamiento en Wayland;
7. comportamiento en GPU integrada;
8. impacto con varias instancias del dock.

Sin respuesta a los ocho puntos, no se introduce.

## Reglas

- Distinguir el movimiento continuo de una superficie de su acabado material:
  la apertura desde un control puede resolverse con geometría QML y un marco
  Plasma sin simular refracción. La inspiración de Liquid Glass no convierte el
  vidrio en requisito del proyecto.
- Si se solicita un material más expresivo, reservarlo para superficies de
  navegación o controles destacados donde refuerce la jerarquía. Evaluar
  contraste, tema claro/oscuro, movimiento reducido y coste antes de aplicar
  una respuesta de luz, sombra o fusión de formas; el reposo debe ser legible.
- Mantener la continuidad entre el control de origen y la superficie revelada
  aun cuando el efecto óptico se desactive. Seguir la
  [doctrina compartida](../plasma-fluid-motion/references/motion-doctrine.md)
  para el patrón inspirado en macOS.
- Un efecto por superficie: no acumular blur, sombra dibujada y borde para el
  mismo acabado.
- Preferir el marco y la sombra del tema Plasma antes que reproducirlos.
- El velo, el recorte y la sombra de la superficie tienen reglas propias en
  `AGENTS.md`; no sustituirlas por aproximaciones visuales.
- No animar la intensidad de un blur sobre una superficie grande sin medir.
- Las sombras y los bordes del tema ya escalan con el tema; no fijar valores
  absolutos en píxeles para el acabado.
- No usar color fijo cuando el efecto deba adaptarse a tema claro u oscuro.
- Todo efecto debe degradar a un estado legible: sin blur, la superficie sigue
  siendo legible y coherente.
- No introducir dependencias de X11 ni de `Xlib`/`XCB` específico de X11.

## Ejemplos

### GOOD — presión con material simulado

```qml
Rectangle {
    radius: Kirigami.Units.cornerRadius
    color: Kirigami.Theme.highlightColor

    scaleX: pressed ? 1.03 : 1.0
    scaleY: pressed ? 0.97 : 1.0

    Behavior on scaleX { NumberAnimation { duration: Kirigami.Units.veryShortDuration } }
    Behavior on scaleY { NumberAnimation { duration: Kirigami.Units.veryShortDuration } }
}
```

### GOOD — una sola sombra del tema

```qml
KSvg.FrameSvgItem {
    imagePath: "widgets/background"
}
```

El borde y la sombra provienen del tema; el plasmoide no dibuja otra sombra
encima.

### GOOD — un único efecto de composición

```qml
import QtQuick.Effects

MultiEffect {
    source: surface
    blurEnabled: true
    blur: 0.4
    blurMax: 24
}
```

### BAD — blur apilados sobre la misma superficie

```qml
MultiEffect { source: card; blurEnabled: true; blur: 0.6 }
MultiEffect { source: card; blurEnabled: true; blur: 0.3 }
```

Duplica el coste y no aporta un acabado distinto perceptible.

### BAD — efecto por delegate

```qml
Repeater {
    model: 40
    delegate: MultiEffect { source: icon; shadowEnabled: true }
}
```

Un efecto por cada icono multiplica el trabajo offscreen por el número de
elementos visibles.

### BAD — shader para una deformación que ya existe

```qml
ShaderEffect {
    // desplazamiento senoidal sobre scale/translation
}
```

Si `scale`, `translation` o una curva de escala consiguen el efecto, el shader
solo añade coste y riesgo.

## Verificación

1. Comprobar el efecto con tema claro y oscuro.
2. Comprobar con escalado fraccionario si el efecto depende de píxeles.
3. Comprobar que la degradación sin el efecto sigue siendo legible.
4. Comprobar el coste con varias instancias del dock y con el panel lleno.
5. Si el efecto se anima, comprobar la fluidez con el puntero en movimiento.
6. Declarar explícitamente qué no se pudo probar.
