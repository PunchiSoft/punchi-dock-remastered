# Punchi Dock Remastered

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered es un dock de lanzadores e interfaz de tareas nativo para KDE Plasma 6, diseñado principalmente para Wayland. Puede funcionar como dock flotante o integrarse en un panel de Plasma respetando el tema activo.

Este repositorio es una reescritura modular del proyecto original [Punchi Dock Plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid). Actualmente el proyecto está preparando su camino hacia una versión estable 1.0.

## Características

- Modos dock flotante y panel de Plasma.
- Lanzadores fijados y entradas dinámicas de tareas opcionales.
- Tarjetas de ventanas, miniaturas vivas y controles para ventanas agrupadas.
- Carpetas configurables, notas rápidas, papelera, separadores y calendario.
- Visualizador de audio PipeWire opcional con seis estilos, colores dinámicos o del tema Plasma y hasta 48 elementos visuales.
- Popups adaptados al tema de Plasma con animaciones de apertura configurables y transiciones fluidas entre miniaturas y menús.
- Acciones nativas de aplicacion y ventana en los menus contextuales de launchers fijados y tareas dinamicas.
- Tarjetas multimedia MPRIS contextuales con caratula, informacion de pista y controles de reproduccion.
- Operaciones asíncronas de papelera con actividad, progreso, sonido de finalización y notificaciones temáticas de KDE.
- Integración QML nativa en C++ para descubrir aplicaciones, servicios de ejecución, análisis de audio y operaciones de papelera.

## Requisitos

- Fedora 44 o posterior en `x86_64` es el objetivo actual de publicación.
- KDE Plasma 6 o posterior.
- Wayland es la sesión principal soportada.
- PipeWire es necesario para el visualizador de audio opcional.
- Los binarios nativos incluidos en el paquete `.plasmoid` se compilan y validan actualmente para Fedora 44+ `x86_64`; no son binarios universales para todas las distribuciones con Plasma.

## Instalar un paquete publicado

El usuario final debe instalar un paquete `.plasmoid` ya construido para la plataforma soportada. No necesita paquetes de desarrollo ni un compilador.

El objetivo actual del paquete publicado es Fedora 44+ `x86_64` con KDE Plasma 6 o posterior.

En Fedora, `kpackagetool6` pertenece a `kf6-kpackage` y normalmente ya está disponible en una instalación de Plasma:

```bash
sudo dnf install kf6-kpackage
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-0.8.6-fedora44-x86_64.plasmoid
```

Para actualizar una instalación existente:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-0.8.6-fedora44-x86_64.plasmoid
```

Cierra y vuelve a iniciar sesión, o reinicia Plasma Shell, si el plasmoide actualizado no se carga inmediatamente.

## Compilar desde fuentes en Fedora 44+ `x86_64`

El árbol de fuentes contiene un módulo QML nativo en C++. Instalar directamente el directorio del repositorio con `kpackagetool6` no compila ese módulo.

Instala las dependencias de compilación:

```bash
sudo dnf install \
    binutils cmake gcc-c++ ninja-build extra-cmake-modules \
    qt6-qtdeclarative-devel \
    kf6-kcoreaddons-devel kf6-kio-devel kf6-kjobwidgets-devel \
    kf6-kservice-devel libplasma-devel \
    pipewire-devel \
    zip unzip
```

Compila el módulo nativo y crea el artefacto versionado para el sistema actual:

```bash
scripts/empaquetar-plasmoid.sh
```

El script detecta Fedora o Debian desde `/etc/os-release`. El paquete resultante se genera con un nombre inequívoco:

```text
dist/punchi-dock-remastered-<version>-<distribución><versión>-<arquitectura>.plasmoid
```

Por ejemplo: `punchi-dock-remastered-0.8.6-fedora44-x86_64.plasmoid` o `punchi-dock-remastered-0.8.6-debian13-x86_64.plasmoid`. No instales en Debian un artefacto identificado como Fedora ni a la inversa.

Los wrappers explícitos quedan disponibles para automatización o diagnóstico:

```bash
scripts/build-fedora-package.sh
scripts/build-debian-package.sh
```

Cada wrapper exige ejecutarse en su distribución y usa su baseline propio. El flujo Debian fue comprobado en Debian 13, donde el artefacto se instaló y cargó correctamente. Consulta [scripts/README.md](scripts/README.md) para distinguir empaquetado, instalación local y validación limpia.

Define `PACKAGE_BUILD_TYPE` o `STRIP_BIN` solo cuando un flujo de desarrollo necesite reemplazarlos explícitamente. No uses `PACKAGE_OUTPUT_FILE` para poner una etiqueta Debian a un binario Fedora ni uses compilación cruzada para publicar el módulo QML nativo.

Para compilar, instalar y reiniciar Plasma durante una prueba local de desarrollo:

```bash
scripts/probar-plasmoid.sh
```

Este script ejecuta las comprobaciones de empaquetado y CTest, actualiza el plasmoide local, reinicia Plasma Shell y escribe diagnósticos de inicio filtrados en `debug.log`. Como reinicia el shell del escritorio, úsalo después de un cambio coherente y no tras guardar cada archivo.

Antes de publicar una versión, reproduce el paquete desde un árbol fuente temporal limpio:

```bash
scripts/validar-empaquetado-limpio.sh
```

Para iteración visual rápida, `scripts/watch-plasmoidviewer.sh` puede reconstruir y reabrir `plasmoidviewer` al detectar cambios. No sustituye la prueba final dentro del panel o dock real de Plasma.

## Estructura del proyecto

- `contents/`: paquete ejecutable del plasmoide.
- `contents/ui/components/`: componentes reutilizables de la interfaz QML.
- `contents/code/`: lógica JavaScript compartida y valores predeterminados.
- `src/`: módulo nativo de integración QML en C++.
- `scripts/`: herramientas de empaquetado y pruebas locales.
- `metadata.json`: metadata KPackage y compatibilidad declarada con Plasma.

Las notas internas de desarrollo y los registros de auditoría se excluyen deliberadamente del repositorio público y del paquete distribuido.

## Licencia

Punchi Dock Remastered se distribuye bajo la [Licencia Pública General de GNU versión 3.0 o posterior](LICENSE).
