# Clasificación de coste, duraciones y contrato de Plasma

Detalle operativo de `plasma-animation-performance`.

## Matriz de coste

| Clase | Qué implica | Ejemplos en Punchi Dock |
|---|---|---|
| BAJO | Solo transformación o composición sobre elementos ya existentes; sin relayout, sin capas nuevas | `scale` de un icono, `opacity` de una tarjeta, `x`/`y` de una superficie pequeña |
| MEDIO | Capa offscreen, blur pequeño, pocas instancias, o varias propiedades coordinadas | popup con escala y opacidad; blur de un menú; resaltado con borde y escala |
| ALTO | Superficie grande con blur, sombra o máscara; efecto por delegate; relayout animado; shader por elemento; trabajo por fotograma en JavaScript | blur sobre el dock completo; sombra animada en cada icono; `Layout.preferredWidth` animado |

Regla de decisión: toda animación MEDIA o ALTA debe explicar por qué no puede
reducirse a BAJA. Si no hay explicación, no se aprueba.

## Consumidores simultáneos del dock

El coste de una animación no se juzga en aislamiento. Pueden coexistir:

- varias instancias del plasmoide en pantallas distintas;
- muchos delegates (iconos, tareas, favoritos, carpetas);
- modelo de ventanas con actualizaciones frecuentes;
- previsualizaciones y miniaturas;
- PipeWire y espectro de audio;
- blur, sombras y superficies temáticas;
- MPRIS con metadatos cambiantes;
- calendario, papelera y popups;
- polling de estado y timers de mantenimiento;
- animaciones de hover, magnificación, apertura y cierre.

Una animación BAJO repetida por delegate deja de ser BAJO.

## Prohibiciones operativas

| Práctica | Por qué se prohíbe |
|---|---|
| `Timer` como motor de animación | No está sincronizado con el fotograma; trabajo variable y saltos |
| Bucle JavaScript por fotograma | Bloquea el hilo de la interfaz y no aprovecha el sistema de animaciones |
| Recrear delegates durante la animación | Destruye y recrea objetos y estados; produce saltos |
| Reconstruir modelos por fotograma | Coste de notificación y de binding desproporcionado |
| Alternar `Loader` para un efecto | Recarga componentes donde un estado bastaba |
| Animar `Layout.*` o `width`/`height` | Relayout en cascada |
| Blur apilados | Coste duplicado sin acabado distinto |
| Efecto o shader por delegate | Multiplica el trabajo por el número de elementos |

## Duraciones de Plasma: contrato verificado

Evidencia en `docs/Referencias/referencia-motion-plasma-qt.md`.

Resumen:

- `Kirigami.Units` expone `veryShortDuration`, `shortDuration`, `longDuration` y
  `veryLongDuration`;
- el estilo Plasma de Kirigami deriva los cuatro valores de `plasmarc [Units]
  longDuration` (200 ms por defecto) multiplicado por `[KDE]
  AnimationDurationFactor` de `kdeglobals`;
- el resultado se limita a un mínimo de 1 ms porque los animadores con duración 0
  no se disparan de forma fiable;
- `shortDuration` y `veryShortDuration` se obtienen por división entera, de modo
  que con un factor muy bajo pueden llegar a 0.

Consecuencias prácticas:

1. multiplicar la duración del tema para ajustarla al rol, nunca sustituirla por
   una constante;
2. no aplicar `Math.max(...)` con un valor fijo sobre una duración del tema;
3. si una duración puede ser 0, llevar la propiedad a su valor final de forma
   explícita en lugar de confiar en que el animador se dispare;
4. no asumir que la preferencia del usuario está aplicada sin verificarlo en el
   entorno: la implementación que la aplica existe en el estilo Plasma de
   Kirigami, y un plugin de plataforma genérico puede no incluirla;
5. comprobar en Fedora y Debian objetivo antes de apoyar el criterio de
   movimiento reducido en el valor de una duración del tema.

## Criterio de movimiento reducido

El proyecto usa hoy más de un criterio (`Kirigami.Units.longDuration > 0`,
`longDuration === 0` y `longDuration > 1`). Al tocar movimiento:

- usar un único criterio por componente y documentarlo;
- preferir una propiedad explícita del componente (`motionEnabled`) o de
  configuración cuando exista;
- verificar que el criterio realmente cambia con la preferencia del usuario; un
  criterio que nunca es falso desactiva la protección sin que se note.

## Cómo comprobar

1. Panel lleno de iconos y varias instancias del dock.
2. Puntero moviéndose rápido durante la animación.
3. Animaciones concurrentes reales, no una aislada.
4. Modelo de tareas con el máximo de elementos.
5. Movimiento reducido activado.
6. Registrar el coste esperado y lo que no se pudo medir.

Lint, pruebas y carga correcta no demuestran fluidez: hace falta observación en
una sesión Plasma real.
