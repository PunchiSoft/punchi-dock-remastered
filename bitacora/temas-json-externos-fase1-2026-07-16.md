# Temas JSON externos: fase 1

Fecha: 2026-07-16

## Objetivo

Iniciar el soporte de fondos personalizados para Punchi Dock mediante archivos JSON externos, sin incluir temas ni presets dentro del paquete `.plasmoid`.

## Implementacion

- Se añadió `DockThemeValidator` para validar y normalizar `schemaVersion: 1`.
- Se añadió `DockThemeRepository` como integración nativa entre QML y el almacenamiento del usuario.
- Los temas importados se copian bajo
  `QStandardPaths::GenericDataLocation/punchi-dock-remastered/themes/`.
- La configuración conserva un identificador derivado del contenido normalizado, no la ruta original.
- Se rechazan archivos no locales, ilegibles, vacíos, mayores de `64 KiB` o incompatibles.
- Se restringen colores a `#RRGGBB` y `#AARRGGBB`.
- Se limitan gradientes, radios, bordes y sombras antes de exponerlos a QML.
- El renderer reserva dentro del dock el margen requerido por la sombra para reducir clipping en los límites de la ventana.
- Se añadió en Apariencia la selección entre fondo Plasma y tema JSON externo.
- Se añadió `FlatThemeBackground.qml` como primer renderer 2D.
- `DockBackground.qml` mantiene `AudioSpectrumLayer` por encima del fondo seleccionado.
- El fondo Plasma actúa como fallback ante un tema ausente o inválido.
- Los paneles Plasma conservan su fondo nativo; la fase inicial se limita al dock flotante.

## Distribucion

- No se creó `contents/themes/`.
- No se incorporaron presets ni fixtures al paquete.
- Los temas deberán descargarse y distribuirse por separado.
- La inspección del artefacto Fedora confirmó que el único JSON empaquetado es `metadata.json`.

## Catalogo local de pruebas

Se creó `docs/themes/` para adaptar las propuestas del prototipo:

```text
docs/guias-usuario/punchi-dock-24-propuestas-3d-2d.html
```

El HTML es una referencia visual y no una dependencia ejecutable.

Se adaptaron las doce propuestas 2D, numeradas desde:

- `13_cristal_plasma_2d.json`;
- hasta `24_segmentado_2d.json`.

La propuesta 1 dispone ahora de un fixture experimental 2.5D. Las propuestas
2–12 continúan pendientes y no se degradaron a temas planos porque perderían
su repisa, canto y rim.

Las adaptaciones reproducen color, transparencia, gradiente dominante, borde,
radio, sombra y el separador propio de cada tema. Se siguen simplificando
texturas, sombras interiores y cambios estructurales de layout.

## Separadores integrados en el tema

- `schemaVersion: 1` admite una sección opcional `separator`.
- El tema selecciona geometrías internas `line`, `dot` o `capsule`.
- Se admiten gradiente, borde, glow y patrones internos limitados.
- `ThemedSeparator.qml` aplica el estilo globalmente a los separadores
  existentes.
- El tema no crea, elimina ni mueve separadores.
- Los temas antiguos, el modo Plasma y los paneles conservan el separador
  nativo.
- Los doce ejemplos 2D incorporan el separador equivalente del prototipo HTML.

## Convivencia con el espectro y exclusión de paneles

- El fondo Plasma o JSON queda fijado en `z: 0`.
- `AudioSpectrumLayer` queda fijado en `z: 10`, por lo que el espectro se
  compone siempre sobre el fondo personalizado.
- En modo panel no se carga el tema administrado ni se considera activo.
- La sección completa de temas externos se oculta en Apariencia cuando el
  `formFactor` corresponde a un panel horizontal o vertical.
- La preferencia no se elimina y vuelve a estar disponible si el plasmoide
  regresa al modo flotante.

Todos los temas 2D pasan:

- validación sintáctica mediante `jq`;
- validación semántica mediante `DockThemeValidator`.

La prueba `dockthemevalidator_test` acepta ahora rutas opcionales para validar temas externos contra el mismo contrato del runtime.

## Validacion del usuario

El 2026-07-16 el usuario confirmó que los temas importados “quedaron hermosos”.

La evidencia confirma el resultado visual del renderer 2D y del catálogo adaptado en Plasma real. Permanecen pendientes las pruebas de persistencia tras reinicio, fallback manual, visualizador activo, escalado y Debian.

Posteriormente el usuario confirmó explícitamente que el soporte 2D
personalizable es correcto. La fase 2D queda cerrada y el trabajo continúa con
el renderer 2.5D experimental.

## Inicio del renderer 2.5D

- Se añadió el renderer `shelf`.
- `ShelfThemeBackground.qml` compone una repisa superior inclinada, un canto
  frontal y un rim luminoso.
- La geometría usa `Rotation` de Qt Quick, disponible desde Qt Quick 2.0/6.0.
- Se evita `distanceToPlane` porque su revisión aparece en Qt 6.11.
- Los parámetros geométricos se validan y limitan antes de llegar a QML.
- Se añadió `docs/themes/2.5d/01_cristal_integrado_2_5d.json` como primer fixture
  externo.
- No se incorporaron temas al paquete ni se añadió Qt Quick 3D.

## Validacion visual del renderer 2.5D

El usuario probó el primer tema en Plasma real, aportó una captura y confirmó
que es funcional y que los iconos se perciben sobre un cristal inclinado.

La geometría base queda validada para continuar el catálogo:

- repisa reconocible;
- canto y rim continuos;
- iconos y reloj legibles;
- sin clipping grave visible.

El trabajo pendiente es de dirección artística por tema, especialmente
perspectiva, peso del canto, unión con los iconos, luces y sombras.

## Catálogo inicial 2.5D

Con la geometría base confirmada se añadieron cuatro temas más, completando el
primer grupo experimental:

- `01_cristal_integrado_2_5d.json`;
- `02_madera_barnizada_2_5d.json`;
- `03_acero_industrial_2_5d.json`;
- `04_obsidiana_2_5d.json`;
- `05_marco_neon_2_5d.json`.

Los cinco reutilizan el mismo renderer `shelf`; sólo cambian datos visuales.
Los diecisiete temas externos disponibles pasan `jq` y
`DockThemeValidator`. Las propuestas 6–12 quedan pendientes de comparación
visual.

## Pulido geométrico inspirado en Urban Dock

La primera geometría funcional fue reemplazada por una composición poligonal
de `QtQuick.Shapes` para aproximar mejor la referencia aportada por el usuario:

- cubierta trapezoidal;
- parte posterior estrecha;
- canto frontal biselado;
- facetas laterales;
- rim y sombra poligonal.

El JSON controla ahora `topDepthRatio`, `backInset` y `sideBevel`. Los ángulos
de la primera prueba se conservan únicamente como compatibilidad de lectura.

La decisión se apoya en usos de `QtQuick.Shapes` dentro de Plasma Workspace y
Kirigami. El renderer no añade animación continua, Qt Quick 3D, shaders ni
recursos externos.

## Afinado visual de proporciones 2.5D

La prueba del renderer poligonal mostró una repisa reconocible, pero con un
canto frontal demasiado alto, poca cubierta visible y una sombra con aspecto
de placa sólida.

Se mantuvo la geometría trapezoidal y se afinó su acabado:

- cantos de `11–13` píxeles según el material;
- cubierta superior más profunda;
- perspectiva posterior y biseles más suaves;
- rim más fino;
- sombra poligonal con menor opacidad;
- reflejo superior gradual;
- filo inferior sutil en el canto.

Los cinco fixtures 2.5D de `docs/themes/` fueron actualizados. Para observar
los cambios es necesario volver a importar cada JSON, porque Punchi Dock usa
una copia administrada del archivo seleccionado.

## Límite visual de los separadores

Una captura posterior confirmó que los separadores con glow podían superar la
altura de los iconos. La causa combinaba dos medidas:

- el cuerpo se calculaba con `iconSize + 12`;
- el glow se extendía fuera del cuerpo sin descontarse de esa longitud.

El renderer aplica ahora una restricción común a todos los temas:

```text
longitud del cuerpo + glow superior + glow inferior <= iconSize
```

También limita el grosor efectivo al tamaño del icono. La corrección vive en
`DockItem.qml` y `ThemedSeparator.qml`, por lo que no requiere modificar cada
JSON ni confiar en que temas externos futuros elijan valores conservadores.

La primera corrección reveló una particularidad adicional:
`Kirigami.ShadowedRectangle` expande su sombra según la relación de aspecto.
En separadores muy estrechos y altos esto producía halos irregulares incluso
con la longitud lógica correctamente reservada.

El separador ya no usa ese shader. El glow se construye con tres capas QML
translúcidas, estáticas y de tamaño conocido:

- la expansión vertical coincide exactamente con el espacio reservado;
- la expansión horizontal queda limitada por el grosor;
- no se recorta con `clip`;
- gradientes, bordes y patrones mantienen el mismo contrato JSON.

La decisión se contrastó con
`kde-sdk/frameworks/kirigami/src/primitives/shadowedrectangle.cpp`, en
particular `adjustRectForShadow()`.

## Glow acotado del rim 2.5D

Marco Neón reveló el mismo comportamiento en el rim frontal del renderer
`shelf`. Su glow de tamaño `12`, aplicado a una línea casi tan ancha como el
dock, producía una franja horizontal que sobresalía ampliamente de los
extremos.

`ShelfThemeBackground.qml` dejó de usar `Kirigami.ShadowedRectangle` para el
rim. El halo se representa ahora mediante un gradiente vertical estático:

- conserva el tamaño vertical solicitado por `rim.glow.size`;
- limita la expansión horizontal a tres píxeles;
- mantiene el núcleo del rim nítido;
- no requiere modificar el JSON de Marco Neón;
- protege futuros temas con rims anchos y glows intensos.

## Nomenclatura y canto ligero 2.5D

El catálogo dejó de utilizar `3D` en nombres visibles y nombres de archivo.
Los cinco temas se identifican ahora correctamente como `2.5D`, ya que el
renderer compone polígonos planos y no una escena Qt Quick 3D.

Los archivos usan el sufijo `_2_5d.json`, declaran versión `1.1` y reducen la
altura del canto frontal:

- `8` para cristal, obsidiana y marco neón;
- `9` para madera y acero.

La perspectiva de la cubierta se mantiene. El cambio hace más ligera la
silueta sin eliminar la lectura de repisa y material.

Los diecisiete temas externos pasan `jq` y `DockThemeValidator` después de los
renombrados. No quedan nombres visibles 3D en el catálogo 2.5D.

## Aprobación visual de temas y pestaña de audio

El usuario aprobó los fondos personalizados 2D y 2.5D después de las
correcciones visuales. La fase de renderer queda aceptada en Plasma real.

Como reorganización posterior, el visualizador de audio dejó de formar parte
de `ConfigAspect.qml`. Se creó:

```text
contents/ui/config/ConfigAudioVisualizer.qml
```

La nueva categoría se ubica después de Apariencia y conserva todas las claves
`cfg_audioSpectrum*`. No existe migración de datos ni cambio de runtime:
únicamente se separa la interfaz de configuración por dominio.

La página incluye activación, privacidad, fondo, intensidad, color, densidad,
estilo, movimiento y dirección. Los controles mantienen semántica estándar y
se añadieron nombres accesibles a selectores y slider.

Validación:

- página nueva sin diagnósticos propios de `qmllint`;
- baseline global: `757` advertencias, sin errores de importación o layout;
- `ctest`: `5/5`;
- paquete Fedora correcto y con la página nueva incluida.

## Biblioteca administrada de temas

La ubicación administrada se aisló definitivamente de cualquier versión
legacy:

```text
~/.local/share/punchi-dock-remastered/themes/
```

No existe migración automática desde `~/.local/share/punchi-dock/themes/`.
Los temas de una instalación anterior deben importarse explícitamente si la
persona desea reutilizarlos.

`DockThemeRepository` escanea y valida la carpeta Remastered, expone una lista
reactiva con nombre, ID, renderer, versión y etiqueta `2D`/`2.5D`, y actualiza
el modelo después de cada importación.

La página Apariencia muestra un segundo `ComboBox` para seleccionar temas ya
instalados y mantiene el botón `Importar…`. El tema recién importado queda
seleccionado automáticamente.

El listado ignora symlinks, nombres no administrados, archivos vacíos,
sobredimensionados o rechazados por `DockThemeValidator`. No se añadió código
JavaScript ni contenido bajo `contents/themes/`.

La validación Fedora conserva el baseline global de `qmllint`, supera
`ctest 5/5` y produce un paquete que expone la biblioteca sin incorporar
ningún JSON de tema.

La validación Debian queda pendiente en un host Debian 13. El wrapper bloqueó
correctamente el intento desde Fedora para evitar mezclar binarios nativos.

## Importación de colecciones por carpeta

La biblioteca administrada admite importar en lote todos los JSON del primer
nivel de una carpeta elegida con `QtDialogs.FolderDialog`.

La operación permanece en `DockThemeRepository`; QML sólo solicita la carpeta
y presenta el resultado. Cada archivo reutiliza el mismo validador,
normalización, ID por hash y escritura segura de la importación individual.

Límites deliberados:

- escaneo recursivo sin seguir enlaces simbólicos;
- máximo de 256 JSON por operación;
- extensión `.json` sin distinguir mayúsculas;
- rechazo de symlinks, archivos ilegibles, vacíos, sobredimensionados o
  incompatibles;
- deduplicación por contenido normalizado.

El botón compacto `Importar…` abre un menú con importación de archivo o
carpeta. El KCM informa cuántos temas fueron añadidos, ya estaban instalados,
fueron rechazados o quedaron fuera del límite, y selecciona el primer tema
válido del lote.

Los fixtures se separaron en `docs/themes/2d/` y `docs/themes/2.5d/` para
validar colecciones organizadas por subcarpetas. La prueba automatizada incluye
un JSON anidado y confirma que el repositorio lo descubre. También comprueba
que una carpeta enlazada hacia otra ubicación no sea recorrida.

La decisión de usar `QtDialogs.FolderDialog` se contrastó con el patrón
upstream de Plasma en
`kde-sdk/plasma-workspace/wallpapers/image/imagepackage/contents/ui/AddFileDialog.qml`.

## Organización por tema y eliminación administrada

Los diecisiete fixtures de `docs/themes/` se separaron en carpetas
individuales bajo `2d/` y `2.5d/`. Importar la raíz recorre ahora tres niveles
reales de colección.

Las nuevas copias administradas se almacenan como:

```text
themes/2d/<nombre-seguro>/<id>.json
themes/2.5d/<nombre-seguro>/<id>.json
```

La biblioteca conserva lectura recursiva de archivos planos anteriores.
`DockThemeRepository::removeTheme()` elimina únicamente IDs administrados,
ignora symlinks, limpia directorios vacíos y actualiza el modelo reactivo.

Apariencia incorpora confirmación mediante `Kirigami.PromptDialog`. Al borrar
el tema activo se selecciona otro disponible o se vuelve al fondo Plasma si no
quedan temas. El patrón de confirmación se contrastó con
`kde-sdk/plasma-workspace/kcms/lookandfeel/ui/ConfirmDeletionDialog.qml`.

## Seguridad

- El identificador administrado acepta únicamente dieciséis caracteres hexadecimales.
- No se construyen rutas desde nombres suministrados por el tema.
- No se evalúa HTML, JavaScript, QML, shaders ni código externo.
- No se admiten recursos remotos ni rutas a imágenes en `schemaVersion: 1`.

## Validacion

- `qmllint` Fedora reportó `757` advertencias, por debajo del baseline, con
  `0` advertencias de layout y `0` errores de importación.
- Compilación Release completada.
- `ctest`: `5/5` pruebas superadas.
- `ShelfThemeBackground.qml` superó `qmllint` focalizado sin diagnósticos
  después del afinado visual.
- Los cinco temas 2.5D actualizados pasaron `jq` y `DockThemeValidator`.
- `ThemedSeparator.qml` superó `qmllint` sin diagnósticos.
- El límite visual de separadores conserva el baseline global en `757`
  advertencias y `ctest` en `5/5`.
- La sustitución del shader de sombra mantiene el mismo baseline, las pruebas
  en `5/5` y el empaquetado Fedora correcto.
- El halo acotado del rim mantiene `qmllint` en el baseline, `ctest` en `5/5`
  y el paquete Fedora correcto.
- Los doce temas con separadores pasaron `DockThemeValidator`.
- Se verificó importación, almacenamiento temporal, recarga y rechazo de traversal.
- Se verificó importación por carpeta, deduplicación, rechazo parcial y carpeta
  inexistente sin abortar los temas válidos del lote.
- Se verificó almacenamiento jerárquico, compatibilidad con archivos planos,
  borrado del tema activo, limpieza de carpetas vacías, rechazo de traversal y
  protección frente a symlinks.
- El baseline global se mantuvo en `757` advertencias, `0` de layout y `0`
  errores de importación.
- El paquete local Fedora se instaló y Plasma Shell reinició con PID nuevo.
- El diagnóstico de arranque no contiene errores propios de Punchi Dock.
- El selector de biblioteca protege `currentValue` e índices transitorios
  durante la reconstrucción del modelo, evitando el `TypeError` observado
  después de una importación completa.
- Se creó `dist/punchi-dock-remastered-0.8.7-fedora44-x86_64.plasmoid`.
- El paquete incluye `ShelfThemeBackground.qml` y no incluye el fixture 2.5D.

## Pendiente

- Prueba visual de los nuevos separadores después de volver a importar los
  temas actualizados.
- Prueba del visualizador sobre un fondo personalizado.
- Validación nativa en Debian.
- Administración de múltiples temas y eliminación desde el KCM.
- Blur real y validación visual del renderer 2.5D.
