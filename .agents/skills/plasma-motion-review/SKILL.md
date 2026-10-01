---
name: plasma-motion-review
description: "Auditar el movimiento de Punchi Dock sin modificar código: localizar animaciones y efectos, clasificar cada hallazgo con el catálogo MOTION, priorizarlo por riesgo, coste y prioridad, y entregar un informe con archivo, línea, componente, síntoma, causa, clasificación, recomendación, riesgo, coste y prioridad. Usar antes de refactorizar animaciones existentes o cuando se pida revisar fluidez, continuidad, reversibilidad, sincronía, coste o respeto a la velocidad de animación del usuario. No usar para implementar la corrección; para eso, `plasma-fluid-motion`, `plasma-liquid-effects` o `plasma-animation-performance`."
---

# Auditoría de movimiento

## Objetivo

Producir un informe verificable sobre el movimiento existente, ordenado por
prioridad, sin tocar el código.

## Regla principal

Esta skill **no modifica código**. No edita QML, no ajusta duraciones, no
introduce animaciones. Solo lee, comprueba y reporta.

Si el usuario pide además la corrección, entregar primero el informe y aplicar
después las skills de implementación sobre los hallazgos que autorice.

## Coordinación

- `plasma-fluid-motion` para recomendar el mecanismo concreto.
- `plasma-liquid-effects` para el nivel técnico del efecto.
- `plasma-animation-performance` para coste y duraciones del tema.
- `animations` para la política del proyecto sobre qué debe animarse.
- `accessibility` cuando el hallazgo afecte foco, teclado o movimiento reducido.
- `performance` si el hallazgo exige un diagnóstico de rendimiento mayor.
- `visual-review` cuando el problema sea perceptible pero no medible en código.

## Procedimiento

1. Delimitar el alcance: componente, superficie o flujo a auditar.
2. Inventariar animaciones y efectos con su ubicación exacta:

   ```bash
   grep -rn "Behavior on\|Animation {\|Animator {\|Transition {\|ShaderEffect\|MultiEffect" contents/ui/
   ```

3. Inventariar duraciones y su origen: valor propio, duración del tema, piso
   fijo o factor de configuración.
4. En aperturas contextuales, identificar el control de origen, la superficie
   revelada y los vecinos desplazados. Comprobar si comparten progreso, si la
   relación espacial sobrevive a una inversión y si el foco sigue el contenido
   visible. Tratar una preferencia estética como tal; registrar un hallazgo
   solo cuando exista una ruptura observable o un riesgo sustentado.
5. Comprobar el criterio de movimiento reducido usado por cada componente.
6. Clasificar cada hallazgo con el catálogo de
   [references/finding-catalog.md](references/finding-catalog.md).
7. Asignar riesgo, coste y prioridad con criterio explícito.
8. Entregar el informe con el formato obligatorio, ordenado por prioridad.
9. Indicar qué no se pudo verificar sin sesión Plasma real.

## Formato obligatorio por hallazgo

Cada hallazgo incluye, en este orden:

```text
ARCHIVO
LÍNEA / APROXIMACIÓN

COMPONENTE

ANIMACIÓN ACTUAL

SÍNTOMA

CAUSA

CLASIFICACIÓN

RECOMENDACIÓN

RIESGO

COSTE

PRIORIDAD
```

Ejemplo real de referencia:

```text
ARCHIVO
contents/ui/components/DockItem.qml

LÍNEA / APROXIMACIÓN
232-320 (cálculo de waveScale)

COMPONENTE
Magnificación de iconos del dock

ANIMACIÓN ACTUAL
Escala continua por distancia al cursor con curva coseno; el modo y la escala
dependen de hoverAnimationMode y hoverScaleSetting.

SÍNTOMA
Con el modo single o axisZoom, el conjunto de iconos no acompaña al cursor: solo
cambia el icono señalado y los vecinos permanecen inmóviles.

CAUSA
El modo elegido convierte una entrada continua (posición del cursor) en un
objetivo prácticamente binario por icono.

CLASIFICACIÓN
MOTION-04 · hover discreto donde debería existir continuidad.

RECOMENDACIÓN
Mantener el modo wave como comportamiento continuo y reservar single o axisZoom
para preferencias explícitas del usuario; no alterar el modo por defecto sin
decisión del usuario.

RIESGO
Bajo (no rompe funcionalidad; cambia la percepción del movimiento).

COSTE
Bajo (ya existe el cálculo; no añade efectos).

PRIORIDAD
Media.
```

## Criterios de clasificación

**Riesgo** — qué puede romper la corrección:

- Bajo: cambio visual aislado, sin impacto funcional.
- Medio: afecta a interacción, foco o estados compartidos.
- Alto: puede alterar comportamiento, carga o accesibilidad.

**Coste** — trabajo de renderizado añadido o retirado:

- Bajo: transformaciones y opacidad sobre elementos existentes.
- Medio: capas offscreen, blur pequeño o varias propiedades coordinadas.
- Alto: superficies grandes, efectos por delegate, relayout o trabajo por
  fotograma.

**Prioridad** — orden de intervención:

- Alta: el hallazgo rompe continuidad, reversibilidad, accesibilidad o provoca
  trabajo por fotograma.
- Media: degrada la percepción sin romper nada.
- Baja: mejora de coherencia o de mantenimiento.

## Qué no hacer

- No proponer una reescritura del sistema de animaciones sin inventario previo.
- No recomendar cambios de arquitectura como corrección de un hallazgo puntual.
- No marcar como hallazgo una preferencia estética sin impacto observable.
- No afirmar que una animación es fluida o lenta sin haberla observado.
- No incluir hallazgos sin ubicación exacta.

## Salida esperada

- Resumen del alcance auditado y de los archivos revisados.
- Tabla de hallazgos con identificador, ubicación, clasificación y prioridad.
- Cuerpo de cada hallazgo con el formato obligatorio.
- Lista de comprobaciones que requieren sesión Plasma real.
- Riesgos no cubiertos y límites de la auditoría.
