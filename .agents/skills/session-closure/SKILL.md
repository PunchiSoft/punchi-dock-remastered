---
name: session-closure
description: Procedimiento automático para finalizar la sesión, redactar la bitácora y empaquetar commits en Git. Activar cuando el usuario indique terminar el día, finalizar la sesión o preparar subida.
---

# Cierre de Sesión y Mantenimiento Git (session-closure)

Esta skill se activa cuando el usuario indica que la sesión de trabajo ha terminado (ej: "terminamos por hoy", "cierra la sesión", "prepara el código para subir", "haz la bitácora de cierre").

## Procedimiento de Cierre (Paso a Paso)

Cuando se solicite el cierre de sesión, el agente **debe ejecutar en orden estricto** los siguientes pasos:

1. **Revisión de Estado (Git Status)**
   - Ejecutar `git status` para analizar qué archivos han sido modificados, creados o borrados durante la sesión.

2. **Redacción de la Bitácora (`bitacora/`)**
   - Basándose en el historial de la conversación actual y en los archivos modificados, crear un nuevo archivo Markdown en la carpeta `bitacora/` con el formato `YYYY-MM-DD-resumen-de-sesion.md` o `YYYY-MM-DD-descriptor.md`.
   - El archivo debe detallar de forma técnica y profesional qué se logró en esta sesión (ej: refactorizaciones, corrección de bugs, nuevas funciones).
   - **Bloque Obligatorio de Métricas de Calidad y Validación**: Toda bitácora debe incluir la tabla/resumen con:
     * Versión del plasmoide (`metadata.json` y `CMakeLists.txt`).
     * Resultado exacto de la suite CTest (`38/38` o total activo).
     * Métricas del **Baseline de `qmllint`** (Total, Unqualified, Missing-Property, Layout, Import) confirmando la no introducción de deuda técnica.
     * Estado de los catálogos de traducción (`po/*.po` al 100% sin cadenas vacías ni difusas).
     * Resultado de la verificación de seguridad preflight.
     * Estado del gate de integridad de pruebas (`--check`): sin cambios en
       pruebas, o cambios autorizados indicando su motivo.

3. **Preparación del Entorno (Git Add)**
   - Añadir únicamente las rutas correspondientes al cambio que se está cerrando,
     con staging explícito: `git add <ruta1> <ruta2> ...`, y revisar después el
     diff preparado.
   - No usar `git add .`, `git add -A` ni `git add --all`: el staging global
     arrastra archivos ajenos al alcance del commit. Una lista fija de archivos
     tampoco sirve, porque el conjunto depende del cambio que se cierra.

4. **Commit Profesional**
   - Crear un mensaje de commit claro y semántico que resuma el trabajo realizado.
   - Ejecutar `git commit -m "feat/fix/docs: <Resumen general>"` según aplique.

5. **Subida (Git Push)**
   - Ejecutar `git push` para sincronizar los cambios con el repositorio remoto.

6. **Publicacion de version cuando sea explicita**
   - Si el usuario declara una version actual o solicita publicar una release,
     actualizar `metadata.json`, `CMakeLists.txt`, `CHANGELOG.md` y ejemplos de
     artefactos antes del commit.
   - Generar y validar al menos el artefacto de la distribucion actual.
   - Crear un tag anotado `v<version>` con titulo y resumen tecnico.
   - Subir el tag y crear la GitHub Release con notas y artefactos validados.
   - Si el usuario solo cierra una etapa sin declarar version, no crear tag ni
     release.

7. **Mensaje de Cierre y Reporte al Usuario**
   - Informar al usuario que la bitácora fue redactada y que los cambios están respaldados en Git.
   - **Presentar de forma explícita el resumen de Baseline, CTests, traducciones y versión** para que nunca se pierda en el hilo de conversación.

> [!IMPORTANT]
> Nunca uses git para subir archivos basura, logs o archivos `.plasmoid`. Confía en el `.gitignore` existente. Si hay dudas sobre un archivo grande o extraño detectado en el `git status`, detente y pregúntale al usuario antes de hacer el commit.
