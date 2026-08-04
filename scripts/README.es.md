# Scripts de Empaquetado y Setup

[English](README.md) | [Español](README.es.md)

## Asistente Maestro de Setup (`scripts/setup.sh`)

El punto principal de entrada para compilar, probar, instalar y administrar Punchi Dock Remastered es:

```bash
scripts/setup.sh
```

Al ejecutar `scripts/setup.sh` sin argumentos, se despliega un **menú interactivo en terminal** que detecta automáticamente tu distribución anfitriona (Fedora o Debian 13).

```text
==========================================================
   Punchi Dock Remastered - Asistente Maestro de Setup    
==========================================================
Sistema detectado: Fedora Linux 44 (x86_64)

¿Qué deseas hacer?
  [1] Compilar paquete de versión oficial (Release en dist/)
  [2] Compilar, instalar y probar localmente (--local-test)
  [3] Instalar un paquete .plasmoid ya existente desde dist/
  [4] Instalación limpia (eliminar actual + recompilar + instalar)
  [5] Verificar e instalar dependencias de compilación
  [6] Desinstalar el plasmoide de este sistema
  [7] Ayuda (ver referencia de comandos CLI)
  [8] Salir
```

### Auto-Detección de Idioma y Anulación (`PUNCHI_LANG`)

El asistente detecta automáticamente la configuración regional del sistema (`LC_ALL` / `LC_MESSAGES` / `LANG`). También puedes forzar un idioma específico usando `PUNCHI_LANG`:

```bash
PUNCHI_LANG=es ./scripts/setup.sh    # Forzar interfaz en Español
PUNCHI_LANG=en ./scripts/setup.sh    # Forzar interfaz en Inglés
```

### Modo de Banderas CLI Directas

Puedes enviar banderas directamente para automatización en terminal, scripts de desarrollo o CI:

```bash
# Compilar e instalar de inmediato para pruebas locales en tu escritorio
scripts/setup.sh --local-test

# Instalación limpia: elimina la instalación actual, borra la caché de compilación, recompila e instala
scripts/setup.sh --clean-install

# Verificar e instalar dependencias de compilación requeridas (DNF/APT) sin compilar
scripts/setup.sh --dependencies-only

# Desinstalar el plasmoide del entorno de escritorio Plasma local
scripts/setup.sh --uninstall

# Responder afirmativamente de forma automática a los gestores DNF/APT
scripts/setup.sh --yes --local-test

# Modo simulación: previsualizar comandos planificados sin modificar el sistema
scripts/setup.sh --dry-run

# Mostrar la ayuda completa y referencia de opciones del comando
scripts/setup.sh --help

# Instalar directamente un paquete .plasmoid ya construido sin volver a compilar
scripts/setup.sh dist/punchi-dock-remastered-0.9.5-universal.plasmoid
```

---

## Matriz de Distribución y Artefactos

| Distribución Anfitriona | Perfil de Destino | Artefacto de Salida Generado |
|---|---|---|
| **Fedora 44+** (`x86_64`) | Fedora Nativo | `dist/punchi-dock-remastered-<version>-fedora44-x86_64.plasmoid` |
| **Debian 13 (Trixie)** (`x86_64`) | KDE Store Universal | `dist/punchi-dock-remastered-<version>-universal.plasmoid` *(Con redirección dinámica `$ORIGIN/compat`)* |
| **Prueba Local (Cualquier host)** | Test Local de Distro | `dist/punchi-dock-remastered-<version>-<distro>-x86_64-local-test.plasmoid` |

---

## Sistema de Registro Persistente de Log

Todas las ejecuciones de `scripts/setup.sh` (interactivas o CLI) canalizan su salida mediante `scripts/lib/setup-logging.sh` (`punchi_run_setup_with_log`).

Los archivos de log se guardan en:
```text
docs/logs/<distribución>/
```

- **Log con marca de tiempo**: `setup-<distro>-YYYYMMDD-HHMMSS.log`
- **Última ejecución**: `setup-<distro>-latest.log`

---

## Diagnóstico del Entorno de Compilación

Para diagnosticar las librerías del sistema, Qt 6, KDE Frameworks 6 y la línea base de `qmllint` sin modificar el sistema:

```bash
scripts/check-build-environment.sh
```

---

## Herramientas Útiles de Desarrollo (`scripts/dev/`)

- `scripts/dev/instalar-plasmoide.sh`: Selector interactivo para instalar paquetes `.plasmoid` vigentes desde `dist/`.
- `scripts/dev/validar-empaquetado-limpio.sh`: Realiza una compilación y validación temporal limpia sin instalar.
- `scripts/dev/update-translations.sh`: Regenera plantillas POT y actualiza catálogos PO en `po/`.
- `scripts/dev/watch-plasmoidviewer.sh`: Ayuda a previsualizar la UI en `plasmoidviewer`.

---

## Organización Interna y Árbol de Scripts

- `scripts/setup.sh`: Script maestro interactivo y CLI con i18n (Inglés/Español).
- `scripts/setup-universal.sh`: Instalador de paquetes `.plasmoid` precompilados.
- `scripts/distro/`: Perfiles por distribución (`fedora-setup.sh`, `debian13-setup.sh`, etc.).
- `scripts/lib/`: Motores de compilación e instalación compartidos (`package-plasmoid.sh`, `install-local-test.sh`, `local-package-install.sh`, `setup-logging.sh`).
- `scripts/dev/`: Herramientas auxiliares de desarrollo y diagnóstico.
