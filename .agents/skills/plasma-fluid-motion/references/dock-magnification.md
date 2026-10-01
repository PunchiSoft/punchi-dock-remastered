# Magnificación continua del dock

Modelo de magnificación por proximidad del cursor para Punchi Dock.

Este comportamiento **ya existe** en el proyecto. Esta referencia describe el
modelo vigente, cómo extenderlo sin romper su continuidad y qué no hacer. No
autoriza a reescribir la implementación.

## Implementación vigente

Estado verificado el 2026-09-18 en `contents/ui/components/DockItem.qml`:

| Elemento | Rol |
|---|---|
| `waveScale` (línea 232) | escala calculada del icono |
| `waveInfluenceRadius` (189) | radio de influencia en píxeles del eje principal |
| `waveItemPitch` (175) | distancia entre centros de iconos |
| `waveSharedScaleDelta` (157) | incremento máximo compartido entre vecinos |
| `wavePrimaryScaleDelta` (159) | incremento extra para el icono bajo el cursor |
| `hoverZoomProgress` (63) | progreso continuo de entrada y salida del zoom |
| `hoverAnimationMode` | `wave`, `single`, `axisZoom`, `selectionPulse`, `none` |
| `selectionPulseScale` (66) | escala del modo de pulso de selección |
| `layoutController.pointerPrimaryAxis` | posición del puntero en el eje principal |
| `mapToItem(dockItemContainer.layoutController, ...)` | centro del icono en el mismo sistema de coordenadas |

El valor se obtiene con una curva coseno continua:

```text
influence = 0.5 * (1 + cos(pi * distance / influenceRadius))
scale     = 1 + sharedDelta * influence * hoverZoomProgress
```

Propiedades del modelo:

- la influencia es continua y vale 1 en el centro del icono;
- decae suavemente hasta 0 en el radio, sin escalón al salir;
- el radio cubre el icono activo y sus vecinos, de modo que el efecto se percibe
  como una onda, no como un icono aislado;
- por encima del 150 % se añade un pico adicional con `wavePrimaryScaleDelta`
  aplicado solo bajo el puntero, de forma continua, para no agrandar vecinos;
- `hoverZoomProgress` aporta la rampa de entrada y salida del conjunto, de modo
  que el efecto completo aparezca y desaparezca sin saltos.

## Alternativa equivalente

`smoothstep` produce un perfil similar y algo más plano en los extremos:

```text
t = clamp(1 - distance / influenceRadius, 0, 1)
smooth = t * t * (3 - 2 * t)
scale = 1 + maximumMagnification * smooth
```

Perfil esperado sobre iconos consecutivos con el cursor sobre el cuarto:

```text
1.00  1.05  1.16  1.34  1.50  1.34  1.16  1.05  1.00
```

Lo inaceptable es un perfil escalonado:

```text
1.00  1.00  1.00  1.50  1.00  1.00
```

## Reglas

- No convertir la magnificación en un estado booleano por icono
  (`hovered ? 1.5 : 1.0`). Rompe la continuidad cuando el cursor atraviesa
  varios iconos seguidos.
- La escala debe ser función de la distancia real entre el cursor y el centro
  del icono, medida en el mismo sistema de coordenadas.
- Normalizar siempre dentro del radio y limitar el resultado; el valor nunca
  debe depender de un cociente sin cotas.
- Al ampliar la magnificación máxima, revisar el radio: un pico alto con radio
  corto se percibe como inestable; el pico debe transferirse de forma continua.
- Mantener el efecto simétrico en paneles horizontales y verticales; el eje
  principal decide la distancia.
- El centro del icono debe recalcularse si cambia el layout, el tamaño o la
  orientación del panel; no guardar posiciones absolutas en caché sin
  invalidarlas.
- Con movimiento reducido, limitar la escala a un cambio sutil del icono activo
  y no aplicar onda a los vecinos.

## Coste

`scale` y el desplazamiento visual son transformaciones: coste **BAJO**. La parte
que puede encarecerse es el cálculo por elemento (`mapToItem` y recomposición de
la onda) cuando el número de iconos crece y el puntero se mueve rápido.

Vigilar:

- recalcular solo los iconos cuyo centro esté dentro del radio;
- no crear objetos por fotograma;
- no invocar `mapToItem` desde un binding que se reevalúe más de lo necesario;
- confirmar que mover el puntero rápido no produce saltos ni picos de CPU.

## Varios docks

Con más de una instancia del plasmoide:

- cada dock calcula su onda a partir de **su** puntero y **su** layout;
- el dock que no contiene el puntero no debe magnificar;
- no compartir una única posición de cursor global como fuente de escala sin
  comprobar en qué dock está.

## Verificación

1. Recorrer el cursor lentamente de un extremo al otro: el perfil debe
   desplazarse sin escalones.
2. Cruzar varios iconos a velocidad alta: sin saltos ni iconos que se queden
   magnificados.
3. Entrar y salir del dock a mitad de la onda: la escala vuelve a 1 sin
   terminar el recorrido anterior.
4. Comprobar con el máximo de magnificación configurado y por encima del 150 %.
5. Comprobar con movimiento reducido.
6. Comprobar panel horizontal y vertical, y con más de un dock visible.
