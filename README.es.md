# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="160" alt="Logo de Punchi Dock Remastered">
</p>

<p align="center">
  <a href="https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.41">
    <img src="https://img.shields.io/badge/release-v0.9.7.41-4caf50" alt="Versión v0.9.7.41">
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
[v0.9.7.41](https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.41).

## Novedades de la versión 0.9.7.41

- **Animación en Cascada en Popups de Carpetas (`FolderPopup`)**: Apertura escalonada secuencial de las aplicaciones contenidas con retardo indexado dinámico y amortiguación elástica.
- **Elevación Táctil Interactiva**: Microinteracción fluida en hover (`1.04x`) y respuesta a la presión (`0.95x`) con cursores de mano en cada elemento de la carpeta.
- **100% Validado**: Suite CTest completa aprobada (38/38) y catálogos de traducción al 100%.

Consulta el [changelog de la versión 0.9.7.41](CHANGELOG.md#09741---2026-08-17) para
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
- Carpetas configurables con vistas de rejilla, lista y detalle, además de notas rápidas, papelera, separadores y calendario.
- Lanzador de aplicaciones PunchiMenu con modos Normal y Pantalla completa,
  búsqueda, categorías, favoritos, carpetas de aplicaciones con nombre,
  ocultación selectiva, operación por teclado, atajo global y acciones de
  sesión nativas. Compacto queda reservado para una versión futura.
- Visualizador de audio PipeWire opcional con seis estilos, colores dinámicos o del tema Plasma y hasta 48 elementos visuales.
- Popups adaptados al tema de Plasma con animaciones de apertura configurables, transiciones fluidas entre miniaturas y menús, y retargeting continuo entre elementos del dock.
- Acciones nativas de aplicacion y ventana en los menus contextuales de launchers fijados y tareas dinamicas.
- Badges opcionales de conteo para aplicaciones agrupadas con varias ventanas.
- Tarjetas multimedia MPRIS contextuales con caratula, informacion de pista, controles de reproduccion y una accion accesible para silenciar o restaurar el volumen en todos los formatos de tarjeta.
- Item MPRIS compacto para el dock con reproductor seleccionable, fallback de caratula, modos de texto vertical y apertura seguida de Play.
- Controles circulares de color Plasma/personalizado y separacion configurable entre iconos con unidades visuales explicitas.
- Arrastre seguro de archivos hacia aplicaciones fijadas y la Papelera, además de acciones de desanclado adaptadas a aplicaciones y carpetas.
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
- Wayland es la sesión principal soportada.
- PipeWire es necesario para el visualizador de audio opcional.
- Fedora 44 `x86_64` es el objetivo principal de paquetes precompilados. Debian 13 cuenta con un flujo separado de compilación, instalación y arranque validado; su revisión funcional completa sigue en curso.
- Kubuntu dispone de un perfil de compilación e instalación local validado en Plasma 6.6.4. El módulo nativo debe seguir compilándose dentro de Kubuntu; esto no vuelve compatible un artefacto generado en otra distribución.
- Usuarios de la comunidad reportan funcionamiento correcto en otras distribuciones Linux actuales con Plasma 6. Estos reportes indican una compatibilidad más amplia, pero todavía no equivalen a un perfil de distribución validado por el proyecto.
- La compilación requiere CMake 3.22+, un compilador C++20, Qt 6.6+, ECM/KF6 6.0+, Plasma 6.0+ y archivos de desarrollo de PipeWire, todos proporcionados por una pila coherente de la distribución.
- Los binarios nativos incluidos en cada `.plasmoid` no son universales: debe usarse el artefacto etiquetado para la distribución donde fue compilado.

La compatibilidad distingue Fedora como objetivo principal de publicación,
Debian como perfil validado por separado, Kubuntu como perfil validado de
compilación nativa y las demás distribuciones como reportes comunitarios. Una
distribución actual puede compilar y ejecutar Punchi Dock sin cambios, pero
necesita una compilación y baseline compatibles. No mezcles repositorios ni
reemplaces la pila Qt/KDE del sistema únicamente para alcanzar estas versiones.

## Instalar un paquete publicado

El usuario final debe instalar un paquete `.plasmoid` ya construido para la plataforma soportada. No necesita paquetes de desarrollo ni un compilador.

El objetivo actual del paquete publicado es Fedora 44+ `x86_64` con KDE Plasma 6 o posterior.

En Fedora, `kpackagetool6` pertenece a `kf6-kpackage` y normalmente ya está disponible en una instalación de Plasma:

```bash
sudo dnf install kf6-kpackage
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-0.9.7.41-fedora44-x86_64.plasmoid
```

Para actualizar una instalación existente:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-0.9.7.41-fedora44-x86_64.plasmoid
```

Cierra y vuelve a iniciar sesión, o reinicia Plasma Shell, si el plasmoide actualizado no se carga inmediatamente.

## Compilar desde fuentes

El árbol de fuentes contiene un módulo QML nativo en C++. Instalar directamente el directorio del repositorio con `kpackagetool6` no compila ese módulo.

Comprueba el entorno de desarrollo local antes de instalar o cambiar paquetes:

```bash
scripts/check-build-environment.sh
```

El comprobador informa la distribución, arquitectura y versiones de Plasma, CMake y `qmllint`. Qt 6.11 es el perfil principal de lint y Qt 6.8 dispone de un perfil de compatibilidad separado porque sus diagnósticos difieren. `qmllint` es una herramienta de desarrollo, no una dependencia de ejecución para quien instala un `.plasmoid` precompilado compatible; un fallo de lint con Qt 6.8 por sí solo no demuestra que el dock no pueda ejecutarse en ese sistema.

Usa los paquetes de desarrollo Qt 6, KF6 y Plasma suministrados por la distribución. No reemplaces la pila Qt del sistema con una instalación independiente de Qt 6.11 solo para igualar el perfil principal de lint, porque el módulo nativo debe compilarse contra una pila coherente de la distribución.

En Fedora 44+, instala las dependencias de compilación:

```bash
sudo dnf install \
    binutils cmake gcc-c++ ninja-build extra-cmake-modules \
    qt6-qtdeclarative-devel \
    kf6-kconfig-devel kf6-kcoreaddons-devel kf6-kglobalaccel-devel kf6-kio-devel kf6-kjobwidgets-devel \
    kf6-kservice-devel kf6-kwindowsystem-devel libplasma-devel plasma-workspace-devel \
    pipewire-devel gettext \
    zip unzip
```

En Debian o Kubuntu deben instalarse los paquetes de desarrollo de la propia
distribución para Qt 6, KF6, Plasma, PipeWire, ECM, CMake, gettext y ZIP. El
wrapper Debian fue validado en Debian 13 con Qt 6.8.2; el flujo de compilación,
instalación, arranque y funcionamiento de Kubuntu fue validado en Plasma 6.6.4.

Compila el módulo nativo y crea el artefacto utilizando el script maestro de setup:

```bash
scripts/setup.sh
```

Or para generación automática no interactiva del paquete universal:

```bash
scripts/setup-universal.sh
```

```text
dist/punchi-dock-remastered-<versión>-<distribución>-<arquitectura>.plasmoid
```

La release 0.9.7.41 de GitHub ofrece
`punchi-dock-remastered-0.9.7.41-fedora44-x86_64.plasmoid`. Los artefactos
universales se publican por separado únicamente después de completar su
compilación en Debian 13 y su validación entre distribuciones.
No instales un artefacto identificado para otra distribución.

El flujo Debian 13 fue comprobado por separado de Debian 14/testing. Kubuntu
registra un baseline local independiente y superó compilación, instalación,
arranque y validación funcional del usuario en Plasma 6.6.4. Consulta
[scripts/README.es.md](scripts/README.es.md) para conocer las opciones de cada setup y
distinguir artefactos públicos, instalación local y validación limpia.

Define `PACKAGE_BUILD_TYPE` o `STRIP_BIN` solo cuando un flujo de desarrollo necesite reemplazarlos explícitamente. No uses `PACKAGE_OUTPUT_FILE` para poner una etiqueta Debian a un binario Fedora ni uses compilación cruzada para publicar el módulo QML nativo.

Para compilar, instalar y reiniciar Plasma durante una prueba local en Fedora:

```bash
scripts/setup-fedora.sh --local-test
```

En una instalación limpia de Kubuntu, prepara las dependencias APT oficiales y
crea el paquete nativo con:

```bash
scripts/setup-kubuntu.sh --yes
```

Añade `--local-test` para instalar el resultado y reiniciar Plasma Shell. El
script debe ejecutarse como usuario del escritorio; solicita `sudo` solo para
APT.

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
