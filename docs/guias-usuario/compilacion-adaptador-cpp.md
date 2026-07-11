# Compilación del adaptador C++

## Dependencias para Fedora 44+

El entorno necesita CMake, Ninja, ECM, Qt 6 de desarrollo, KService y KIO de desarrollo. En Fedora 44+, instalar lo que falte con:

```bash
sudo dnf install cmake ninja-build extra-cmake-modules \
  qt6-qtbase-devel qt6-qtdeclarative-devel \
  kf6-kservice-devel kf6-kio-devel
```

## Compilar e instalar para el usuario

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build
cmake --install build
cmake --build build --target stage_plasmoid_module
```

Durante el desarrollo, el módulo puede instalarse en `~/.local/lib64/qml/org/punchi/dock`. Plasma no busca necesariamente esa ruta. Por ello, el paquete final incluye una copia compilada bajo `contents/ui/org/punchi/dock`, usa RPATH relativo y la importa mediante rutas locales (`"org/punchi/dock"` desde `main.qml` y `"../org/punchi/dock"` desde configuración). Se puede inspeccionar el módulo de desarrollo con:

```bash
qmlplugindump-qt6 -nonrelocatable org.punchi.dock 1.0 "$HOME/.local/lib64/qml"
```

Tras modificar el adaptador, volver a compilar, instalar y ejecutar `stage_plasmoid_module`. Este target copia el plugin, su biblioteca, `qmldir` y los metadatos QML a `contents/ui/org/punchi/dock` con RPATH `$ORIGIN`. Después se debe reconstruir el paquete del plasmoide.

## Empaquetado correcto del plasmoide

El artefacto distribuible `.plasmoid` debe contener solo:

- `metadata.json`
- `LICENSE`
- `contents/`

No debe incluir `build/`, `src/`, `docs/`, `bitacora/`, `backup/`, `kde-sdk/` ni scripts auxiliares del repositorio. Empaquetar el directorio completo vuelve el archivo innecesariamente grande y lento de generar e instalar.

La forma minima recomendada es:

```bash
mkdir -p dist
rm -f dist/punchi-dock-remastered.plasmoid
zip -rq dist/punchi-dock-remastered.plasmoid metadata.json LICENSE contents
unzip -tq dist/punchi-dock-remastered.plasmoid
```

El script [probar-plasmoid.sh](/home/CMUNOZJ/Escritorio/Aprendizaje/punchi-dock-remastered/probar-plasmoid.sh:1) ya usa este criterio.

## Alcance del adaptador

`SystemDiscovery` proporciona:

- listado asíncrono de carpetas mediante KIO;
- descubrimiento de aplicaciones y categorías mediante KService;
- búsqueda de aplicaciones e iconos por identificador;
- lanzamiento de aplicaciones mediante `KIO::ApplicationLauncherJob`;
- apertura de URL mediante `KIO::OpenUrlJob`.

El adaptador sustituyó las cuatro rutas Python de `configScripts.js`. Los elementos antiguos que ya contienen un campo `command` conservan el fallback existente; los elementos nuevos descubiertos por KService/KIO usan `storageId` o `url` para lanzamiento nativo.
