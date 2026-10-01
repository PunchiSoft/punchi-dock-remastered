# Catálogo de hallazgos de movimiento

Categorías que reconoce `plasma-motion-review` y cómo justificar cada una.

## Categorías

Cada categoría incluye síntoma, causa habitual y línea de recomendación. La
recomendación concreta se redacta según el componente auditado.

### MOTION-01 · Cambio instantáneo de propiedad

- Síntoma: el valor salta de un estado a otro sin transición perceptible.
- Causa: asignación directa donde existía un cambio de estado visible.
- Recomendación: `Behavior` o `Transition` con duración del tema, si el cambio
  aporta información.

### MOTION-02 · Easing inadecuado

- Síntoma: el movimiento se siente rígido, mecánico o demasiado elástico.
- Causa: `Easing.Linear` en transiciones de estado, o `OutBack`/`OutElastic` como
  valor por defecto.
- Recomendación: `Out*` al aparecer, `In*` al salir, `InOut*` entre estados
  equivalentes; elástico solo con justificación.

### MOTION-03 · Animación que reinicia desde cero

- Síntoma: al cambiar el objetivo a mitad de animación, el movimiento vuelve al
  inicio o da un salto.
- Causa: `stop()` seguido de `start()`, animación recreada o `from` fijado al
  valor inicial.
- Recomendación: dejar que el binding cambie el objetivo sobre la misma
  animación, o evaluar `SmoothedAnimation`.

### MOTION-04 · Hover discreto donde debería existir continuidad

- Síntoma: el cursor atraviesa varios elementos y cada uno cambia de golpe.
- Causa: `hovered ? x : y` por elemento sobre una entrada continua.
- Recomendación: función continua de la distancia al cursor con radio y
  normalización; ver la magnificación del dock en
  `../plasma-fluid-motion/references/dock-magnification.md`.

### MOTION-05 · Rebote excesivo

- Síntoma: oscilación visible después de llegar al destino, o sensación de
  gelatina.
- Causa: resorte con amortiguación insuficiente o `OutElastic`/`OutBounce`.
- Recomendación: aumentar amortiguación o volver a `NumberAnimation` con ease-out.

### MOTION-06 · Animaciones relacionadas fuera de sincronía

- Síntoma: el borde, el texto y el fondo de un mismo elemento terminan en
  momentos distintos sin intención.
- Causa: animaciones independientes disparadas por el mismo evento con duraciones
  y retardos distintos.
- Recomendación: coordinarlas con `ParallelAnimation` o desde el mismo estado.

### MOTION-07 · Relayout durante la animación

- Síntoma: la animación provoca recálculo de posiciones del resto de elementos y
  pérdida de fluidez.
- Causa: animar `width`, `height`, `Layout.*`, márgenes o tamaños de texto.
- Recomendación: transformar o recortar; mantener el layout estable.

### MOTION-08 · Animación JavaScript innecesaria

- Síntoma: movimiento irregular, dependiente de la carga del sistema.
- Causa: bucles o cálculos por fotograma en JavaScript que replican el sistema de
  animaciones.
- Recomendación: usar animaciones declarativas de Qt Quick.

### MOTION-09 · Efecto GPU costoso

- Síntoma: caída de fluidez con blur, sombras, máscaras o capas offscreen.
- Causa: superficie grande, muchas instancias o propiedades del efecto animadas.
- Recomendación: reducir superficie, reutilizar el efecto o bajarlo de nivel; ver
  `../plasma-liquid-effects/SKILL.md`.

### MOTION-10 · Shader innecesario

- Síntoma: coste alto para un acabado que otro nivel consigue.
- Causa: `ShaderEffect` para algo resoluble con transformaciones, opacidad o
  `MultiEffect`.
- Recomendación: simplificar a nivel 1 o 2, conservando el resultado visual.

### MOTION-11 · Animación que no puede invertirse correctamente

- Síntoma: entrar y salir rápido deja el elemento a medio camino, con parpadeo o
  con el estado visual equivocado.
- Causa: la animación debe terminar antes de invertirse, o se reinicia.
- Recomendación: inversión desde el estado actual, sin detener ni reiniciar.

### MOTION-12 · Duración fija que ignora Plasma

- Síntoma: la animación mantiene el mismo tiempo aunque el usuario cambie la
  velocidad global de animaciones.
- Causa: constante propia en lugar de la duración del tema.
- Recomendación: usar `Kirigami.Units.*` o escalarla multiplicativamente.

### MOTION-13 · Elemento invisible que continúa animándose

- Síntoma: consumo persistente sin nada visible que lo justifique.
- Causa: animación activa con `visible: false`, `opacity: 0` o el componente
  fuera de pantalla.
- Recomendación: detenerla cuando el elemento no sea visible.

### MOTION-14 · Múltiples efectos redundantes

- Síntoma: coste alto sin mejora perceptible.
- Causa: blur apilados, sombra dibujada más sombra del tema, varios efectos sobre
  la misma superficie.
- Recomendación: conservar un solo efecto por objetivo visual.

### MOTION-15 · Movimiento visual sin propósito

- Síntoma: la interfaz se siente inquieta y no comunica nada nuevo.
- Causa: animación decorativa, permanente o repetida sin cambio de estado.
- Recomendación: retirarla o sustituirla por feedback directo.

### MOTION-16 · Criterio de movimiento reducido inconsistente o inefectivo

- Síntoma: con movimiento reducido, unas animaciones se detienen y otras no;
  o ninguna, pese a que la preferencia está activa.
- Causa: convivencia de criterios (`> 0`, `=== 0`, `> 1`) y criterios que nunca
  resultan falsos.
- Recomendación: un único criterio por componente, verificable en el entorno real;
  ver `docs/Referencias/referencia-motion-plasma-qt.md`.

### MOTION-17 · Mínimo fijo que anula la duración del tema

- Síntoma: la animación permanece igual de lenta con la velocidad global al
  mínimo.
- Causa: `Math.max(<valor fijo>, Kirigami.Units.<duración>)`.
- Recomendación: usar la duración del tema y escalarla; si se necesita un mínimo,
  justificarlo y comprobar que no anula la preferencia.

### MOTION-18 · Duración 0 en un animador que puede no dispararse

- Síntoma: la propiedad se queda en su valor inicial o intermedio cuando la
  velocidad de animación está al mínimo.
- Causa: duración derivada del tema que puede llegar a 0; los animadores con
  duración 0 no se disparan de forma fiable.
- Recomendación: llevar la propiedad a su valor final de forma explícita y
  aplicar un mínimo de 1 ms.

### MOTION-19 · Se pierde la relación entre control y contenido

- Síntoma: una sección o menú aparece lejos de su control, los vecinos se
  mueven con otro ritmo, o el cierre deja foco en contenido oculto.
- Causa: geometría independiente del origen, varias animaciones sin progreso
  compartido, o estado visual separado del estado de interacción.
- Recomendación: conservar el origen espacial, coordinar las propiedades de la
  misma expansión y sincronizar foco y alcance con el contenido visible. No
  aplicar esta categoría a superficies cuya presentación independiente sea una
  decisión deliberada de diseño.

## Prioridad sugerida

| Clasificación | Prioridad por defecto |
|---|---|
| MOTION-08, MOTION-11, MOTION-16, MOTION-18 | Alta |
| MOTION-03, MOTION-04, MOTION-07, MOTION-09, MOTION-17, MOTION-19 | Alta o media según componente |
| MOTION-01, MOTION-02, MOTION-05, MOTION-06, MOTION-12, MOTION-13 | Media |
| MOTION-10, MOTION-14, MOTION-15 | Media o baja según impacto |

La prioridad final depende de la frecuencia de uso del componente: un elemento
que se usa a diario pesa más que uno excepcional.

## Límites de la auditoría

- Sin sesión Plasma real, no se puede afirmar fluidez ni latencia percibida.
- La medición de GPU no forma parte de esta skill; si hace falta, escalar a
  `performance`.
- Un hallazgo sin ubicación exacta no se incluye.
