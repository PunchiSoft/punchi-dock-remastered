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
