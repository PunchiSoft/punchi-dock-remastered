# Instrucciones del proyecto: Punchi Dock Remastered

## Alcance y precedencia

Este archivo es la fuente canónica de instrucciones para todo el repositorio.

- Se aplica a todos los archivos y directorios, salvo que exista un `AGENTS.md` más cercano con instrucciones específicas.
- Las instrucciones específicas complementan estas reglas; no deben contradecirlas sin explicar la excepción.
- `.agents/skills/` contiene procedimientos especializados que se activan según la tarea.
- Si una skill contradice este archivo, prevalece este archivo.

## Contexto del proyecto

Punchi Dock Remastered es un plasmoide para KDE Plasma 6 construido principalmente con QML, Qt 6 y JavaScript.

- El código ejecutable del plasmoide vive en `contents/`.
- `metadata.json` define la identidad, versión y compatibilidad declarada del paquete.
- `kde-sdk/` contiene repositorios locales de KDE usados como referencia técnica.
- `docs/Referencias/` conserva evidencia ya verificada del SDK, Qt y los estilos
  instalados, para no volver a leer el SDK completo en cada sesión.
- `docs/` conserva diseño, revisiones y planes temas exclusivos del usuario.
- `bitacora/` registra cambios relevantes del proyecto.

## Matriz de compatibilidad

| Dimensión | Política actual |
|---|---|
| Sistema | Linux |
| Plasma mínimo declarado | 6.0, según `metadata.json` |
| Plasma objetivo | Plasma 6.0+ (Wayland / X11) en Fedora, Arch Linux, Debian 13/14, Kubuntu y derivados |
| Qt mínimo de compilación declarado | Qt 6.6, según `CMakeLists.txt`; no equivale a una garantía de runtime sin pruebas |
| Qt del entorno oficial observado | Qt 6.8.2 en Debian 13 (Trixie), según el setup local del 2026-08-05 |
| KDE Frameworks | KF6 (KF 6.0+) |
| Sesión principal | Wayland (soporte secundario X11) |
| Entorno principal de desarrollo | Debian 13 (Trixie) (anfitrión físico de desarrollo y build universal oficial) |
| Entorno de build universal oficial | Debian 13 (Trixie) con proxies binarios C (`.so`) en `compat/` |
| SDK local | Referencia upstream reciente en `kde-sdk/` |

Reglas derivadas:

1. No elevar el mínimo declarado de Plasma, Qt o KF sin autorización explícita y evidencia de necesidad.
2. No afirmar compatibilidad efectiva con Plasma 6.0 sin una prueba en ese entorno. `metadata.json` expresa el mínimo declarado, no una garantía de pruebas.
3. Una API encontrada en el SDK local puede ser posterior al mínimo declarado. Antes de usarla, comprobar desde cuándo existe o proporcionar una alternativa compatible.
4. Priorizar Wayland. Solo implementar comportamiento específico de X11 cuando la tarea lo requiera expresamente.
5. Los comandos de desarrollo deben ser compatibles prioritariamente con Debian 13. El código debe respetar el mínimo Qt 6.6 declarado cuando sea viable, y toda compatibilidad binaria entre versiones o distribuciones debe validarse con el artefacto real.

## Uso del SDK local

Consultar `kde-sdk/` antes de introducir o cambiar integraciones con Plasma, Kirigami, KPackage, KConfig, ki18n, iconos o modelos de tareas.

La búsqueda debe ser dirigida:

| Dominio | Rutas prioritarias |
|---|---|
| Tareas y ventanas | `kde-sdk/plasma-workspace/libtaskmanager/` |
| Componentes Plasma | `kde-sdk/frameworks/plasma-framework/`, `kde-sdk/plasma-workspace/components/` |
| Kirigami | `kde-sdk/frameworks/kirigami/` |
| Empaquetado | `kde-sdk/frameworks/kpackage/` |
| Configuración | `kde-sdk/frameworks/kconfig/` |
| Traducciones | `kde-sdk/frameworks/ki18n/` |
| Iconos | `kde-sdk/frameworks/kiconthemes/` |
| Servicios | `kde-sdk/frameworks/kservice/` |

Al usar el SDK:

- buscar primero símbolos, tipos, ejemplos y pruebas relacionados con la tarea;
- preferir patrones oficiales sobre APIs inventadas o integraciones externas;
- registrar en la explicación final qué referencia respaldó una decisión relevante;
- distinguir una API estable de una implementación interna o snapshot de desarrollo;
- no modificar `kde-sdk/` salvo que la tarea sea explícitamente mantener o estudiar el SDK.

Antes de repetir una búsqueda amplia en `kde-sdk/`, consultar
`docs/Referencias/`. Esa carpeta conserva evidencia ya verificada, con ruta y
línea, para no volver a leer el SDK completo.

- una referencia acelera la decisión, pero no crea obligaciones ni sustituye a
  este archivo ni a los contratos visuales aprobados;
- si una referencia discrepa del SDK actual, prevalece el SDK y la referencia
  se corrige dentro de la misma tarea;
- cuando la tarea aporte evidencia nueva sobre un tema ya cubierto, actualizar
  la referencia existente en lugar de crear un documento paralelo;
- `docs/Referencias/README.md` y `plantilla-referencia.md` son la fuente
  operativa del formato.

Las consultas puramente documentales o los cambios que no afectan integraciones KDE no requieren una búsqueda artificial en el SDK.

## Arquitectura obligatoria

El flujo preferido es:

```text
UI → señales → controlador → servicio → adaptador de API → KDE
```

Aplicar estas reglas cuando las capas correspondientes existan:

1. La UI representa estado, recoge interacciones y emite señales. No debe ejecutar procesos ni concentrar lógica de negocio compleja.
2. Los controladores coordinan vistas, servicios y estado sin asumir responsabilidades visuales.
3. Los servicios encapsulan operaciones y lógica de negocio. No almacenan estado visual ni preferencias persistentes del usuario.
4. Los adaptadores de API separan dominios como tareas, ventanas o escritorios virtuales. Evitar una API monolítica.
5. Los modelos representan datos; el estado representa condiciones transitorias de la interfaz o aplicación.
6. Los proxies adaptan modelos nativos sin duplicar estructuras que ya expone `QAbstractItemModel`.
7. Ningún módulo lógico o de datos puede depender de componentes visuales.
8. Evitar dependencias circulares entre capas.
9. **Sincronización Reactiva de Configuración (Hot Refresh Obligatorio):** Toda nueva opción, control o ventana emergente de configuración debe reaccionar de forma reactiva y desacoplada a los cambios de configuración (evento "Aplicar" / `onConfigChanged`), invalidando o actualizando las instancias en memoria al instante sin requerir reiniciar `plasmashell`.

La estructura real del repositorio puede evolucionar. No crear carpetas o abstracciones vacías solo para imitar el diagrama; introducir una capa cuando tenga una responsabilidad concreta.

## Modularidad y tamaño

- Cada archivo y componente debe tener una responsabilidad reconocible.
- Evitar concentrar la interfaz y la lógica en `main.qml`.
- Colocar componentes visuales reutilizables en `contents/ui/components/` cuando corresponda.
- Al superar aproximadamente 300–400 líneas, revisar cohesión y oportunidades de extracción.
- El umbral de líneas es una señal de revisión, no una orden de fragmentar código cohesivo.
- Evitar reescrituras extensas si una modificación incremental resuelve el problema.

## QML e integración visual

- Preferir componentes oficiales de Plasma y Kirigami cuando correspondan al contexto del plasmoide.
- Usar colores, tipografía, medidas y métricas proporcionadas por el tema y el sistema.
- Usar unidades visibles coherentes en la configuración: `px` para medidas físicas o de trazo, `%` para escalas visuales relativas, opacidad, intensidad y proporciones. Los multiplicadores `1x`, `1.5x` o similares deben quedar como representación interna salvo que el contexto técnico exija mostrarlos.
- Nombrar los controles según su unidad real: `grosor` para trazos en `px`, `escala` para valores relativos en `%`, y `tamaño` solo cuando no oculte la diferencia entre medida absoluta y escala visual.
- No introducir colores fijos para elementos que deban adaptarse al tema claro u oscuro.
- Componer cada popup alrededor de una sola superficie visual principal. Añadir fondos, bordes o marcos internos únicamente cuando cumplan una función concreta de recorte, contraste, interacción o comunicación de estado; evitar composiciones de tarjeta dentro de tarjeta y separar colecciones mediante espaciado y estados transitorios antes que con contornos permanentes.
- Favorecer bindings declarativos legibles; evitar bindings costosos, ciclos y actualizaciones continuas innecesarias.
- Mantener animaciones sutiles y acotadas. Considerar coste de CPU/GPU y preferencias de reducción de movimiento.
- Preservar navegación por teclado, foco visible, nombres accesibles y escalado.
- No asumir que una API de compatibilidad con Plasma 5 está prohibida solo por su nombre. Si el proyecto ya depende de `Plasma5Support`, evaluar su disponibilidad, necesidad y alternativa antes de retirarla.
- **Animaciones de Superficies Flotantes (Fade In / Fade Out):** Al abrir o cerrar overlays o diálogos flotantes a pantalla completa, diferir la visibilidad (`visible = false`) mediante un temporizador `closeTimer` hasta que concluya la animación de Fade Out (`opacity: 1.0 -> 0.0`), evitando cortes abruptos en la interfaz.
- **Geometría de Diálogos Flotantes a Pantalla Completa:** Utilizar `PlasmaCore.Dialog` con `location: Floating`, `x: 0, y: 0`, `width: Screen.width, height: Screen.height` e integración `openWithReveal()` / `closeWithFade()` para cubrir el monitor sin interferencia de struts.
- **Poblado Reactivo de Vistas QML:** Alimentar vistas dinámicas asíncronas (`GridView` / `ListView`) desde C++ a través de un `ListModel` reactivo para garantizar la renderización inmediata de elementos.

### Región de blur en superficies temáticas Plasma

Cuando una superficie visible use un `KSvg.FrameSvgItem`, especialmente
`widgets/background`, y la ventana reserve además espacio para la sombra o el
borde del tema, calcular la región de blur desde la geometría temática efectiva:

- no usar la ventana completa ni deducir la región mediante márgenes fijos o
  porcentajes del ancho o alto;
- tomar como fuente reactiva la propiedad `mask` del `FrameSvgItem` y leer sus
  cuatro valores de `inset`, que indican dónde comienza el fondo efectivo al
  excluir la proyección exterior del borde y la sombra;
- no sustituir `inset` por `FrameSvgItem.margins`: `margins` distribuye el
  contenido interior y produce una región distinta; tampoco aplicar la máscara
  completa sin contracción cuando incluya la proyección exterior del tema;
- contraer la máscara por cada `inset` sin convertirla en un rectángulo, de modo
  que se conserven esquinas redondeadas, huecos y regiones no convexas;
- expresar el resultado en píxeles lógicos y coordenadas cliente de la ventana;
  mapear la posición desde la jerarquía visual real —por ejemplo con
  `mapToItem(null, ...)`— para seguir traslaciones y animaciones;
- en una `QQuickWindow`, interpretar `mapToItem(null, ...)` como mapeo a la
  escena, equivalente al sistema cliente que consume KWin. No usar
  `mapToGlobal(...)` ni sumar `Dialog.x`, `Dialog.y`, la posición del panel o la
  pantalla: mover la ventana no cambia una región relativa a su área cliente;
- tratar `mapToItem(...)` como una operación de mapeo, no como una declaración
  completa de dependencias QML. Todo binding que atraviese una superficie
  transformada debe leer explícitamente posición, ancho, alto, `scale`,
  `transformOrigin` y los componentes de cada `Translate` involucrado; de ese
  modo el origen se recalcula al desplazar, agrandar, reducir o animar el menú;
- distinguir el estado asentado de una transformación transitoria: el contrato
  de coincidencia exacta del blur se valida con la superficie en `scale === 1`.
  Observar `scale` evita conservar un origen intermedio, pero no escala por sí
  solo la forma de una `QRegion`; si una interacción futura exige silueta exacta
  durante `scale !== 1`, deberá transformar también la región o mantener el
  fondo fuera de esa escala y añadir una prueba específica;
- recalcular al cambiar la máscara, los `inset`, el tamaño, el tema o la
  transformación visual; se permite agrupar señales y reutilizar una región en
  caché cuando su origen y geometría no hayan cambiado;
- validar que los cuatro `inset` sean finitos y no negativos. Si el tema no los
  publica correctamente, conservar la máscara original; si la contracción deja
  una región inválida o vacía, desactivar el blur de forma segura;
- no cambiar el tamaño, márgenes, layout, fondo ni sombra de la superficie para
  corregir un excedente del blur;
- no anclar ni compensar el blur con la caja exterior de la sombra. La sombra
  puede desplazarse o cambiar de extensión según el tema, mientras la región
  solicitada a KWin debe continuar limitada al fondo efectivo delimitado por
  `mask` e `inset`;
- no fijar en código mediciones observadas en un tema concreto, como `12 px`:
  son evidencia de runtime, no métricas universales.

La implementación de referencia vive en `BlurBehindController`,
`PunchiMenuMappedSurfaceGeometry`, `PunchiMenuNormal` y `PunchiMenuCompact`. El
controlador conserva y contrae la `QRegion`; el helper resuelve su origen
reactivo en coordenadas cliente para ambos modos. Este patrón es obligatorio
cuando el fondo temático efectivo no ocupa toda la ventana; una superficie
diseñada intencionadamente para cubrir la ventana completa puede seguir
solicitando blur completo.

La comparación entre `margins`, geometría o máscara completa e `inset`, así
como la diferencia entre la región exacta del blur y la geometría visual del
velo modal, se documenta en
`docs/Referencias/referencia-composicion-visual-punchimenu.md`. Los contratos de
referencia viven en `tests/blurbehindcontroller_test.cpp` y
`tests/punchimenu_context_contract_test.py`; la reactividad ante movimiento,
escala, origen de transformación y tamaño se valida en
`tests/punchimenu_mapped_surface_geometry_test.qml`.

### Resaltado de elementos interactivos de PunchiMenu

Aplicaciones, favoritos, carpetas contenedoras y aplicaciones dentro de
carpetas deben reutilizar `PunchiMenuItemHighlight` en Normal y Fullscreen. El
perfil común es:

- relleno `Kirigami.Theme.highlightColor` al 20 % para hover o selección;
- borde `Kirigami.Theme.highlightColor` de 2 px para selección o foco;
- radio `Kirigami.Units.cornerRadius * 2`;
- escala `1.03` al resaltar y `0.97` durante la presión, condicionada por la
  preferencia de movimiento existente;
- estados de entrada explícitos (`hovered`, `selected`, `pressed`) sin forzar el
  foco desde el puntero;
- semántica accesible y foco visible conservados por el delegado interactivo,
  mientras la superficie decorativa permanece ignorada por accesibilidad.

No duplicar estos valores inline ni introducir perfiles diferentes por modo sin
una nueva revisión visual aprobada. `PunchiMenuSearchBackground`,
`PunchiMenuCategoryPill` y `PunchiMenuActionBackground` permanecen
especializados porque representan foco de entrada, filtro activo y acciones,
no selección de un lanzador.

### Contrato único de hover y estados interactivos

Todo el proyecto debe usar una sola semántica para la interacción de puntero.
No crear variantes locales del mismo comportamiento mediante colores, bordes,
escalas o duraciones copiados inline.

- `hovered` representa únicamente la presencia válida del puntero;
- `focused` representa foco de teclado o accesible y nunca se deduce del hover;
- `pressed` representa presión transitoria y debe poder interrumpirse;
- `selected` representa selección persistente o navegación actual;
- `dropTarget` o sus intenciones especializadas representan DnD y no deben
  simularse mediante `hovered` o `selected` cuando comunicarían otra acción;
- todos los estados deben usar colores del tema, respetar movimiento reducido y
  reaccionar sin temporizadores que sinteticen entradas o mantengan loops;
- cada rol visual debe tener una única primitiva canónica compartida. Extender
  esa primitiva cuando aparezca un segundo consumidor; no copiar su perfil;
- una forma especializada —por ejemplo botón circular, campo de búsqueda,
  categoría, lanzador o magnificación del dock— puede conservar geometría propia,
  pero debe consumir esta misma semántica y no redefinir el comportamiento base;
- toda excepción nueva debe justificarse en una revisión, registrar su rol
  distinto y validarse con puntero, teclado, tema claro/oscuro y movimiento
  reducido antes de incorporarse.

Para lanzadores de PunchiMenu la primitiva canónica sigue siendo
`PunchiMenuItemHighlight`; para acciones, búsqueda y categorías se mantienen
las superficies especializadas enumeradas en la sección anterior. Una futura
migración global debe hacerse por dominio después de inventariar consumidores,
no mediante un reemplazo masivo sin pruebas.

### Skills de movimiento y efectos visuales

Cuatro skills locales gobiernan cómo se implementa, cuánto cuesta y cómo se
audita el movimiento. Activarlas según el trabajo, sin sustituir las skills de
dominio existentes:

| Skill | Usar cuando |
|---|---|
| `plasma-motion-review` | se auditen animaciones existentes antes de refactorizarlas; no modifica código y entrega informe por hallazgo |
| `plasma-fluid-motion` | se implemente o corrija el mecanismo de una animación QML: tipo de animación, retargeting, reversibilidad, movimiento continuo ligado al cursor |
| `plasma-liquid-effects` | se decida el nivel técnico de un material o efecto: propiedades QML, `MultiEffect` o shader |
| `plasma-animation-performance` | la modificación visual pueda alterar fluidez, coste por fotograma o el respeto a la velocidad de animación del usuario |

Orden recomendado al refactorizar movimiento: `plasma-motion-review` →
`plasma-fluid-motion` → `plasma-liquid-effects` solo si hace falta →
`plasma-animation-performance` → validación visual y de rendimiento.

`animations` conserva la política del proyecto sobre qué animar; las cuatro
skills anteriores gobiernan el mecanismo, el coste y la auditoría. La evidencia
verificada de duraciones y efectos vive en
`docs/Referencias/referencia-motion-plasma-qt.md`.

### Perfiles de superficies modales de PunchiMenu

Seleccionar el perfil según la responsabilidad visual de la superficie. No
mezclar propiedades de ambos perfiles por intuición ni copiar sus valores en
componentes nuevos.

#### Perfil `WidgetModal`

Usar `WidgetModal` para las superficies de carpetas abiertas y acciones de
carpeta en PunchiMenu Normal —acoplado o centrado— y Fullscreen:

- fondo Plasma `widgets/background`;
- opacidad, sombra, radio y borde definidos por el tema Plasma;
- sin `Kirigami.ShadowedRectangle` ni sombra numérica adicional;
- velo exterior al 64 % del color de fondo temático;
- mantener clic exterior, bloqueo de rueda, Tab, Mayús+Tab, Escape y
  restauración de foco;
- conservar la geometría funcional propia del contenido; el perfil no define
  ancho ni alto;
- no aplicarlo automáticamente al fondo general de PunchiMenu, menús
  contextuales, tooltips ni popups externos.

El velo y su área de entrada cumplen responsabilidades complementarias. Nunca
retirar el área exterior que bloquea interacción con el contenido posterior.

##### Geometría del velo `WidgetModal` en superficies temáticas

Cuando el velo de `WidgetModal` deba terminar en el fondo efectivo de un
`KSvg.FrameSvgItem`, usar el mismo origen temático que la región de blur, pero
mantener separadas sus representaciones:

- tomar los cuatro valores de `FrameSvgItem.inset` como límite aprobado del
  fondo efectivo;
- mapear las esquinas contraídas desde el `FrameSvgItem` hasta el sistema de
  coordenadas del modal mediante `mapToItem(...)`, siguiendo tamaño,
  traslaciones y animaciones;
- declarar explícitamente como dependencias la posición y el tamaño del modal,
  de la superficie y del fondo, además de `scale`, `transformOrigin` y cada
  `Translate`; `mapToItem(...)` por sí solo no invalida el binding al cambiar
  una transformación de un ancestro;
- validar que los cuatro `inset` sean finitos, no negativos y no vacíen la
  superficie; ante datos inválidos, usar como fallback el rectángulo del
  contenido del menú y no la extensión completa del frame;
- no usar `FrameSvgItem.margins`: delimitan el área de contenido y dejan el
  marco temático sin velo;
- no usar la geometría completa del `FrameSvgItem`: incluye su proyección
  exterior y oscurece la zona de sombra;
- mantener el manto en coordenadas locales del modal y el blur en coordenadas
  cliente de la ventana. Ambos parten del mismo fondo efectivo, pero el manto
  es un `QRect` visual y el blur una `QRegion`; nunca intersectar ni sustituir
  uno con la representación del otro;
- redondear una sola vez en píxeles lógicos: para el blur, el origen mapeado;
  para el manto, el origen normalizado y las diferencias entre las dos esquinas
  mapeadas. No aplicar manualmente el factor de escala del dispositivo;
- conservar la capa de entrada del velo sobre toda la superficie modal aunque
  su capa visual esté acotada al fondo efectivo;
- recalcular al cambiar `inset`, tamaño, tema o transformación visual, sin fijar
  mediciones observadas en una captura;
- validar en Plasma real los cuatro lados y las esquinas. Lint, contratos y
  carga correcta no sustituyen esta comprobación visual.

La implementación aprobada vive en
`PunchiMenuMappedSurfaceGeometry.effectiveBackdropGeometry` y se expone como
`PunchiMenuNormal.folderDialogBackdropGeometry`; sus contratos están en
`tests/punchimenu_folder_ui_contract_test.py` y
`tests/punchimenu_mapped_surface_geometry_test.qml`. El proceso comparativo y
los intentos descartados se documentan en
`docs/Referencias/referencia-composicion-visual-punchimenu.md`.

#### Perfil `ModalElevated`

Usar `ModalElevated` cuando un diálogo, selector o flujo modal ajeno a las
carpetas de PunchiMenu necesite una superficie sólida y una elevación
claramente perceptible. La elevación la aporta el marco del tema, no una sombra
dibujada por el plasmoide:

- fondo temático `solid/dialogs/background` en las superficies elevadas; la
  primitiva admite `dialogs/background` por defecto y `widgets/background` para
  el perfil `WidgetModal`;
- opacidad del panel de 100 %;
- la proyección exterior del marco (borde y sombra del tema) queda fuera del
  fondo efectivo delimitado por `inset`, igual que en el resto de superficies
  temáticas;
- sin `Kirigami.ShadowedRectangle` ni sombra numérica adicional, coherente con
  `WidgetModal`;
- radio y borde proceden del recurso temático; sin rectángulo de relleno
  adicional;
- no añadir propiedades de sombra independientes si no controlan un consumidor
  visual real; la elevación continúa perteneciendo al marco del tema;
- limitarlo a superficies modales elevadas, no al fondo general de PunchiMenu;
- conservar la adaptación a temas Plasma claros y oscuros y validar ambos
  antes de aprobar una superficie nueva.

La implementación compartida de referencia es
`contents/ui/components/punchimenu/PunchiMenuModalSurface.qml`. No copiar los
valores en nuevos componentes: reutilizar o extraer una superficie temática
compartida cuando exista un segundo consumidor confirmado. La especificación
ampliada vive en
`docs/Referencias/referencia-composicion-visual-punchimenu.md`.

## JavaScript, procesos y seguridad

- Usar sintaxis compatible con el motor JavaScript de la versión objetivo de QML.
- Preferir `const` y `let`; evitar contaminar el ámbito global.
- Usar `.pragma library` solo cuando el comportamiento compartido y sin estado lo justifique.
- Tratar entradas, rutas, argumentos y datos externos como no confiables.
- No construir comandos concatenando datos sin validar.
- Aplicar privilegio mínimo y manejar explícitamente fallos, recursos ausentes y resultados vacíos.
- Bajo Wayland, utilizar integraciones nativas de KDE para tareas restringidas por el compositor.
- Python puede utilizarse para herramientas de desarrollo en `scripts-dev/`, pero no como dependencia del runtime del plasmoide.

## Idioma fuente del proyecto

- El inglés es el único idioma fuente del código, independientemente del idioma usado por el usuario para dar instrucciones.
- Escribir en inglés identificadores, comentarios, mensajes de log, errores propios, nombres y mensajes de pruebas, salidas de scripts y textos visibles de fallback en QML, JavaScript, C++ y herramientas del repositorio.
- No introducir labels, menús, tooltips, placeholders, estados, mensajes accesibles ni otros textos visibles directamente en español u otro idioma dentro del código ejecutable.
- Mantener las traducciones exclusivamente en `po/<idioma>.po`, salvo los campos localizados de formatos que lo requieran expresamente, como `Name[es]` o `Description[es]` en `metadata.json`.
- Si se encuentra un texto fuente del runtime en un idioma distinto del inglés, convertirlo a inglés y conservar su traducción mediante ki18n.
- La documentación interna en `docs/`, `bitacora/` y los archivos de instrucciones puede conservar el idioma establecido por el documento o solicitado por el usuario; esta excepción no se extiende al código ni a la interfaz.

## Internacionalización

- Todo texto visible para el usuario debe ser traducible mediante ki18n.
- Usar `i18n`, `i18nc` o `i18np` según contexto y pluralidad.
- Usar marcadores como `%1` en lugar de concatenar fragmentos traducidos.
- No traducir anticipadamente en JavaScript si ello impide reaccionar a cambios de idioma.
- Tratar como cambio de internacionalización cualquier alta, modificación o retirada de menús, labels, botones, tooltips, placeholders, estados vacíos, errores, notificaciones y nombres o descripciones accesibles.
- Después de cambiar un texto visible, ejecutar `scripts-dev/update-translations.sh`, actualizar todos los catálogos soportados y validar que no queden entradas vacías ni difusas.
- Mantener inglés como fallback y no declarar un idioma compatible hasta que su PO esté completo, revisado y supere `msgfmt --check --check-format` y `translation_catalog_test`.
- Empaquetar los MO bajo `contents/locale/<idioma>/LC_MESSAGES/` con el dominio exacto del plasmoide; no colocarlos en `locale/` en la raíz del KPackage.

## Notas y textos explicativos dirigidos al usuario

Todo texto cuya función sea explicar a quien usa el dock una función, un modo, un
límite o una precaución —notas de paneles, avisos y advertencias, tooltips
explicativos, textos de ayuda bajo un control, estados vacíos con causa, mensajes
de error explicativos y notas de manuales o guías públicas— se propone antes de
implementarlo:

1. redactar la propuesta con su ubicación, su disparador, el texto en inglés, su
   traducción al español, el énfasis previsto, su extensión y lo que deja fuera;
2. presentarla y esperar la confirmación explícita del usuario; el silencio no
   autoriza, y no se escribe código, ni se traduce, ni se extraen catálogos antes
   de esa respuesta;
3. implementar literalmente el texto aprobado; cualquier cambio posterior de
   redacción, longitud o énfasis se propone de nuevo;
4. registrar la redacción aprobada en la modificación o la revisión
   correspondiente.

El énfasis forma parte de la decisión: qué parte va en negrita y qué parte queda
en peso normal se propone junto con el texto. Pedir «mejóralo» no delega el
contenido. Aplicar la skill `notice-copy-approval` para el procedimiento completo.

## Empaquetado

- Mantener `metadata.json` coherente con las capacidades reales del plasmoide.
- Revisar `.kpackageignore` cuando se creen carpetas o artefactos que no pertenezcan al paquete.
- `docs/`, `bitacora/`, `kde-sdk/`, `.agents/`, copias, logs y artefactos de desarrollo no deben incluirse en la distribución.
- No cambiar versión, licencia, compatibilidad mínima o identificador del plugin como efecto lateral de otra tarea.

## Flujo de trabajo

Antes de cambiar código:

1. Leer este archivo y cualquier `AGENTS.md` aplicable al archivo objetivo.
2. Inspeccionar el estado existente y preservar cambios ajenos.
3. Para revisar un bug reportado, activar `review-cycle` como procedimiento
   inicial. Recuperar contexto, evidencia e hipótesis y preparar el plan; no
   activar anticipadamente las skills de validación ni ejecutar sus pruebas.
   Incorporar las demás skills cuando corresponda a su etapa de trabajo.
4. Consultar el SDK local cuando la tarea afecte integraciones KDE.
5. Elegir el cambio más pequeño que satisfaga el objetivo.

Después de preparar la revisión:

6. Implementar la corrección autorizada y preparar los casos de validación
   pertinentes, preservando los cambios ajenos.
7. Ejecutar la validación posterior: CTest completo, control del baseline de
   `qmllint`, auditoría ki18n y preflight de seguridad, según el protocolo
   proporcional siguiente. Las pruebas de comportamiento y runtime también
   corresponden a esta etapa. Registrar resultados y limitaciones.
8. Actualizar la revisión y la bitácora cuando corresponda y entregar el
   resultado con la evidencia obtenida.

La revisión inicial no debe lanzar la suite técnica para repetirla después de
implementar. Leer pruebas, logs y baselines existentes para preparar el plan no
equivale a ejecutarlos. Si el diagnóstico necesita una reproducción técnica
previa, justificar y limitar esa comprobación al fallo investigado; no iniciar
por ello la suite completa. Conservar la evidencia previa de `qmllint` para la
comparación antes/después. Una validación ya completada solo se repite si hay
cambios posteriores relevantes, fallos pendientes o una solicitud explícita
del usuario. Las comprobaciones preventivas necesarias antes de una operación
riesgosa siguen aplicando y no implican ejecutar pruebas anticipadamente.

Durante el trabajo:

- no mezclar refactorizaciones no solicitadas con correcciones o funciones;
- no modificar archivos ajenos al alcance sin una razón necesaria;
- documentar decisiones que no sean evidentes desde el código;
- mantener las operaciones reversibles siempre que sea posible.

## Protocolo de validación proporcional posterior a modificaciones

### Preflight de entorno y limpieza de pruebas

Antes de ejecutar una suite que incluya QML, D-Bus, portales o ventanas:

1. recompilar los targets afectados; `ctest` ejecuta binarios existentes y no
   sustituye `cmake --build`;
2. comprobar con un probe breve que el entorno puede crear la sesión D-Bus y
   ejecutar un test QML representativo;
3. si el sandbox rechaza sockets o repite timeouts durante la inicialización,
   detener esa ejecución sin esperar el resto de los timeouts y solicitar la
   ejecución equivalente en el host; no relajar, omitir ni presentar esos
   tests como aprobados;
4. ejecutar en el host solo las pruebas autorizadas. Salir del sandbox no
   autoriza por sí mismo instalaciones, red, gestores de paquetes ni reinicios
   de Plasma;
5. usar paralelismo moderado acorde con CPU y memoria, sin convertir una
   medición puntual en un nuevo umbral permanente.

Cada test debe ser dueño de un directorio temporal único y limpiar procesos,
sockets, configuraciones, cachés, paquetes, logs y archivos que haya creado,
tanto tras éxito como tras fallo, señal o timeout. Cuando librerías globales
puedan escribir durante la terminación del proceso, un wrapper padre debe ser
dueño del temporal y eliminarlo únicamente después de que finalice todo el
árbol hijo. No limpiar mediante globs amplios ni rutas compartidas.

Solo se permite conservar temporalmente un artefacto cuando una prueba o
diagnóstico lo requiera de forma explícita. Primero se extraerá la evidencia
necesaria hacia una ruta aprobada y documentada; después se eliminarán el
original, sus cachés auxiliares y los temporales intermedios. Una limpieza que
no pueda completarse debe hacer fallar el test o quedar reportada como
limitación, nunca pasar inadvertida.

La suite técnica completa es obligatoria cuando se modifica código que puede
afectar el plasmoide, su runtime, compilación, empaquetado funcional o pruebas,
y al implementar una función, corregir un bug o realizar una refactorización.
En esos casos deben ejecutarse estas cinco verificaciones antes de entregar:

1. **Suite CTest completa**: Ejecutar `ctest --test-dir build --output-on-failure` y garantizar que el 100% de las pruebas del total activo resulten aprobadas.
2. **Control de Deuda y Baseline de `qmllint`**: Inspeccionar el log de `qmllint` contra el baseline del entorno (`scripts-dev/qmllint-baseline-fedora.env` o `debian`), verificando cero deuda nueva y confirmando que ninguna métrica (`total`, `unqualified`, `missing-property`, `layout`, `import`) haya aumentado.
3. **Auditoría de Catálogos ki18n**: Ejecutar `scripts-dev/update-translations.sh`, validar con `msgfmt --check --check-format` y comprobar que todos los catálogos soportados (`es`, `de`, `pt_BR`) queden al 100% sin mensajes vacíos ni difusos.
4. **Revisión Preventiva de Seguridad (Preflight)**: Activar `preflight-security-review` para comprobar que no existan secretos expuestos, llamadas peligrosas al sistema, rutas locales indebidas ni fugas de privacidad.
5. **Integridad de las pruebas**: Ejecutar `python3 scripts-dev/test-integrity-guard.py --check` y garantizar que ningún archivo de `tests/`, manifiesto de nombres, suelo por perfil o contrato de gate haya cambiado sin autorización explícita. Un cambio legítimo se registra antes con `--update --authorized "<motivo>"`.

No ejecutar CTest completo de forma automática para cambios que no afectan el
código ni el comportamiento del plasmoide, por ejemplo:

- documentación interna o archivos de instrucciones como `AGENTS.md`;
- limpieza del seguimiento de Git;
- añadir, retirar o ignorar archivos auxiliares que no participan en el
  runtime, la compilación ni el paquete instalado;
- subir o retirar recursos no ejecutables sin consumidores en el código.

Antes de aplicar esta excepción, comprobar mediante búsqueda de referencias que
el archivo realmente no participa en el plasmoide. Para estos cambios ejecutar
solo verificaciones proporcionales al alcance, como inventario, referencias,
`git diff --check`, sintaxis del archivo afectado o configuración limpia cuando
corresponda. Cada indicador de la suite completa se ejecuta por separado cuando
su dominio sí resulte afectado: `qmllint` para QML, ki18n para textos visibles o
extracción de catálogos y preflight para seguridad, privacidad o publicación.

**Requisito de reporte explícito**: Cuando aplique la suite completa, el agente
debe incluir en su respuesta final y en la bitácora correspondiente la tabla con
CTest, Baseline qmllint, ki18n, Seguridad e Integridad de pruebas. Cuando aplique
la excepción, debe indicar brevemente qué verificaciones proporcionales realizó y
por qué omitió la suite completa.

### Commit y push de cambios ya validados

Una solicitud de commit o push no activa nuevamente CTest, `qmllint`, ki18n ni
otras pruebas técnicas. Esas verificaciones pertenecen al ciclo de modificación
y deben haberse ejecutado cuando se implementó y revisó el cambio.

Al preparar un commit o push:

- revisar `git status` y el diff preparado únicamente para confirmar el alcance
  exacto y evitar incluir archivos ajenos;
- usar staging por rutas concretas y redactar un mensaje coherente con el cambio;
- proceder con el commit y push sin repetir pruebas ya realizadas;
- repetir una validación solo cuando el código haya cambiado después de la
  evidencia registrada o cuando el usuario lo solicite expresamente;
- no usar la proximidad del push como motivo suficiente para ejecutar de nuevo
  suites, empaquetado, instalación o pruebas de runtime.

La inspección del diff preparado es una protección de integridad del commit, no
una nueva fase de validación técnica del proyecto.

## Integridad de las pruebas

Los archivos de `tests/` son la evidencia del contrato del proyecto, no un
obstáculo para obtener un resultado favorable. Un verde conseguido debilitando
una prueba oculta el bug que esa prueba existía para atrapar.

### Protección por defecto

Toda prueba existente queda protegida. Sin autorización explícita del usuario no
se puede modificar, eliminar, renombrar, desactivar, omitir ni debilitar:

- ningún archivo bajo `tests/`, aunque el cambio solo añada líneas: añadir líneas
también puede neutralizar una prueba mediante un retorno temprano, un `skip`, un
cambio de fixture, un mock, una condición o una excepción;
- los nombres canónicos de CTest del perfil, que no pueden desaparecer, renombrarse
ni perderse por un registro condicional;
- el suelo de cantidad de pruebas del perfil;
- `tests/CMakeLists.txt` y el resto de la infraestructura que decide qué se
prueba;
- los scripts de gate, que deben seguir ejecutando el gate real sin enmascararlo
ni filtrarlo.

Crear un archivo de prueba nuevo sí está permitido sin autorización. Una vez
rastreado por Git debe incorporarse con `--update`, que solo añade entradas. Si
registrarlo exige modificar `tests/CMakeLists.txt`, ese cambio es protegido y se
reporta antes de realizarlo.

### Gate obligatorio

Antes de entregar cualquier cambio, como quinta verificación de la suite técnica
completa:

```bash
python3 scripts-dev/test-integrity-guard.py --check
```

Un cambio legítimo se registra únicamente con autorización explícita:

```bash
python3 scripts-dev/test-integrity-guard.py --update --authorized "<motivo>"
```

El recibo del comando y el diff del manifiesto se conservan en la modificación o
la revisión correspondiente. El procedimiento operativo está en la skill
`testing`; la descripción de los datos, en
`scripts-dev/test-integrity/README.md`.

A diferencia del baseline de `qmllint`, donde una cifra menor es mejor, aquí la
cifra es un **suelo**: no puede disminuir sin autorización y se consolida al alza
al incorporar pruebas nuevas.

### Señales de desactivación

`DISABLED`, `WILL_FAIL`, `SKIP_RETURN_CODE`, `skip(`, `ignoreWarning`,
`QEXPECT_FAIL`, `ctest -E` y `ctest ... || true` requieren revisión contextual,
no rechazo automático. Lo preexistente y justificado está documentado en el
baseline de patrones; una aparición nueva detiene la entrega y se reporta.

## Operaciones destructivas, movimientos y renombrados

Activar `safe-removal-review` antes de borrar, sobrescribir, reemplazar, mover o
renombrar archivos y directorios, y antes de retirar funcionalidad. Una
sobrescritura se considera eliminación del contenido anterior.

Reglas obligatorias:

1. Resolver y mostrar objetivos exactos dentro de la raíz autorizada; no operar
   con globs, variables vacías o rutas amplias sin validar.
2. Para dos o más movimientos, construir primero el mapa completo
   `origen → destino` sin mutar el árbol.
3. Comprobar que orígenes y destinos sean únicos, que ningún destino esté vacío
   o exista previamente y que la cantidad de destinos únicos coincida con la
   cantidad de orígenes.
4. No calcular nombres y ejecutar `mv` dentro del mismo bucle sin una fase de
   validación independiente. No permitir sobrescritura por defecto.
5. `BASH_REMATCH` es estado mutable: copiar sus capturas inmediatamente y no
   leerlas después de otra evaluación `=~`. Una captura vacía detiene la tarea.
6. Antes de modificar material ignorado o no rastreado, crear un respaldo
   recuperable y verificar que Git no sea asumido como única vía de retorno.
7. Comparar inventario, tamaños o hashes y referencias después de cada lote
   pequeño. Toda reducción no autorizada obliga a detenerse y tratar el hecho
   como incidente.
8. No retirar fuentes legacy ni respaldos hasta comprobar que todos los
   destinos existen, no están vacíos y sus referencias fueron actualizadas.

### Retención de respaldos locales en `backup/`

`backup/` es material local ignorado por Git (`.gitignore`), sin recuperación por
el repositorio. Su retención está acordada con el usuario, así que la política es
la autorización y **no** se exige crear un respaldo previo de lo que se retira
(la regla 6 de esta sección no aplica a esta carpeta).

1. **Corte de 30 días.** Se retira toda entrada de primer nivel de `backup/` cuya
   fecha de modificación sea anterior o igual a `hoy - 30 días`.
2. **Unidad de eliminación.** Se retira la entrada completa
   (`backup/<nombre>`). Nunca ficheros sueltos dentro de un respaldo: un respaldo
   recortado deja de ser un respaldo válido.
3. **Excepciones que siempre se conservan:** `backup/README.md`, los respaldos
   creados en la sesión en curso y el directorio de las raíces funcionales que
   usan herramientas del repositorio, del que solo se podan sus contenidos
   antiguos. La única raíz funcional hoy es `backup/qmllint-debt-cycle/`, usada
   por `scripts-dev/qmllint_debt_cycle.py`.
4. **Procedimiento obligatorio:** enumerar primero las rutas candidatas exactas
   —sin globs ni variables—, comprobar que cada una está dentro de `backup/`, que
   es única y que ninguna herramienta la referencie, y eliminar después solo esas
   rutas, una por una.
5. **Registro:** cada limpieza se anota en `backup/README.md` con la fecha, el
   corte aplicado, las entradas retiradas y el espacio liberado. Un cambio de
   política exige además una entrada en `bitacora/`.
6. **Nunca elevar el corte** ni usar la limpieza para retirar material vigente,
   referenciado o de la sesión en curso sin autorización explícita del usuario.

## Bitácora y documentación

### Contrato editorial de posts para KDE Store

Los archivos `docs/Post KDE/post-kde-store-<version>.md` deben conservar la
arquitectura visual del último post confirmado como publicado en KDE Store. El
contenido cambia con cada versión; el formato base no debe cambiar por decisión
del agente.

El orden obligatorio es:

1. título `Punchi Dock Remastered <version>`;
2. presentación estable del dock, de PunchiMenu y de su inspiración visual;
3. resumen acumulativo desde el último post publicado;
4. tabla `What changes from <last-version>` / `Qué cambia respecto de
   <última-versión>`;
5. highlights temáticos de la versión;
6. funciones;
7. compatibilidad;
8. rendimiento y privacidad;
9. nota de actualización;
10. licencia;
11. changelog temático, incluida la evidencia de calidad y traducciones.

Reglas derivadas:

- redactar primero el post inglés y mantener su compañero `-es` con el mismo
  orden, hechos, alcance y estado de validación;
- usar temas propios de la versión dentro de highlights y changelog, sin
  sustituir la estructura pública por categorías genéricas como
  `Added / Changed / Fixed`;
- no retirar, renombrar ni reordenar las secciones principales sin autorización
  explícita del usuario;
- conservar los posts históricos sin reescribirlos y actualizar la referencia
  de «último post publicado» solo tras confirmar la publicación externa;
- usar `docs/Post KDE/README.md` y `plantilla-post-kde.md` como fuentes
  operativas del formato antes de preparar una nueva versión.

Para mantener trazabilidad en la documentación local, los documentos nuevos de
`docs/revisiones/` deben usar `revision-YYYY-MM-DD-descriptor.md`. Los
documentos nuevos de `docs/nuevas-modificaciones/` deben usar
`modificaciones_YYYY-MM-DD-descriptor.md`, y los de `docs/auditorias/` deben
usar `auditoria-YYYY-MM-DD-descriptor.md`. Las referencias de
`docs/Referencias/` deben usar `referencia-<descriptor>.md`, sin fecha, porque
son documentos vivos que se corrigen en el sitio. Toda carpeta documental nueva debe
incluir un `README.md`; si contiene un flujo repetible, también debe incluir
una plantilla. Los README y plantillas de cada carpeta son la referencia
operativa; no reescribir documentos históricos para adaptarlos a versiones
posteriores.

Crear o actualizar una entrada en `bitacora/` cuando ocurra al menos una de estas condiciones:

- se implementa una función o corrección relevante;
- cambia la arquitectura, compatibilidad, empaquetado o flujo de desarrollo;
- se completa una fase de trabajo planificada;
- se toma una decisión técnica que futuras sesiones deben conocer;
- el usuario solicita expresamente un registro.

No es obligatorio crear una bitácora para:

- consultas sin cambios;
- inspecciones breves sin una conclusión duradera;
- correcciones tipográficas triviales;
- acciones ya registradas adecuadamente en una entrada activa.

Los errores visuales reportados por el usuario pueden tener evidencia en `docs/revisiones/`; consultar esa carpeta cuando corresponda.

## Política de deuda estática QML

Los baselines de `qmllint` representan el máximo de deuda histórica tolerada
por cada entorno, no un objetivo ni una licencia para introducir advertencias.
Aplicar obligatoriamente estas reglas a toda modificación QML:

1. **El baseline solo puede mantenerse o disminuir.** Ningún agente puede
   aumentar, regenerar, recalibrar ni ejecutar un modo de grabación de baseline
   para hacer pasar una tarea. Una elevación requiere autorización explícita del
   usuario y evidencia de un cambio real de versión o diagnóstico de la
   herramienta, documentada por distribución y categoría.
2. **Cero deuda nueva.** Un archivo QML nuevo debe quedar sin advertencias
   atribuibles al proyecto. Un archivo existente modificado no puede aumentar
   su cantidad de advertencias ni introducir categorías o firmas nuevas.
3. **Toda reducción se conserva.** Cuando una validación reproducible reduzca
   el total o una categoría en el entorno correspondiente, actualizar el
   baseline hacia abajo dentro de la misma modificación validada. Nunca volver
   a elevarlo para compensar una regresión posterior.
4. **Comparar identidad, no solo cantidad.** Registrar antes y después la
   versión efectiva de `qmllint`, el total por categoría y los diagnósticos de
   los archivos modificados. La retirada de una advertencia antigua no puede
   compensar la introducción de otra distinta.
5. **Corregir antes de suprimir.** Priorizar `missing-property`, imports, tipos,
   ciclos y `Quick.layout-positioning` antes que deuda `unqualified`. Las
   supresiones solo se admiten para un falso positivo confirmado, con el alcance
   mínimo posible y una explicación junto al código; no envolver componentes o
   bloques amplios para silenciar código nuevo.
6. **Fallo implica corrección.** Si una tarea supera el baseline o añade un
   diagnóstico, corregir el código o detener la entrega. No editar el baseline,
   excluir el archivo ni relajar el gate como solución automática.
7. **Perfiles separados.** Fedora, Debian y otros entornos pueden producir
   diagnósticos distintos. Comparar cada ejecución únicamente con el baseline
   de la misma distribución y versión efectiva de Qt, sin copiar valores entre
   perfiles.

La reducción debe hacerse por componentes y en lotes verificables; esta
política no autoriza una reescritura masiva ajena al alcance de la tarea.

### Ciclo obligatorio de inventario y reducción

Activar la skill `qmllint-debt-cycle` ante cualquier tarea que clasifique,
corrija, suprima o cierre advertencias QML, o que modifique un baseline de
`qmllint`. `docs/deuda-qmllint/` es la fuente de verdad operativa del ciclo.

- mantener un inventario separado por distribución y versión efectiva de Qt;
- registrar cada ocurrencia con identificador, checkbox, correspondencia,
  observación y evidencia de cierre;
- actualizar el inventario antes y después de cada lote pequeño;
- no marcar una advertencia como resuelta hasta que desaparezca al repetir el
  mismo perfil; una edición de código sin esa evidencia sigue pendiente;
- usar `scripts-dev/qmllint_debt_inventory.py` para generar o actualizar el cuadro
  sin perder los campos manuales de diagnósticos todavía presentes;
- usar `scripts-dev/qmllint_debt_cycle.py` para cerrar cada ID después de corregirlo;
  el comando debe verificar el perfil completo, rechazar firmas nuevas, ejecutar
  el gate, respaldar el estado y reducir el baseline antes de marcar `[x]`;
- no editar manualmente checkbox y baseline para simular el cierre cuando el
  comando transaccional haya fallado;
- conservar el corte anterior cuando cambie el perfil o la versión de la
  herramienta, sin reescribirlo como si fuera equivalente.

## Validación proporcional

Toda modificación debe verificarse en proporción a su riesgo.

- Documentación: revisar enlaces, rutas, consistencia y afirmaciones verificables.
- QML/JavaScript: ejecutar validación sintáctica o lint cuando exista la herramienta adecuada.
- Empaquetado: comprobar estructura, metadata y exclusiones.
- Empaquetado Universal (`.plasmoid` para publicación):
  1. Compilar obligatoriamente sobre **Debian 13 (Trixie)** con la versión Qt provista por el entorno oficial, observada como **Qt 6.8.2** el 2026-08-05. Registrar la versión efectiva en cada build y no afirmar compatibilidad binaria con otra versión o distribución sin probar el mismo artefacto allí.
  2. Usar módulos proxy binarios C reales (`.so`) en `contents/ui/org/punchi/dock/compat/` compilados con `-Wl,-soname,<librería.so.6>` y constructor `dlopen()`. NUNCA incluir symlinks en `compat/` dentro del archivo `.plasmoid`, ya que el descompresor gráfico de KDE Plasma (`KZip`) los elimina por seguridad dejando la carpeta vacía.
- Integración visual: complementar la inspección estática con una prueba en Plasma cuando sea posible.
- Cambios de comportamiento: probar el flujo normal, errores previsibles y estados vacíos.

No declarar que algo funciona en runtime si solo fue inspeccionado estáticamente. Informar qué se verificó y qué quedó pendiente.

## Cierre de Sesión y Respaldo (Git)

### Versionado incremental de respaldos

- Cada respaldo Git solicitado debe incrementar en una unidad el cuarto
  componente de la versión de desarrollo: `0.9.7.26`, `0.9.7.27` y así
  sucesivamente.
- Mantener esta secuencia hasta la transición a `0.9.8`, salvo que el usuario
  indique explícitamente otra versión.
- Sincronizar el valor en todos los archivos canónicos de versión antes del
  commit y no crear un tag o una release salvo solicitud expresa.

Cualquier asistente de IA o agente autónomo (ej. Antigravity, Codex, Copilot) debe obedecer este protocolo estricto cuando el usuario solicite terminar la sesión de trabajo, finalizar el día o preparar el código para subir:

1. **Escribir la Bitácora**: Antes de tocar Git, crear un resumen técnico del progreso del día en `bitacora/YYYY-MM-DD-resumen-sesion.md`.
2. **Revisar estado**: Ejecutar `git status` asegurando que no haya basura expuesta (el `.gitignore` debe proteger esto).
3. **Añadir cambios**: Ejecutar `git add -- <rutas concretas>` únicamente para los archivos del alcance autorizado y revisar el diff preparado antes del commit para evitar incluir cambios ajenos. No usar `git add .`.
4. **Commit Profesional**: Ejecutar `git commit -m "feat/fix/docs/refactor: <resumen claro del trabajo>"`.
5. **Sincronización**: Ejecutar `git push` para respaldar el código en remoto.

Nunca se debe usar git para forzar la subida de binarios u ocultar errores. Este proceso automatiza el fin del día del usuario.

## Lista de cierre

Antes de finalizar una modificación, comprobar lo que aplique:

- [ ] El cambio cumple el alcance solicitado y preserva trabajo no relacionado.
- [ ] Las integraciones KDE se contrastaron con una referencia pertinente.
- [ ] La compatibilidad declarada no se elevó accidentalmente.
- [ ] UI, estado y lógica mantienen responsabilidades separadas.
- [ ] No se introdujeron colores, dimensiones o textos visibles inadecuadamente fijos.
- [ ] Entradas, procesos y errores se manejan de forma segura.
- [ ] Las exclusiones de paquete siguen cubriendo artefactos de desarrollo.
- [ ] Toda opción o control de configuración reacciona de forma reactiva en caliente ("Aplicar") sin requerir reiniciar plasmashell.
- [ ] Se ejecutaron validaciones proporcionales y se comunicaron sus límites.
- [ ] La bitácora se actualizó si el cambio lo amerita.
