---
name: plasmoid-packaging
description: "Revisar o modificar el empaquetado KPackage de Punchi Dock: metadata.json, estructura contents/, exclusiones, instalación local y artefactos .plasmoid. Usar para validar, instalar o preparar distribución; no usar para versionado Git o publicación de una release salvo como complemento de release."
---

# Empaquetado del plasmoide

## Objetivo

Probar que el KPackage contiene exactamente lo autorizado, puede instalarse y
actualizarse de forma controlada, y que el mismo artefacto funciona en los
entornos cuya compatibilidad se anuncia. Separar estructura, instalacion y
runtime: ninguna de esas evidencias implica automaticamente las otras.

## Procedimiento

1. Inspeccionar `metadata.json`, `contents/`, `.kpackageignore` y scripts reales del repositorio.
2. Consultar `kde-sdk/frameworks/kpackage/` y plantillas Plasma locales antes de añadir o retirar campos.
3. Verificar identificador, tipo de paquete, entrada QML, licencia, versión y compatibilidad declarada sin cambiarlos como efecto lateral.
4. Confirmar que archivos de desarrollo, SDK, documentación, logs y copias no entren al artefacto.
5. Instalar o validar con `kpackagetool6` cuando esté disponible; crear un `.plasmoid` solo si la tarea lo requiere.

El patron oficial local para aislar rutas, validar `main.qml`, listar entradas y
comprobar el hash del contenido vive en
`kde-sdk/frameworks/plasma-framework/autotests/plasmoidpackagetest.cpp`.
Consultarlo como referencia, sin asumir que el snapshot cambia el minimo
declarado.

## Reglas

- No asumir que campos heredados o ejemplos de otra versión son obligatorios.
- No elevar versiones mínimas ni cambiar el identificador sin autorización explícita.
- No escribir artefactos en una carpeta inventada; usar el flujo existente o una salida temporal claramente indicada.
- No afirmar que el paquete carga en Plasma si solo se verificó su estructura.
- **Empaquetado Universal (`.plasmoid` de Publicación)**:
  - Todo `.plasmoid` universal para distribución oficial **debe compilarse en Debian 13 (Trixie)** con la versión Qt del entorno oficial, observada como Qt 6.8.2 el 2026-08-05. Registrar la versión efectiva y validar el mismo artefacto en cada distribución objetivo; no inferir compatibilidad binaria únicamente por compartir la versión mayor Qt 6.
  - La carpeta `contents/ui/org/punchi/dock/compat/` **debe contener archivos binarios C proxy `.so` reales** compilados con `-Wl,-soname,<nombre.so.6>` y constructor `dlopen()`.
  - **PROHIBIDO usar enlaces simbólicos (symlinks) en `compat/` dentro del archivo zip**: El gestor gráfico de paquetes de KDE Plasma (`KZip`) elimina silenciosamente los symlinks al descomprimir por razones de seguridad, dejando la carpeta vacía.

## Seleccion de entorno

- **Podman/Docker:** build limpio, dependencias, CTest, `qmllint`, catalogos,
  reproducibilidad e inventario del paquete. Compartir kernel o display con el
  host no demuestra una sesion Plasma aislada.
- **Plasma anidado:** integracion automatizada con shell, compositor y DBus
  cuando esos procesos pertenecen realmente a la sesion anidada.
- **Maquina virtual:** instalacion, actualizacion, compatibilidad del sistema y
  sesion Plasma completa con aislamiento.
- **Equipo fisico:** validacion final de GPU, pantallas, escalado, rendimiento y
  comportamiento cotidiano.

Docker o Podman complementan una VM; no la reemplazan para probar un plasmoide
completo. Para planificar la frecuencia y el dominio, leer la
[matriz compartida de pruebas](../testing/references/test-matrix.md).

## Validación

- Validar JSON y rutas referenciadas.
- Inspeccionar la lista de archivos del paquete (`unzip -l`) antes de distribuirlo y confirmar que los archivos en `compat/` sean binarios ELF de ~11-14 KB y posean cabecera `DT_SONAME`.
- Comprobar que el paquete no contenga `docs/`, `bitacora/`, `.agents/`, SDK,
  tests, logs, backups, caches, rutas personales ni binarios inesperados.
- Registrar hash, tamaño, inventario, distribucion y versiones efectivas del
  entorno que produjo el artefacto.
- Ejecutar validación/instalación con `kpackagetool6` y una prueba de carga
  cuando el entorno lo permita.
- Antes de release, probar instalacion limpia y actualizacion desde la version
  publica anterior, conservando configuracion, lanzadores, carpetas y
  preferencias.
- Probar el mismo archivo y verificar su hash en cada distribucion objetivo;
  una recompilacion por destino prueba fuentes, no portabilidad del artefacto.
- Un fallo de paquete o actualizacion debe terminar sin instalacion parcial y
  conservar una ruta de recuperacion. No probar desinstalacion destructiva ni
  borrar configuracion personal sin autorizacion explicita.

## Criterios de aceptación

- La estructura coincide con KPackage y no contiene fuentes de desarrollo ajenas al plasmoide.
- La metadata describe las capacidades reales y conserva compatibilidad e identidad autorizadas.
- El artefacto oficial fue construido en el entorno canonico y se identifica
  por hash durante toda la matriz.
- La actualizacion conserva el estado persistido cuando forma parte del
  alcance de release.
- Se informa por separado validacion estructural, build en contenedor,
  instalacion, actualizacion y prueba runtime en Plasma.
