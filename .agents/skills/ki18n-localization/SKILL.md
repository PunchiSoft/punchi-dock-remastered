---
name: ki18n-localization
description: Preparar y revisar textos traducibles de Punchi Dock con ki18n, incluidos contexto, pluralización, marcadores, extracción y catálogos. Usar siempre que se añada, cambie o retire cualquier texto visible, menú, label, botón, tooltip, placeholder, error, estado o mensaje accesible, y al modificar la infraestructura de traducción; no usar para documentación interna ajena a la interfaz.
---

# Localización con ki18n

## Procedimiento

1. Inspeccionar la infraestructura de traducción existente; no inventar directorios ni scripts ausentes.
2. Escribir siempre el texto fuente del runtime en inglés, aunque la solicitud o las instrucciones estén en español.
3. Usar `i18n`, `i18nc` o `i18np` según significado, ambigüedad y pluralidad; usar las variantes con dominio para mensajes propios del módulo C++.
4. Sustituir concatenaciones por marcadores `%1`, `%2`, etc., preservando el orden traducible.
5. Mantener variables sin traducir en la capa lógica cuando la traducción deba reaccionar al idioma de la UI.
6. Ejecutar `scripts-dev/update-translations.sh` después de añadir, cambiar o retirar cualquier texto visible.
7. Actualizar todos los PO soportados y no dejar mensajes nuevos vacíos, obsoletos por descuido ni difusos.
8. Si cambia la extracción o el empaquetado, contrastar el patrón con `kde-sdk/frameworks/ki18n/`, `kde-sdk/frameworks/kpackage/` y plantillas Plasma locales.

## Reglas

- Traducir todo texto visible, incluidos tooltips, estados vacíos, errores y accesibilidad.
- Mantener en inglés identificadores, comentarios, mensajes de log, errores fuente, nombres y mensajes de pruebas, salidas de scripts y todos los `msgid`.
- No escribir labels españoles ni traducciones inline en QML, JavaScript o C++; conservarlas en `po/<idioma>.po`.
- Permitir campos localizados inline solo cuando el formato los defina expresamente, como `Name[es]` y `Description[es]` de `metadata.json`.
- Si se encuentra texto fuente del runtime en otro idioma, convertirlo a inglés y trasladar su traducción al catálogo correspondiente.
- Añadir contexto cuando una palabra aislada pueda tener varios significados.
- No usar una variable como cadena de formato traducible.
- No modificar traducciones existentes ni crear catálogos sin revisar el flujo real del proyecto.
- No declarar soporte para un idioma con entradas vacías o difusas.
- Empaquetar los MO en `contents/locale/<idioma>/LC_MESSAGES/`; KPackage no descubre `locale/` en la raíz.
- Mantener la documentación interna en el idioma establecido por cada documento; no confundirla con texto fuente de la interfaz.

### Prevención de Desplazamiento y Contaminación Semántica (PO Integrity)

- **Integridad de Alineación**: Prohibido editar catálogos `.po` mediante expresiones regulares globales o reemplazos por número de línea. Las modificaciones deben realizarse por bloque completo (`msgid` + `msgstr`) o usando `msgmerge` para sincronizar con la plantilla `.pot`.
- **Prevención de Contaminación Semántica**: Evitar traducir un `msgid` con palabras que empiecen por la misma cadena exacta del texto inglés si ello activa el detector de `translation_catalog_semantics.py` (ejemplo: preferir `"Reducido"` sobre `"Compacto"` para `msgid "Compact"`, `"Agenda"` sobre `"Calendario"` para `msgid "Calendar"`, `"Embellecer"` sobre `"Formato"` para `msgid "Format"`).
- **Recuperación segura**: Ante sospecha de corrupción o desalineación masiva, no depender de una ruta de respaldo fija: recuperar desde una fuente conocida y versionada (`po/` está bajo control de versiones) y regenerar los catálogos con el procedimiento real del proyecto, que `Messages.sh` y `scripts-dev/update-translations.sh` aplican con `msgmerge --previous`, validando después con `msgfmt --check --check-format`.

## Validación

- Buscar texto visible nuevo sin envolver y concatenaciones alrededor de llamadas i18n.
- Ejecutar `scripts-dev/update-translations.sh` y revisar el diff del POT y de todos los PO.
- Ejecutar `msgfmt --check --check-format` sobre cada catálogo soportado.
- Ejecutar `python3 tests/translation_catalog_semantics.py --check po/es.po po/pt_BR.po po/de.po`.
- Ejecutar `ctest -R translation_catalog_test` y el flujo de empaquetado cuando cambien textos o catálogos.
- Comprobar que el `.plasmoid` contiene los MO en `contents/locale/` y no distribuye PO/POT.
- Probar marcadores, plural singular/plural y textos más largos en la interfaz cuando aplique.

## Criterios de aceptación

- Las cadenas son extraíbles, tienen contexto suficiente y no dependen del orden del idioma fuente.
- Todos los mensajes fuente están en inglés y cada idioma soportado está completo y sin difusos.
- Todo cambio visible queda reflejado en el POT y los catálogos soportados.
- Los cambios respetan la ubicación y herramientas reales del proyecto y superan `translation_catalog_test`.
