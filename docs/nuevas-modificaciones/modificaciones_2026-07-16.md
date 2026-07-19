# Modificaciones del plasmoide: Soporte Temas Personalizados (JSON)

Fecha: 2026-07-16

Estado: abierta.

## Contexto

El usuario desea incorporar soporte de temas visuales externos en Punchi Dock. La intención es que cada persona pueda descargar o crear una plantilla, importarla desde la configuración de apariencia y aplicarla al fondo del dock sin ejecutar HTML, JavaScript, QML ni código dinámico proporcionado por terceros.

El prototipo `docs/guias-usuario/punchi-dock-24-propuestas-3d-2d.html` se utilizará únicamente como referencia visual para convertir una selección de sus propuestas en datos JSON compatibles con un conjunto cerrado de renderizadores QML.

Esta modificación abre una línea nueva y no autoriza todavía su implementación. Primero se debe cerrar el contrato del formato, sus límites, el mecanismo de importación y el comportamiento de fallback.

## Objetivo de la modificacion

Permitir fondos personalizados seguros, ligeros y compatibles con Plasma 6 mediante archivos JSON declarativos y versionados. El motor deberá conservar siempre el fondo nativo de Plasma como opción y como recuperación automática ante archivos ausentes, incompatibles o inválidos.

## Primera modificacion

"en docs deje punchi-dock-24-propuestas-3d-2d.html que serian unos ejemplos de temas eso es aplicable? en fotmatos HTML, o Js me explico quiero que el dock tenga ese soporte de forma externa, donde cada usuario pueda descargar plantillas con los temas pensados, y guardarlos en un lugar de su entorno, donde pueda elegir cual aplicar, cual seria tu opinion de esto? [...] dame un plan de accion, para poder implementar esto cosa que en appearence dock background añadamos tema personalizado, y ahi podamos elegir el tema a mostrar que seria lo que propones de un fichero Json de ejemplo. y vemos que tal queda"

## Segunda modificacion

"perfecto me quedo mas claro procede. con el inicio de las modificaciones , para los temas los dejaras en una carpeta nueva como themes? lo ideal es que no sean incluidos en la compilacion del codigo se deben descargar por separado."

## Tercera modificacion

"los temas los creaste? hay que crear una carpeta themes en docs donde debemos dejar temas externos si ya existen muevelos ahi ya que para probar debemos tener los temas de ejemplo"

## Cuarta modificacion

"me interesaria mas que el tema traiga el tipo de separador y se implemente en conjunto al elegir el tema personalizado"

## Quinta modificacion

"confirmado el soporte 2D personalizable es correcto procede con lo que sigue"

## Sexta modificacion

"Los temas dicen 3D; deberían decir 2.5D como corrección. También creo que los
grosores de los temas 3D deberían ser menores, refiriéndose a la simulación de
su espesor que se observa."

## Septima modificacion

"En Appearance debemos separar en una pestaña Audio Visualizer y sus
componentes, ahora que ya se aprueba el tema 2D y 2.5D."

## Octava modificacion

"Añadir la opción de importar una carpeta para incorporar por lotes todos los
temas JSON que contiene."

## Novena modificacion

"Importar colecciones con subcarpetas. Podemos separar por carpetas los temas
para probar si es funcional. La vista previa y la galería remota no entran por
el momento."

## Decima modificacion

"Implementar borrar un tema, que no existe. Al importar, que tenga soporte a
subcarpetas, y probar separando por nombre del tema cada tema en
`docs/themes/` para forzar que detecte subcarpetas con temas y organice de igual
forma para dejar todo estructurado."

## Observaciones

- JSON es el formato recomendado porque permite describir valores visuales sin ejecutar código de terceros.
- No se cargarán archivos HTML, QML o JavaScript externos ni se utilizará `Loader` con contenido proporcionado por el tema.
- La lectura de archivos locales mediante `XMLHttpRequest` no será la base del sistema: Qt la restringe por defecto y no ofrece un comportamiento fiable para esta función.
- No se creará `contents/themes/` ni se incluirán temas JSON dentro del paquete `.plasmoid`.
- Los temas de ejemplo para desarrollo y prueba se conservarán en `docs/themes/`, fuera de `contents/`.
- Los temas se distribuirán y descargarán por separado. El archivo seleccionado se validará y copiará a una ubicación administrada por Punchi Dock bajo `QStandardPaths::GenericDataLocation`.
- No se dependerá permanentemente de una ruta externa que pueda moverse, desmontarse o desaparecer.
- Los colores deberán usar formatos compatibles con Qt, preferentemente `#RRGGBB` y `#AARRGGBB`. No se aceptarán directamente formatos CSS como `rgba(...)` ni `#RRGGBBAA`.
- El efecto denominado 3D será una composición visual 2.5D de superficies Qt Quick transformadas. No se incorporará Qt Quick 3D ni se elevará la compatibilidad mínima declarada.
- `DockBackground.qml` ya contiene `AudioSpectrumLayer`; la modificación deberá preservar su orden de capas y sus modos actuales, no añadir una segunda integración.
- En la primera fase los temas controlarán la pintura del fondo y, cuando lo
  declaren, el estilo global de los separadores existentes. No controlarán el
  layout general, el tamaño de los iconos ni el espaciado estructural del dock.
- La importación por carpeta recorrerá subcarpetas sin seguir enlaces
  simbólicos, procesará únicamente archivos `.json` y aplicará a cada uno el
  mismo validador y almacenamiento administrado usado por la importación
  individual.

## Alcance confirmado

La capacidad completa se dividirá en fases para evitar mezclar el formato externo, la importación, el renderizado 2D y la geometría 2.5D en una sola implementación.

### Fase 1: contrato y motor 2D

- Definir un esquema JSON `schemaVersion: 1`, documentado y con un conjunto cerrado de propiedades admitidas.
- Admitir inicialmente dos fuentes de fondo:
  - `"plasma"`: fondo nativo actual;
  - `"custom"`: copia importada y administrada por Punchi Dock.
- Implementar un validador y normalizador que produzca un objeto interno seguro con valores por defecto.
- Implementar un único renderizador 2D para color, gradiente lineal, borde, radio y sombra limitada.
- Probar el contrato con fixtures de desarrollo y pruebas que no se incorporarán al paquete distribuido.
- Mantener `AudioSpectrumLayer` por encima del fondo seleccionado y por debajo de los elementos del dock.
- Aplicar el fondo personalizado inicialmente al modo flotante. Los paneles conservarán el fondo controlado por Plasma.
- Aplicar conjuntamente el separador declarado por el tema a todos los
  separadores existentes, sin insertar, eliminar ni mover elementos.
- Conservar el separador Plasma cuando el tema no declare esta sección.

### Fase 2: renderizador 2.5D experimental

- Añadir un renderizador horizontal compuesto por repisa superior, canto frontal y rim de iluminación.
- Utilizar transformaciones disponibles en el objetivo Plasma 6 sin depender de propiedades recientes que eleven la versión mínima.
- Validar la geometría con un fixture 2.5D externo que no forme parte del paquete.
- Usar un fallback 2D o Plasma en orientaciones y entornos todavía no compatibles.

### Fase 3: catálogo inicial

- Convertir de tres a cinco propuestas del prototipo HTML únicamente después de estabilizar los dos renderizadores.
- Publicar esos temas como descargas separadas del `.plasmoid`.
- Añadir gradualmente capacidades que el esquema inicial no cubra, siempre mediante una nueva versión compatible del esquema.

### Ampliacion de la biblioteca: importacion por carpeta

- Añadir una acción `Importar carpeta…` junto a la importación individual.
- Usar el selector nativo `QtDialogs.FolderDialog`.
- Procesar como máximo 256 JSON por operación, incluyendo subcarpetas.
- Informar cantidades de temas añadidos, ya instalados, rechazados y omitidos
  por el límite.
- Seleccionar el primer tema válido del lote para permitir su aplicación
  inmediata, sin depender de los nombres originales de archivo.

### Ampliacion de la biblioteca: organizacion y borrado

- Organizar cada fixture de `docs/themes/` dentro de una carpeta propia.
- Guardar las importaciones nuevas en una jerarquía administrada equivalente
  por renderer y nombre seguro del tema.
- Mantener compatibilidad de lectura con archivos planos instalados por
  versiones anteriores.
- Añadir una acción de borrado con confirmación desde Apariencia.
- Si se elimina el tema activo, seleccionar un fallback instalado o regresar
  al fondo Plasma cuando la biblioteca quede vacía.

## Esquema JSON propuesto

El esquema deberá separar metadatos, renderizador y grupos visuales. Ejemplo orientativo para la primera fase:

```json
{
  "schemaVersion": 1,
  "metadata": {
    "name": "Obsidiana 2D",
    "author": "Punchi",
    "version": "1.0"
  },
  "renderer": "flat",
  "surface": {
    "color": "#ff1d2127",
    "radius": 24,
    "gradient": {
      "direction": "vertical",
      "stops": [
        {
          "position": 0,
          "color": "#ff1d2127"
        },
        {
          "position": 1,
          "color": "#ff050709"
        }
      ]
    },
    "border": {
      "width": 1,
      "color": "#1fffffff"
    }
  },
  "shadow": {
    "color": "#8c000000",
    "size": 8,
    "xOffset": 0,
    "yOffset": 4
  },
  "effects": {
    "blurRequested": true
  }
}
```

Reglas iniciales:

- `schemaVersion` será obligatorio.
- `renderer` solo aceptará identificadores conocidos, inicialmente `"flat"` y posteriormente `"shelf"`.
- Los gradientes usarán paradas con posición explícita y una cantidad máxima limitada.
- Los campos desconocidos se ignorarán o rechazarán según su nivel, pero nunca se evaluarán como código.
- Los valores numéricos se convertirán y limitarán antes de llegar a QML.
- `blurRequested` expresará una preferencia; no garantizará que KWin pueda aplicar desenfoque real.

## Riesgos y dependencias

- **Lectura de archivos locales**: `XMLHttpRequest` no debe utilizarse como dependencia principal para importar el JSON. El proyecto necesitará una operación nativa de lectura e importación o una integración equivalente ya disponible.
- **Persistencia**: guardar solo la ruta absoluta del archivo dejaría el tema roto si el archivo se mueve o desaparece. La copia importada debe quedar bajo control del plasmoide y conservar información suficiente para mostrar su origen.
- **Distribución independiente**: el dock no podrá asumir que existe un tema personalizado después de instalarse. El paquete debe iniciar siempre con Plasma y funcionar completamente sin descargas adicionales.
- **Empaquetado**: los fixtures y ejemplos usados durante el desarrollo deben permanecer fuera de `contents/` y quedar excluidos del artefacto final.
- **Validación**: JSON válido sintácticamente no implica tema válido. Se deben verificar versión, tipos, estructura, colores, rangos, cantidad de paradas y renderer admitido.
- **Compatibilidad de colores**: Qt interpreta los colores hexadecimales de ocho dígitos como `#AARRGGBB`; convertir ejemplos CSS sin normalización produciría transparencias y canales incorrectos.
- **Blur y contraste**: el desenfoque real depende de KWin, de la ventana y de su máscara. Un rectángulo translúcido en QML no equivale por sí solo a blur del contenido situado detrás.
- **Clipping de sombras**: sombras grandes pueden superar el espacio exterior reservado actualmente por el dock y recortarse en los límites de la ventana.
- **Geometría 2.5D**: la repisa y el canto pueden alterar la silueta visual, la zona útil y el espacio necesario alrededor de los iconos. La primera prueba debe limitarse a modo flotante horizontal.
- **Rendimiento**: sombras amplias, múltiples superficies transparentes y capas animadas pueden elevar el coste de GPU, especialmente cuando el visualizador está activo.
- **Orientación**: un tema horizontal no puede asumirse correcto en paneles verticales. Cada renderer deberá declarar las orientaciones que soporta y disponer de fallback.
- **Accesibilidad y contraste**: el tema no debe volver ilegibles etiquetas, indicadores, reloj ni controles. Más adelante puede requerirse declarar colores de contenido o calcular contraste, pero esto queda fuera de la primera fase.
- **Compatibilidad mínima**: no se utilizarán APIs del snapshot reciente del SDK local sin comprobar su disponibilidad en el mínimo declarado.
- **Separadores anchos**: una cápsula puede necesitar más ancho que la línea
  Plasma. El elemento separador deberá ampliar únicamente su propio tamaño
  implícito sin permitir que el tema altere el resto del layout.
- **Carpetas grandes o no confiables**: el escaneo masivo debe estar acotado,
  recorrer subcarpetas sin seguir enlaces simbólicos y mantener el límite
  individual de `64 KiB` para evitar trabajo excesivo en la configuración.

## Plan de implementacion

1. Cerrar y documentar el esquema JSON `schemaVersion: 1`, sus valores por defecto y sus límites.
2. Definir la ubicación administrada bajo `QStandardPaths::GenericDataLocation` para temas importados y el comportamiento de reemplazo, eliminación y archivo ausente.
3. Añadir pruebas unitarias para validación y normalización antes de conectar el formato con QML.
4. Implementar una operación nativa o servicio de dominio que:
   - lea únicamente archivos locales seleccionados explícitamente;
   - limite el tamaño máximo;
   - rechace archivos inválidos;
   - copie el tema aceptado a la ubicación administrada;
   - devuelva errores comprensibles sin bloquear Plasma.
5. Añadir en `main.xml` claves equivalentes a:
   - `dockThemeMode`;
   - `dockThemeCustomId` o una referencia administrada, evitando depender de una ruta externa permanente.
6. Añadir en `ConfigAspect.qml` una sección traducible de tema de fondo con:
   - Tema Plasma;
   - tema JSON personalizado;
   - selector de archivo;
   - nombre del tema activo;
   - estado de error y acción para volver a Plasma.
7. Mantener `DockBackground.qml` como coordinador y extraer renderizadores con responsabilidades claras:
   - `PlasmaDockBackground.qml`;
   - `FlatThemeBackground.qml`;
   - `ShelfThemeBackground.qml` cuando comience la fase 2.
8. Verificar el flujo completo de importar, aplicar, reiniciar y recuperar con un tema 2D externo de prueba.
9. Implementar el renderer 2.5D horizontal como experimento separado y probarlo con un tema externo.
10. Medir geometría, clipping y rendimiento antes de publicar por separado el catálogo inicial.

## Limites iniciales propuestos

Los límites exactos deberán cerrarse antes de implementar. Como punto de partida:

- tamaño máximo del archivo JSON: `64 KiB`;
- cantidad máxima de paradas por gradiente: `8`;
- radio: `0–48`;
- ancho de borde: `0–4`;
- tamaño de sombra: `0–8`;
- desplazamientos de sombra: `-4–4`;
- ángulos y profundidades 2.5D limitados por el renderer, no libres;
- ninguna ruta a imágenes, shaders, scripts o recursos remotos en `schemaVersion: 1`;
- ningún control del tamaño de iconos, hover, layout o comportamiento del dock.

## Validacion

### Validacion automatizada prevista

- pruebas del parser, validador y normalizador con temas válidos e inválidos;
- `qmllint` sobre cada QML modificado;
- compilación del módulo nativo;
- `ctest`;
- construcción independiente de los paquetes Fedora y Debian;
- inspección del `.plasmoid` para comprobar que no contiene temas JSON, fixtures ni archivos de desarrollo.
- validación directa de cada ejemplo de `docs/themes/` con `DockThemeValidator`.
- pruebas de estilos, límites y fallback del separador opcional.

### Validacion manual prevista

- alternar inmediatamente entre Plasma y tema personalizado;
- importar JSON válido, mal formado, incompatible, vacío y demasiado grande;
- mover o eliminar el archivo original después de importarlo;
- reiniciar el plasmoide y Plasma conservando el tema administrado;
- comprobar fallback automático al fondo Plasma;
- probar tema claro y oscuro, escalado y diferentes tamaños de icono;
- probar visualizador activo e inactivo;
- comprobar modo flotante horizontal y fallbacks en panel u orientación vertical;
- revisar sombras, clipping, consumo y fluidez en Fedora y Debian cuando sea posible.

No se considerará validado el blur, la geometría 2.5D ni el rendimiento mediante inspección estática. Esos puntos requieren una prueba real dentro de Plasma/KWin.

### Validacion realizada en la fase 1

- `qmllint` completado con el baseline Fedora existente:
  - `759` advertencias totales conocidas;
  - `746` advertencias `unqualified` conocidas;
  - `0` advertencias de layout;
  - `13` propiedades de Plasma ya registradas en el baseline;
  - `0` errores de importación.
- compilación Release del módulo nativo completada;
- `ctest`: `5/5` pruebas superadas;
- pruebas específicas añadidas para:
  - JSON válido;
  - JSON mal formado;
  - colores CSS no admitidos;
  - renderer no soportado;
  - sombras fuera de rango;
  - archivo superior a `64 KiB`;
  - importación a un `XDG_DATA_HOME` temporal;
  - recarga por identificador;
  - rechazo de identificadores con intento de traversal;
- paquete Fedora creado correctamente:
  - `dist/punchi-dock-remastered-0.8.7-fedora44-x86_64.plasmoid`;
- contenido del paquete inspeccionado:
  - contiene el motor `FlatThemeBackground.qml`;
  - no contiene carpeta de temas;
  - no contiene archivos JSON de tema;
  - el único JSON empaquetado es `metadata.json`.
- catálogo local de pruebas validado:
  - doce adaptaciones numeradas desde `13_cristal_plasma_2d.json` hasta `24_segmentado_2d.json`;
  - todos superaron `jq` y `DockThemeValidator`.
- extensión de separadores temáticos:
  - `qmllint` global Fedora: `757` advertencias, por debajo del baseline;
  - `0` advertencias de layout y `0` errores de importación;
  - compilación completada;
  - `ctest`: `5/5`;
  - `ThemedSeparator.qml` superó `qmllint` sin diagnósticos;
  - los doce JSON fueron aceptados por el validador del runtime.

### Validacion del usuario en entorno local

El 2026-07-16 el usuario confirmó después de importar y observar los temas:

> "quedaron hermosos"

Esta confirmación valida en el entorno local del usuario:

- que el flujo permite visualizar temas JSON externos;
- que el renderer 2D produce un resultado visual satisfactorio;
- que las adaptaciones del prototipo HTML conservan una identidad estética reconocible.

La confirmación es visual y no sustituye las pruebas todavía pendientes de persistencia, recuperación, espectro, orientación, blur, consumo o Debian.

El 2026-07-16 el usuario confirmó explícitamente:

> "confirmado el soporte 2D personalizable es correcto"

Con esta evidencia queda cerrada funcionalmente la fase 2D. El trabajo
posterior pertenece a la fase 2.5D experimental.

Pendiente:

- comprobación visual de los nuevos separadores después de volver a importar
  los doce temas actualizados;
- comprobación visual con espectro activo e inactivo;
- prueba de reinicio real de Plasma;
- comprobación manual del fallback con archivo administrado ausente o dañado;
- revisión de distintos tamaños de icono y escalado;
- validación nativa en Debian;
- blur real y validación visual del renderer 2.5D.

### Inicio de la fase 2.5D experimental

La primera iteración queda limitada a:

- un renderer interno `shelf`;
- modo flotante horizontal;
- superficie superior, canto frontal y rim;
- parámetros geométricos limitados y normalizados;
- un único tema externo de prueba basado en la propuesta 1;
- fallback Plasma ante datos inválidos o entornos no compatibles.

No se convertirán todavía las propuestas 2–12 ni se declarará validada la
geometría sin una revisión visual en Plasma real.

## Implementacion modificacion N° 1: base de temas JSON externos

Se implementó el inicio de la fase 1 con los siguientes límites:

- `DockThemeValidator` define y normaliza `schemaVersion: 1`;
- `DockThemeRepository` importa únicamente archivos locales seleccionados, limita su tamaño y los copia a:
  - `QStandardPaths::GenericDataLocation/punchi-dock-remastered/themes/`;
- la configuración guarda un identificador hexadecimal derivado del contenido normalizado, no una ruta absoluta;
- el identificador se valida antes de construir una ruta, evitando traversal;
- `ConfigAspect.qml` permite elegir entre el fondo Plasma y un tema JSON externo;
- el KCM muestra nombre del tema y errores traducibles;
- `FlatThemeBackground.qml` representa:
  - color base;
  - gradiente horizontal o vertical con hasta ocho paradas;
  - radio;
  - borde;
  - sombra limitada;
- `DockBackground.qml` conserva el visualizador como capa independiente;
- un tema inválido, ausente o no seleccionado deja visible el fondo Plasma;
- los temas personalizados se aplican inicialmente solo al dock flotante;
- no se incluyó ningún preset ni fixture dentro de `contents/`.

Límites deliberados:

- no existe todavía descarga desde una galería o URL;
- no existe administración de múltiples temas desde el KCM;
- no existe eliminación desde la interfaz;
- `blurRequested` se valida y conserva, pero todavía no activa blur de KWin;
- solo se admite `renderer: "flat"`;
- no se implementó geometría 2.5D;
- no se modificó el fondo de paneles Plasma.

## Implementacion modificacion N° 2: catálogo externo adaptado desde el prototipo

Se creó `docs/themes/` como ubicación local para temas externos de desarrollo y se tomó como fuente visual:

```text
docs/guias-usuario/punchi-dock-24-propuestas-3d-2d.html
```

El HTML sigue siendo solo una referencia visual; no se carga ni ejecuta en Punchi Dock.

Se adaptaron las doce propuestas compatibles con el renderer 2D actual:

1. `13_cristal_plasma_2d.json`;
2. `14_cristal_biselado_2d.json`;
3. `15_madera_plana_2d.json`;
4. `16_obsidiana_2d.json`;
5. `17_marco_neon_2d.json`;
6. `18_burbujas_2d.json`;
7. `19_ceramica_2d.json`;
8. `20_industrial_plano_2d.json`;
9. `21_tela_tecnica_2d.json`;
10. `22_holografico_2d.json`;
11. `23_piedra_plana_2d.json`;
12. `24_segmentado_2d.json`.

Las propuestas 1–12 no se deformaron para encajarlas en el renderer plano.
La propuesta 1 dispone ahora de un fixture `shelf`; las propuestas 2–12
continúan pendientes porque dependen de repisa, canto frontal y rim.

Las adaptaciones conservan los aspectos representables por `schemaVersion: 1`:
color, transparencia, gradiente lineal dominante, borde, radio, sombra y
separador temático. Las texturas, sombras interiores y cambios estructurales de
layout continúan documentados como simplificaciones.

Los doce ejemplos:

- usan `schemaVersion: 1`;
- declaran `renderer: "flat"`;
- respetan colores Qt `#RRGGBB` y `#AARRGGBB`;
- respetan los límites actuales de radio, borde y sombra;
- pasan `jq` y el mismo validador utilizado por `DockThemeRepository`;
- permanecen fuera del paquete porque `docs/` no se copia al `.plasmoid`.

## Implementacion modificacion N° 3: separadores integrados en el tema

Se extendió `schemaVersion: 1` con una sección opcional `separator`. La sección
selecciona únicamente renderizadores internos y valores normalizados; no carga
QML, JavaScript ni recursos aportados por terceros.

El contrato admite:

- geometrías `line`, `dot` y `capsule`;
- color, opacidad, grosor, longitud relativa y radio;
- gradiente lineal horizontal o vertical;
- borde y glow limitados;
- patrones internos `none`, `dashed`, `hazard` y `centerLine`.

`ThemedSeparator.qml` representa el separador normalizado. `main.qml` entrega
la sección del tema activo a `DockItem.qml`, que la aplica globalmente a todos
los elementos de tipo `separator`.

Comportamiento preservado:

- el tema no agrega, elimina ni reordena separadores;
- los JSON anteriores sin `separator` mantienen el separador Plasma;
- volver al fondo Plasma restaura el separador nativo;
- los paneles mantienen fondo y separador Plasma;
- una cápsula ancha sólo amplía el ancho implícito de su propio elemento.

Los doce temas de `docs/themes/` incorporan ahora los separadores de sus
prototipos: líneas translúcidas o con glow, cápsulas biseladas, punto luminoso,
franjas industriales, línea discontinua, gradiente holográfico y cápsula
segmentadora.

## Implementacion modificacion N° 4: inicio del renderer 2.5D

Se añadió el renderer interno `shelf` como primera implementación experimental
de la fase 2.5D.

El contrato reutiliza `surface` para la repisa superior y añade:

- `shelf.geometry`:
  - ángulo de la repisa;
  - ángulo y profundidad del canto;
  - grosor del rim;
  - margen horizontal;
- `shelf.edge`:
  - color;
  - gradiente;
  - radio;
  - borde;
- `shelf.rim`:
  - color;
  - opacidad;
  - glow limitado.

`ShelfThemeBackground.qml` compone tres superficies internas:

1. repisa superior inclinada;
2. canto frontal;
3. rim luminoso.

La inclinación utiliza `Rotation` de Qt Quick con `origin`, `axis` y `angle`.
No utiliza `distanceToPlane`, incorporado en Qt 6.11, ni Qt Quick 3D. La
referencia técnica se contrastó con:

- `kde-sdk/plasma-workspace/applets/analog-clock/qml/Hand.qml`;
- `kde-sdk/frameworks/kirigami/autotests/tst_sceneposition.qml`;
- el tipo público `QtQuick/Rotation`, disponible desde Qt Quick 2.0 y 6.0.

Se creó el fixture externo:

```text
docs/themes/2.5d/01_cristal_integrado_2_5d.json
```

El tema adapta la propuesta 1 con repisa de vidrio, canto azul, rim luminoso y
separador integrado. Permanece fuera del `.plasmoid`.

Límites deliberados:

- sólo modo flotante horizontal;
- sin animación continua;
- sin texturas, shaders o imágenes;
- las propuestas 2–12 quedan pendientes;
- la geometría no se considera validada hasta revisarla en Plasma real.

Validación técnica:

- `ShelfThemeBackground.qml` y `DockBackground.qml` superaron `qmllint`
  focalizado sin diagnósticos;
- `qmllint` global Fedora:
  - `757` advertencias;
  - `744` advertencias `unqualified`;
  - `0` de layout;
  - `13` propiedades Plasma del baseline;
  - `0` errores de importación;
- compilación completada;
- `ctest`: `5/5`;
- los trece temas externos pasan `jq` y `DockThemeValidator`;
- paquete Fedora generado correctamente;
- el paquete incluye `ShelfThemeBackground.qml`;
- el paquete no incluye `docs/themes/` ni el fixture 2.5D;
- el único JSON empaquetado continúa siendo `metadata.json`.

Pendiente:

- importar `01_cristal_integrado_2_5d.json` en Plasma real;
- revisar perspectiva, clipping, escala de iconos, canto y rim;
- probar la convivencia con el espectro;
- decidir ajustes geométricos antes de convertir los temas 2–12.

### Validacion visual del usuario: renderer shelf

El 2026-07-16 el usuario probó la versión inicial de
`01_cristal_integrado_2_5d.json` en Plasma real,
aportó una captura y confirmó:

> "es funcional, se ve como si estuvieran sobre un cristal inclinado"

La captura confirma:

- la repisa inclinada se reconoce visualmente;
- los iconos permanecen legibles y ordenados;
- no se observa clipping grave del fondo;
- canto y rim se representan de forma continua;
- reloj, papelera, separador e indicadores conservan su posición;
- el renderer es funcional en el modo flotante horizontal probado.

La validación funcional no equivale todavía a cierre artístico. Como
preferencias de acabado quedan:

- equilibrar la presencia del canto frontal;
- reforzar o suavizar la perspectiva según cada material;
- mejorar la transición visual entre repisa, rim e iconos;
- ajustar luces, transparencias y sombras por tema.

Con esta confirmación se considera estable la geometría base y puede comenzar
el catálogo inicial 2.5D sin modificar el motor.

## Implementacion modificacion N° 5: catálogo inicial 2.5D

Después de la validación visual del usuario se completó el catálogo
experimental inicial previsto, conservando el renderer `shelf` sin cambios.

Se añadieron:

1. `01_cristal_integrado_2_5d.json`;
2. `02_madera_barnizada_2_5d.json`;
3. `03_acero_industrial_2_5d.json`;
4. `04_obsidiana_2_5d.json`;
5. `05_marco_neon_2_5d.json`.

Las adaptaciones comparan cinco direcciones de material:

- vidrio translúcido;
- madera barnizada;
- acero industrial;
- obsidiana;
- marco neón.

Cada tema incluye superficie, canto, rim y separador coherentes. Los efectos
que el contrato todavía no representa —vetas, texturas, sombras interiores y
patrones complejos sobre la repisa— permanecen simplificados.

Validación:

- los diecisiete JSON de `docs/themes/` pasan `jq`;
- los diecisiete JSON pasan `DockThemeValidator`;
- `git diff --check` no detecta errores.

Los temas 6–12 quedan pendientes hasta comparar visualmente este primer grupo.

## Implementacion modificacion N° 6: pulido geométrico Urban Dock

El usuario aportó una referencia visual de Urban Dock y solicitó aproximar sus
formas geométricas. La comparación mostró que la primera versión inclinaba un
rectángulo, pero no generaba el estrechamiento posterior ni los biseles del
objeto de referencia.

Se sustituyó la representación de la repisa por polígonos de
`QtQuick.Shapes`:

- cubierta trapezoidal, más estrecha en la parte posterior;
- canto frontal trapezoidal;
- extremos inferiores biselados;
- facetas laterales de luz y sombra;
- línea posterior y rim frontal;
- sombra poligonal simplificada.

El contrato `shelf.geometry` añadió:

- `topDepthRatio`;
- `backInset`;
- `sideBevel`.

Los campos antiguos `topAngle` y `edgeAngle` continúan aceptándose para
compatibilidad con copias administradas de la primera prueba, pero el renderer
nuevo no depende de ellos.

Los cinco temas 2.5D fueron ajustados para usar la nueva perspectiva. La
implementación conserva:

- EQ en una capa superior;
- ausencia de animación permanente;
- ejecución limitada al modo flotante;
- temas JSON fuera del paquete;
- ausencia de Qt Quick 3D, shaders o imágenes.

Referencia técnica:

- Plasma utiliza `QtQuick.Shapes` en
  `kde-sdk/plasma-workspace/kcms/users/src/ui/FingerprintProgressCircle.qml`;
- Kirigami utiliza la misma API en
  `kde-sdk/frameworks/kirigami/src/controls/private/PullDownIndicator.qml`.

Validación técnica:

- `ShelfThemeBackground.qml` superó `qmllint` focalizado sin diagnósticos;
- `qmllint` global Fedora se mantuvo en `757` advertencias:
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades Plasma del baseline;
  - `0` errores de importación;
- compilación completada;
- `ctest`: `5/5`;
- los diecisiete temas externos pasan `jq` y `DockThemeValidator`;
- paquete Fedora generado correctamente;
- `git diff --check` sin errores.

Pendiente:

- volver a importar los cinco temas 2.5D;
- comparar visualmente trapecio, biseles, canto y sombra con la referencia;
- ajustar valores de cada JSON según material, sin reescribir el motor.

## Implementacion modificacion N° 7: afinado visual 2.5D

La segunda captura del renderer poligonal confirmó que la silueta trapezoidal
era correcta, pero también mostró tres desequilibrios:

- el canto frontal ocupaba demasiado alto y dominaba los iconos;
- la cubierta superior quedaba demasiado estrecha;
- la sombra poligonal se percibía como otra placa sólida.

Se conservó el motor `QtQuick.Shapes` y se realizó un ajuste incremental:

- profundidad del canto reducida de `20–23` a `11–13`;
- cubierta superior ampliada mediante `topDepthRatio` de `0.70–0.76`;
- estrechamiento posterior suavizado con `backInset` de `14–17`;
- biseles laterales reducidos a `4–5`;
- rim reducido a `2–3`;
- sombra poligonal atenuada;
- reflejo gradual añadido sobre la cubierta;
- filo inferior fino añadido al canto.

Los cambios mantienen diferencias pequeñas por material: madera y acero
conservan un canto algo más grueso, mientras cristal, obsidiana y neón usan una
silueta más ligera.

Validación técnica:

- `ShelfThemeBackground.qml` superó `qmllint` focalizado sin diagnósticos;
- los cinco JSON 2.5D pasan `jq` y `DockThemeValidator`;
- `ctest`: `5/5`;
- paquete Fedora creado correctamente;
- `qmllint` global conserva `757` advertencias:
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades Plasma del baseline;
  - `0` errores de importación;
- el paquete incluye el renderer actualizado y no incluye `docs/themes/`.

Pendiente:

- volver a importar el JSON para reemplazar la copia administrada;
- comparar visualmente la nueva proporción en Plasma real;
- decidir si algún material necesita un ajuste individual posterior.

## Implementacion modificacion N° 8: nomenclatura y espesor 2.5D

Se corrigió la identidad del catálogo para no presentar como 3D una
composición que utiliza geometría 2.5D:

- los cinco nombres visibles usan ahora `2.5D`;
- los archivos externos fueron renombrados de `_3d.json` a `_2_5d.json`;
- la versión declarada de cada tema subió de `1.0` a `1.1`;
- la documentación del catálogo utiliza la misma terminología.

También se redujo el espesor simulado del canto:

- cristal, obsidiana y marco neón usan `edgeDepth: 8`;
- madera y acero usan `edgeDepth: 9`;
- el contrato conserva el rango `8–28` para temas externos, pero los ejemplos
  oficiales se sitúan ahora en su extremo ligero.

No se redujo la profundidad de la cubierta ni la perspectiva trapezoidal. El
cambio afecta únicamente la altura visible del canto frontal.

Validación técnica:

- los diecisiete JSON de `docs/themes/` pasan `jq`;
- los diecisiete temas pasan `DockThemeValidator`;
- no quedan nombres visibles 3D ni referencias a los cinco nombres de archivo
  anteriores dentro del catálogo y su documentación;
- `git diff --check` no detecta errores.

Pendiente:

- volver a importar los temas renombrados, porque el repositorio administra
  copias por contenido;
- confirmar visualmente el nuevo espesor en Plasma real.

### Aprobacion del usuario: fondos 2D y 2.5D

El 2026-07-16 el usuario dio por aprobados los temas 2D y 2.5D después de las
iteraciones de geometría, separadores, sombras, rim, nomenclatura y espesor.

Esta aprobación cierra la fase visual de fondos personalizados. Ajustes
posteriores del catálogo se tratarán como nuevas ampliaciones artísticas, no
como bloqueadores del renderer actual.

## Implementacion modificacion N° 9: pestaña Visualizador de audio

La configuración del visualizador fue extraída de `ConfigAspect.qml` a una
página independiente:

```text
contents/ui/config/ConfigAudioVisualizer.qml
```

La nueva categoría `Audio visualizer` aparece inmediatamente después de
`Appearance` y usa el icono Breeze `audio-volume-high`.

La página reúne:

- activación del visualizador;
- aviso permanente de privacidad;
- modo de fondo;
- intensidad;
- colores Plasma o reactivos;
- cantidad de barras o densidad;
- estilo;
- movimiento rítmico;
- dirección desde el borde.

Se conservaron sin cambios las claves `cfg_audioSpectrum*`, de modo que las
preferencias existentes continúan cargándose y guardándose. `Appearance`
queda dedicada a temas, etiquetas e indicadores.

Accesibilidad:

- controles estándar mantienen navegación por teclado y foco nativo;
- selectores y slider incorporan nombres accesibles específicos;
- los controles dependientes permanecen deshabilitados cuando el visualizador
  está apagado;
- el aviso de privacidad no depende únicamente del icono o el color.

Validación técnica:

- `ConfigAudioVisualizer.qml` supera `qmllint` sin diagnósticos propios;
- `qmllint` global conserva el baseline:
  - `757` advertencias;
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades conocidas;
  - `0` errores de importación;
- `ctest`: `5/5`;
- paquete Fedora generado correctamente;
- el artefacto contiene `ConfigAudioVisualizer.qml`, `ConfigAspect.qml` y la
  categoría actualizada;
- `git diff --check` sin errores.

Pendiente:

- abrir la configuración en Plasma real;
- comprobar la nueva categoría, orden de foco y persistencia de preferencias;
- revisar la página con ancho normal y estrecho.

## Implementacion modificacion N° 10: biblioteca desplegable de temas

Se añadió una biblioteca reactiva de temas administrados sin JavaScript
externo. La ubicación definitiva es:

```text
QStandardPaths::GenericDataLocation/punchi-dock-remastered/themes/
```

En una instalación Linux habitual:

```text
~/.local/share/punchi-dock-remastered/themes/
```

El namespace `punchi-dock-remastered` es deliberado. No se consulta, modifica
ni migra automáticamente `~/.local/share/punchi-dock/themes/`, evitando
colisiones con una instalación legacy.

`DockThemeRepository` expone ahora:

- la propiedad reactiva `availableThemes`;
- la señal `themesChanged`;
- el método `refreshThemes()`.

Cada entrada válida contiene:

- identificador administrado;
- nombre legible;
- etiqueta visible con tipo `2D` o `2.5D`;
- renderer;
- versión declarada.

El escaneo sólo admite:

- archivos `.json` con nombre hexadecimal de dieciséis caracteres;
- archivos normales y legibles, nunca symlinks;
- tamaño entre `1` byte y `64 KiB`;
- contenido aceptado por `DockThemeValidator`.

`ConfigAspect.qml` conserva el selector Plasma/Personalizado y añade, para el
modo personalizado:

- un `ComboBox` con la biblioteca instalada;
- estado vacío traducible;
- botón `Importar…`;
- selección automática del tema recién importado.

No se añadieron presets a `contents/themes/`, no se modificó `main.qml` ni se
renombró `dockThemeCustomId`. Los renderers `flat` y `shelf` continúan usando
la integración existente.

Validación técnica:

- compilación del módulo C++ completada;
- `ctest`: `5/5`;
- pruebas nuevas para:
  - almacenamiento exclusivo en el namespace Remastered;
  - ausencia de escritura en la ruta legacy;
  - listado con nombre, ID y renderer;
  - rechazo de nombres no administrados;
  - notificación reactiva sin emisiones redundantes;
- `.qmltypes` sincronizado con la nueva API;
- `ConfigAspect.qml` no añade propiedades o señales QML desconocidas;
- `qmllint` global conserva el baseline:
  - `757` advertencias;
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades conocidas;
  - `0` errores de importación;
- paquete Fedora generado correctamente;
- el paquete expone la API nueva y continúa sin incluir JSON de temas;
- `git diff --check` sin errores.

Pendiente:

- comprobar en Plasma real el listado de varios temas;
- importar un tema y confirmar su selección inmediata;
- reiniciar el KCM y verificar persistencia;
- comprobar el estado vacío en una cuenta sin temas.
- ejecutar `build-debian-package.sh` en Debian 13; el wrapper rechazó
  correctamente ejecutarse desde el host Fedora actual.

## Implementacion modificacion N° 11: importacion por carpeta

La biblioteca admite ahora importar colecciones completas mediante el mismo
flujo seguro utilizado para un archivo individual.

`DockThemeRepository` incorpora `importThemeDirectory()`, que:

- acepta únicamente una carpeta local elegida por el usuario;
- procesa archivos `.json` de la carpeta y sus subcarpetas;
- considera la extensión sin distinguir mayúsculas y minúsculas;
- rechaza enlaces simbólicos, archivos ilegibles, vacíos, mayores de `64 KiB`
  o incompatibles con `DockThemeValidator`;
- limita cada operación a 256 candidatos;
- normaliza y deduplica cada tema por el hash de su contenido;
- actualiza la biblioteca una sola vez al terminar.

El resultado expuesto a QML diferencia:

- archivos candidatos;
- temas añadidos;
- temas ya instalados;
- archivos rechazados;
- archivos no procesados por el límite;
- primer tema válido disponible para selección inmediata.

En `ConfigAspect.qml`, el botón `Importar…` abre un menú anclado con:

- `Importar archivo…`;
- `Importar carpeta…`.

La carpeta se selecciona mediante `QtDialogs.FolderDialog`, siguiendo el patrón
usado por Plasma en
`kde-sdk/plasma-workspace/wallpapers/image/imagepackage/contents/ui/AddFileDialog.qml`.
El resumen del lote es visible, traducible y no comunica el resultado sólo por
color o iconografía.

Validación técnica:

- compilación del módulo nativo completada;
- `ctest`: `5/5`;
- `qmllint` global Fedora conserva el baseline:
  - `757` advertencias;
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades conocidas;
  - `0` errores de importación;
- prueba de repositorio ampliada para:
  - ignorar archivos que no sean JSON;
  - aceptar `.json` sin distinguir mayúsculas;
  - añadir temas nuevos;
  - detectar duplicados;
  - rechazar JSON inválido sin abortar el lote;
  - rechazar carpetas inexistentes;
- `ConfigAspect.qml` supera `qmllint` individual sin diagnósticos;
- `.qmltypes` sincronizado con `importThemeDirectory()`;
- paquete Fedora generado correctamente sin incorporar JSON de temas;
- `git diff --check` sin errores.

Pendiente:

- instalar el paquete actualizado en Plasma;
- importar visualmente `docs/themes/` y comprobar el resumen del lote;
- recorrer el menú y el selector de carpeta sólo con teclado;
- ejecutar la validación nativa en Debian 13.

### Ampliacion recursiva de la modificacion N° 11

- El escaneo usa `QDirIterator::Subdirectories` sin `FollowSymlinks`.
- Los candidatos se ordenan por ruta completa antes de importarse para obtener
  un resultado estable.
- `docs/themes/` se reorganizó en:
  - `docs/themes/2d/`;
  - `docs/themes/2.5d/`.
- La prueba automatizada coloca un tema válido dentro de una subcarpeta y
  confirma que es descubierto e importado.
- La misma prueba enlaza una carpeta externa y confirma que el iterador no la
  recorre.
- Los diecisiete JSON reorganizados superan validación sintáctica con `jq`.
- Vista previa y galería remota permanecen explícitamente fuera del alcance.

## Implementacion modificacion N° 12: organizacion administrada y borrado

Cada uno de los diecisiete fixtures externos quedó dentro de una carpeta con
nombre propio bajo `docs/themes/2d/` o `docs/themes/2.5d/`. De este modo,
importar `docs/themes/` obliga a recorrer tres niveles y comprueba el flujo
recursivo con una estructura cercana a una colección distribuible.

Las importaciones nuevas se guardan bajo:

```text
themes/2d/<nombre-seguro>/<id>.json
themes/2.5d/<nombre-seguro>/<id>.json
```

El nombre de carpeta se deriva exclusivamente de metadatos ya validados. Se
normalizan acentos y separadores, y no se reutilizan rutas suministradas por la
colección. El repositorio sigue descubriendo recursivamente archivos planos
anteriores para no invalidar instalaciones existentes.

`DockThemeRepository` incorpora `removeTheme(themeId)`. La operación:

- exige un identificador hexadecimal administrado de dieciséis caracteres;
- localiza el archivo únicamente dentro de la biblioteca Remastered;
- ignora symlinks;
- elimina sólo el JSON identificado;
- limpia carpetas de tema y renderer cuando quedan vacías;
- refresca `availableThemes` y limpia el estado si el tema eliminado estaba
  cargado.

En Apariencia se añadió un botón de papelera junto al selector. Un
`Kirigami.PromptDialog` exige confirmación explícita y muestra el nombre del
tema. Si se elimina el tema activo, el KCM selecciona otro tema disponible; si
la biblioteca queda vacía, limpia el identificador y vuelve al fondo Plasma.
El flujo mantiene acciones con nombre accesible, foco estándar y textos
traducibles.

Validación automatizada:

- compilación del módulo nativo completada;
- `ctest`: `5/5`;
- baseline global de `qmllint` conservado:
  - `757` advertencias;
  - `744` `unqualified`;
  - `0` de layout;
  - `13` propiedades conocidas;
  - `0` errores de importación;
- pruebas de almacenamiento jerárquico, descubrimiento recursivo,
  compatibilidad plana, borrado activo, limpieza de carpetas, traversal,
  archivo ausente y symlink;
- los diecisiete fixtures reorganizados pasan `jq` y
  `DockThemeValidator`;
- paquete Fedora creado e inspeccionado sin JSON de temas;
- paquete local instalado y Plasma Shell reiniciado correctamente;
- diagnóstico de arranque sin errores propios de Punchi Dock.

Pendiente:

- prueba visual de importación completa;
- confirmar por teclado el diálogo de borrado y sus fallbacks;
- validación nativa separada en Debian 13.

### Decisiones tomadas para futuras fases

- JSON será un formato de datos, nunca un mecanismo para cargar código.
- El fondo Plasma seguirá siendo opción visible y fallback permanente.
- La primera implementación funcional será 2D.
- La geometría 2.5D se incorporará como fase experimental separada.
- Los temas externos se importarán a una ubicación administrada.
- Los temas, ejemplos y catálogos se distribuirán por separado y no formarán parte del `.plasmoid`.
- `docs/themes/` será la ubicación local para ejemplos y pruebas mientras se desarrolla el formato.
- el prototipo HTML será la referencia visual para adaptar el catálogo, sin convertirse en dependencia de runtime.
- El visualizador existente se preservará como capa independiente.
- El esquema se versionará desde su primera publicación.
- El separador es parte de la identidad visual global del tema, no una
  preferencia persistente independiente por elemento.

### Soluciones descartadas para no mezclar alcance

- cargar temas externos como HTML, CSS, QML o JavaScript;
- usar `Loader` para ejecutar componentes aportados por terceros;
- depender de `XMLHttpRequest` para leer archivos locales externos;
- guardar solamente la ruta absoluta del tema seleccionado;
- crear `contents/themes/` o empaquetar presets con el plasmoide;
- prometer blur real mediante una propiedad booleana del JSON;
- incorporar Qt Quick 3D;
- permitir recursos remotos, imágenes externas o shaders en la primera versión;
- permitir que un tema controle layout, tamaño de iconos o comportamiento;
- convertir todos los ejemplos del prototipo antes de estabilizar el motor.
