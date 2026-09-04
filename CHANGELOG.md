## [0.9.7.58] - 2026-09-04

### Agregado

- Centrado vertical simétrico del layout de iconos en el panel nativo de Plasma en `main.qml`.
- Altura dinámica precalculada para modo panel con tema de Plasma en `DockGeometryState.qml`:
  fórmula adaptativa exacta (`Math.round((root.effectiveIconSize * scale) + 9.2 + root.dockLabelAreaHeight)`) que garantiza una altura óptima (ej. 62 px para icono de 32 px con zoom de 65 %) sin alterar el modo de temas JSON.
- Limitación estricta de la escala de ampliación (hover) al 65 % en modo panel nativo Plasma para evitar recortes contra los márgenes del panel.
- Advertencia contextual reactiva en Preferencias de Ratón (`ConfigMouse.qml`) cuando el zoom de ampliación excede el 65 % en modo panel con tema Plasma, con mensaje explicativo refinado y ocultamiento automático en temas JSON.
- Actualización de marcador de búsqueda intuitivo en el editor de elementos de configuración (`ConfigItems.qml`, `ItemEditorPanel.qml` y `ActionDialog.qml`): *"Escriba el nombre o alias... luego buscar"*.
- Actualización completa de catálogos de localización (`de`, `es`, `pt_BR`) y contratos de prueba.

## [0.9.7.57] - 2026-09-02

### Agregado

- Control de Opacidad del panel nativo de Plasma 6 desde Preferencias (`ConfigGeneral.qml`):
  - Opciones de opacidad nativa: *Adaptable*, *Opaco* y *Transparente*.
  - Sincronización bidireccional inmediata en tiempo real mediante `PanelLengthModeBridge` (`panelOpacityMode`).
  - Persistencia de configuración en la clave KConfig `panelOpacityMode`.
  - Pruebas unitarias completas para el puente de opacidad en `panellengthmodebridge_test.cpp`.

## [0.9.7.56] - 2026-09-02

### Agregado

- Control integral del panel nativo de Plasma 6 directamente desde las Preferencias de Punchi Dock:
  - Selector de modo de longitud (*Ajustar al contenido* o *Rellenar anchura/altura*).
  - Selector de alineación (*Izquierda/Arriba*, *Centro*, *Derecha/Abajo*).
  - Selector de modo flotante (*Panel y miniaplicaciones*, *Solo miniaplicaciones*, *Desactivado*).
  - Selector de visibilidad (*Esquivar ventanas*, *Siempre visible*, *Ocultar automáticamente*, *Las ventanas van por detrás*).
  - Selector de altura/grosor del panel (`SpinBox` de 24 px a 256 px en pasos de 2 px con sincronización bidireccional inmediata en tiempo real).
- Puente C++ `PanelLengthModeBridge` para compartir y sincronizar en memoria propiedades de geometría, longitud, alineación, modo flotante, visibilidad y grosor entre `main.qml` y el diálogo de configuración.
- Cálculo adaptativo de límite seguro para tamaño de iconos en modo panel según la altura activa del panel y el factor de zoom en hover (`hoverScale`), previniendo recortes visuales sin sacrificar espacio.

### Corregido

- Corrección visual de los `ComboBox` de longitud y alineación en `ConfigGeneral.qml`, eliminando evaluaciones iniciales inválidas de `indexOfValue` y asegurando que muestren su valor activo desde el primer milisegundo de apertura.
- Ajuste de holgura física en `DockGeometryState.qml` y `ConfigGeneral.qml` para permitir iconos de 32 px en paneles de 64 px con zoom de 1.65x sin recorte.

## [0.9.7.55] - 2026-09-02

### Agregado

- Submenú completo de gestión de audio en el Centro de control con soporte para
  selección de dispositivos de salida/entrada y volumen de aplicaciones.
- Conmutador dedicado de notificación OSD de volumen de Plasma vía KConfig
  (`plasmaparc`) en la tarjeta de Sonido.
- Iconografía dinámica reactiva al nivel del deslizador de volumen de audio
  (`audio-volume-low`, `audio-volume-medium`, `audio-volume-high` y
  `audio-volume-muted`) y detección automática de auriculares (`audio-headphones`).
- Botón de navegación hacia el submenú de audio con icono universal de ecualizador
  (`view-media-equalizer`).

### Corregido

- Ajuste geométrico simétrico del botón de configuración en la baldosa de
  Intensidad de Luz nocturna (`Kirigami.Units.largeSpacing` y estilo `flat`).
- Unificación de interacción con cursor interactivo (`PointingHandCursor`) y
  tooltips descriptivos en todos los botones de acción de las tarjetas del Centro de control.

## [0.9.7.54] - 2026-09-01

### Agregado

- Primera fase del Centro de control fullscreen como ítem persistente y de
  instancia única del dock, con rail derecho adaptable y fondo compartido con
  PunchiMenu.
- Accesos internos para redes Wi-Fi y dispositivos Bluetooth, con búsqueda,
  conexión, desconexión, contraseña efímera y degradación hacia los KCM
  oficiales cuando el proveedor no está disponible.
- Controles directos de brillo, volumen, silencio, No molestar, tema
  claro/oscuro y Luz nocturna, además de accesos a Actualizaciones y
  Calculadora y un espacio reservado para Captura de pantalla.
- Historial de notificaciones siempre visible, con conteo no leído, cierre
  individual, limpieza de expiradas y acceso a su configuración.
- Ajuste de intensidad de Luz nocturna de 0 a 100 %, convertido al rango
  oficial de KWin de 6500 a 1000 K con previsualización durante el arrastre.

### Cambiado

- Las acciones circulares del Centro de control usan un diámetro compacto de
  tres unidades de cuadrícula, iconografía mediana y estados temáticos más
  sutiles.
- Luz nocturna alterna directamente entre «Siempre activadas» y «Siempre
  desactivadas»; la programación avanzada permanece disponible mediante su
  botón de configuración.

### Validación

- Suite CTest aprobada al 100 % (83/83 pruebas) en el árbol de trabajo,
  incluida carga integral offscreen, contratos del Centro de control y
  conversión de intensidad de Luz nocturna.
- `qmllint` 6.11.1 permanece en 0 para `total`, `unqualified`,
  `missing-property`, `layout` e `import`.
- Catálogos `es`, `de` y `pt_BR` completos, sin entradas vacías ni difusas y
  validados mediante `msgfmt --check --check-format`.
- Revisión preventiva de seguridad apta: integraciones locales mediante APIs
  KDE, KConfig y D-Bus, sin shell, red, telemetría ni datos personales.

## [0.9.7.53] - 2026-08-30

### Corregido

- El desplazamiento vertical de aplicaciones agrupadas por categorías en
  PunchiMenu Normal y Pantalla completa sigue ahora la sensibilidad configurada
  por el sistema mediante el controlador estándar de Kirigami.
- Las ruedas de alta resolución y los paneles táctiles conservan deltas finos
  sin aplicar un multiplicador global a otros menús, carruseles o superficies.

### Validación

- La respuesta fue confirmada por el usuario en Plasma real como más rápida y
  fluida.
- Suite CTest aprobada al 100 % (71/71 pruebas), incluida la carga integral del
  plasmoide y el contrato específico de desplazamiento por categorías.
- `qmllint` 6.11.1 permanece en 0 para `total`, `unqualified`,
  `missing-property`, `layout` e `import`.
- Catálogos `es`, `de` y `pt_BR` completos, sin entradas vacías ni difusas.

## [0.9.7.52] - 2026-08-29

### Corregido

- Estabilización del dimensionamiento de PunchiMenu en modo Normal: cálculo de dimensiones basado en el monitor activo y su área disponible (`availableScreenRect`) en lugar del ancho combinado de escritorios virtuales (`Screen.desktopAvailableWidth`).
- Aplicación diferida de cambios de tamaño: los ajustes de porcentaje de ancho y alto se guardan de inmediato y se aplican en la siguiente apertura del menú (`applyConfiguredDimensions`), evitando geometrías irregulares mientras permanece abierto.
- Guía contextual traducible en la configuración de PunchiMenu informando que los cambios de tamaño se aplicarán al volver a abrir el menú.
- Cobertura de pruebas unitarias y de contrato para el estado de tamaño de PunchiMenu Normal y preservación de aserciones independientes de la localización del entorno de pruebas.

## [0.9.7.51] - 2026-08-28

### Agregado

- Soporte de personalización individual de apariencia para separadores en elementos de dock y marcador de aplicaciones abiertas, permitiendo alternar entre el tema del dock y valores específicos por elemento.

### Corregido

- Corrección del bloqueo y ciclo de retroalimentación en los controles deslizantes (Grosor, Largo, Opacidad) de la ventana de configuración del separador al interactuar con el cursor.
- Protección durante el arrastre activo (`pressed` guard) para evitar que la sincronización del modelo interrumpa el gesto de arrastre de Qt Quick Controls.

## [0.9.7.50] - 2026-08-27

### Agregado

- Asistentes separados para usuarios y desarrollo en `scripts-user/` y
  `scripts-dev/`, con deteccion de Fedora, Arch Linux, Debian y Ubuntu,
  aislamiento de builds por plataforma y seleccion segura del artefacto.
- Perfil estricto de desarrollo para Arch Linux, infraestructura reproducible
  de Debian 13 y resolucion compartida de `qtpaths` para Qt 6.
- Configuracion interactiva y por CLI del paralelismo de compilacion, con
  reduccion automatica de concurrencia en equipos con memoria limitada.
- README principales en aleman y portugues brasileno, junto con instrucciones
  de dependencias y compilacion actualizadas para cada distribucion.

### Cambiado

- Fedora 44 permanece como objetivo del paquete nativo y Debian 13 como host
  oficial del build universal; Debian 14/sid y la familia Ubuntu reutilizan el
  perfil binario compatible de Debian en lugar de una ruta inexistente.
- Los asistentes aceptan locales `C`, `C.UTF-8` y `POSIX`, respetan la
  seleccion explicita de idioma y comprueban las herramientas de shaders de
  Qt 6 entre las dependencias de compilacion.

### Corregido

- PunchiMenu Pantalla Completa usa flags de ventana gestionados por KWin y ya
  no depende de `BypassWindowManagerHint`, mejorando foco, desactivacion y
  capturas de puntero en Wayland.
- El reordenamiento persistente cancela mediante watchdog cualquier arrastre
  huerfano que pierda movimiento del puntero o foco de ventana.
- Los asistentes ya no mezclan caches de distribuciones, no dependen de un
  locale `en_US` instalado y pueden ofrecer instalacion interactiva de
  dependencias faltantes sin ejecutarla de forma implicita.

### Validacion

- Suite CTest aprobada al 100 % (67/67 pruebas) en el build Fedora 44 de
  publicacion.
- `qmllint` 6.11.1: 0 advertencias en `total`, `unqualified`,
  `missing-property`, `layout` e `import`, igual al baseline Fedora.
- Catalogos `es`, `de` y `pt_BR` completos con 1075 mensajes traducidos por
  idioma, sin entradas vacias ni difusas y aprobados mediante
  `msgfmt --check --check-format`.
- Artefacto Fedora 44 `x86_64` creado y auditado estructuralmente; la prueba de
  instalacion y actualizacion en Plasma real permanece separada.

## [0.9.7.49] - 2026-08-25

### Corregido

- La distancia configurada en 0 % para popups y menus vuelve a conservarse
  como distancia visual cero; la compensacion de la sombra tematica ya no
  introduce un hueco adicional respecto del panel.
- La geometria corregida se aplica tanto a los bordes horizontales como a los
  verticales y conserva las distancias positivas existentes.

### Validacion

- Se ampliaron el contrato de superficies y la prueba QML de posicionamiento
  para cubrir distancia cero y separaciones positivas.

## [0.9.7.48] - 2026-08-24

### Agregado

- Accion contextual `Mover la seccion de aplicaciones abiertas` en las tareas
  dinamicas, con un control temporal que permite arrastrar el bloque completo
  sin convertir las ventanas en elementos persistentes.
- Movimiento accesible mediante flechas mientras el control esta visible y
  conservacion de `Ctrl+Shift` mas flechas fuera de ese modo.
- Geometria dedicada para el control en paneles horizontales y verticales,
  junto con cobertura runtime del puente entre el applet y su representacion.

### Corregido

- El modo de movimiento cruza ahora el limite de `fullRepresentation` mediante
  un puente con ciclo de vida explicito y se activa despues de cerrar el menu
  contextual.
- Al mover el marcador se atenuan conjuntamente las tareas visibles y el item
  de desbordamiento, comunicando que se desplaza toda la seccion dinamica.

### Validacion

- La accion y el movimiento de la seccion fueron confirmados por el usuario en
  una sesion real de Plasma.
- Las pruebas cubren accion contextual, geometria, carga integral y restauracion
  de opacidad al finalizar o cancelar el movimiento.

## [0.9.7.47] - 2026-08-24

### Corregido

- La pagina Elementos vuelve a cargar correctamente los items predeterminados
  cuando la configuracion no contiene un `dockItemsJson` persistido, sin
  confundir ese caso con el arreglo vacio explicito `[]`.
- PunchiMenu Compacto alinea la region de blur con la superficie tematica
  efectiva y excluye la proyeccion exterior de la sombra.

### Validacion

- Se anadio una prueba QML dedicada al contrato de carga predeterminada y se
  amplio el contrato de contexto de PunchiMenu para la geometria de blur.

## [0.9.7.46] - 2026-08-24

### Agregado

- Geometría compartida y reactiva para mapear la superficie temática efectiva
  de PunchiMenu entre los sistemas de coordenadas del menú, el diálogo y sus
  capas auxiliares.
- Cobertura de primer inicio que carga dos instancias aisladas del plasmoide y
  comprueba que el modelo contiene los elementos predeterminados.

### Corregido

- La región de blur y el velo modal de PunchiMenu Normal vuelven a excluir la
  proyección exterior de la sombra sin desplazarse al mover o redimensionar el
  menú, tanto en modo anclado como centrado.
- Los submenús de PunchiMenu Compacto calculan el anclaje horizontal desde la
  superficie primaria visible y no desde el ancho exterior de su ventana.
- Una instalación o instancia nueva ya no pierde los elementos predeterminados
  cuando KConfig notifica inicialmente un `dockItemsJson` vacío; el valor JSON
  explícito `[]` continúa representando un dock vacío intencional.

### Validación

- Suite CTest aprobada al 100% (57/57 pruebas), incluida la carga integral de
  dos instancias sin configuración previa.
- `qmllint` 6.11.1: 0 advertencias en total y en todas las categorías del
  baseline Fedora.
- Catálogos ki18n (`es`, `de`, `pt_BR`) completos, sin entradas vacías ni
  difusas y validados mediante `msgfmt --check --check-format`.
- Revisión preventiva de seguridad conforme para commit; no se realizó push.

## [0.9.7.45] - 2026-08-24

### Agregado

- Selector contextual para cambiar directamente la vista de una carpeta entre
  rejilla, lista y detalle, con persistencia transaccional del cambio.
- Controles porcentuales y reactivos para ajustar la distancia de carpetas,
  menús contextuales y PunchiMenu respecto del dock.

### Cambiado

- El límite máximo de separación sigue las métricas adaptativas de Kirigami en
  lugar de depender de píxeles fijos, manteniendo una distancia visual segura.
- Los popups flotantes calculan su posición desde los bordes efectivos de los
  fondos temáticos de Plasma y compensan su sombra exterior.

### Corregido

- El valor de separación 0 % vuelve a unir visualmente los popups y menús al
  dock sin conservar un hueco equivalente a la proyección del tema.
- La región de blur y el velo modal de carpetas en PunchiMenu Normal comparten
  la misma geometría efectiva, convertida al sistema de coordenadas propio de
  cada consumidor, y ya no sobresalen ni se desplazan hacia el interior.

### Validación

- Suite CTest aprobada al 100% (56/56 pruebas), incluida la carga integral del
  plasmoide y el contrato geométrico para los cuatro bordes.
- `qmllint` 6.11.1: 0 advertencias en total y en todas las categorías del
  baseline Fedora.
- Catálogos ki18n (`es`, `de`, `pt_BR`) completos, sin entradas vacías ni
  difusas.
- Revisión preventiva de seguridad conforme para commit y push.

## [0.9.7.44] - 2026-08-24

### Agregado

- Marcador persistente y reordenable de aplicaciones abiertas que permite
  elegir dónde se intercalan las tareas dinámicas sin almacenar ventanas en la
  configuración.
- Reordenamiento de elementos persistentes mediante pulsación prolongada en el
  panel y mediante `Ctrl+Shift` más las flechas; el gesto en modo flotante es
  opcional y permanece desactivado por defecto para no interferir con Plasma.
- Incorporación de lanzadores validados a contenedores manuales mediante
  drag-and-drop desde PunchiMenu o el escritorio, incluida una ruta secundaria
  dentro del editor de carpetas.
- Cobertura de regresión para la migración del marcador, el orden visual, el
  arrastre persistente, la aceptación del drop y la persistencia de carpetas.

### Cambiado

- La animación hover y las miniaturas se suspenden mientras se reordena un
  elemento para mantener estable el gesto y su indicador de inserción.
- El marcador de aplicaciones abiertas reutiliza la apariencia configurable
  del separador y permite ocultar únicamente su trazo sin perder el anclaje.
- El elemento de calendario se identifica como `Calendar/Clock` para evitar la
  traducción ambigua que aparecía como agenda.

### Corregido

- La aceptación de lanzadores sobre carpetas se conserva durante todo el
  movimiento del puntero y no se pierde antes de soltar.
- El alta en contenedores publica inmediatamente el modelo persistido y evita
  accesos a identificadores QML fuera de ámbito; un éxito queda silencioso y no
  abre diálogos.

### Validación

- Suite CTest aprobada al 100% (53/53 pruebas), incluida la carga integral del
  plasmoide.
- `qmllint` 6.11.1: 0 advertencias en total y en todas las categorías del
  baseline Fedora.
- Catálogos ki18n (`es`, `de`, `pt_BR`) completos con 927/927 mensajes, sin
  entradas vacías ni difusas.
- Flujo directo de lanzadores a un contenedor manual confirmado por el usuario
  en Plasma real.
- Revisión preventiva de seguridad conforme para el commit y el paquete local.

## [0.9.7.43] - 2026-08-23

### Agregado

- Estado compartido `PunchiMenuApplicationState` para normalizar favoritos,
  aplicaciones ocultas y conteos de catálogo entre los modos Normal,
  Pantalla Completa y Compacto.
- Prueba integral `plasmoid_full_load_test` que carga dos veces el KPackage real
  mediante Plasma, instancia la representación completa y valida su destrucción
  bajo XDG y D-Bus aislados.
- Runner QML propio con contexto ki18n y política de fallo ante warnings de
  runtime, junto con contratos para estado de aplicaciones, editor de
  separadores y ciclo de vida de `ThemedSeparator`.
- Diagnóstico de inicio de Plasma Shell limitado al PID recién creado, con log
  privado y detección bloqueante de errores QML atribuibles al plasmoide.

### Cambiado

- El editor de separadores intercambia valores tipados entre componentes en
  lugar de exponer controles visuales mediante cadenas de aliases.
- `ThemedSeparator` conserva una fuente temática segura y evita delegados
  efímeros en los estilos de línea doble y chevrón.
- El controlador del atajo de PunchiMenu difiere el acceso a `KGlobalAccel`
  mientras no exista una secuencia configurada.
- Los instaladores locales exigen un reinicio verificable de Plasma Shell y
  reutilizan el diagnóstico de journal centralizado.

### Validación

- Suite CTest aprobada al 100% (44/44 pruebas).
- `qmllint` 6.11.1: 0 advertencias en total y en todas las categorías del
  baseline Fedora.
- Catálogos ki18n (`es`, `de`, `pt_BR`) al 100%, sin mensajes vacíos ni fuzzy.
- Revisión preventiva de seguridad conforme para el commit local.

## [0.9.7.42] - 2026-08-17

### Agregado

- **Cinemática de Apertura y Cierre Suave en PunchiMenu Normal y Compacto**:
  - Brote elástico de superficie (*Spring Reveal*) con escala dinámica (`0.88 ──► 1.00`), curvas `Easing.OutBack` (sobreimpulso `1.15`) y traslación vertical anclada al dock (`1.5 gridUnits`) en `PunchiMenuNormal.qml`.
  - Superficie animada reactiva en `PunchiMenuCompact.qml` con escala, desplazamiento vertical y desvanecimiento alfa coordinados.
  - Cierre suave diferido con Fade Out (`closeWithFade()`) y temporizadores de ciclo de vida dedicados en `punchiMenuNormalDialog` y `punchiMenuCompactDialog` (`main.qml`), eliminando desapariciones abruptas al cerrar el menú por clic exterior, tecla Escape o lanzamiento de aplicaciones.

### Validación

- Suite CTest aprobada al 100% (38/38 pruebas).
- `qmllint-qt6`: 0 advertencias, 0 errores, 0 deuda técnica.
- Catálogos ki18n (`es`, `de`, `pt_BR`) 100% traducidos.
- Revisión preventiva de seguridad (Preflight) conforme.

## [0.9.7.41] - 2026-08-17

### Agregado

- **Animación en Cascada y Elevación Interactiva en Popups de Carpetas (`FolderPopup`)**:
  - Despliegue escalonado secuencial (*Staggered Cascade*) de las aplicaciones contenidas con retardo indexado dinámico de 22 ms.
  - Curvas de escala elásticas (`0.82 ──► 1.00`) con `Easing.OutBack` y desvanecimiento alfa `Easing.OutCubic`.
  - Microinteracción de elevación táctil en hover (`1.04x`) y respuesta de presión (`0.95x`) en cada elemento de la carpeta.
  - Integración de cursores de mano nativos `PointingHandCursor` en delegados de aplicaciones y botón de cierre.

### Validación

- Suite CTest aprobada al 100% (38/38 pruebas).
- `qmllint-qt6`: 0 advertencias, 0 errores, 0 deuda técnica.
- Catálogos ki18n (`es`, `de`, `pt_BR`) 100% traducidos.
- Revisión preventiva de seguridad (Preflight) conforme.

## [0.9.7.40] - 2026-08-17

### Agregado

- **Nuevo Modo Compacto de PunchiMenu (`PunchiMenuCompact`)**:
  - Vista de menú compacto con submenú lateral de aplicaciones (`PunchiMenuCompactFlyout`).
  - Campo de búsqueda estilizado con esquinas redondeadas (`Kirigami.SearchField` + `PunchiMenuSearchBackground` nativo).
  - Fila superior dinámica de favoritos conectada a `root.favorites` con soporte para menú contextual completo (eliminar de favoritos, anclar al dock y añadir acceso al escritorio).
  - Menú de categorías con resaltado canónico unificado `PunchiMenuItemHighlight` y cursor `PointingHandCursor`.
  - Vista integrada de configuración compacta (`PunchiMenuCompactSettingsView`) con interruptor de fila de favoritos y controles de escala, opacidad y separación.
- **Cinemática de Apertura para Miniaturas de Ventanas**:
  - Transformación dinámica con origen anclado al dock (`transformOrigin: Bottom/Top/Left/Right`) en `PopupAnimatedContent.qml`.
  - Curvas de aceleración y desaceleración fluidas (`Easing.OutCubic` y `Easing.OutBack`) con amplitud visible de escala (`0.84 -> 1.00`) y deslizamiento de 18 px.
  - Microinteracción interactiva de elevación (`scale: 1.02`) y cursor `PointingHandCursor` en tarjetas de previsualización (`WindowPreviewCard.qml`).

### Cambiado

- **Compensación de Sombras de Marco Temático de Plasma**:
  - Integración de `themeFrameOverlap` en `compactBackground` y propagación de `themeFrameMargin` a `PunchiMenuNormalPlacement.qml`, descontando la holgura transparente del tema Breeze y permitiendo que con `0 px` el menú quede pegado al ras del dock.
- **Calibración de Altura Implícita del Menú Compacto**:
  - Ajuste de altura a `21.6 gridUnits` (sin favoritos) y `24.2 gridUnits` (con favoritos), eliminando por completo el espacio vacío inferior.

### Corregido

- **Cierre Sincronizado del Menú Contextual**:
  - Corrección del fallo donde el menú contextual emergente permanecía visible en pantalla tras cerrar el menú o cambiar de categoría.

### Validación

- Suite CTest aprobada al 100% (38/38 pruebas).
- `qmllint-qt6`: 0 advertencias, 0 errores, 0 deuda técnica.
- Catálogos ki18n (`es`, `de`, `pt_BR`) 100% traducidos sin cadenas difusas ni huérfanas.
- Revisión preventiva de seguridad (Preflight) conforme.

## [0.9.7.39] - 2026-08-17

### Agregado

- Dashboard interactivo HTML de auditoría de compilación y deuda QML (`docs/deuda-qmllint/auditoria-advertencias-kde6.html`) con filtros dinámicos en tiempo real por estado (Resueltas/Pendientes), grado de dificultad (1 a 5) y exportador a Excel (CSV).
- Matriz de auditoría estructurada en CSV UTF-8 con BOM (`docs/deuda-qmllint/matriz-advertencias-kde6.csv`) y resumen ejecutivo técnico (`docs/deuda-qmllint/auditoria-ejecutiva-kde6.md`).
- Purga automatizada de traducciones huérfanas y obsoletas (`#~`) en `scripts/dev/update-translations.sh` mediante `msgattrib --no-obsolete`.

### Cambiado

- **Erradicación Total de Deuda QML (100% Limpio)**: Eliminadas las 742 advertencias estáticas de `qmllint` en todos los archivos del plasmoide (`CalendarPopup.qml`, `FolderPopup.qml`, `ConfigItems.qml`, `DockItem.qml`, `main.qml`, etc.).
- Reducción del baseline `QMLLINT_BASELINE_TOTAL`, `QMLLINT_BASELINE_UNQUALIFIED` y `QMLLINT_BASELINE_MISSING_PROPERTY` a **0** en `scripts/qmllint-baseline-fedora.env`.
- Adopción universal de `pragma ComponentBehavior: Bound` y propiedades requeridas fuertemente tipadas en todos los delegados QML del proyecto.
- Calificación estricta de controladores (`root.controller`), modelos de datos y ámbitos léxicos en la totalidad de componentes y diálogos.

### Corregido

- Limpieza de la totalidad de advertencias por accesos no calificados (`unqualified`), falsos positivos de `ki18n` e imports no utilizados en la suite QML.
- Eliminación de advertencias `missing-property` en `WindowPreviewCard.qml`, `TaskWindowsPopup.qml` y `main.qml`.

### Validación

- Suite CTest completa aprobada al 100% (38/38 pruebas unitarias y de integración).
- Cero advertencias (`0 warnings`) en la ejecución global de `qmllint` en todos los archivos QML.
- Baseline en Fedora ratcheted down a 0 absoluto.
- Catálogos ki18n 100% sincronizados sin cadenas vacías, difusas ni huérfanas en español (`es.po`), alemán (`de.po`) y portugués brasileño (`pt_BR.po`).
- Revisión preventiva de seguridad (Preflight) conforme.

## [0.9.7.38] - 2026-08-16

### Agregado

- Vista de secciones de categorías nativas en PunchiMenu Normal (`PunchiMenuCategorySectionsView`) con clasificación inteligente de aplicaciones en C++ (`ApplicationCategoryClassifier`).
- Interruptor configurable para mostrar u ocultar el carrusel de categorías en PunchiMenu Normal (`cfg_punchiMenuNormalShowCategoryCarousel`).
- Soporte completo de Drag & Drop para reorganizar y agrupar aplicaciones dentro de la vista por categorías en Normal.
- Modos de posicionamiento en el menú contextual de PunchiMenu: Acoplado al Dock, Centrado en Pantalla o según la Configuración.
- Agrupación por categorías, búsqueda activa transparente, integración de favoritos y navegación por teclado 2D completa en PunchiMenu Pantalla Completa.
- Vista de sesión de usuario en PunchiMenu Normal con controles integrados de bloqueo, cierre de sesión, reinicio y apagado.
- Acción de acceso directo "Configurar Punchi Dock..." en los menús contextuales de aplicaciones y elementos del dock.
- Interruptores en KCM de Configuración de Menús (`ConfigMenus.qml` / `main.xml`) para controlar la visibilidad de "Configurar Punchi Dock...", "Añadir al escritorio" y "Editar este elemento...", con refresco reactivo instantáneo (Hot Refresh).
- Módulo de configuración de atajos adicionales (`ConfigAdditionalShortcuts.qml`).
- Integración C++ avanzada de papelera en múltiples particiones (`TrashIntegration`) con menús de acciones y seguimiento de estado.
- Vistas de configuración modular embebidas (`PunchiMenuNormalSettingsView` y `PunchiMenuFullScreenSettingsView`) basadas en `PunchiMenuSettingsBase`.

### Cambiado

- Sustitución del archivo monolítico `ConfigPunchiMenu.qml` por paneles de configuración embebidos con aislamiento estricto de preferencias por modo.
- El retardo de elevación de ventanas al arrastrar archivos sobre el dock (`externalDropActivationDelay`) se redujo de 1600 ms a 250 ms, conforme al estándar oficial de KDE Plasma TaskManager.
- El ciclo de vida de `DropArea` en el dock se vinculó a `onContainsDragChanged` para garantizar el reseteo inmediato del estado visual al salir el puntero o cancelar un arrastre.
- La fase de hover en Wayland (`onEntered`) ahora acepta la bandera de URLs (`drag.hasUrls`) y delega la auditoría estricta de seguridad C++ a `onDropped`, previniendo falsos rechazos en listas vacías.
- Aislamiento en la detección y coincidencia de reproductores KDE MPRIS (Elisa, Spotify, VLC) evitando interferencias con ventanas de terminal u otros procesos.
- Optimización de la onda elástica (`waveMainAxisShift`) y el cajón de desbordamiento (Overflow Drawer) para paneles verticales y horizontales.

### Corregido

- Se solucionó el fallo de alertas e iconos de advertencia (`dialog-warning-symbolic`) que quedaban congelados de forma permanente sobre los iconos del dock al arrastrar archivos desde Dolphin en Wayland (Debian 13 y Fedora).
- Se corrigió la fuga de memoria potencial durante el listado asíncrono de carpetas en `SystemDiscovery`.
- Se corrigió el recorte y la visibilidad de ranuras de inserción en PunchiMenu Normal y Fullscreen.
- Se restableció la visibilidad y alias de propiedades para las opciones del menú contextual en el KCM de configuración.
- Se restauraron los permisos de archivo en `.qmltypes`.

### Validación

- Cobertura CTest ampliada de 30 a 38 pruebas unitarias y de integración (100% aprobadas), incluyendo contratos para `ApplicationCategoryClassifier`, `TrashIntegration`, `DockOverflow`, `DockWave`, `PopupCoordinator`, `AppActionsPopup` y `PunchiMenuLayoutModel`.
- Herramientas automatizadas de ciclo de deuda e inventario `qmllint` añadidas en `scripts/`.
- Cero deuda técnica nueva en `qmllint` respecto a los baselines de Debian 13 y Fedora.
- Catálogos ki18n actualizados a 891 mensajes por idioma (100% traducidos en alemán, español y portugués brasileño sin mensajes vacíos ni difusos).
- Revisión preventiva de seguridad (Preflight) aprobada, manteniendo intacta la política estricta de `DropUrlPolicy`.

## [0.9.7] - 2026-08-09

### Agregado

- Arrastre interno de aplicaciones, favoritos y carpetas en PunchiMenu Normal
  y Pantalla completa, con destinos explícitos y persistencia transaccional.
- Control independiente de opacidad para el fondo de las tarjetas multimedia
  MPRIS, aplicado reactivamente sin reiniciar `plasmashell`.
- Componente `RoundedImage` con shader empaquetado para recortar las carátulas
  completas respetando el radio de la superficie.

### Cambiado

- Las superficies de PunchiMenu, menús contextuales, carpetas y tarjetas MPRIS
  usan perfiles temáticos más coherentes con Plasma y conservan su semántica
  de hover, foco, presión y selección.
- Los modos MPRIS `card` y `fullCard` comparten una ruta exclusiva de estado y
  geometría; `overlay` continúa como tarjeta compacta bajo las miniaturas.
- El enrutado entre miniaturas, controles multimedia y cambios rápidos de ítem
  prepara la geometría antes de mostrar el diálogo y mantiene transiciones
  interrumpibles.

### Corregido

- Los popups ya no intentan abrir diálogos con geometría vacía durante la
  preparación, condición que podía reiniciar `plasmashell` bajo Wayland.
- Las aplicaciones fijadas conservan sus miniaturas válidas cuando una segunda
  consulta estricta por identidad no devuelve ventanas.
- Las tarjetas multimedia aparecen correctamente al desactivar las vistas
  previas de ventana y sustituyen la miniatura según el modo seleccionado.
- Los controles MPRIS respetan una zona interior segura y las carátulas de
  `fullCard` ya no sobresalen visualmente por las esquinas.
- Los flujos de arrastre y los menús emergentes mantienen su destino durante
  retargeting, desplazamiento y cambios rápidos de superficie.

### Validación

- Contratos dirigidos de shader, miniaturas, superficies y coordinación
  correctos.
- Fedora 44 `x86_64`, Plasma 6.7.4 y Qt 6.11.1: build Release correcto y CTest
  completo con 30 de 30 pruebas aprobadas.
- `qmllint`: 706 advertencias conocidas dentro del baseline Fedora, sin errores
  ni aumento de categorías protegidas.
- Catálogos alemán, español y portugués brasileño: 840 mensajes traducidos por
  idioma, sin entradas vacías o difusas y con validación de formato correcta.
- El usuario validó en Plasma real la recuperación de `card` y `fullCard`, la
  mejora de reacción y el recorte redondeado de la carátula completa.
- Paquete Fedora final:
  `punchi-dock-remastered-0.9.7-fedora44-x86_64.plasmoid`, 720243 bytes y
  SHA-256
  `ea271fb0030e8b2f033e73fa1517023528ca9d20d208ee7c5e3c5435dd45aec2`.
- El paquete contiene 147 entradas, metadata 0.9.7, módulos nativos stripped,
  tres proxies ELF reales con `DT_SONAME` y los catálogos MO esperados; no
  contiene symlinks ni archivos de desarrollo.
- El artefacto universal permanece pendiente de compilación oficial en Debian
  13 y no forma parte de esta publicación Fedora.

## [0.9.6] - 2026-08-07

### Agregado

- Carpetas de aplicaciones persistentes y con nombre en PunchiMenu Normal y
  Pantalla completa, con acciones para crear, abrir, renombrar, mover, quitar,
  disolver y deshacer la última operación mientras el menú permanece abierto.
- Ocultación selectiva de aplicaciones, revelado temporal, indicador de estado
  y comportamiento equivalente dentro de las carpetas.
- Vista de sesión en Pantalla completa con avatar circular, cerrar sesión,
  reiniciar y apagar; el recorte del avatar usa un shader empaquetado con
  fallback de renderizado por software.
- Categoría principal de configuración de PunchiMenu para presentación,
  apariencia, desenfoque, opacidad, ubicación, separación, dimensiones,
  escalas, etiqueta de distribución, icono y atajo global.
- Reconocimiento seguro de lanzadores `.desktop` locales y enlaces simbólicos
  autorizados por KDE en los contenedores Grid, List y Detail.
- Soporte efectivo de miniaturas de ventanas en sesiones Plasma X11 mediante
  una ruta dedicada, manteniendo Wayland como objetivo principal.

### Cambiado

- PunchiMenu Pantalla completa sustituye el carrusel preliminar de categorías
  por una grilla paginada adaptable de aplicaciones con navegación mediante
  rueda, touchpad, arrastre, teclado, indicadores y flechas laterales.
- Favoritos dispone de un área reservada independiente en ambos modos y de una
  escala de iconos configurable dentro de límites seguros.
- PunchiMenu Normal puede abrirse centrado en el escritorio o acoplado al dock
  o panel, considerando orientación, grosor real, límites de pantalla y una
  separación configurable.
- Búsqueda, categorías, controles, cursores, tooltips, foco y estados hover se
  armonizaron con los colores y métricas del tema Plasma activo.
- El diálogo rápido de cada ítem conserva solo opciones básicas; los editores
  de icono y atajo global viven únicamente en la configuración principal.
- La organización de carpetas persiste solo identidades canónicas, etiquetas,
  membresía y orden; nunca guarda comandos ni iconos descubiertos.

### Corregido

- La rueda en Pantalla completa ya no avanza en exceso ni retrocede de página;
  el arbitraje por ráfagas limita cada gesto y permite transiciones suaves e
  interrumpibles.
- Los menús contextuales de PunchiMenu Normal se posicionan junto al elemento
  correcto incluso después de desplazar la grilla, se trasladan con un nuevo
  clic derecho y se cierran al pulsar fuera.
- Las carpetas de Normal calculan una superficie compacta según sus miembros y
  reservan correctamente el espacio de la barra de desplazamiento.
- Las notificaciones de operaciones aparecen sobre la superficie modal,
  reinician su temporizador al repetirse y ofrecen cierre manual.
- Los controles de sesión, categorías y navegación usan texto resaltado del
  tema, cursor de mano y geometría que evita solapamientos en ambos modos.

### Seguridad

- Las acciones de aplicaciones resuelven identidades canónicas exactas en vez
  de coincidencias parciales.
- La creación de accesos de escritorio usa escrituras atómicas, límites de
  recursos y comprobaciones de colisión y enlaces simbólicos.
- Enlaces rotos, URLs remotas, destinos que no son `.desktop`, archivos fuera
  de límites y lanzadores no autorizados por KDE permanecen no ejecutables.
- Punchi Dock no incorpora telemetría; favoritos, carpetas, elementos ocultos,
  configuración, temas y avatar permanecen locales.

### Validación

- Fedora 44 `x86_64`: compilación Release y paquete nativo `.plasmoid`
  generados correctamente.
- CTest completo: `25/25` pruebas correctas.
- `qmllint`: línea base estable en 707 advertencias heredadas, sin aumento.
- Catálogos alemán, español y portugués brasileño: 816 mensajes traducibles
  por idioma y validación `msgfmt` correcta.
- El usuario confirmó en Plasma real los dos modos de PunchiMenu, carpetas,
  favoritos, ocultación, navegación, menús contextuales, avatar, controles de
  sesión, temas claro/oscuro, opacidad y desenfoque.

## [0.9.5] - 2026-08-03

### Agregado

- Paquete universal `.plasmoid` con soporte transparente para múltiples distribuciones Linux (Fedora 44, Arch Linux, Debian 13/14, Kubuntu 26.04+).
- Arquitectura de compatibilidad dinámica basada en módulos binarios compartidos C proxy (`libPlasma.so.6`, `libPlasmaQuick.so.6`, `libPlasmaActivities.so.6`) en `$ORIGIN/compat` compilados con constructores `dlopen()` y banderas `-Wl,-soname`, evitando la pérdida de symlinks provocada por la extracción con `KZip` en la interfaz gráfica de Plasma.
- Script maestro unificado `scripts/setup.sh` con menú interactivo CLI de 8 opciones, auto-detección de SO e internacionalización.
- Script de instalación universal para usuarios finales `scripts/setup-universal.sh`.
- Etiquetas emergentes (ToolTips) accesibles en los botones de acción de PunchiMenu visible tanto al pasar el ratón (`hover`) como al navegar por teclado (`foco`).

### Cambiado

- Las dimensiones de PunchiMenu (ancho y alto entre 30% y 90%) reaccionan en caliente al presionar "Aplicar" de forma reactiva sin requerir el reinicio de `plasmashell`.
- Modo Normal fijado como la opción predeterminada al añadir PunchiMenu.
- Catálogos de traducción al 100% actualizados para alemán (`de.po`), español (`es.po`) y portugués de Brasil (`pt_BR.po`).

## [0.9.4] - 2026-08-01

### Agregado

- Primera versión pública preliminar de PunchiMenu como ítem singleton del
  dock, con modo Normal y modo Pantalla completa. Normal es la presentación más
  pulida de esta versión; Pantalla completa continúa en una fase preliminar y
  Compacto permanece reservado para una versión futura.
- Modo Normal con búsqueda de aplicaciones, categorías desplazables, grilla de
  seis columnas, favoritos persistentes por instancia y acciones contextuales
  para añadir o retirar favoritos.
- Navegación completa por teclado para búsqueda, categorías, aplicaciones y
  favoritos, con foco visible, `Enter`, `Espacio`, flechas, `Tab`, menú
  contextual y cierre mediante `Escape`.
- Configuración de PunchiMenu para elegir presentación, dimensiones seguras del
  modo Normal, escala de iconos, icono del ítem y atajo global dedicado.
- Acciones nativas de cerrar sesión, reiniciar y apagar desde PunchiMenu,
  respetando las capacidades expuestas por la sesión Plasma.
- Blur nativo mediante KWindowSystem con fallback transparente ligero cuando el
  efecto no está disponible.
- Efecto de hover `Axis zoom` como opción predeterminada y control global de
  velocidad del movimiento del dock.
- Nuevas formas de separador para ítems y temas JSON: diamante, anillo, chevrón
  y doble línea, además del catálogo visual existente.
- Pruebas para descubrimiento de aplicaciones, propiedad de geometría de tareas
  entre instancias y contaminación semántica de catálogos de traducción.

### Cambiado

- PunchiMenu Normal se ancla desde el borde del ítem correspondiente y respeta
  el borde real del panel, la orientación, la pantalla disponible y límites de
  geometría seguros.
- El dock dentro de un panel neutraliza su representación expandida propia al
  abrir PunchiMenu; el menú conserva su popup independiente.
- Las categorías y favoritos usan desplazamiento horizontal suavizado con
  controles laterales reservados, sin barras redundantes.
- La grilla Normal reserva una zona independiente para Favoritos y mantiene el
  scroll vertical de aplicaciones dentro de su área disponible.
- El indicador de conteo de ventanas pasa a estar habilitado por defecto y la
  publicación de geometría de tareas elige una sola instancia propietaria.
- El ítem MPRIS compacto reduce trabajo visual innecesario y comparte controles
  configurables de movimiento con el resto del dock.
- La página de Elementos presenta una paleta compacta de dos columnas, con
  encabezados superiores, descripciones accesibles y alturas simétricas.
- El sombreado del Calendario/Reloj se independiza del sombreado global de
  etiquetas persistentes.
- Los scripts de Fedora, Debian y Kubuntu incorporan las dependencias nativas de
  GlobalAccel y Plasma Workspace requeridas por PunchiMenu.

### Corregido

- La navegación repetida del carrusel ya no acumula destinos ni acelera de
  forma descontrolada; flechas, rueda y teclado comparten límites coherentes.
- El segundo clic sobre el ítem PunchiMenu vuelve a cerrar el modo Normal sin
  afectar la minimización esperada de aplicaciones, carpetas u otros ítems.
- PunchiMenu en panel ya no fuerza la expansión visual completa del plasmoide ni
  coloca el dock por encima del menú.
- Los estados de carga, vacío y error de la grilla permanecen visibles y
  diferenciados durante el descubrimiento de aplicaciones.
- La resolución de favoritos elimina duplicados, descarta identificadores no
  válidos y no persiste comandos ni rutas externas como fuente de verdad.
- La geometría de minimización deja de competir entre varias instancias del
  dock y conserva una única fuente para el compositor.
- Los catálogos alemán, español y portugués brasileño ya no concatenan contexto
  interno, texto fuente inglés y traducción; una prueba semántica impide que la
  contaminación vuelva a pasar como catálogo válido.

### Validación

- Fedora 44, Qt 6.11.1 y Plasma 6.7.3: `qmllint` dentro del baseline conocido,
  compilación Release y paquete nativo para `x86_64`.
- CTest completo: `16/16` pruebas correctas.
- Catálogos `de`, `es` y `pt_BR`: 734 de 734 mensajes traducidos, sin difusos ni
  prefijos semánticamente contaminados.
- El usuario confirmó en Plasma real el modo Normal, Favoritos, navegación por
  teclado, cierre mediante segundo clic, atajo dedicado, suavidad horizontal y
  recuperación del idioma. Pantalla completa continúa declarada preliminar.

## [0.9.3] - 2026-07-28

### Agregado

- Item multimedia MPRIS compacto configurable con reproductor predeterminado,
  carátula con esquinas redondeadas, icono de aplicación y controles de pista.
- Selección de reproductor mediante aplicaciones multimedia descubiertas por
  KDE, con apertura segura de la aplicación configurada.
- Inicio diferido de reproducción: el botón Play abre el reproductor cerrado y
  envía `Play` cuando su servicio MPRIS anuncia `CanPlay`.
- Modos de información de pista `Automático`, `Siempre visible` y `Oculto`,
  adaptados a paneles verticales estrechos y con tooltip accesible.
- Apertura opcional del reproductor seleccionado en estado minimizado.
- Selector circular de color junto a un `ComboBox` para elegir color Plasma o
  color personalizado.
- Separación configurable entre iconos del dock y controles de tamaño con
  unidades explícitas (`px` para medidas físicas y `%` para escalas visuales).
- Arrastre seguro de archivos hacia aplicaciones fijadas, con validación de
  URLs, activación temporal de la ventana y feedback visual y accesible.
- Operación de arrastre hacia Papelera mediante `KIO::trash`, con validación
  local de URLs, límites de lote, actualización asíncrona y reporte de errores.
- Acciones de contexto para desanclar aplicaciones y carpetas del dock.

### Cambiado

- La geometría del item MPRIS comparte una única decisión de visibilidad entre
  el delegate y la capacidad del panel; en vertical sin texto se elimina la
  fila intermedia y los controles permanecen dentro del marco.
- La configuración de calendario, apariencia, popups, carpetas y menús usa
  controles compactos coherentes con Kirigami y métricas de accesibilidad.
- Las preferencias nuevas se normalizan y persisten de forma compatible con
  configuraciones existentes.
- Se ampliaron los catálogos de alemán, español y portugués brasileño y se
  actualizaron las descripciones accesibles de los controles multimedia.

### Corregido

- La carátula del item MPRIS ya no pisa el borde inferior y se recorta con
  esquinas redondeadas.
- El arrastre de archivos a Papelera ya no construye comandos shell: valida los
  elementos recibidos y usa el job nativo de KDE para moverlos de forma segura.
- El fallback de reproductores cerrados conserva el icono de la aplicación o
  usa un icono multimedia adaptable al tema.
- El texto multimedia no reinicia su desplazamiento cada segundo mientras
  avanza la duración de la pista.
- El item MPRIS vertical no reserva espacio invisible ni recorta Play/Siguiente
  cuando el texto está oculto.
- La selección de reproductor admite correctamente listas expuestas por C++ y
  no queda limitada a la opción automática.

### Validación

- Fedora 44, Qt 6.11.1 y Plasma 6.7.3: `qmllint` dentro del baseline, compilación
  Release y paquete `.plasmoid` generado para `x86_64`.
- CTest completo: `14/14` pruebas correctas.
- Catálogos `de`, `es` y `pt_BR` validados con `msgfmt` y sin entradas vacías
  o difusas.
- El usuario confirmó en Plasma real el funcionamiento completo del item MPRIS
  vertical y del inicio mediante Play.

## [0.9.2] - 2026-07-23

### Agregado

- Traducciones iniciales completas de la interfaz en alemán (`de`) y portugués
  brasileño (`pt_BR`), incluidas en el paquete junto con español. Se mantiene
  pendiente su revisión por hablantes nativos antes de declararlas mantenidas.
- Soporte nativo completo e integración para Paneles de Plasma 6 Verticales / Laterales (borde izquierdo y derecho de la pantalla).
- Disposición adaptativa dinámica (`GridLayout` con flujo `TopToBottom`) al colocar el dock en paneles laterales.
- Orientación de despliegue inteligente para ventanas emergentes, menús contextuales, miniaturas, notas y calendario (`Qt.RightEdge` en panel izquierdo y `Qt.LeftEdge` en panel derecho).
- Renderizado de separadores horizontales adaptados al ancho del panel vertical en `ThemedSeparator.qml`.
- Ubicación adaptable de indicadores de estado activo de tareas (`TaskIndicator.qml`) en el borde interior del dock (`left`/`right`).
- Ecualizador de audio (`AudioSpectrumLayer`) con orientación vertical y origen adaptado al borde del panel.

### Cambiado

- `DockGeometryState.qml` abstrae la medición de contenido sobre el eje Y (`panelLengthForDockItem`, `panelItemExtent`).
- `DockItem.qml` calcula dinámicamente `implicitWidth` y `implicitHeight` preservando la proporción cuadrada de las celdas en orientación vertical.
- `DockItem.qml` adapta el seguimiento del ratón (`mouseOffset`) sobre el eje Y para propagar la ola de forma fluida de arriba a abajo.
- La versión declarada en KPackage y CMake avanza a 0.9.2.

### Corregido

- Corregido el recorte (*clipping*) de iconos en los bordes de la celda acotando la holgura de desplazamiento lateral `hoverOffsetX` en `DockGeometryState.qml` y `DockItem.qml`.
- Corregida la visibilidad y alineación de separadores en paneles verticales mediante `visualAreaHeight`.
- Corregido el cálculo de capacidad de slots dinámicos (`dynamicTaskSlotCapacity`) en paneles verticales de modo *fill*.
- Restaurada la función `focusItem()` para retornar el foco por teclado tras cerrar controles de medios.
- Restaurado el centrado horizontal del layout en modo flotante cuando hay tareas de desbordamiento.

## [0.9.1] - 2026-07-22

### Agregado

- Opciones independientes para mostrar sombras sutiles en los textos del dock,
  las miniaturas de ventanas, los popups y los menus.
- Deslizadores independientes para escala del texto de hora (`timeTextScale`) y fecha (`dateTextScale`) en el item de Calendario/Reloj.
- Panel dedicado de configuración de Separadores (`SeparatorOptions.qml`) con aviso informativo nativo de Kirigami.
- Soporte para personalización de Separadores con selección de formas geométricas (Línea, Círculo, Cuadrado, Cápsula redondeada, Estrella), grosor (1-16px), proporción de largo (20%-100%), opacidad (10%-100%) y efecto de resplandor sutil.
- Distancia configurable para los popups de carpetas en los perfiles de
  rejilla, lista y detalle, limitada a un rango seguro.
- Configuracion separada de animacion, velocidad e intensidad para popups
  generales, menus y vistas previas.
- Componentes dedicados para estado de configuracion, geometria, gestion de
  items y acciones contextuales del dock.

### Cambiado

- `main.qml` delega configuracion, geometria y coordinacion de items en modulos
  con responsabilidades acotadas.
- Los textos de menus y superficies emergentes pueden conservar contraste
  sobre fondos claros mediante sombras configurables.
- La direccion de cada popup flotante se calcula al abrir desde la posicion
  real del item que origina la accion.
- La version declarada en KPackage y CMake avanza a 0.9.1.

### Corregido

- Los popups del dock flotante inferior ya no nacen hacia abajo ni pierden la
  distancia configurada por usar el area de edicion completa del plasmoide.
- Carpetas, menus, calendario, notas, overflow y vistas previas comparten el
  anclaje preciso al `DockItem` de origen.
- Las pestañas de Apariencia mantienen la correspondencia correcta con su
  contenido despues de separar los controles de animacion.
- Los perfiles de carpeta conservan una jerarquia tipografica coherente entre
  rejilla, lista y detalle.

### Validacion

- Fedora 44, Plasma 6.7.3 y Qt 6.11.1: validacion QML dentro del baseline con
  725 advertencias conocidas, compilacion Release y paquete Fedora correcto.
- CTest completo: `12/12` pruebas correctas.
- El usuario confirmo en Plasma real que la direccion y distancia de los
  popups flotantes funcionan correctamente en la posicion inferior.

## [0.9.0] - 2026-07-21

### Agregado

- Tarjetas multimedia MPRIS ampliadas con caratula resuelta de forma segura,
  volumen, silencio, barra de progreso, repeticion y reproduccion aleatoria.
- Superficies reutilizables para miniaturas individuales y grupos de ventanas,
  con acciones de ventana y estados de previsualizacion coherentes.
- Perfiles independientes para popups de carpetas en rejilla, lista y detalle:
  tamano de icono, filas, columnas, labels, tipografia y scroll visible.
- Configuracion de menus contextuales para ancho, alto de fila, tamano de icono,
  acciones visibles, velocidad y direccion de la transicion desde miniaturas.
- Selector nativo de iconos de KDE con busqueda, categorias e importacion de
  archivos personalizados bajo demanda.
- Scripts unificados por distribucion para Fedora 44, Debian 13,
  Debian 14/testing y Kubuntu, con deteccion de dependencias, paquete publico y
  variante `local-test`.
- Pruebas para resolucion de caratulas multimedia, deteccion de Plasma en
  Kubuntu y dependencias de Debian.

### Cambiado

- Los popups multimedia, de ventanas y menus contextuales comparten una
  superficie morph estable que conserva geometria y contenido saliente durante
  sus transiciones.
- La Papelera usa una superficie estructurada y adaptable para menu,
  confirmacion, progreso, exito y error, con una sola indicacion semantica por
  estado.
- Las notas rapidas comunican guardado y conservan el contenido de forma
  predecible durante edicion y cierre.
- Las herramientas de desarrollo se organizaron en `scripts/dev/`, los perfiles
  de sistema en `scripts/distro/` y los motores compartidos en `scripts/lib/`.
- La documentacion de compilacion distingue claramente artefactos publicables,
  instalaciones locales y compatibilidad binaria por distribucion.

### Corregido

- Se eliminaron artefactos de un frame al abrir, cerrar o cambiar rapidamente
  entre miniaturas, controles multimedia y menus contextuales.
- El menu contextual vuelve suavemente al tamano de miniatura y puede desplegar
  sus acciones desde la direccion elegida sin perder el anclaje al item.
- El scroll de listas y menus ya no invade el resaltado de seleccion.
- Los popups de carpetas conservan todos los elementos mediante scroll cuando
  el numero de filas visibles es menor que el contenido disponible.
- Las caratulas MPRIS locales y remotas se normalizan sin bloquear la interfaz
  ni reutilizar resultados obsoletos.
- Se retiraron wrappers redundantes de empaquetado y el antiguo selector de
  iconos limitado al sistema de archivos.

### Validacion

- Fedora 44, Plasma 6.7.3 y Qt 6.11.1: `qmllint` dentro del baseline con 732
  advertencias conocidas, compilacion Release, empaquetado e instalacion local.
- CTest completo: `9/9` pruebas correctas.
- Plasma Shell permanecio activo tras la instalacion local con
  `NRestarts=0`; los popups modificados fueron revisados iterativamente en una
  sesion Wayland real.
- El usuario confirmo los flujos de build dedicados en Debian 13,
  Debian 14/testing y Kubuntu Plasma 6.6.4 durante el ciclo de desarrollo.

## [0.8.9] - 2026-07-18

### Agregado

- Reserva flexible del espacio libre en paneles horizontales configurados para rellenar el ancho disponible.
- Capacidad automática para grupos dinámicos y desbordamiento ajustado al espacio realmente asignado por Plasma.
- Acciones `Pin to Dock` y `Unpin from Dock` para tareas dinámicas y aplicaciones fijadas.
- Creación de notas rápidas desde el menú global y eliminación segura desde el editor de notas.
- Reflejos opcionales y degradados para iconos en dock flotante y panel horizontal.
- Opción para mostrar u ocultar el fondo temático de hover y aplicación activa.
- Publicación de la geometría de los items para dirigir hacia ellos la animación de minimización de KWin.
- Reacciones configurables al minimizar: rebote lento y onda lateral acotada a los items vecinos.
- Infraestructura ki18n reproducible con inglés como fuente, catálogo español y compilación de traducciones dentro del `.plasmoid`.
- Renderer `shaped` con esquema JSON v2 y gradientes animados opcionales para temas externos.
- Comprobador portable del entorno de compilación y diagnóstico detallado cuando `qmllint` supera un baseline.

### Cambiado

- El modo `Fill free panel space` solo se activa cuando el panel horizontal usa realmente `FillAvailable`; los modos compacto, flotante y vertical conservan su tamaño normal.
- Los items dinámicos se alinean después del último elemento fijado y el overflow ocupa la última celda disponible sin desplazar el bloque persistente.
- Las transiciones entre tarea dinámica y aplicación fijada utilizan una animación breve sin alterar el orden persistido.
- El idioma de la interfaz sigue automáticamente la configuración regional de KDE; no se añade un selector que pueda afectar globalmente a `plasmashell`.
- Fedora Qt 6.11 y Debian Qt 6.8 conservan perfiles de lint independientes sin convertir la versión del linter en requisito de ejecución.

### Corregido

- Desanclar utiliza un índice persistente validado y elimina correctamente el launcher fijado.
- Los reflejos nacen bajo el icono, se desvanecen gradualmente y respetan el espacio real disponible en paneles horizontales.
- Las notas eliminadas no vuelven a guardarse accidentalmente al cerrar su popup.
- Las ventanas minimizadas reciben como destino el icono, grupo u overflow que las representa.
- Los falsos positivos de Qt 6.8 para la acción contextual oficial `PlasmaCore.Action` quedan suprimidos localmente sin ampliar el baseline global.

### Validación

- Fedora 44 con Qt 6.11.1: `qmllint` dentro del baseline, compilación Release, CTest `6/6` y empaquetado completado.
- Varias mejoras visuales y funcionales fueron confirmadas por el usuario en Plasma 6 Wayland real.
- Debian 13 con Qt 6.8.2 mantiene validación independiente; queda pendiente confirmar el flujo completo después de la última corrección localizada de lint.

## [0.8.8] - 2026-07-16

### Agregado

- Biblioteca administrada de temas JSON externos sin incluir presets dentro del paquete.
- Importación individual o recursiva de carpetas, detección de duplicados, límite de seguridad y borrado de temas instalados.
- Validación nativa de esquema, tamaño, colores, gradientes, bordes, sombras, separadores y geometría antes de exponer un tema a QML.
- Renderers de fondo plano 2D y repisa 2.5D para el dock flotante.
- Separadores temáticos con estilos line, dot y capsule, gradiente, borde, patrón y glow acotado.
- Página de configuración independiente para el visualizador de audio.
- Pruebas unitarias para validación y repositorio de temas.

### Cambiado

- Los temas externos se almacenan bajo la ubicación de datos del usuario y la configuración conserva un identificador estable, no la ruta original.
- Los paneles Plasma mantienen su fondo nativo; los temas JSON se aplican únicamente al dock flotante.
- El espectro de audio se compone sobre el fondo Plasma o JSON seleccionado.
- El matching de tareas sigue el patrón de KDE y compara `AppId` y `LauncherUrlWithoutIcon`.
- Las tareas sin servicio instalado pueden reutilizar el icono entregado por la ventana mediante `Qt.DecorationRole`.
- El build Debian usa un directorio de caché fuera de la carpeta compartida de VirtualBox y un baseline propio para Qt 6.8.
- El script de prueba confirma instalación válida y cambio real de PID al reiniciar Plasma Shell.

### Corregido

- Los iconos ya no reducen su tamaño al activar el autoocultado del panel.
- Aplicaciones portables pueden mostrar el icono publicado por su ventana sin depender de un archivo `.desktop` instalado.
- Ventanas con identidad distinta a su lanzador, incluido el flujo de ejecución de VirtualBox, disponen de una segunda vía estándar de asociación.
- La importación de temas tolera subcarpetas y conserva una biblioteca estructurada.
- El selector de temas ya no falla durante reconstrucciones transitorias del modelo ni después de borrar el tema activo.
- Los glows de separadores y rims quedan limitados para no desbordar visualmente el dock.
- Se retiraron opciones de diálogo no disponibles en Qt 6.8 y se recalibró el baseline Debian tras revisar el log completo.

### Validación

- Fedora 44: `qmllint` dentro del baseline, compilación Release, `ctest` `5/5`, empaquetado, instalación y reinicio de Plasma.
- Debian 13 con Qt 6.8.2: flujo de `qmllint` revisado y baseline específico actualizado; el usuario confirmó la continuación correcta del proceso de prueba.
- Los temas JSON externos permanecen fuera del artefacto `.plasmoid`.

## [0.8.7] - 2026-07-15

### Agregado

- Módulo QML nativo en C++ para integración con KDE, persistencia y operaciones de runtime.
- Lanzadores fijados, tareas dinámicas, previsualizaciones de ventanas y controles para grupos.
- Carpetas, notas, papelera, calendario, separadores y acciones contextuales configurables.
- Acciones contextuales nativas de archivos `.desktop` y controles de ventana para launchers fijados y tareas dinamicas.
- Tarjeta multimedia MPRIS contextual con caratula, metadatos y controles anterior, reproducir/pausar y siguiente.
- Visualizador de espectro de audio basado en PipeWire, con prueba unitaria del analizador, seis estilos y flujo ritmico opcional en ambos sentidos.
- Animaciones de apertura configurables para los popups nativos, con controles porcentuales de velocidad e intensidad.
- Empaquetado reproducible con selección explícita de `qmllint` para Qt 6 y línea base de advertencias.
- Perfiles nativos separados para Fedora 44 y Debian 13 con nombres de artefacto inequívocos.
- Adaptador QML para compatibilidad con distintas APIs de escritorios virtuales de TaskManager.

### Cambiado

- El objetivo actual de publicación se documenta como Fedora 44+ `x86_64`, Plasma 6 y Wayland.
- Los fondos flotantes y popups siguen el tema activo de Plasma.
- El menu contextual integrado conserva el tamano de la preview y permite ajustar entre `10%` y `200%` la velocidad con que desplaza las acciones.
- Las animaciones de popups comienzan despues del primer frame presentado para seguir siendo visibles en contenidos complejos como cuadriculas y listas.
- El vaciado de la papelera usa una sola superficie con transicion horizontal entre menu y confirmacion, iconos de estado, progreso, sonido configurable o tematico, proteccion ante operaciones concurrentes y el job oficial de KIO.
- La persistencia JSON distingue instancias del plasmoide.
- El paquete de distribucion compila el modulo nativo en modo `Release`, retira simbolos de desarrollo y rechaza bibliotecas que conserven secciones de depuracion.
- Las carpetas conservan las vistas de rejilla, lista y detalle; las vistas radial y fan se retiraron temporalmente hasta su rediseño.
- La coordinacion de popups se extrajo de `main.qml` a un componente dedicado.

### Corregido

- Los lanzadores personalizados conservan comandos con argumentos mediante un fallback de runtime seguro.
- Los popups de carpetas, notas, papelera, calendario, tareas y acciones vuelven a inicializar e interactuar correctamente tras la modularizacion.
- Los controles de miniaturas y ventanas agrupadas permanecen disponibles en sus superficies interactivas.
- La papelera ya no deja su primera accion resaltada visualmente al abrirse con el raton.
- La hora y la fecha usan sombras adaptadas al tema para mantener legibilidad.
- Se eliminaron las 14 advertencias de layout indefinido compartidas por Fedora y Debian.
- Los modelos de tareas ya no fallan cuando el runtime no expone `filterByCurrentVirtualDesktop`.

### Pendiente

- Continuar reduciendo advertencias no críticas de `qmllint` y ampliar pruebas automatizadas de comportamiento QML.
- Completar la revisión funcional de Debian y la modularización de responsabilidades restantes en `main.qml`.

## [0.1.0] - Inicio de la Remasterización

### Agregado

- Estructura de directorios modular.
- Metadatos actualizados para KDE Plasma 6.
- Archivos `.kpackageignore`, `README.md`, y `CHANGELOG.md`.
