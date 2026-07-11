# Ajuste de animaciones según borde del panel

Fecha: 2026-07-11

## Resumen

Se corrigió el posicionamiento interno del `dockLayout` en `contents/ui/main.qml` para que el espacio extra del panel quede del lado interior de la pantalla según `Plasmoid.location`.

## Motivo

`DockItem.qml` ya desplazaba iconos en la dirección correcta para panel superior, inferior, izquierdo y derecho, pero el layout seguía centrado dentro del alto o ancho ampliado del panel. Eso hacía que algunas animaciones no aprovecharan el margen interior de forma consistente.

## Cambio aplicado

- Se expuso `panelLocation` y banderas `topPanel`, `bottomPanel`, `leftPanel`, `rightPanel`.
- `dockLayout` dejó de usar `anchors.centerIn` y ahora calcula `x` e `y` según el borde del panel.
- Los delegados `DockItem` reutilizan `root.panelLocation` para un comportamiento uniforme entre accesos fijos y ventanas dinámicas.

## Efecto esperado

- En panel superior, las animaciones crecen hacia abajo.
- En panel inferior, las animaciones crecen hacia arriba.
- En panel izquierdo o derecho, las animaciones empujan hacia el interior.
- El ajuste aplica por igual a `wave`, `single` y `paragraph`, porque el margen interno ahora lo resuelve el layout raíz y no solo el delegado.
