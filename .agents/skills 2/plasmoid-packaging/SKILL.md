---
name: plasmoid-packaging
description: Activa esta skill para tareas relacionadas con el empaquetado, manifiestos (metadata.desktop o metadata.json), configuración de CMakeLists.txt (si aplica) y la preparación del widget de Plasma 6 para su distribución o instalación.
---

# Plasmoid Packaging Skill

## Instrucciones Detalladas
El empaquetado de un Plasmoid para KDE Plasma 6 requiere seguir especificaciones precisas para que el gestor de paquetes de Plasma lo reconozca y lo cargue correctamente.
1. Gestiona la metadata del plasmoide en `metadata.json` (Plasma 6 prefiere JSON sobre el antiguo `.desktop`).
2. Configura los metadatos de KPackage de forma correcta, asegurando que `X-Plasma-API` esté seteado en `declarativeappletscript`.
3. Prepara la estructura dentro del directorio base o empaqueta el contenido en un archivo `.plasmoid` (que es un zip renombrado) para la distribución.
4. Toda la lógica de automatización de este proceso debe guardar los resultados en la carpeta `Packaging/`.

## Checklist
- [ ] ¿El archivo `metadata.json` contiene la ID única del paquete y la versión correcta?
- [ ] ¿El campo de API específica `X-Plasma-API` está presente y correcto para Plasma 6?
- [ ] ¿Se incluyen todos los metadatos requeridos por la KDE Store si se va a publicar?
- [ ] ¿El proceso respeta la estructura de directorios de KPackage (`contents/ui`, `contents/config`, etc.)?

## Buenas Prácticas
- Usar identificadores inversos (ej. `org.kde.punchitaskmanager`) en los metadatos.
- Validar el archivo `metadata.json` con las herramientas oficiales (`desktoptojson` o `kpackagetool6 --validate`) si es posible.

## Errores Comunes
- **Formato heredado de Plasma 5**: Usar metadatos obsoletos (`X-KDE-PluginInfo-...`) en lugar del formato moderno esperado por Plasma 6.
- **Carpetas mal nombradas**: KPackage es estricto con los nombres de las carpetas internas (como `ui/main.qml` en lugar de cualquier otra estructura). Todo el código fuente de QML/JS debe estar mapeado al interior de la estructura estándar de KPackage al empaquetarse.

## Criterios de Aceptación
- El paquete generado puede ser instalado con `kpackagetool6 -i .` sin arrojar errores de validación.
- Plasma reconoce el widget y lo muestra en el selector de widgets con el icono y nombre correctos.
