---
name: ki18n-localization
description: Activa esta skill para tareas de internacionalización (i18n), extracción de cadenas de texto traducibles y configuración del sistema de idiomas para el plasmoide utilizando ki18n.
---

# Localization (ki18n) Skill

## Instrucciones Detalladas
Para asegurar que Punchi Task Manager pueda ser utilizado por usuarios de distintos idiomas, todas las cadenas de texto visibles en la UI deben ser preparadas para traducción.
1. En QML y JS, utiliza siempre la función `i18n("Texto a traducir")` o sus variantes (`i18nc`, `i18np`, etc.) proporcionadas por el framework de Plasma.
2. Extrae y mantén los archivos de plantillas de traducción (`.pot` y `.po`) en el directorio `Localization/`.
3. No hardcodees ningún string directamente en los archivos QML si está destinado a ser visto por el usuario.

## Checklist
- [ ] ¿Todos los textos visibles están envueltos en `i18n()` o equivalente?
- [ ] ¿Se han documentado contextos (`i18nc`) para traducciones que puedan ser ambiguas?
- [ ] ¿Están actualizados los archivos `.pot` o los scripts de extracción tras agregar nuevos strings?
- [ ] ¿Se están respetando las convenciones de pluralización (`i18np`)?

## Buenas Prácticas
- Usar marcadores de posición (`%1`, `%2`) en lugar de concatenación de strings para las variables.
- Añadir comentarios para los traductores en los casos donde la interfaz tenga un comportamiento muy específico.

## Errores Comunes
- **Concatenar cadenas**: Evitar `i18n("Cargando ") + item`. En su lugar, usa `i18n("Cargando %1", item)`. La concatenación rompe el orden de las palabras en diferentes idiomas.
- **Traducciones en el backend JS antes de tiempo**: Retornar strings traducidos desde el JS hacia el QML a veces provoca problemas al cambiar el idioma en caliente. Lo ideal es pasar las variables y que QML traduzca.

## Criterios de Aceptación
- Ninguna cadena de texto quemada (hardcoded) es visible en la UI.
- Los archivos `.pot`/`.po` se pueden generar o actualizar sin errores usando herramientas estándar (`xgettext` o integraciones de cmake).
