---
name: plasmoid-packaging
description: "Revisar o modificar el empaquetado KPackage de Punchi Dock: metadata.json, estructura contents/, exclusiones, instalación local y artefactos .plasmoid. Usar para validar, instalar o preparar distribución; no usar para versionado Git o publicación de una release salvo como complemento de release."
---

# Empaquetado del plasmoide

## Procedimiento

1. Inspeccionar `metadata.json`, `contents/`, `.kpackageignore` y scripts reales del repositorio.
2. Consultar `kde-sdk/frameworks/kpackage/` y plantillas Plasma locales antes de añadir o retirar campos.
3. Verificar identificador, tipo de paquete, entrada QML, licencia, versión y compatibilidad declarada sin cambiarlos como efecto lateral.
4. Confirmar que archivos de desarrollo, SDK, documentación, logs y copias no entren al artefacto.
5. Instalar o validar con `kpackagetool6` cuando esté disponible; crear un `.plasmoid` solo si la tarea lo requiere.

## Reglas

- No asumir que campos heredados o ejemplos de otra versión son obligatorios.
- No elevar versiones mínimas ni cambiar el identificador sin autorización explícita.
- No escribir artefactos en una carpeta inventada; usar el flujo existente o una salida temporal claramente indicada.
- No afirmar que el paquete carga en Plasma si solo se verificó su estructura.

## Validación

- Validar JSON y rutas referenciadas.
- Inspeccionar la lista de archivos del paquete antes de distribuirlo.
- Ejecutar validación/instalación con `kpackagetool6` y una prueba de carga cuando el entorno lo permita.

## Criterios de aceptación

- La estructura coincide con KPackage y no contiene fuentes de desarrollo ajenas al plasmoide.
- La metadata describe las capacidades reales y conserva compatibilidad e identidad autorizadas.
- Se informa por separado validación estructural, instalación y prueba runtime.
