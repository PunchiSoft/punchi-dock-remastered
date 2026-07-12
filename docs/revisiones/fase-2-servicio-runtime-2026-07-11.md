# Fase 2 - Servicio de runtime nativo

## Objetivo

Retirar de `main.qml` la escritura de archivos y la gestion directa de procesos sin modificar el comportamiento visible del dock.

## Cambios

- Se agrego `DockRuntimeService` al modulo nativo `org.punchi.dock`.
- `persistDockItemsJson(json)` escribe atomicamente con `QSaveFile` en `~/.config/punchi-dock-remastered/dock_items.json`.
- `launchCommand(command)` inicia comandos configurados mediante `QProcess::startDetached`.
- `main.qml` dejo de importar `org.kde.plasma.plasma5support`, construir comandos de escritura y administrar `DataSource`.
- Se retiraron de `logic.js` los envoltorios de procesos que quedaron sin consumidores.
- Se actualizo el descriptor `punchidockintegration.qmltypes` para el IDE y las herramientas QML.

## Validacion automatica

- compilacion C++ completa: correcta;
- `qmllint` de `main.qml`: correcto;
- empaquetado desde archivos no ignorados: correcto;
- staging del modulo y generacion de `.plasmoid`: correctos.

## Prueba local solicitada

1. Ejecutar `scripts/probar-plasmoid.sh` para compilar, instalar y reiniciar Plasma.
2. Confirmar que el dock carga sin errores de tipo QML.
3. Abrir aplicaciones configuradas por `storageId` y por comando personalizado.
4. Editar un elemento, cerrar la configuracion y comprobar que el cambio persiste tras reiniciar Plasma.
5. Verificar que `~/.config/punchi-dock-remastered/dock_items.json` refleja el estado guardado.
6. Probar abrir y vaciar la papelera, incluido arrastrar un archivo hacia ella.
7. Confirmar que las miniaturas de ventanas siguen visibles.

No se realizo instalacion ni prueba visual desde la auditoria automatica; esos puntos requieren la prueba local indicada.

## Segundo corte - Controlador del modelo de tareas

Se agrego `contents/ui/components/TaskModelController.qml` como propietario de:

- `TaskManager.TasksModel` y su filtro por escritorio virtual;
- refrescos agrupados ante cambios estructurales o visuales;
- normalizacion de identificadores de aplicaciones;
- calculo de indicadores, ventanas, iconos y filas visibles;
- solicitudes de activar, minimizar y cerrar ventanas.

`main.qml` conserva la decision visual de abrir popups o lanzar elementos, pero ya no consulta roles ni ejecuta solicitudes directamente sobre `TasksModel`. Su tamano bajo de 1069 a 780 lineas.

### Prueba local del segundo corte

1. Abrir una aplicacion fijada y comprobar contador, indicador activo y minimizacion al pulsarla nuevamente.
2. Abrir dos ventanas de la misma aplicacion y verificar el popup con ambas miniaturas.
3. Activar cada ventana desde el popup y cerrar una ventana mediante su boton.
4. Abrir una aplicacion no fijada y comprobar que aparece como tarea adicional con nombre e icono.
5. Activar y minimizar esa tarea adicional desde el dock.
6. Cambiar la opcion de mostrar tareas del escritorio actual y comprobar el filtrado al cambiar de escritorio.
7. Confirmar que cerrar o abrir ventanas actualiza el dock sin duplicados ni indicadores estancados.
