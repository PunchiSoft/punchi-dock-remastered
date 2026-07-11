# Adaptador C++ con KService y KIO

## Estado actual

Se compiló, instaló e integró el módulo QML `org.punchi.dock` y la clase `SystemDiscovery`.

El adaptador está diseñado para sustituir las rutas Python que actualmente:

- recorren carpetas;
- descubren aplicaciones por categoría;
- buscan aplicaciones por alias;
- resuelven iconos de aplicaciones y Flatpak.

También ofrece apertura de URL y lanzamiento de aplicaciones mediante trabajos KIO, para que los elementos descubiertos no necesiten construir comandos shell nuevos.

## Archivos

- `CMakeLists.txt`
- `src/CMakeLists.txt`
- `src/systemdiscovery.h`
- `src/systemdiscovery.cpp`
- `docs/compilacion-adaptador-cpp.md`

## Dependencias

El entorno tiene CMake, Ninja, ECM, `qt6-qtbase-devel`, `qt6-qtdeclarative-devel`, `kf6-kservice-devel` y `kf6-kio-devel`.

La biblioteca se instaló en `~/.local/lib64` y el plugin QML bajo `~/.local/lib64/qml/org/punchi/dock`. Como Plasma no incluye esa ruta de usuario en todos los entornos, el módulo también se incorpora dentro de `contents/ui/org/punchi/dock`.

## Corrección visual relacionada

Se corrigió la doble asignación del grupo `font` que impedía cargar `FolderPopup.qml`. El paquete fue reconstruido, validado y actualizado en la instalación local. La copia instalada coincide byte por byte con la fuente corregida.

## Integración completada

Se realizaron estos cambios:

1. El módulo compiló y enlazó con KService y KIO.
2. La introspección QML cargó `SystemDiscovery` y enumeró sus métodos y señales.
3. `ConfigItems.qml` usa KIO para carpetas y KService para categorías y búsqueda de aplicaciones.
4. `main.qml` lanza aplicaciones por `storageId` y abre elementos de carpeta por `url`.
5. Las cuatro funciones Python fueron retiradas de `configScripts.js`.
6. No quedan referencias a `python3` en `contents/`.
7. Todos los QML pasan `qmllint`.
8. El paquete se reconstruyó, pasó su prueba de integridad y se actualizó localmente.
9. `plasmawindowed` mantuvo el plasmoide activo durante la prueba de arranque sin emitir errores; terminó únicamente por el timeout de la prueba.
10. El módulo incluido usa RPATH `$ORIGIN`, no contiene rutas del directorio de compilación y resuelve todas sus bibliotecas.
11. El target CMake `stage_plasmoid_module` automatiza la copia de los binarios y metadatos al paquete.
12. Tras instalar el módulo dentro del paquete, `plasmawindowed` volvió a arrancar sin el error `module "org.punchi.dock" is not installed`.
13. La importación por URI todavía dependía de las rutas globales de QML de Plasma. Se sustituyó por importaciones relativas al módulo incluido en el paquete y se actualizó la instalación local.
14. La copia instalada contiene las importaciones relativas y los cuatro archivos del módulo; `plasmawindowed` permaneció activo hasta el timeout sin emitir errores de carga.

## Validación manual pendiente

Abrir las preferencias y comprobar:

- carga de una carpeta como contenedor;
- carga de una categoría de aplicaciones;
- autocompletado por alias;
- apertura de un archivo o carpeta descubierto;
- lanzamiento de una aplicación descubierta.

La prueba de arranque no reemplaza estas interacciones manuales.
