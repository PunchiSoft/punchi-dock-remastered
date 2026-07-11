# Auditoría puntual de deuda shell

Fecha: 2026-07-11

## Objetivo

Inventariar los usos actuales de `sh -c`, `Plasma5Support.DataSource` y ejecución indirecta por shell para decidir:

- qué rutas deben migrarse a integración nativa;
- qué rutas pueden mantenerse temporalmente;
- qué parte conviene resolver en QML/JS y cuál amerita ampliar el adaptador C++.

## Hallazgos

### 1. `main.qml` concentra la deuda shell de runtime más sensible

Archivo: [contents/ui/main.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/main.qml:43)

Usos detectados:

- `Plasma5Support.DataSource` con `engine: "executable"`;
- sondeo periódico del estado de la papelera con `find ... | wc -l`;
- escritura de `dock_items.json` externo mediante `mkdir -p` + `printf`;
- ejecución de comandos finales vía `Logic.detachedCommand(...)`.

Clasificación:

- `trashMonitorTimer` + conteo de papelera: deuda alta.
- sincronización de `dock_items.json`: deuda media.
- `runCommand()` como fallback genérico: deuda media-alta.

Riesgo:

- mezcla lógica de UI con shell y un `DataEngine` heredado;
- acopla comportamiento del dock a comandos de usuario/entorno;
- complica pruebas y futuras migraciones fuera de Plasma5Support.

### 2. `IconPickerController.qml` usa shell para indexar iconos del sistema

Archivo: [contents/ui/config/IconPickerController.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/IconPickerController.qml:95)

Uso detectado:

- `iconSource.connectSource("sh -c " + page.shellQuote(ConfigScriptsJS.iconIndexScript()))`

El script de [configScripts.js](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/code/configScripts.js:51) hace:

- lectura del tema activo con `kreadconfig6`;
- recorrido de herencia de temas;
- `find` sobre múltiples raíces de iconos;
- deduplicación con `awk`, `sort`, `head`.

Clasificación:

- deuda alta, pero de migración más costosa que la papelera.

Riesgo:

- alta dependencia de herramientas externas (`find`, `awk`, `sort`, `sed`, `kreadconfig6`);
- coste de mantenimiento elevado;
- difícil de validar en forma portable y sin shell.

### 3. Preview de sonido de papelera sigue apoyándose en shell

Archivo: [contents/ui/config/ConfigItems.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigItems.qml:245)

Uso detectado:

- `soundPreviewSource.connectSource("sh -c " + shellQuote(script))`

El script en [configScripts.js](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/code/configScripts.js:66) prueba:

- `paplay`;
- `pw-play`;
- `canberra-gtk-play`.

Clasificación:

- deuda media.

Riesgo:

- no es central al funcionamiento del dock;
- pero sigue dependiendo de varias herramientas externas y fallback por shell.

### 4. Lanzamiento y operaciones de papelera en `logic.js` siguen encapsulando shell

Archivo: [contents/code/logic.js](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/code/logic.js:41)

Usos detectados:

- `detachedCommand()` genera `sh -c`;
- `launchTrash()` decide entre `kioclient6` y `gio open`;
- `trashUrlsScript()` construye comandos por shell para mover a `trash:/` o `gio trash`.

Clasificación:

- deuda media-alta.

Riesgo:

- la construcción está razonablemente cuidada con `shellQuote`, pero sigue siendo una interfaz basada en texto;
- mezcla fallback de compatibilidad con lógica de negocio.

### 5. Hay shell heredado en `configScripts.js` que ya no es prioritario

Archivo: [contents/ui/config/code/configScripts.js](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/code/configScripts.js:1)

Observación:

- contiene utilidades para abrir archivos, garantizar config files y guardar JSON;
- no todo está necesariamente activo en el flujo crítico actual;
- parte de este archivo es deuda residual de etapas anteriores.

Clasificación:

- deuda baja a media, según uso real.

## Qué ya está nativo y no debe rehacerse

El adaptador [SystemDiscovery](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/src/systemdiscovery.h:1) ya cubre correctamente:

- listado de carpetas vía KIO;
- descubrimiento de aplicaciones vía KService;
- búsqueda de aplicaciones;
- apertura de URL;
- lanzamiento de aplicaciones.

Conclusión:

- no conviene mover a shell nada de esos dominios;
- la próxima ampliación nativa debería concentrarse en papelera, iconos o utilidades de archivo/configuración.

## Recomendación de migración

### Prioridad 1

Mover el estado de papelera y sus operaciones principales a una ruta nativa.

Objetivo mínimo:

- consultar si la papelera tiene contenido sin usar `find | wc -l`;
- abrir papelera y vaciarla sin depender de comandos shell construidos en QML;
- evaluar extensión de `SystemDiscovery` o un adaptador dedicado como `TrashIntegration`.

### Prioridad 2

Eliminar la escritura por shell de `dock_items.json`.

Opciones razonables:

- ampliar el adaptador C++ con lectura/escritura simple de archivo de configuración;
- o decidir explícitamente que el archivo espejo externo deje de existir si ya no aporta valor real.

### Prioridad 3

Revisar el preview de sonido.

Opciones:

- dejarlo como deuda aceptada y documentada;
- o encapsularlo mejor si existe una API Qt/KDE razonable para reproducción corta.

### Prioridad 4

Plan específico para indexado de iconos.

No recomiendo atacarlo inmediatamente junto con papelera.

Primero conviene decidir:

- si basta un subconjunto de iconos del tema activo;
- si se acepta una carga más lenta pero nativa;
- si el adaptador C++ debería exponer un índice de iconos ya resuelto.

## Decisión recomendada para la siguiente implementación

La siguiente tarea de código debería ser:

1. diseñar una pequeña ampliación nativa para papelera;
2. sustituir en `main.qml` el monitoreo y acciones de papelera;
3. dejar el indexado de iconos para una subfase posterior.

## Conclusión

La deuda shell existe y es real, pero no toda tiene el mismo peso.

El mayor retorno técnico inmediato está en sacar de shell la papelera y la sincronización de archivo externo. El indexado de iconos también merece migración, pero debería entrar como tarea separada porque su coste y superficie de cambio son mayores.
