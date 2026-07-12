# Punchi-dock Remastered

**Punchi-dock Remastered** es un plasmoide nativo para **KDE Plasma 6 (Wayland)** diseñado bajo una ideología clara: proporcionar un dock altamente funcional, de rendimiento excepcional y extremadamente fácil de personalizar para el usuario final. 

Nacido como la evolución profesional del proyecto [punchi-dock-plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid) original, esta versión ha sido reestructurada desde sus cimientos para aprovechar al máximo las tecnologías modernas. Actualmente, el proyecto goza de una base arquitectónica **muy estable**, estando enfocado en el pulido final de la experiencia de usuario y la simplificación de sus menús de configuración.

### Historia y Refactorización (De *Spaghetti* a Modular)
El proyecto original creció tan rápido que su código terminó convirtiéndose en un "frankenstein" o código *spaghetti*. La falta de separación de responsabilidades (*Separation of Concerns*) hacía abrumador y peligroso arreglar bugs o auditar el código, ya que modificar una parte solía romper otras. 
Para solucionar esto de raíz, se tomó la decisión de pausar el desarrollo antiguo y extraer cuidadosamente ("con bisturí") las funciones al nuevo repositorio **Remastered**. Este nuevo proyecto se convertirá en la **versión oficial 1.0** una vez terminada la reestructuración, dejando al proyecto original como un archivo *Legacy*.

## Características Principales

- **Nativo para Wayland y Plasma 6**: Integración profunda con KWin y Plasma, garantizando animaciones a 60fps sin cuelgues (lag).
- **Dualidad de Formato**: Opera con total fluidez tanto en formato **dock flotante** como anclado al borde de la pantalla actuando como **panel tradicional**.
- **Simplicidad ante todo**: Filosofía centrada en que el usuario final pueda adaptar el aspecto y el comportamiento del dock sin lidiar con opciones abrumadoras o confusas.
- **Arquitectura Modular Robusta**: Separación estricta entre la lógica de negocio y la interfaz visual, garantizando escalabilidad y un bajo consumo de recursos.

---

## Instalación (Orientada a Fedora 44+)

1. **Instalación de dependencias**:
   ```bash
   sudo dnf install plasma-sdk extra-cmake-modules kf6-kcoreaddons-devel kf6-kdeclarative-devel kf6-ki18n-devel qt6-qtdeclarative-devel libplasma-devel
   ```

2. **Instalación del plasmoide** mediante la herramienta nativa de KDE:
   ```bash
   kpackagetool6 -t Plasma/Applet -i .
   
   # Para actualizar una instalación previa en el sistema:
   kpackagetool6 -t Plasma/Applet -u .
   ```

## Estructura de Desarrollo

- **Organización**: El código UI reside de forma modular en `contents/ui/components/`, mientras que la lógica pura se concentra en `contents/code/`.
- **Módulo C++**: Para interactuar con partes más profundas del sistema operativo. [Leer guía de compilación](docs/guias-usuario/compilacion-adaptador-cpp.md).
- **Distribucion limpia**: `scripts/empaquetar-plasmoid.sh` compila el modulo nativo y genera un `.plasmoid` reproducible con solo `metadata.json`, `LICENSE` y `contents/`. `scripts/probar-plasmoid.sh` queda reservado para instalarlo y probarlo localmente.
- **Internacionalización**: Desarrollado con el inglés como idioma fuente (`i18n`), listo para incorporar catálogos de traducción globales.
