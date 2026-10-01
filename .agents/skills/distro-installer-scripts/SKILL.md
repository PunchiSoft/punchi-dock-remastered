---
name: distro-installer-scripts
description: Crear, ordenar o refactorizar scripts por distribucion para compilar, empaquetar, instalar y probar Punchi Dock, incluidos chequeo de dependencias, artefactos publicables y artefactos local-test.
---

# Scripts por Distribucion

Usar esta skill cuando el usuario pida un script de instalacion, preparacion,
compilacion o prueba para una distribucion concreta.

## Politica

- Mantener `scripts-user/setup.sh` como entrada publica sencilla: compilar,
  empaquetar, instalar y reiniciar Plasma sin ejecutar pruebas de desarrollo.
- Mantener los orquestadores y perfiles estrictos dentro de `scripts-dev/`;
  los perfiles por distribucion viven en `scripts-dev/distro/`.
- El flujo de desarrollo debe cubrir, por opciones:
  1. detectar distribucion, version y arquitectura;
  2. verificar dependencias requeridas del plasmoide;
  3. informar paquetes faltantes y el comando sugerido de instalacion;
  4. empaquetar un artefacto publicable sin sufijo `local-test` cuando el
     usuario lo decida;
  5. empaquetar un artefacto de prueba con sufijo `local-test` cuando se vaya a
     instalar en el entorno;
  6. instalar el artefacto de prueba con `kpackagetool6`;
  7. reiniciar Plasma Shell;
  8. recoger diagnosticos locales;
  9. ordenar los artefactos publicables por version cuando el usuario lo pida.
- Mantener el nucleo comun de empaquetado en
  `scripts-user/lib/package-plasmoid.sh` y la instalacion de pruebas en
  `scripts-dev/lib/install-local-test.sh`; evitar duplicar zip, traducciones,
  tests, staging, instalacion y reinicio.
- Los scripts historicos pueden quedar como wrappers de compatibilidad, pero no
  deben ser el camino principal si confunden al usuario.

## Dependencias

- Antes de instalar o compilar, leer las dependencias reales desde los scripts y
  CMake del plasmoide: `CMakeLists.txt`, `src/CMakeLists.txt`,
  `scripts-user/lib/package-plasmoid.sh` y wrappers existentes.
- `scripts-dev/check-build-environment.sh` debe ser el lugar principal para
  diagnosticar faltantes y sugerir comandos de instalacion. No debe instalar ni
  usar `sudo`.
- Los scripts de setup por distribucion pueden instalar dependencias solo si el
  usuario lo pidio o eligio una opcion que lo implica.
- Para Debian 13/14 limpio, conservar como referencia minima los paquetes:
  `binutils`, `build-essential`, `cmake`, `extra-cmake-modules`, `gettext`,
  `git`, `kpackagetool6`, `libkf6coreaddons-dev`, `libkf6i18n-dev`,
  `libkf6jobwidgets-dev`, `libkf6kio-dev`, `libkf6service-dev`,
  `libpipewire-0.3-dev`, `libplasma-dev`, `ninja-build`, `pkg-config`,
  `qt6-base-dev`, `qt6-base-dev-tools`, `qt6-declarative-dev`,
  `qt6-declarative-dev-tools`, `qt6-qmltooling-plugins`, `unzip` y `zip`.

## Artefactos

- Publicable: `dist/punchi-dock-remastered-<version>-<distro>-<arch>.plasmoid`.
- Prueba local:
  `dist/punchi-dock-remastered-<version>-<distro>-<arch>-local-test.plasmoid`.
- No subir ni presentar el artefacto `local-test` como publicable.
- Si el usuario pide ambos, generar primero el publicable y despues el
  `local-test` para instalar/probar.
- Para preparar subida a KDE Store, permitir un modo que copie o mueva los
  artefactos publicables a `dist/<version>/`, por ejemplo `dist/0.8.9/`.
- La carpeta por version no debe contener paquetes `local-test`, logs, builds ni
  otros artefactos de prueba.

## Validacion

- Ejecutar `bash -n` sobre scripts Bash modificados.
- Ejecutar `--help` cuando exista.
- Ejecutar `git diff --check`.
- En la distro objetivo, validar al menos: `qmllint`, build nativo, `ctest`,
  creacion del paquete, instalacion con `kpackagetool6`, reinicio de Plasma y
  diagnosticos.
- Documentar por separado lo que fue validado en el host actual y lo que queda
  pendiente en la distribucion objetivo.
