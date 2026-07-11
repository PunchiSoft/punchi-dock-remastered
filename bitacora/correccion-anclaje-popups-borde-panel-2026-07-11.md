# Corrección de anclaje de popups según borde del panel

Fecha: 2026-07-11

## Resumen

Se corrigió la ubicación de los `PlasmaCore.Dialog` del dock para que, cuando el plasmoide esté anclado a un borde del panel, los popups se abran hacia el interior visible de la pantalla y no hacia afuera del borde.

## Cambio aplicado

- `contents/ui/main.qml` añade `popupDialogLocation`.
- Si el dock está en panel, `popupDialogLocation` usa el borde opuesto a `Plasmoid.location`.
- Se actualizó la ubicación de:
  - `folderPopupDialog`
  - `calendarPopupDialog`
  - `trashMenuDialog`
  - `notePopupDialog`
  - `taskPreviewDialog`
  - `taskWindowsDialog`
  - `trashConfirmDialog`

## Motivo

Cuando el dock estaba en el borde inferior, varios popups intentaban abrirse también hacia abajo porque heredaban `location: Plasmoid.location`. Eso podía dejar la interfaz fuera del área visible y afectar especialmente la percepción de los previews hover.
