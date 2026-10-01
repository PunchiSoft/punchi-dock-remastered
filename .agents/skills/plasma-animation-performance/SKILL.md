---
name: plasma-animation-performance
description: "Evitar que las mejoras visuales reduzcan la fluidez real de Punchi Dock: reglas por fotograma en Qt Quick, clasificación de coste BAJO/MEDIO/ALTO, prohibición de motores de animación con Timer o JavaScript, coste de delegates, blur, sombras, shaders y modelos de tareas, integración con las duraciones de Plasma y con la preferencia de velocidad de animación del usuario. Usar cuando una modificación visual pueda alterar fluidez, coste por fotograma o consumo con varias instancias del dock. No usar para el diagnóstico global del plasmoide (usar `performance`) ni para decidir el mecanismo de una animación (usar `plasma-fluid-motion`)."
---

# Rendimiento de animaciones

## Objetivo

Que la mejora visual no degrade la fluidez percibida. Una animación que no puede
mantener su ritmo con el panel lleno, varias instancias y el puntero en
movimiento es una animación mal dimensionada.

La doctrina común de movimiento está en
[la referencia compartida](../plasma-fluid-motion/references/motion-doctrine.md).

## Coordinación

- `performance` para el diagnóstico general del plasmoide.
- `plasma-fluid-motion` para el mecanismo de la animación.
- `plasma-liquid-effects` para el nivel técnico del efecto.
- `testing` para decidir qué evidencia sostiene la afirmación de fluidez.
- `qmllint-debt-cycle` si la corrección toca deuda estática de QML.

## Reglas por fotograma

Preferir, en este orden:

1. `transform` (`scale`, `x`, `y`, `rotation`, `translation`);
2. `opacity`;
3. color, radio y borde;
4. tamaño de un elemento sin hijos en layout.

Animar `width`, `height`, `implicitWidth`, `Layout.*`, tamaños de texto o
márgenes provoca relayout y repintado en cascada.

En una expansión en línea, el cambio de altura puede ser indispensable para
ceder espacio al contenido. Medir el área que se relayouta y mantener estable
el resto de la superficie; derivar las propiedades visuales relacionadas de un
solo progreso no elimina por sí mismo el coste del layout. Una deformación
breve de presión sobre un control existente cuesta menos que añadir un efecto
óptico por delegate.

## Prohibiciones

No usar como motor de animación:

- `Timer` repitiéndose para desplazar propiedades;
- bucles de JavaScript por fotograma;
- polling de alta frecuencia para simular interpolación;
- JavaScript calculando interpolación donde Qt Quick ya tiene animaciones.

```qml
// BAD: motor manual, sin sincronía con el fotograma
Timer {
    interval: 16
    repeat: true
    onTriggered: item.x += 2
}
```

```qml
// GOOD: el sistema de animaciones controla el tiempo
NumberAnimation on x {
    to: target
    duration: Kirigami.Units.shortDuration
    easing.type: Easing.OutCubic
}
```

No crear ni destruir durante una animación:

- delegates recreados por cambios de modelo o de `key`;
- modelos reconstruidos en cada fotograma;
- jerarquías QML reemplazadas por un `Loader` que alterna;
- componentes creados dinámicamente para un efecto que un estado existente
  resuelve.

## Coste del plasmoide

Punchi Dock puede tener simultáneamente: varias instancias del dock, muchos
delegates, iconos, modelo de ventanas, previsualizaciones, PipeWire, miniaturas,
blur, sombras, espectro de audio, MPRIS, calendario, papelera, popups,
animaciones, polling y modelos de tareas.

Antes de introducir una animación, clasificar su coste y explicarlo en una frase.
La matriz completa y los criterios están en
[references/cost-classification.md](references/cost-classification.md).

| Cambio | Coste |
|---|---|
| Modificar `scale` de un icono existente | BAJO |
| Modificar `opacity` de una superficie pequeña | BAJO |
| Desplazar una superficie pequeña con `x`/`y` | BAJO |
| Animación de popup con escala y opacidad | MEDIO |
| Blur animado sobre una superficie grande | MEDIO/ALTO |
| Sombra animada sobre muchos delegates | ALTO |
| Shader independiente por icono | ALTO |
| Recorte o máscara recalculada por fotograma | ALTO |
| Animación que cambia el tamaño de un layout | ALTO |

Una animación MEDIA o ALTA debe justificar por qué no puede ser BAJA.

## Duraciones y preferencia del usuario

- Usar las duraciones del tema antes que valores propios.
- No imponer mínimos fijos a una duración del tema: anula la preferencia de
  velocidad de animación del usuario.
- No fijar todas las animaciones en el mismo valor si el tema ya expone el rol
  correspondiente.
- Un valor propio se admite con razón técnica explícita junto al código.
- El contrato verificado de estas duraciones, sus riesgos y la forma de
  comprobarlo en el entorno están en
  `docs/Referencias/referencia-motion-plasma-qt.md`.

## Movimiento reducido

- Reducir duración antes que retirar el cambio de estado.
- Eliminar deformaciones, efectos elásticos y desplazamientos amplios.
- Mantener feedback básico y el estado final siempre alcanzable.
- No depender del movimiento para comprender el estado.
- Un componente que declara `motionEnabled` debe respetarlo en **todas** sus
  animaciones, no solo en algunas.

## Ejemplos

### GOOD — transformación sobre un icono existente

```qml
scale: hovered ? 1.05 : 1.0
Behavior on scale { NumberAnimation { duration: Kirigami.Units.shortDuration } }
```

### GOOD — movimiento reducido que conserva el estado

```qml
opacity: root.motionEnabled ? 1.0 : 1.0
transform: Translate { y: root.motionEnabled ? offset : 0 }
```

El estado final es idéntico; solo desaparece el desplazamiento.

### BAD — piso sobre una duración del tema

```qml
duration: Math.max(140, Kirigami.Units.shortDuration)
```

Cuando el usuario reduce o desactiva las animaciones, la duración del tema baja y
el piso la devuelve a 140 ms: la preferencia se ignora.

### BAD — sombra y blur animados en cada delegate

```qml
Repeater {
    model: tasksModel
    delegate: Item {
        MultiEffect { source: icon; blurEnabled: true; blur: hovered ? 0.8 : 0.0 }
    }
}
```

El coste crece con el número de tareas y la animación recompone el efecto por
fotograma.

### BAD — relayout animado

```qml
Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
```

Recalcula la posición del resto de elementos en cada fotograma de la animación.

## Verificación

1. Medir con el panel lleno de iconos y con varias instancias del dock.
2. Mover el puntero rápido durante la animación, no solo observarla en reposo.
3. Comprobar animaciones concurrentes, no una sola aislada.
4. Comprobar con el máximo de elementos del modelo de tareas.
5. Comprobar con movimiento reducido.
6. Declarar el coste esperado y qué no se pudo medir.
7. En aperturas desde un control, comparar la fluidez durante la expansión, la
   inversión a mitad, el cambio de tamaño y la coincidencia con otras
   animaciones.

No declarar fluidez sin haberla observado en una sesión Plasma real.
