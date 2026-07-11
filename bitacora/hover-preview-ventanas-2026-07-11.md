# Hover preview de ventanas

Fecha: 2026-07-11

## Resumen

Se pulió la base de miniaturas de ventanas para que el popup de previsualización pueda abrirse al pasar el mouse sobre iconos con ventanas activas, en lugar de depender solo del click.

## Cambios

- `DockItem.qml` ahora expone señales `hoverEntered` y `hoverExited`, además de una propiedad pública `containsMouse`.
- `main.qml` añade timers de apertura/cierre para previews hover, de modo que el popup no aparezca de forma instantánea ni se cierre de golpe al cruzar del icono a la tarjeta.
- `taskWindowsForRows()` deja de forzar conversión textual temprana de `WinIdList`; el `uuid` de ventana se pasa más directo al `ScreencastingRequest`.
- `TaskWindowsPopup.qml` expone `containsMouse` para ayudar a mantener abierto el popup mientras el cursor entra a la miniatura.

## Efecto esperado

- Hover sobre un icono con ventanas abiertas: aparece un popup de preview tras un pequeño retraso.
- Al salir del icono, el popup tiene un margen corto antes de cerrarse, suficiente para entrar con el cursor.
- Si la miniatura viva no se puede crear, el popup conserva la estructura y muestra el icono como fallback.
