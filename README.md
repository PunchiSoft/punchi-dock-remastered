# Punchi-dock Remastered

Una versión modularizada, optimizada y profesional del clásico Punchi-dock para KDE Plasma 6.

## Instalación (Fedora 44+)

1. Asegúrate de tener las dependencias de desarrollo instaladas:
   ```bash
   sudo dnf install plasma-sdk extra-cmake-modules kf6-kcoreaddons-devel kf6-kdeclarative-devel kf6-ki18n-devel qt6-qtdeclarative-devel libplasma-devel
   ```
2. Instala el plasmoide usando la herramienta nativa:
   ```bash
   kpackagetool6 -t Plasma/Applet -i .
   # O si ya está instalado y quieres actualizar:
   kpackagetool6 -t Plasma/Applet -u .
   ```

## Desarrollo

- El módulo C++ auxiliar se documenta en [docs/guias-usuario/compilacion-adaptador-cpp.md](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/docs/guias-usuario/compilacion-adaptador-cpp.md:1).
- El paquete incluye un módulo QML compilado bajo `contents/ui/org/punchi/dock`, actualizado mediante `cmake --build build --target stage_plasmoid_module`.
- La validación automática actual es mínima; `ctest` solo cubre `appstreamtest`.

## Internacionalización

- El idioma fuente del proyecto es inglés.
- Todo texto visible nuevo debe escribirse en inglés y envolverse con `i18n(...)`, `i18nc(...)` o `i18np(...)` según corresponda.
- Si no existen catálogos de traducción instalados, la interfaz se mostrará en inglés. Ese comportamiento es esperado.
- La infraestructura completa de traducción compilada aún está pendiente.

## Estructura Modular

El código está dividido en componentes UI reutilizables dentro de `contents/ui/components/` y lógica pura en `contents/code/`.
