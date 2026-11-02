---
name: config-control-choice
description: Elegir y convertir los controles de los paneles de configuración y ajustes de Punchi Dock, con el interruptor (`Controls.Switch`) como forma principal para encender o apagar una capacidad y la casilla (`Controls.CheckBox`) reservada a selección múltiple, estados triples y filas densas de edición. Usar al añadir un ajuste, al convertir un control existente o al revisar una página de configuración; no usar para redactar texto explicativo (usar `notice-copy-approval`) ni para decidir la estructura de una página (usar `ui-design`).
---

# Selección de controles de configuración

## Objetivo

Que cualquier opción de configuración de Punchi Dock se reconozca por su forma
antes de leerse: interruptor para encender o apagar, casilla solo cuando el
ajuste forma parte de una selección múltiple, de un estado triple o de una fila
densa de edición.

Esta skill no redacta textos, no diseña la jerarquía de la página y no sustituye
la revisión de configuración: gobierna qué control representa cada ajuste.

## Regla principal

Un ajuste que **enciende o apaga una capacidad, un detalle de presentación o un
comportamiento** se ofrece con `Controls.Switch`.

El interruptor describe el estado del ajuste, no promete efecto inmediato. Por
eso se usa también en el KCM, que se aplica con «Aplicar» o «Aceptar», tal como
ya ocurre en las páginas más recientes del proyecto.

## Cuándo una casilla sigue siendo correcta

`Controls.CheckBox` se admite únicamente en estos casos:

- **selección múltiple**: varias casillas independientes bajo una etiqueta común
  representan un conjunto y el usuario puede marcar cualquier combinación;
- **estado triple**: el ajuste necesita `checkState` con una tercera posición
  indeterminada;
- **fila densa de edición**: cada elemento de una lista editable tiene su propia
  casilla y decenas de filas conviven en la misma vista, donde un interruptor
  por fila dominaría la lista; el caso vigente es
  `contents/ui/config/ItemActionEditor.qml`.

Fuera de estos tres casos, una casilla que enciende o apaga algo es deuda de
interfaz y debe convertirse.

## Controles de elección y de magnitud

- `Controls.RadioButton` para dos a cinco opciones mutuamente excluyentes que
  conviene ver a la vez.
- `Controls.ComboBox` para listas excluyentes más largas o cuando el valor
  actual importa más que las alternativas.
- `Controls.Slider` y `Controls.SpinBox` para magnitudes; las unidades siguen la
  convención de `AGENTS.md` (`px`, `%`).
- No usar un interruptor para elegir entre dos alternativas reales: un
  interruptor expresa activado o desactivado, no «A frente a B».

## Anatomía obligatoria del interruptor

- `id` y `objectName` estables; algunos contratos leen el archivo por texto, así
  que revisar `tests/` antes de cambiar el tipo.
- `Kirigami.FormData.label` nombra la fila con un sustantivo, igual que el resto
  de la página.
- `text` es la frase de acción que el usuario entiende.
- `Accessible.description` explica el efecto del ajuste.
- El alias `cfg_<clave>` apunta a `.checked`, que `Controls.Switch` expone igual
  que `Controls.CheckBox`, de modo que la clave de configuración y su valor no
  cambian.
- Convertir el tipo **no cambia ningún texto visible**: si el texto debe mejorar,
  se propone aparte.

## Conversión de un control existente

1. Identificar la página y la clave KConfig del control.
2. Comprobar si alguna prueba o contrato cita ese control o su texto.
3. Sustituir `Controls.CheckBox` por `Controls.Switch` conservando `id`,
   `Kirigami.FormData.label`, `text`, `Accessible.description` y el alias.
4. Validar con `qmllint` del perfil, la suite CTest completa y una revisión
   visual en Plasma con tema claro y oscuro.
5. Extraer catálogos solo si cambió algún texto visible.

Convertir una página por cambio. Nunca un reemplazo masivo de todos los
`Controls.CheckBox` del proyecto: cada página necesita su revisión visual y sus
pruebas.

## Estado observado del proyecto (2026-11-02)

Ya usan interruptor para encender o apagar:

- `contents/ui/config/ConfigFolderPopups.qml`
- `contents/ui/config/ConfigMenus.qml`
- `contents/ui/config/components/RecentApplicationsSettings.qml`
- `contents/ui/components/punchimenu/PunchiMenuCompactSettingsView.qml`
- `contents/ui/components/punchimenu/PunchiMenuNormalSettingsView.qml`
- `contents/ui/components/punchimenu/PunchiMenuFullScreenSettingsView.qml`

Siguen usando casilla para encender o apagar y son candidatas a conversión por
página:

- `contents/ui/config/ConfigAspect.qml`
- `contents/ui/config/ConfigWindows.qml`
- `contents/ui/config/ConfigMouse.qml`
- `contents/ui/config/ConfigAudioVisualizer.qml`
- `contents/ui/config/ConfigPopups.qml`
- las opciones «Item text» y «Text shadows» de
  `contents/ui/config/ConfigFolderPopups.qml`

Este listado es evidencia de partida, no un compromiso de conversión.

## Antipatrones

- casilla para encender una sección o una función completa;
- interruptor para una elección entre alternativas;
- cambiar el texto al cambiar el tipo de control;
- convertir varias páginas en el mismo cambio;
- sustituir un interruptor por una casilla «para ahorrar espacio»;
- comprobar solo `qmllint` y dar por validada una conversión sin revisión visual.

## Relación con otras skills

- `ui-design` decide jerarquía y estructura de la página;
- `accessibility` cubre foco, nombres y descripciones accesibles;
- `plasma-config-review` audita el contrato KConfig y el runtime del KCM;
- `notice-copy-approval` redacta y aprueba cualquier nota o texto explicativo;
- `ki18n-localization` se aplica cuando la conversión cambia textos.
