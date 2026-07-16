# Corrección de tareas portables y panel autoocultable

Fecha: 2026-07-16

## Resumen

Se corrigieron dos fallos encontrados durante pruebas reales de Punchi Dock en
un panel de Plasma 6:

- reducción visual de todos los iconos al activar el autoocultado del panel;
- identidad e icono incompletos para aplicaciones portables y ventanas cuyo
  lanzador publica una identidad diferente, con Antigravity y VirtualBox como
  casos de prueba.

## Cambios técnicos

- El grosor del panel se obtiene desde la geometría real del containment en vez
  de inferirse desde el área de pantalla reservada.
- Si la geometría no está disponible, el fallback conserva el tamaño de icono
  configurado y no vuelve a dividirlo por la escala de hover.
- `TaskModelController` compara lanzadores y ventanas mediante `AppId` o
  `LauncherUrlWithoutIcon`, siguiendo `TaskTools::appsMatch()` de
  `kde-sdk/plasma-workspace/libtaskmanager/tasktools.cpp`.
- La agrupación dinámica conserva las dos identidades para poder unir ventanas
  aunque sólo coincidan por una de ellas.
- Los iconos de tareas usan `Qt.DecorationRole` como respaldo cuando
  `SystemDiscovery` no encuentra un `KService`, caso esperado para aplicaciones
  portables.
- `DockItem.iconName` acepta ahora fuentes de icono QML además de nombres de
  icono en texto.

## Validación

- baseline de `qmllint`: `757/744/0/13/0`;
- compilación Fedora completada;
- `ctest`: `5/5`;
- paquete local instalado;
- Plasma Shell reiniciado correctamente;
- journal sin errores propios de Punchi Dock.

Queda pendiente la confirmación visual del usuario con autoocultado,
Antigravity portable y la ventana de ejecución de VirtualBox.
