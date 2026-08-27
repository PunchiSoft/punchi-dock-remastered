# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="160" alt="Logo de Punchi Dock Remastered">
</p>

<p align="center">
  <a href="https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.42">
    <img src="https://img.shields.io/badge/release-v0.9.7.42-4caf50" alt="Versión v0.9.7.42">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/licencia-GPL--3.0--or--later-blue" alt="Licencia GPL-3.0-or-later">
  </a>
  <a href="https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W">
    <img src="https://img.shields.io/badge/Donar-PayPal-0070ba" alt="Donar con PayPal">
  </a>
</p>

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered es un dock nativo de lanzadores e interfaz de tareas para KDE Plasma 6, diseñado principalmente para Wayland. Puede funcionar como dock flotante o integrarse en un panel de Plasma siguiendo el tema activo.

Este repositorio es una reescritura modular del [Plasmoide Punchi Dock original](https://github.com/PunchiSoft/punchi-dock-plasmoid). Actualmente el proyecto prepara su camino hacia la versión estable 1.0.

La versión actual es
[v0.9.7.42](https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.42).

## Novedades de la versión 0.9.7.42

- **Cinemática de Apertura y Cierre Suave en PunchiMenu**: Brote elástico de superficie (*Spring Reveal*) con escala dinámica (`0.88 ──► 1.00`), desplazamiento vertical anclado y desvanecimiento suave de salida (*Fade Out*) tanto en Modo Normal como en Modo Compacto.
- **100% Validado**: Suite CTest completa aprobada (38/38) y catálogos de traducción al 100%.

Consulta el [changelog de la versión 0.9.7.42](CHANGELOG.md#09742---2026-08-17) para
conocer las notas detalladas del lanzamiento y la validación realizada.

## Capturas

| PunchiMenu Normal — vista preliminar recomendada |
|:--:|
| <img src="Images/PunchiMenuNormal.png?v=0.9.7" alt="PunchiMenu Normal con categorías, grilla de aplicaciones y favoritos" width="760"> |

| PunchiMenu Pantalla completa |
|:--:|
| <img src="Images/PunchiMenuFullScreen.png?v=0.9.7" alt="Lanzador de aplicaciones PunchiMenu en Pantalla completa" width="760"> |

| Controles multimedia MPRIS |
|:--:|
| <img src="Images/MPRIS-Controls.png" alt="Formatos de popup MPRIS con carátula y controles de reproducción" width="760"> |

| Disposiciones del dock |
|:--:|
| <img src="Images/desktop-layouts.png" alt="Punchi Dock en disposición horizontal, vertical y como panel de Plasma" width="760"> |

| Carpeta en cuadrícula | Calendario y reloj |
|:--:|:--:|
| <img src="Images/MenuGrid.png" alt="Popup de carpeta en vista de cuadrícula" width="300"> | <img src="Images/Calendar_clock.png" alt="Popup de calendario y reloj" width="300"> |

## Características

- Modos dock flotante y panel de Plasma.
- Lanzadores fijados y entradas dinámicas de tareas opcionales.
- Lanzadores personalizados con preservación segura de comandos y argumentos.
- Tarjetas de ventanas, miniaturas vivas y controles para ventanas agrupadas, con selección entre tarjetas, miniaturas en vivo o sin ventana emergente.
- Carpetas configurables con vistas de rejilla, lista y detalle, cambio directo
  de vista desde el menú contextual y arrastre de lanzadores desde PunchiMenu o
  el escritorio, además de notas rápidas, papelera, separadores y calendario.
- Lanzador de aplicaciones PunchiMenu con modos Normal y Pantalla completa,
  búsqueda, categorías, favoritos, carpetas de aplicaciones con nombre,
  ocultación selectiva, operación por teclado, atajo global y acciones de
  sesión nativas. Compacto queda reservado para una versión futura.
- Visualizador de audio PipeWire opcional con seis estilos, colores dinámicos o del tema Plasma y hasta 48 elementos visuales.
- Popups adaptados al tema de Plasma con animaciones de apertura configurables,
  distancia adaptativa respecto del dock, transiciones fluidas entre miniaturas
  y menús, y retargeting continuo entre elementos del dock.
- Acciones nativas de aplicacion y ventana en los menus contextuales de launchers fijados y tareas dinamicas.
- Badges opcionales de conteo para aplicaciones agrupadas con varias ventanas.
- Tarjetas multimedia MPRIS contextuales con caratula, informacion de pista, controles de reproduccion y una accion accesible para silenciar o restaurar el volumen en todos los formatos de tarjeta.
- Item MPRIS compacto para el dock con reproductor seleccionable, fallback de caratula, modos de texto vertical y apertura seguida de Play.
- Controles circulares de color Plasma/personalizado y separacion configurable entre iconos con unidades visuales explicitas.
- Reordenamiento persistente de elementos del dock mediante pulsación prolongada
  o teclado, arrastre seguro de archivos hacia aplicaciones fijadas y la
  Papelera, y acciones de desanclado adaptadas a aplicaciones y carpetas.
- Tarjeta MPRIS opcional bajo las miniaturas vivas, revelada despues de la vista previa para conservar la continuidad visual.
- Operaciones asíncronas de papelera con actividad, progreso, sonido de finalización y notificaciones temáticas de KDE.
- Temas externos JSON almacenados en una biblioteca administrada, con importación recursiva de carpetas, borrado y fallback seguro al fondo Plasma.
- Renderers plano 2D y repisa 2.5D con separadores, bordes, gradientes, rims y glow acotado definidos por cada tema.
- Reloj y calendario con sombras adaptadas al tema para conservar legibilidad sobre fondos variables.
- Compatibilidad dinámica con APIs de TaskManager disponibles en distintas versiones de Plasma 6.
- Iconos de ventanas para aplicaciones portables y asociación de tareas mediante identificadores de aplicación o URL de lanzador.
- Tamaño estable de iconos al alternar un panel Plasma entre Siempre visible y Ocultar automáticamente.
- Cumplimiento con estándares de almacenamiento de usuario XDG: Los temas JSON importados (`~/.local/share/punchi-dock-remastered/`) y la configuración de ítems por instancia (`~/.config/punchi-dock/`) utilizan almacenamiento aislado con escritura atómica para evitar la corrupción de `desktop-appletsrc` y conservar los datos del usuario al actualizar el plasmoide.
- Integración QML nativa en C++ para descubrir aplicaciones, servicios de ejecución, análisis de audio y operaciones de papelera.

## Requisitos

- KDE Plasma 6 o posterior.
- Sesión Wayland recomendada (soporte secundario para X11).
- PipeWire es necesario para el visualizador de audio opcional.
- **Distribución de referencia oficial**: Fedora 44 `x86_64` con KDE Plasma 6+.
- **Paquete Universal oficial**: Se compila en Debian 13 (Trixie) con proxies binarios C (`compat/`), permitiendo una instalación y ejecución directa en múltiples distribuciones modernas con Plasma 6 (Fedora, Arch Linux, Debian, Kubuntu y derivados).
- **Compilación local desde código fuente**:
  - Requiere CMake 3.22+, compilador C++20, Qt 6.6+, ECM/KF6 6.0+, Plasma 6.0+ y archivos de desarrollo de PipeWire (suministrados por los repositorios de tu propia distribución).
  - Se incluyen asistentes automatizados con y sin pruebas para compilar e instalar en un solo paso.

## Instalar un paquete publicado

El usuario final puede instalar directamente un paquete `.plasmoid` precompilado oficial (ya sea el específico de su distribución o el paquete universal) sin necesidad de instalar compiladores ni herramientas de desarrollo.

Para instalar o actualizar mediante el asistente universal:

```bash
./scripts-user/setup-universal.sh ruta/al/paquete.plasmoid
```

O manualmente mediante `kpackagetool6`:

```bash
# Instalación inicial
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-<versión>-<distro>-x86_64.plasmoid

# Actualización
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-<versión>-<distro>-x86_64.plasmoid
```

Cierra y vuelve a iniciar sesión, o reinicia Plasma Shell, si el plasmoide actualizado no se carga inmediatamente.

## Compilar desde fuentes

El plasmoide contiene un módulo nativo en C++ para integrarse con Plasma 6, PipeWire y el sistema de tareas. Se puede compilar fácilmente en cualquier distribución moderna con Plasma 6.

### Dependencias de compilación por distribución

El asistente `setup.sh` comprueba e informa automáticamente los paquetes faltantes en tu sistema, pero si prefieres instalarlos manualmente:

#### Fedora / RHEL / Nobara
```bash
sudo dnf install \
    gcc-c++ cmake extra-cmake-modules \
    qt6-qtbase-devel qt6-qtdeclarative-devel \
    plasma-workspace-devel pipewire-devel \
    kf6-kconfig-devel kf6-ki18n-devel kf6-kio-devel \
    gettext zip unzip
```

#### Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -S --needed \
    base-devel cmake extra-cmake-modules \
    qt6-base qt6-declarative \
    plasma-workspace pipewire \
    kconfig ki18n kio kservice
```

#### Debian 13 (Trixie) / Kubuntu / Ubuntu
```bash
sudo apt update && sudo apt install \
    build-essential cmake extra-cmake-modules \
    qt6-base-dev qt6-declarative-dev \
    libplasma-dev libpipewire-0.3-dev \
    libkf6config-dev libkf6i18n-dev libkf6kio-dev \
    gettext zip unzip
```

### Asistentes de compilación incluidos

El repositorio incluye asistentes automatizados listos para usar según la necesidad:

#### 1. Asistente para usuarios (Rápido y Seguro, sin tests)

Diseñado para compilar e instalar localmente en segundos sin ejecutar comprobaciones de desarrollo:

```bash
./scripts-user/setup.sh
```

- Configura CMake con `BUILD_TESTING=OFF` (no ejecuta `qmllint` ni CTest).
- Detecta automáticamente tu distribución (Fedora, Arch Linux, Debian, Kubuntu y derivados) y comprueba las dependencias necesarias.
- Permite configurar interactivamente la **concurrencia de compilación y memoria** (Modo Seguro de 1 núcleo para máquinas virtuales o equipos con <= 4 GB RAM, Modo Balanceado, Rápido o Personalizado).
- También admite ejecución directa por línea de comandos:

```bash
# Compilar e instalar localmente limitando a 1 núcleo (Modo Seguro para MV o poca RAM)
./scripts-user/setup.sh --install -j 1

# Crear solo el paquete .plasmoid local usando 4 hilos en paralelo
./scripts-user/setup.sh --build-only --jobs 4

# Desinstalar el plasmoide del escritorio actual
./scripts-user/setup.sh --uninstall
```

El paquete generado se ubica en `dist/punchi-dock-remastered-<versión>-<distro>-<arch>-local-build.plasmoid`. Consulta [scripts-user/README.es.md](scripts-user/README.es.md) para más detalles.

### 2. Asistente maestro para desarrolladores (Validación estricta con tests)

Diseñado para desarrolladores y colaboradores que deseen validar exhaustivamente el código:

```bash
./scripts-dev/setup.sh
```

- Ejecuta `qmllint` para verificación estática de QML según el baseline de la distribución.
- Configura CMake con `BUILD_TESTING=ON` y ejecuta la suite completa de tests con CTest (contratos de arquitectura, shaders, ciclo de vida, integración Plasma y backend nativo).
- Admite opciones CLI como:

```bash
./scripts-dev/setup.sh --local-test           # Compilar, validar tests e instalar en Plasma local
./scripts-dev/setup.sh --local-test -j 1      # Modo seguro (1 núcleo) para máquinas virtuales
./scripts-dev/setup.sh --local-test --jobs 8 # Modo rápido con 8 hilos en paralelo
./scripts-dev/setup.sh --clean-install         # Reinstalación limpia desde cero
./scripts-dev/setup.sh --dependencies-only    # Instalar dependencias oficiales de la distribución
./scripts-dev/setup.sh --lang es --help       # Ayuda en español
```

Consulta [scripts-dev/README.es.md](scripts-dev/README.es.md) para más herramientas de desarrollo (`check-build-environment.sh`, `update-translations.sh`, `validar-empaquetado-limpio.sh`).

## Estructura del proyecto

- `contents/`: paquete ejecutable del plasmoide.
- `contents/ui/components/`: componentes reutilizables de la interfaz QML.
- `contents/code/`: lógica JavaScript compartida y valores predeterminados.
- `src/`: módulo nativo de integración QML en C++.
- `scripts-user/`: flujo normal de compilación e instalación para usuarios.
- `scripts-dev/`: pruebas estrictas, empaquetado y herramientas de mantenimiento.
- `metadata.json`: metadata KPackage y compatibilidad declarada con Plasma.

Las notas internas de desarrollo y los registros de auditoría se excluyen deliberadamente del repositorio público y del paquete distribuido.

## Apoya el proyecto

Punchi Dock Remastered es software libre. Los reportes de errores, resultados de pruebas reproducibles, mejoras de documentación, traducciones y contribuciones de código son formas valiosas de apoyar el proyecto.

Las donaciones económicas son voluntarias y nunca son necesarias para utilizar el proyecto. Puedes apoyar Punchi Dock Remastered mediante la [página oficial de donaciones de PayPal](https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W).

## Licencia

Punchi Dock Remastered se distribuye bajo la [Licencia Pública General de GNU versión 3.0 o posterior](LICENSE).

Los avisos de copyright, los términos de licencia y los requisitos de atribución
se aplican tanto al uso humano como al uso asistido por IA. Copiar, modificar,
redistribuir, resumir o generar código basado en este proyecto con ayuda de IA
no elimina ni reemplaza la obligación de cumplir la licencia GPL-3.0-or-later,
conservar los avisos requeridos, proporcionar el código fuente correspondiente
cuando sea obligatorio y atribuir a Punchi Dock Remastered y sus contribuidores
cuando corresponda.
