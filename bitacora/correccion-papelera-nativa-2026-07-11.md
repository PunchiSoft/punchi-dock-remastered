# Bitácora: corrección nativa de apertura y vaciado de papelera

Fecha: 2026-07-11

## Trabajo realizado

- Se sustituyó en [contents/ui/main.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/main.qml:298) la ruta shell del menú de papelera por llamadas nativas al adaptador `SystemDiscovery`.
- Se amplió [src/systemdiscovery.h](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/src/systemdiscovery.h:21) y [src/systemdiscovery.cpp](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/src/systemdiscovery.cpp:196) con:
  - `openTrash()`, apoyado en `KIO::OpenUrlJob` sobre `trash:/`;
  - `emptyTrash()`, apoyado en `KIO::listDir("trash:/")` + `KIO::del(...)`.

## Motivo

- El flujo anterior dependía de `runCommand()` y `sh -c` para `kioclient6` y `gio`, y en runtime reportado por el usuario la papelera no abría ni se vaciaba.
- Esta corrección reduce la deuda shell justo en la ruta más sensible detectada por la auditoría.

## Validación

- Queda pendiente confirmar runtime en Plasma con el plasmoide cargado, porque esta sesión no ejecuta la interfaz gráfica del usuario.
- Se intentará validación de build y `ctest` en la sesión de desarrollo.
