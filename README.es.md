# Punchi Dock Remastered

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered es un dock de lanzadores e interfaz de tareas nativo para KDE Plasma 6, diseñado principalmente para Wayland. Puede funcionar como dock flotante o integrarse en un panel de Plasma respetando el tema activo.

Este repositorio es una reescritura modular del proyecto original [Punchi Dock Plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid). Actualmente el proyecto está preparando su camino hacia una versión estable 1.0.

## Características

- Modos dock flotante y panel de Plasma.
- Lanzadores fijados y entradas dinámicas de tareas opcionales.
- Tarjetas de ventanas, miniaturas vivas y controles para ventanas agrupadas.
- Carpetas configurables, notas rápidas, papelera, separadores y calendario.
- Popups adaptados al tema de Plasma y una interfaz de configuración compacta.
- Integración QML nativa en C++ para descubrir aplicaciones, servicios de ejecución y operaciones de papelera.

## Requisitos

- Linux con KDE Plasma 6.
- Wayland es la sesión principal soportada.
- Fedora 44 o posterior es el entorno principal de desarrollo y pruebas.

## Instalar un paquete publicado

El usuario final debe instalar un paquete `.plasmoid` ya construido. No necesita paquetes de desarrollo ni un compilador.

En Fedora, `kpackagetool6` pertenece a `kf6-kpackage` y normalmente ya está disponible en una instalación de Plasma:

```bash
sudo dnf install kf6-kpackage
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered.plasmoid
```

Para actualizar una instalación existente:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered.plasmoid
```

Cierra y vuelve a iniciar sesión, o reinicia Plasma Shell, si el plasmoide actualizado no se carga inmediatamente.

## Compilar desde fuentes en Fedora 44+

El árbol de fuentes contiene un módulo QML nativo en C++. Instalar directamente el directorio del repositorio con `kpackagetool6` no compila ese módulo.

Instala las dependencias de compilación:

```bash
sudo dnf install \
    cmake gcc-c++ ninja-build extra-cmake-modules \
    qt6-qtdeclarative-devel \
    kf6-kcoreaddons-devel kf6-kio-devel kf6-kservice-devel \
    zip unzip
```

Compila el módulo nativo y crea el paquete:

```bash
PATH="/usr/lib64/qt6/bin:$PATH" scripts/empaquetar-plasmoid.sh
```

El paquete resultante se genera en:

```text
dist/punchi-dock-remastered.plasmoid
```

Para compilar, instalar y reiniciar Plasma durante una prueba local de desarrollo:

```bash
PATH="/usr/lib64/qt6/bin:$PATH" scripts/probar-plasmoid.sh
```

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
