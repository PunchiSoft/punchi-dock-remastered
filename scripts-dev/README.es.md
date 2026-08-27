# Scripts para desarrolladores

[English](README.md) | [Español](README.es.md)

Esta carpeta contiene el flujo estricto de mantenimiento del proyecto. No es
el camino normal de instalación para una persona usuaria.

La entrada principal de desarrollo es:

```bash
./scripts-dev/setup.sh
```

Detecta Fedora o sistemas de las familias Debian y Arch, puede preparar
dependencias de la distribución, ejecuta `qmllint`, configura CMake con
`BUILD_TESTING=ON`, ejecuta la suite CTest completa, crea el paquete y puede
instalarlo para una prueba local de runtime.

Comandos comunes:

```bash
./scripts-dev/setup.sh --local-test
./scripts-dev/setup.sh --local-test -j 1       # Modo seguro para máquinas virtuales o poca RAM
./scripts-dev/setup.sh --local-test --jobs 8  # Modo rápido con 8 hilos en paralelo
./scripts-dev/setup.sh --clean-install
./scripts-dev/setup.sh --dependencies-only
./scripts-dev/setup.sh --lang es --help
./scripts-dev/check-build-environment.sh
./scripts-dev/update-translations.sh
./scripts-dev/validar-empaquetado-limpio.sh
./scripts-dev/watch-plasmoidviewer.sh
```

## Estructura

- `setup.sh`: orquestador estricto e interactivo para desarrollo.
- `distro/`: perfiles de desarrollo Fedora, Debian 13 y familia Arch.
- `lib/`: helpers exclusivos de logs, prueba local, versión de Plasma y
  qmllint.
- `qmllint*.py` y `qmllint-baseline*.env`: herramientas y perfiles de deuda
  estática.
- `instalar-plasmoide.sh`: selector de paquetes generados localmente.

El flujo de desarrollo reutiliza el motor compartido
`scripts-user/lib/package-plasmoid.sh` con validación completa. El flujo para una
persona normal está documentado en
[scripts-user/README.es.md](../scripts-user/README.es.md).

El asistente detecta inglés, español, alemán y portugués brasileño desde el
locale de la sesión. Se puede usar `--lang en`, `--lang es`, `--lang de` o
`--lang pt_BR` para sustituirlo. La selección de idioma solo cambia los
mensajes del asistente; los gates estrictos de `qmllint`, CTest, traducciones y
empaquetado permanecen activos.

El perfil Arch instala solamente paquetes de los repositorios oficiales ya
configurados mediante `pacman -Syu --needed`; no usa AUR ni habilita
repositorios. Como Arch es rolling release, su baseline estricto de cero
advertencias de `qmllint` debe confirmarse con la versión Qt real de esa
máquina antes de considerar validado el artefacto. `--skip-pacman` permite
verificar sin instalar paquetes.
