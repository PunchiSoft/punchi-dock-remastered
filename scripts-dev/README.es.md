# Scripts para desarrolladores

[English](README.md) | [Español](README.es.md)

Esta carpeta contiene el flujo estricto de mantenimiento del proyecto. No es
el camino normal de instalación para una persona usuaria.

La entrada principal de desarrollo es:

```bash
./scripts-dev/setup.sh
```

Detecta Fedora o sistemas de la familia Debian, puede preparar dependencias de
la distribución, ejecuta `qmllint`, configura CMake con `BUILD_TESTING=ON`,
ejecuta la suite CTest completa, crea el paquete y puede instalarlo para una
prueba local de runtime.

Comandos comunes:

```bash
./scripts-dev/setup.sh --local-test
./scripts-dev/setup.sh --clean-install
./scripts-dev/setup.sh --dependencies-only
./scripts-dev/check-build-environment.sh
./scripts-dev/update-translations.sh
./scripts-dev/validar-empaquetado-limpio.sh
./scripts-dev/watch-plasmoidviewer.sh
```

## Estructura

- `setup.sh`: orquestador estricto e interactivo para desarrollo.
- `distro/`: perfiles de desarrollo Fedora y Debian 13.
- `lib/`: helpers exclusivos de logs, prueba local, versión de Plasma y
  qmllint.
- `qmllint*.py` y `qmllint-baseline*.env`: herramientas y perfiles de deuda
  estática.
- `instalar-plasmoide.sh`: selector de paquetes generados localmente.

El flujo de desarrollo reutiliza el motor compartido
`scripts-user/lib/package-plasmoid.sh` con validación completa. El flujo para una
persona normal está documentado en
[scripts-user/README.es.md](../scripts-user/README.es.md).
