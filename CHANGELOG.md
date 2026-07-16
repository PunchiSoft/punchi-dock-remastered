# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

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

### Cambiado

- El objetivo actual de publicación se documenta como Fedora 44+ `x86_64`, Plasma 6 y Wayland.
- Los fondos flotantes y popups siguen el tema activo de Plasma.
- El menu contextual integrado conserva el tamano de la preview y permite ajustar entre `10%` y `200%` la velocidad con que desplaza las acciones.
- Las animaciones de popups comienzan despues del primer frame presentado para seguir siendo visibles en contenidos complejos como cuadriculas y listas.
- El vaciado de la papelera usa una sola superficie con transicion horizontal entre menu y confirmacion, iconos de estado, progreso, sonido configurable o tematico, proteccion ante operaciones concurrentes y el job oficial de KIO.
- La persistencia JSON distingue instancias del plasmoide.
- El paquete de distribucion compila el modulo nativo en modo `Release`, retira simbolos de desarrollo y rechaza bibliotecas que conserven secciones de depuracion.

### Pendiente

- Preservar los argumentos de comandos personalizados al activar lanzadores sin `storageId`.
- Reducir advertencias de `qmllint` y ampliar pruebas automatizadas de comportamiento.
- Validar una candidata de publicación limpia dentro de una sesión real de Plasma.

## [0.1.0] - Inicio de la Remasterización

### Agregado

- Estructura de directorios modular.
- Metadatos actualizados para KDE Plasma 6.
- Archivos `.kpackageignore`, `README.md`, y `CHANGELOG.md`.
