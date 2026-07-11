# Auditoría general del plasmoide

Fecha: 2026-07-10

## Alcance

Esta auditoría revisa el estado actual del plasmoide a nivel de:

- arquitectura y modularidad;
- configuración y panel de edición;
- internacionalización;
- empaquetado y documentación;
- validación disponible en el repositorio.

Se tomó como referencia el código vigente en `contents/`, `src/`, `metadata.json`, `README.md`, la guía del adaptador C++ y el material previo en `docs/plandeaccion/` y `docs/revisiones/`.

## Validación realizada

- `cmake --build build`: sin trabajo pendiente, build actual consistente.
- `ctest --test-dir build --output-on-failure`: 1/1 prueba aprobada (`appstreamtest`).
- No se pudo ejecutar `qmllint6` porque la herramienta no está instalada en esta sesión.
- No se realizó validación runtime en una sesión real de Plasma/Wayland, por lo que los hallazgos visuales y de interacción quedan limitados a revisión estática.

## Hallazgos

### Alta prioridad

1. El botón de exportación de configuración comunica una acción que no realiza.
   En [contents/ui/config/ConfigFiles.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigFiles.qml:90) `exportJsonRequested()` solo reasigna texto al editor y muestra el mensaje `"Copied to clipboard!"`, pero no interactúa con el portapapeles ni escribe un archivo. Esto genera una falsa confirmación de respaldo exitoso.

2. La internacionalización del panel de configuración no sigue la política del proyecto y está fijada manualmente en español.
   [contents/ui/config/ConfigItems.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigItems.qml:44) y [contents/ui/config/ConfigFiles.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigFiles.qml:22) usan `languageMode: "es"` y delegan textos a un diccionario manual en [contents/ui/config/code/i18n.js](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/code/i18n.js:1). Esto impide usar ki18n de forma estándar, dificulta extracción de cadenas y desacopla el idioma visible del idioma real del sistema.

3. El estado principal del dock no maneja correctamente la transición a configuración vacía.
   En [contents/ui/main.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/main.qml:92) `onDockItemsJsonChanged()` solo actualiza `dockItems` y el archivo externo cuando `raw.trim().length > 0`. Si el valor pasa a vacío, el dock conserva estado previo en memoria y tampoco sincroniza el archivo externo.

### Prioridad media

4. La configuración mezcla demasiadas responsabilidades en un único archivo.
   [contents/ui/config/ConfigItems.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/ConfigItems.qml:20) tiene 1246 líneas y concentra estado, lógica, servicios, composición visual, edición de formularios, carga de iconos y manejo de diálogos. La modularización actual mejoró respecto a versiones anteriores, pero este archivo sigue siendo un cuello de botella para mantenimiento y regresiones.

5. Persisten artefactos temporales o de preview dentro del paquete fuente.
   [contents/ui/config/FolderPathDialog_tmp.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/FolderPathDialog_tmp.qml:1) y [contents/ui/config/test_preview.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/test_preview.qml:1) no aparecen referenciados desde el flujo principal. Aunque no rompen el build, aumentan ruido, riesgo de confusión y deuda de empaquetado.

6. Aún existe dependencia relevante de shell para tareas que ya conviven con adaptadores nativos.
   [contents/ui/main.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/main.qml:43), [contents/code/logic.js](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/code/logic.js:41) y [contents/ui/config/IconPickerController.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/IconPickerController.qml:97) siguen usando `Plasma5Support.DataSource` y scripts `sh -c` para monitoreo de papelera, lanzamiento indirecto e indexado de iconos. Parte de esto es razonable como transición, pero hoy el código mezcla rutas nativas con rutas shell sin un criterio único.

7. La documentación principal del repositorio quedó por detrás del estado real.
   [README.md](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/README.md:5) solo documenta instalación básica del plasmoide y no refleja el adaptador C++, el target `stage_plasmoid_module`, la estructura real de configuración ni el estado de validación actual. La guía detallada sí existe en [docs/guias-usuario/compilacion-adaptador-cpp.md](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/docs/guias-usuario/compilacion-adaptador-cpp.md:13), pero no está integrada al onboarding principal.

### Prioridad baja

8. La cobertura automática sigue siendo mínima.
   El repositorio compila y `ctest` pasa, pero solo existe una prueba de metadata/appstream. No hay evidencia de validación automatizada para QML, flujos de configuración, parsing de JSON ni adaptador C++.

9. Hay inconsistencias menores de UX y localización en componentes auxiliares.
   Por ejemplo, [contents/ui/config/SoundFileDialog.qml](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/contents/ui/config/SoundFileDialog.qml:8) mantiene textos fijos en inglés, mientras otros paneles usan el diccionario manual. No parece crítico por sí solo, pero refuerza que la estrategia de textos está fragmentada.

## Diferencias frente al material previo

- La revisión previa en [docs/revisiones/inicio-10-07-26.md](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/docs/revisiones/inicio-10-07-26.md:1) ya no representa el estado real del proyecto; hoy existe más estructura, más panel de configuración y un adaptador C++ operativo.
- Las bitácoras recientes confirman avances reales en papelera, escritorios virtuales y adaptador C++, por lo que la deuda actual ya no está en “hacer que funcione”, sino en consolidar arquitectura, textos, validación y documentación.
- La guía del adaptador C++ está más alineada con el estado actual que el `README`, por lo que el problema documental no es ausencia de contenido sino dispersión y desactualización del punto de entrada.

## Plan de acción recomendado

### Fase 1. Corregir incoherencias visibles al usuario

- Arreglar `Export...` para que copie realmente al portapapeles o cambie el mensaje a una acción veraz.
- Corregir la sincronización cuando `dockItemsJson` queda vacío para que UI y archivo externo no queden desfasados.
- Revisar las acciones de papelera para que abrir y vaciar sigan una estrategia consistente de fallback.

### Fase 2. Normalizar internacionalización

- Sustituir el sistema manual de `languageMode` + `i18n.js` por ki18n real en QML/JS.
- Migrar primero las pantallas de configuración más usadas: `ConfigItems.qml`, `ConfigFiles.qml`, diálogos de iconos y papelera.
- Eliminar cadenas fijas residuales en inglés o español fuera del flujo estándar de traducción.

### Fase 3. Reducir el tamaño del núcleo de configuración

- Extraer de `ConfigItems.qml` al menos tres áreas: estado/controlador, edición de item base y utilidades de contenido dinámico.
- Mantener el archivo raíz como orquestador visual y no como contenedor total de lógica.
- Aprovechar componentes ya existentes para mover formularios específicos sin reescribir todo el panel.

### Fase 4. Limpiar artefactos y rutas transitorias

- Retirar o aislar `FolderPathDialog_tmp.qml` y `test_preview.qml`.
- Revisar si el indexado de iconos y el monitoreo de papelera pueden migrarse parcial o totalmente a una ruta más nativa.
- Documentar explícitamente qué dependencias shell siguen siendo intencionales y cuáles son deuda técnica.

### Fase 5. Poner al día la documentación principal

- Actualizar `README.md` como punto de entrada real del proyecto.
- Enlazar desde `README.md` a la guía del adaptador C++ y aclarar el flujo `build`, `install`, `stage_plasmoid_module`, empaquetado y validación.
- Registrar en `docs/revisiones/` futuras auditorías con fecha y alcance, no solo notas rápidas.

### Fase 6. Subir el piso de validación

- Añadir al menos validación sintáctica QML en entorno Fedora 44+.
- Incorporar pruebas pequeñas para parsing y normalización de items JS.
- Definir una checklist manual reproducible para Plasma/Wayland: click, menú contextual, popup de carpeta, papelera, configuración, escritorios virtuales.

## Orden sugerido

1. Exportación falsa y sincronización de configuración vacía.
2. Migración de internacionalización.
3. Limpieza de archivos temporales y actualización de `README`.
4. Refactor incremental de `ConfigItems.qml`.
5. Mejoras de validación y reducción de shell.

## Conclusión

El plasmoide ya superó la etapa de prototipo mínimo: compila, tiene adaptador C++, empaquetado funcional y una configuración bastante más rica que la documentada en revisiones anteriores. La deuda principal ya no es de capacidad base, sino de consolidación.

La mejor inversión inmediata es corregir incoherencias de UX visibles, normalizar traducciones y bajar el riesgo de mantenimiento del panel de configuración. Después de eso, el proyecto queda mucho mejor posicionado para iterar nuevas funciones sin seguir acumulando deuda transversal.
