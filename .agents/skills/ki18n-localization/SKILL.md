---
name: ki18n-localization
description: Preparar y revisar textos traducibles de Punchi Dock con ki18n, incluidos contexto, pluralización, marcadores, extracción y catálogos. Usar al añadir o cambiar texto visible, mensajes al usuario o infraestructura de traducción; no usar para documentación interna que no forma parte de la interfaz.
---

# Localización con ki18n

## Procedimiento

1. Inspeccionar la infraestructura de traducción existente; no inventar directorios ni scripts ausentes.
2. Usar `i18n`, `i18nc` o `i18np` según significado, ambigüedad y pluralidad.
3. Sustituir concatenaciones por marcadores `%1`, `%2`, etc., preservando el orden traducible.
4. Mantener variables sin traducir en la capa lógica cuando la traducción deba reaccionar al idioma de la UI.
5. Si cambia la extracción, contrastar el patrón con `kde-sdk/frameworks/ki18n/` y plantillas Plasma locales.

## Reglas

- Traducir todo texto visible, incluidos tooltips, estados vacíos, errores y accesibilidad.
- Añadir contexto cuando una palabra aislada pueda tener varios significados.
- No usar una variable como cadena de formato traducible.
- No modificar traducciones existentes ni crear catálogos sin revisar el flujo real del proyecto.

## Validación

- Buscar texto visible nuevo sin envolver y concatenaciones alrededor de llamadas i18n.
- Ejecutar el mecanismo de extracción existente cuando esté disponible.
- Probar marcadores, plural singular/plural y textos más largos en la interfaz cuando aplique.

## Criterios de aceptación

- Las cadenas son extraíbles, tienen contexto suficiente y no dependen del orden del idioma fuente.
- Los cambios respetan la ubicación y herramientas reales del proyecto.
