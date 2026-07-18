# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

## [0.8.9] - 2026-07-18

### Agregado

- Reserva flexible del espacio libre en paneles horizontales configurados para rellenar el ancho disponible.
- Capacidad automática para grupos dinámicos y desbordamiento ajustado al espacio realmente asignado por Plasma.
- Acciones `Pin to Dock` y `Unpin from Dock` para tareas dinámicas y aplicaciones fijadas.
- Creación de notas rápidas desde el menú global y eliminación segura desde el editor de notas.
- Reflejos opcionales y degradados para iconos en dock flotante y panel horizontal.
- Opción para mostrar u ocultar el fondo temático de hover y aplicación activa.
- Publicación de la geometría de los items para dirigir hacia ellos la animación de minimización de KWin.
- Reacciones configurables al minimizar: rebote lento y onda lateral acotada a los items vecinos.
- Infraestructura ki18n reproducible con inglés como fuente, catálogo español y compilación de traducciones dentro del `.plasmoid`.
- Renderer `shaped` con esquema JSON v2 y gradientes animados opcionales para temas externos.
- Comprobador portable del entorno de compilación y diagnóstico detallado cuando `qmllint` supera un baseline.

### Cambiado

- El modo `Fill free panel space` solo se activa cuando el panel horizontal usa realmente `FillAvailable`; los modos compacto, flotante y vertical conservan su tamaño normal.
- Los items dinámicos se alinean después del último elemento fijado y el overflow ocupa la última celda disponible sin desplazar el bloque persistente.
- Las transiciones entre tarea dinámica y aplicación fijada utilizan una animación breve sin alterar el orden persistido.
- El idioma de la interfaz sigue automáticamente la configuración regional de KDE; no se añade un selector que pueda afectar globalmente a `plasmashell`.
- Fedora Qt 6.11 y Debian Qt 6.8 conservan perfiles de lint independientes sin convertir la versión del linter en requisito de ejecución.

### Corregido

- Desanclar utiliza un índice persistente validado y elimina correctamente el launcher fijado.
- Los reflejos nacen bajo el icono, se desvanecen gradualmente y respetan el espacio real disponible en paneles horizontales.
- Las notas eliminadas no vuelven a guardarse accidentalmente al cerrar su popup.
- Las ventanas minimizadas reciben como destino el icono, grupo u overflow que las representa.
- Los falsos positivos de Qt 6.8 para la acción contextual oficial `PlasmaCore.Action` quedan suprimidos localmente sin ampliar el baseline global.

### Validación

- Fedora 44 con Qt 6.11.1: `qmllint` dentro del baseline, compilación Release, CTest `6/6` y empaquetado completado.
- Varias mejoras visuales y funcionales fueron confirmadas por el usuario en Plasma 6 Wayland real.
- Debian 13 con Qt 6.8.2 mantiene validación independiente; queda pendiente confirmar el flujo completo después de la última corrección localizada de lint.

## [0.8.8] - 2026-07-16

### Agregado

- Biblioteca administrada de temas JSON externos sin incluir presets dentro del paquete.
- Importación individual o recursiva de carpetas, detección de duplicados, límite de seguridad y borrado de temas instalados.
- Validación nativa de esquema, tamaño, colores, gradientes, bordes, sombras, separadores y geometría antes de exponer un tema a QML.
- Renderers de fondo plano 2D y repisa 2.5D para el dock flotante.
- Separadores temáticos con estilos line, dot y capsule, gradiente, borde, patrón y glow acotado.
- Página de configuración independiente para el visualizador de audio.
- Pruebas unitarias para validación y repositorio de temas.

### Cambiado

- Los temas externos se almacenan bajo la ubicación de datos del usuario y la configuración conserva un identificador estable, no la ruta original.
- Los paneles Plasma mantienen su fondo nativo; los temas JSON se aplican únicamente al dock flotante.
- El espectro de audio se compone sobre el fondo Plasma o JSON seleccionado.
- El matching de tareas sigue el patrón de KDE y compara `AppId` y `LauncherUrlWithoutIcon`.
- Las tareas sin servicio instalado pueden reutilizar el icono entregado por la ventana mediante `Qt.DecorationRole`.
- El build Debian usa un directorio de caché fuera de la carpeta compartida de VirtualBox y un baseline propio para Qt 6.8.
- El script de prueba confirma instalación válida y cambio real de PID al reiniciar Plasma Shell.

### Corregido

- Los iconos ya no reducen su tamaño al activar el autoocultado del panel.
- Aplicaciones portables pueden mostrar el icono publicado por su ventana sin depender de un archivo `.desktop` instalado.
- Ventanas con identidad distinta a su lanzador, incluido el flujo de ejecución de VirtualBox, disponen de una segunda vía estándar de asociación.
- La importación de temas tolera subcarpetas y conserva una biblioteca estructurada.
- El selector de temas ya no falla durante reconstrucciones transitorias del modelo ni después de borrar el tema activo.
- Los glows de separadores y rims quedan limitados para no desbordar visualmente el dock.
- Se retiraron opciones de diálogo no disponibles en Qt 6.8 y se recalibró el baseline Debian tras revisar el log completo.

### Validación

- Fedora 44: `qmllint` dentro del baseline, compilación Release, `ctest` `5/5`, empaquetado, instalación y reinicio de Plasma.
- Debian 13 con Qt 6.8.2: flujo de `qmllint` revisado y baseline específico actualizado; el usuario confirmó la continuación correcta del proceso de prueba.
- Los temas JSON externos permanecen fuera del artefacto `.plasmoid`.

## [0.8.7] - 2026-07-15

### Agregado

- Módulo QML nativo en C++ para integración con KDE, persistencia y operaciones de runtime.
- Lanzadores fijados, tareas dinámicas, previsualizaciones de ventanas y controles para grupos.
- Carpetas, notas, papelera, calendario, separadores y acciones contextuales configurables.
- Acciones contextuales nativas de archivos `.desktop` y controles de ventana para launchers fijados y tareas dinamicas.
- Tarjeta multimedia MPRIS contextual con caratula, metadatos y controles anterior, reproducir/pausar y siguiente.
- Visualizador de espectro de audio basado en PipeWire, con prueba unitaria del analizador, seis estilos y flujo ritmico opcional en ambos sentidos.
- Animaciones de apertura configurables para los popups nativos, con controles porcentuales de velocidad e intensidad.
- Empaquetado reproducible con selección explícita de `qmllint` para Qt 6 y línea base de advertencias.
- Perfiles nativos separados para Fedora 44 y Debian 13 con nombres de artefacto inequívocos.
- Adaptador QML para compatibilidad con distintas APIs de escritorios virtuales de TaskManager.

### Cambiado

- El objetivo actual de publicación se documenta como Fedora 44+ `x86_64`, Plasma 6 y Wayland.
- Los fondos flotantes y popups siguen el tema activo de Plasma.
- El menu contextual integrado conserva el tamano de la preview y permite ajustar entre `10%` y `200%` la velocidad con que desplaza las acciones.
- Las animaciones de popups comienzan despues del primer frame presentado para seguir siendo visibles en contenidos complejos como cuadriculas y listas.
- El vaciado de la papelera usa una sola superficie con transicion horizontal entre menu y confirmacion, iconos de estado, progreso, sonido configurable o tematico, proteccion ante operaciones concurrentes y el job oficial de KIO.
- La persistencia JSON distingue instancias del plasmoide.
- El paquete de distribucion compila el modulo nativo en modo `Release`, retira simbolos de desarrollo y rechaza bibliotecas que conserven secciones de depuracion.
- Las carpetas conservan las vistas de rejilla, lista y detalle; las vistas radial y fan se retiraron temporalmente hasta su rediseño.
- La coordinacion de popups se extrajo de `main.qml` a un componente dedicado.

### Corregido

- Los lanzadores personalizados conservan comandos con argumentos mediante un fallback de runtime seguro.
- Los popups de carpetas, notas, papelera, calendario, tareas y acciones vuelven a inicializar e interactuar correctamente tras la modularizacion.
- Los controles de miniaturas y ventanas agrupadas permanecen disponibles en sus superficies interactivas.
- La papelera ya no deja su primera accion resaltada visualmente al abrirse con el raton.
- La hora y la fecha usan sombras adaptadas al tema para mantener legibilidad.
- Se eliminaron las 14 advertencias de layout indefinido compartidas por Fedora y Debian.
- Los modelos de tareas ya no fallan cuando el runtime no expone `filterByCurrentVirtualDesktop`.

### Pendiente

- Continuar reduciendo advertencias no críticas de `qmllint` y ampliar pruebas automatizadas de comportamiento QML.
- Completar la revisión funcional de Debian y la modularización de responsabilidades restantes en `main.qml`.

## [0.1.0] - Inicio de la Remasterización

### Agregado

- Estructura de directorios modular.
- Metadatos actualizados para KDE Plasma 6.
- Archivos `.kpackageignore`, `README.md`, y `CHANGELOG.md`.
