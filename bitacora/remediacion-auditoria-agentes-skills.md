# Remediación de auditoría de agentes y skills

## Alcance aplicado

Se corrigieron primero los hallazgos que no requieren cambiar el comportamiento funcional del plasmoide.

### Skills

- Se reparó el front matter YAML de 11 skills cuyas descripciones contenían dos puntos sin comillas.
- Las 38 skills de `.agents/skills/` pasan `quick_validate.py`.
- `.agents/skills/` continúa siendo la fuente canónica; la retirada física de `.agents/skills 2/` permanece pendiente de la fase 2.

### Empaquetado

- `.kpackageignore` excluye ahora scripts Python y el propio archivo de exclusiones.
- El artefacto `dist/punchi-dock-remastered.plasmoid` se reconstruyó únicamente desde `metadata.json`, `contents/` y `LICENSE`.
- El paquete no contiene `fix_imports.py`, documentación, bitácora, SDK ni carpetas de agentes.
- `unzip -t` confirmó la integridad del artefacto.

### Accesibilidad y tema

- `DockItem.qml`, `FolderPopup.qml` y `CalendarPopup.qml` incorporan navegación por Tab, activación con Enter/Espacio y nombres/roles accesibles en sus controles personalizados principales.
- Los estados de foco son visibles.
- Los colores fijos principales de los popups se sustituyeron por colores semánticos de Kirigami.
- Se reemplazaron tamaños tipográficos fijos principales por fuentes del tema.
- El texto alternativo de carpeta quedó traducible.

## Validación

- Las 38 skills canónicas superaron el validador de `skill-creator`.
- Los tres componentes QML modificados superaron `qmllint` sin diagnósticos.
- El paquete reconstruido superó su prueba de integridad.

## Pendientes que requieren diseño

### Python y ejecución externa

`contents/ui/config/code/configScripts.js` todavía usa Python para descubrir aplicaciones, carpetas e iconos. La consulta del SDK local no encontró un modelo QML público de KService que sustituya todas esas operaciones desde un plasmoide QML puro.

No se reemplazó Python por más scripts shell ni por módulos privados de Plasma. La solución recomendada es uno de estos caminos:

1. crear un adaptador C++ pequeño basado en KService/KIO y empaquetar el proyecto con CMake; o
2. retirar o simplificar las funciones que requieren exploración externa.

### Internacionalización

El diccionario `contents/ui/config/code/i18n.js` y el modo de idioma propio deben migrarse gradualmente a ki18n y catálogos estándar. La migración afecta contratos usados por numerosos componentes y no debe mezclarse con las correcciones visuales.

### Modularidad

`ConfigItems.qml` requiere una extracción incremental de persistencia, descubrimiento, modelos y coordinación. No se recomienda reescribirlo de una sola vez.
