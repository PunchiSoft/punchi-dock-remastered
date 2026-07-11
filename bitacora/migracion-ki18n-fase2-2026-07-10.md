# Bitácora: migración a ki18n nativo en configuración

Fecha: 2026-07-10

## Trabajo realizado

- Se retiró el diccionario manual `i18n.js` de la configuración.
- Se eliminaron `languageMode: "es"` y los imports residuales del sistema manual.
- Los componentes de configuración que dependían de `controller.i18n(...)` o `page.i18n(...)` pasaron a usar `i18n(...)` nativo de QML/KDE.
- Se normalizaron a inglés las cadenas base todavía escritas en español dentro del KCM y sus categorías.
- Se ajustaron diálogos auxiliares para que sus textos por defecto también entren al flujo de traducción nativo.

## Archivos relevantes

- [contents/ui/config/ConfigItems.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigItems.qml:1)
- [contents/ui/config/ConfigFiles.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigFiles.qml:1)
- [contents/ui/config/ConfigGeneral.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigGeneral.qml:1)
- [contents/config/config.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/config/config.qml:1)

## Resultado

- La configuración ya no depende de un diccionario JavaScript fijo en español.
- El texto fuente del KCM queda preparado para el flujo estándar de traducción de KDE.
- En ausencia de catálogos compilados, el comportamiento esperado ahora es mostrar la configuración en inglés.

## Validación pendiente

- Confirmar en Plasma que `i18n(...)` con parámetros siga resolviendo correctamente en tiempo de ejecución.
- Completar una pasada futura para revisar otras cadenas fuente fuera del KCM principal si se decide extender la migración al resto del plasmoide.

## Cierre de fase

- Se completó una pasada adicional sobre strings visibles fuera del KCM principal.
- No se detectaron más cadenas visibles en español que bloquearan esta fase; lo restante en español corresponde a comentarios internos.
- Se documentó en `README.md` que el idioma fuente del proyecto es inglés y que la infraestructura de catálogos sigue pendiente.
- Se corrigió el último uso relevante del patrón antiguo `"%1".replace(...)` en `ItemActionEditor.qml` para usar `i18n("%1 rows", value)` directamente.
- Se revisaron `configItems.js` y `configUi.js`; no fue necesario cambiar su arquitectura en esta fase porque ya delegan correctamente las cadenas visibles al lado QML o reciben funciones de traducción.
