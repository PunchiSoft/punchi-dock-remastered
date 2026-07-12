# Auditoria general del proyecto - 2026-07-11

## Alcance

Auditoria estatica del proyecto versionado: `contents/`, `src/`, `metadata.json`, CMake, reglas de exclusion y scripts mantenidos en Git.

Se excluyeron expresamente `kde-sdk/`, `backup/`, copias instaladas, `build/`, `dist/`, `scratch/`, `bitacora/`, configuraciones del IDE y demas artefactos locales. No se usaron documentos historicos como evidencia del estado actual.

## Hallazgos

### Alta - Un clon limpio no contiene el modulo nativo requerido por el plasmoide

**Evidencia:** `contents/ui/config/ConfigItems.qml:8`, `contents/ui/config/SystemDiscoveryManager.qml:3`, `src/CMakeLists.txt:42` y `scripts/probar-plasmoid.sh:21`.

La configuracion importa `org.punchi.dock`, pero Git solo conserva `qmldir` y `punchidockintegration.qmltypes`. Las bibliotecas `libpunchidockintegration.so` y `libpunchidockintegrationplugin.so` presentes en el arbol local estan ignoradas por `*.so` y no existen en una copia obtenida con `git archive`.

El objetivo `stage_plasmoid_module` puede copiar las bibliotecas, pero no forma parte del build normal y el script de empaquetado no configura, compila ni ejecuta ese objetivo. Por tanto, el paquete creado desde un clon limpio queda sin el backend que requieren las paginas de configuracion.

**Accion recomendada:** convertir el empaquetado en una secuencia reproducible: configurar CMake, compilar `stage_plasmoid_module`, verificar las dos bibliotecas y solo entonces construir el `.plasmoid`. No versionar los binarios.

### Alta - El script principal de prueba y empaquetado usa el directorio equivocado

**Evidencia:** `scripts/probar-plasmoid.sh:5`, `scripts/probar-plasmoid.sh:11` y `scripts/probar-plasmoid.sh:21`.

Tras mover el script desde la raiz a `scripts/`, este ejecuta `cd "$(dirname "$0")"`. Desde ahi intenta encontrar `contents/ui`, `metadata.json` y `LICENSE` dentro de `scripts/`. La ejecucion auditada termina inmediatamente con `find: 'contents/ui': No such file or directory`.

**Accion recomendada:** resolver `PROJECT_ROOT` a partir del directorio del script, como ya hace `scripts/watch-plasmoidviewer.sh`, y ejecutar todo desde la raiz real.

### Media - Empaquetado, instalacion, reinicio y depuracion estan acoplados

**Evidencia:** `scripts/probar-plasmoid.sh:10-47`.

Un solo script valida QML, crea el paquete, lo instala, reinicia Plasma y vuelca el journal completo del usuario a `debug.log`. Esto impide usar el empaquetado como operacion segura y reproducible en automatizacion, y explica por que material exclusivamente local aparece mezclado con el flujo de distribucion.

`scripts/watch-plasmoidviewer.sh` tambien es una herramienta de desarrollo local. Ninguno de los dos scripts entra al `.plasmoid` debido a `.kpackageignore`, pero ambos aparecen en GitHub mientras esten versionados.

**Accion recomendada:** separar `package`, `install/test` y `collect-debug-log`. Decidir expresamente si los scripts de prueba deben seguir versionados; si son personales, ignorarlos y retirarlos de Git.

### Media - La version del proyecto CMake no coincide con la version distribuida

**Evidencia:** `CMakeLists.txt:3` declara `0.1.0`; `metadata.json` declara `0.8.2`.

La divergencia puede producir artefactos, reportes o futuras reglas de release con una version distinta a la publicada.

**Accion recomendada:** definir una fuente de version coherente o validar automaticamente que ambas declaraciones coincidan.

### Media - La UI principal conserva responsabilidades de proceso y persistencia

**Evidencia:** `contents/ui/main.qml:205`, `contents/ui/main.qml:230`, `contents/ui/main.qml:295` y `contents/ui/main.qml:575`.

`main.qml` tiene 1069 lineas y contiene ejecucion de shell, persistencia de JSON, coordinacion del modelo de tareas, gestion de ventanas emergentes y layout. `ConfigItems.qml` alcanza 654 lineas y `configItems.js` 622. La concentracion dificulta pruebas aisladas y mantiene operaciones del sistema dentro de la capa visual.

**Accion recomendada:** trasladar gradualmente persistencia y ejecucion a servicios o al modulo C++, sin reescribir la interfaz completa en una sola fase.

### Media - No existen pruebas automatizadas versionadas

No se encontraron directorios o archivos de prueba en el conjunto rastreado por Git. Los flujos de mayor riesgo son empaquetado limpio, normalizacion de comandos, lectura/escritura de configuracion, vaciado de papelera y conversion de modelos de tareas.

**Accion recomendada:** comenzar con pruebas de scripts y JavaScript puro, y agregar una comprobacion que construya el paquete desde `git archive` y valide su contenido obligatorio.

### Media - Se registran comandos completos en el journal

**Evidencia:** `contents/code/logic.js:94` y `contents/ui/main.qml:299`.

Los comandos configurados por el usuario y su envoltorio de shell se imprimen completos. Ademas de generar ruido permanente de debug, pueden exponer rutas, argumentos o datos sensibles en el journal de usuario.

**Accion recomendada:** eliminar trazas de flujo normal o limitar los mensajes a identificadores no sensibles y errores accionables.

### Baja - Un boton de cierre carece de nombre accesible explicito

**Evidencia:** `contents/ui/components/TaskWindowsPopup.qml:43`.

El boton usa solo icono y no declara `Accessible.name`, a diferencia del boton de cierre de cada ventana en el mismo componente.

**Accion recomendada:** declarar un nombre traducible para lectores de pantalla.

### Baja - Los nombres predeterminados no tienen una ruta de traduccion extraible

**Evidencia:** `contents/code/logic.js:5-20` y `contents/ui/components/DockItem.qml:436`.

Los nombres predeterminados se definen como cadenas inglesas y despues se pasan dinamicamente a `i18n(itemName)`. Las herramientas de extraccion no pueden descubrir de forma fiable esas cadenas dinamicas.

**Accion recomendada:** definir identificadores estables o envolver las cadenas literales en un punto extraible, preservando los nombres personalizados del usuario sin traducirlos.

## Riesgos no confirmados

- La ejecucion de comandos personalizados mediante `Plasma5Support.DataSource` acepta shell arbitrario. Es coherente con un dock configurable, pero los JSON importados deben considerarse contenido ejecutable y no datos inocuos.
- El popup puede mantener varias capturas PipeWire simultaneas para filas visibles. No se midio consumo de GPU o memoria en runtime.
- No se confirmo compatibilidad efectiva con Plasma 6.0. La metadata solo declara ese minimo y el entorno auditado dispone de componentes mas recientes.

## Validaciones realizadas

- `qmllint` sobre todos los QML versionados: correcto.
- validacion JSON de `metadata.json`: correcta.
- validacion XML de `contents/config/main.xml`: correcta.
- configuracion CMake en `/tmp`: correcta.
- compilacion completa C++/QML en `/tmp`: correcta.
- `bash -n` sobre ambos scripts: sintaxis correcta.
- ejecucion acotada de `scripts/probar-plasmoid.sh`: fallo reproducido antes de instalar o reiniciar Plasma.
- inspeccion de una copia limpia creada con `git archive`: confirmada ausencia de las bibliotecas nativas.

No se instalo el plasmoide, no se reinicio Plasma y no se realizo una prueba visual o funcional de runtime durante esta auditoria.

## Orden recomendado de correccion

1. Reparar la resolucion de la raiz en `scripts/probar-plasmoid.sh`.
2. Integrar compilacion y staging reproducible del modulo nativo antes de empaquetar.
3. Separar empaquetado, instalacion y depuracion; decidir que herramientas locales deben permanecer en Git.
4. Agregar una prueba de paquete construido desde una copia limpia.
5. Alinear versiones y retirar trazas sensibles.
6. Reducir gradualmente responsabilidades de `main.qml` y cubrir accesibilidad e internacionalizacion pendientes.

## Avance del plan de accion

Los dos hallazgos altos quedaron corregidos el 2026-07-11:

- `scripts/probar-plasmoid.sh` resuelve ahora la raiz real y delega el empaquetado sin efectos secundarios a `scripts/empaquetar-plasmoid.sh`.
- El modulo nativo se compila y se prepara dentro de `build/package-root`, sin depender de bibliotecas ignoradas presentes en `contents/`.
- `scripts/validar-empaquetado-limpio.sh` reproduce el empaquetado desde archivos no ignorados por Git y confirma que las dos bibliotecas se generan durante el proceso.

La validacion desde fuente limpia produjo un `.plasmoid` integro de 188756 bytes, sin documentacion, SDK, backups, scripts, fuentes C++, logs ni artefactos de desarrollo.

Tambien se completaron correcciones acotadas de severidad media y baja:

- la version CMake se alineo con `metadata.json` en `0.8.2`;
- se retiraron las trazas de flujo normal que imprimian comandos y clics en el journal;
- el boton iconografico que cierra las vistas previas recibio un nombre accesible traducible.

La separacion arquitectonica de persistencia, procesos y coordinacion actualmente concentrados en `main.qml` queda reservada para una fase independiente.

La primera parte de esa fase se implemento posteriormente mediante `DockRuntimeService`: la persistencia y el lanzamiento de comandos salieron de `main.qml` y pasaron al modulo C++ nativo. La coordinacion del modelo de tareas y los popups permanece pendiente de cortes posteriores.

El segundo corte traslado `TaskManager.TasksModel`, sus transformaciones y solicitudes a `TaskModelController.qml`. `main.qml` se redujo a 780 lineas; la gestion visual de popups permanece en la vista para un corte posterior.
