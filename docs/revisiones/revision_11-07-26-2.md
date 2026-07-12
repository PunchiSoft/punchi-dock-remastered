# Revisión del plasmoide

## primera revision:

- al añadir un "dock item" en "configure app" detecta correctamente, la busqueda de app e icono segun el alias y su respectiva descripcion corta si la tiene, pero no se guarda al momento de salir de ese formulario. revisar comportamiento.

- desktop visibility debe mostrar el estado actual, en el downlist "sinlge desktop", "all desktop"

- target desktop funciona perfecto pero debe mostrar por defecto preseleccionad como primera opcion el deskto actual en el que se encuentra el usuario.

- config-general, debe tener 2 parrafos de conguracion un parrafo debe tener un label con "modo flotante" , "modo panel" y estos deben ser detectados de forma automatica;
  - modo flotante:
    - tamaños de iconos con su delizador resepctivo
  - modo panel:
    - tamaño de iconos con su deslizador respectivo (este debe tener limites al tamaño del ancho del panel y un minimo estable) los limites de este delizador se deben calcular al ancho del panel respectivo para no romper visualmente la estetica.

- añadir config/mouse_hover donde deben ir un down list de las animaciones al pasar el mouse:
    - hover mouse anamacion:
        - none
        - wave
        - single
        - paragraph

- notas debe tener iconos en "clean" , "close" como es menu popup puede ser symbolic icon si esta disponible pero siempre adaptandose al color del tema plasma seleccionado.

- notas debe integrar "B: bold",  subrayado, cursivo como basico de texto enriquesido color no, selector de fuente auno no tampoco.

- ver posibilidad que el comando  "plasmoidviewer -a org.kde.plasma.punchi-dock-remastered" pueda actualizarse cuando detecte modificaciones el el plasma permitiendo una vista preliminar en vivo.

## segunda revision

- en modo panel hay un comportamiento anormal del mouse al quedarse sobre un item, aparece una etiqueta que dice ejemplo: "files" para para el enlace a dolphin y genera que el mouse interactue de forma anormal provocando que realice constantemente un zoom in/out como entrando en conflicto con la etiqueta. solo se detecto en modo panel actualmente.
- validacion posterior: el comportamiento anormal se reproduce solo en `plasmoidviewer` y no en el plasmoide ejecutado dentro de Plasma local. se clasifica como bug/quirk del visor de pruebas y no como bug confirmado del runtime real.
- decision tecnica: se mantiene la mejora del watcher para arrancar `plasmoidviewer` simulando panel (`-f horizontal -l bottomedge`), pero se revierte el parche que congelaba el hover del dock con popups abiertos para no sobrecorregir el comportamiento real.


## tercerra revision

- los textos dentro de los popup ya sea menus, popup, no configuran su sombra, añadir este comportamiento a los textos para que resalten esto incluye a los label de la lista de los item cuando se usa grid o similar.
- corregir colores de popup abanico no sigue fielmente el del tema plasma
- añadir popup circular o radial donde al añadir items se añadan al rededor del boton X que se adapte al tema plasma.
- comenzar a preparar el soporte de ventanas;
  - iniciar con que detecte las apicaciones abiertas y las añada al final del dock de forma automatica.
  - se debe añadir nueva categoria config-ventanas. ahi deben ir las configuraciones correspondientes.
  - el icono se debe cargar por defecto y añadir de forma mas optima posible para no generar cargas visuales lag o sobrecarga en el dock.

### avance implementado 2026-07-11

- se añadieron etiquetas con sombra en `FolderPopup.qml`, `NotePopup.qml` y `TrashMenuPopup.qml` para mejorar legibilidad sobre fondos variables.
- los fondos planos de la interfaz circular/abanico en `FolderPopup.qml` comenzaron a migrarse a `KSvg.FrameSvgItem`, tomando el tema Plasma (`widgets/background` y `dialogs/background`) en lugar de colores QML fijos.
- se creó la nueva categoría `ConfigWindows.qml` con opciones base para mostrar tareas activas y limitar su alcance al escritorio virtual actual.
- `main.qml` ya integra una primera fase de `TaskManager.TasksModel`: detecta ventanas activas, añade al final del dock las no fijadas y muestra indicador visual en los lanzadores fijados cuando su aplicación ya está abierta.
- los lanzadores fijados compatibles ahora priorizan activar o minimizar la ventana existente antes de lanzar otra instancia, acercando el comportamiento al de un task manager real.
- se añadió en `SystemDiscovery` un resolvedor nativo de `AppId` por comando para enlazar mejor lanzadores fijos con ventanas reales sin scripts externos.
- fase 2: las tareas dinámicas ahora resuelven el icono usando `AppId` en vez de intentar bindear un `QIcon` directo a `Kirigami.Icon`, y los lanzadores con múltiples ventanas abiertas muestran un popup selector para elegir cuál activar.
- subfase previa a fase 3: el flujo de descubrimiento/configuración de apps ahora persiste `storageId` y `appId`, incluyendo casos `flatpak run ...` y `gtk-launch ...`, para que el matching con tareas no dependa solo del comando bruto.
- fase 3 temprana: el popup de múltiples ventanas ya permite cerrar una ventana concreta, y las acciones/apps internas del dock sincronizan mejor su identidad persistida cuando cambia el comando.

## cuarta revision

- en modo panel, la animacion hover debe orientarse segun el borde real del panel para no chocar contra el limite superior/lateral.
- el orden de tareas dinamicas no debe saltar al activar una ventana.
- el tooltip global del plasmoide no debe competir con los tooltips propios del dock.
- el separador debe renderizarse como separador real y no como icono cuadrado gigante.
- debe existir configuracion de relleno longitudinal del panel solo cuando el panel parece ocupar todo el borde.

### avance implementado 2026-07-11

- `main.qml` ahora silencia `Plasmoid.toolTipMainText` y `Plasmoid.toolTipSubText`.
- `TaskManager.TasksModel` dejó de usar `SortLastActivated` y ahora mantiene orden estable sin saltos visuales por foco.
- el hover en `DockItem.qml` se desplaza hacia el interior de la pantalla segun `Plasmoid.location` y usa una escala mas contenida en panel.
- el tamaño base del icono en panel ahora se calcula para dejar margen al hover sin recorte tan agresivo.
- el separador ya no se dibuja como icono `draw-line`: usa un `Rectangle` fino con ancho reducido y sin interaccion.
- `ConfigWindows.qml` suma modo de longitud del panel (`Fit content` / `Fill panel edge`) visible solo cuando el panel parece ocupar el borde completo.
- `SystemDiscovery.cpp` endurece el autodescubrimiento para priorizar coincidencias exactas y evitar falsos positivos por `Exec`, como launchers personalizados que contienen `konsole` en su comando.

## cuarta revision

-  al usar algun tipo de mouse hover en modo panel como se respeta el alto maximo o ancho maximo segun correponda los iconos que llegan a sobresalir por consecuencia del zoom se cortan ya que estos respetan el espacio del panel es posible mejorar esa condicion? para que se vean sin recorte y mas coherentes al entorno?
-  los items dinamicos se van cambiando de orden segun la ventana que se minimice o maximice o se abra lo ideal es que este comportamiento sea corregido genera lag visual cortes y baja de fps dentro del entorno y genera desorden visual.
-  al mantener el mouse unos segundo sobre el dock aparece un mensaje flotante de "punchi dock remastered. un dock personalizable de lanzadores de KDE plasma 6 con una arquitectura modular y limpia." esa interaccion se debe corregir puede ocacionar conflictos al implementar una vista en miniaturas de ventanas.
-  el separador tiene un pronlema visual, no se ve una linea separadora simple, ocupa mucho espacio virtual similar al de 1 icono.
-  si el modo de soportar ventanas funciona, si esta en un panel flotante debe tener opciones a elegir en un downlist:
    - rellenar espacio libre del panel
    - rellenar espacio igual a X cantidad de iconos, minimo 3 maximo a peticion del usuario. sin romper los margenes de seguridad.
  - si el modo soporte ventanas tiene muchas ventanas abiertas como se deberia comportar? cual seria lo ideal?
- el cajon modo abanico hayq ue eliminarlo causa conflictos visuales.
- al añadir Konsolo de forma automatica me añade datos de otra aplicacion y no konsole como alias hay que revisar ese comportamiento puede que suceda con mas aplicaciones.

## quinta revision

- añadir config-mousehover en las categorias de configuracion, añadir efecto al hacer click sobre el item.
- mover hover animation junto a su donwlist y que esta refleje el actual efecto del mouse al pasar sobre items.
- añadir soporte de comportamiento del mouse en el proyecto general. ejemplo si hay un enlace, si hay un boton, si hay texto etc.
- añadir confing-aspect en las categorias de configuracion.
  - debe tener las siguientes pestañas tema & diock , etiquetas, indicador activo, popups, menus, popup ventanas.
  - config-aspect/etiquetas debe tener:
    - mostrar etiquetas [] = chekcbox
    - fuente de etiquetas = downlist (fuente del tema plasma, fuentes del sistema a elegir)
    - tamaño de etiquetas = un delizador con el tamaño minimo y maximo en rangos seguros y un checkbox si se deja en [] auto.
    - sombra en etiquetas [] = un check box al habilitar muestra un deslizador con grosor siempre en rangos seguros.
    - chip en etiquetas = permite que las etiquetas esten en un chip.
- config-aspect/ indicador activo - debe contener lo siguiente:
  - indicador activo = downlist con punto, linea, aro, cuadro esquinas redondeadas, ninguno, estos deben ser elegibles y por defecto mostrar el que este sleccionado y usar punto como defecto.
    - posicion = downlist (abajo, arriba)
    - modo = down list (tema plasma, personalizado(este permite elegir el color, se habilita al seleccionar personalizado))
    - opacidad del indicador = deslizador (0%-100%) elegibles
    - grosor del indicador = deslizador con rangos seguros
- para no sobrecargar se continuara el la sexta revison con popup menus y popupventanas.

### avance implementado 2026-07-11

- se crearon las nuevas categorias `Appearance` y `Mouse` dentro de la configuracion del plasmoide.
- `hover animation` ya no vive en `ConfigGeneral.qml`; ahora se gestiona desde `ConfigMouse.qml` junto con `clickEffect` y el modo de cursor interactivo para la ventana de ajustes.
- `DockItem.qml` ahora puede mostrar nombres persistentes de los items en una sola linea cuando `showLabels` esta activo.
- el indicador activo dejo de estar hardcodeado como una barra fija y se extrajo a `TaskIndicator.qml`, con soporte base para `line`, `dot`, `ring`, `square` y `none`.
- los items del dock ya soportan efectos de click ligeros (`pulse`, `press`, `bounce`) sin retrasar la activacion de la accion principal.
- `ConfigGeneral.qml` y `ConfigWindows.qml` comenzaron a adoptar el comportamiento de cursor interactivo para sliders, checks y combos.
- la personalizacion avanzada de fuente, chip, sombra y color personalizado del indicador queda movida a una siguiente subfase para no sobrecargar de nuevo `DockItem.qml`.

### subfase popup ventanas 2026-07-11

- el popup de multiples ventanas ahora usa una estructura de tarjeta de previsualizacion mas cercana al patron clasico de miniaturas.
- se integraron miniaturas en vivo usando `TaskManager.ScreencastingRequest` + `PipeWireSourceItem`, alimentadas desde `WinIdList`.
- cuando la miniatura no esta disponible o el usuario la desactiva, el popup mantiene la misma estructura y muestra el icono de la app dentro de la tarjeta.
- `ConfigWindows.qml` suma una opcion para ocultar miniaturas vivas y dejar solo icono, manteniendo el layout tipo preview.

### estado real al cierre de sesion 2026-07-11

- la arquitectura base de miniaturas en vivo ya quedo integrada tanto en hover como en popup de multiples ventanas.
- se aplico `lazy loading` para que los streams de PipeWire solo se soliciten mientras el tooltip o popup estan visibles.
- en runtime real del panel Plasma local, las miniaturas quedaron visibles y funcionales.
- la causa del bloqueo anterior no estaba en el layout del popup sino en la implementacion del stream: la solucion estable fue volver al patron minimo usado por Task Manager y por el proyecto madre con `PipeWireSourceItem.nodeId <- ScreencastingRequest.nodeId`.
- por lo tanto, la funcionalidad de miniatura viva queda **validada en runtime real** para esta sesion.
- se reencamino el comportamiento de hover para acercarlo al proyecto madre: el tooltip sigue existiendo como preview ligero, pero el `TaskWindowsPopup` puede abrirse automaticamente al pasar el mouse sobre items con ventanas activas.

### diagnostico consolidado miniaturas

- `main.qml` obtiene el `windowUuid` desde `TaskManager.AbstractTasksModel.WinIdList` y lo convierte a `String()`.
- `DockItem.qml` y `TaskWindowsPopup.qml` ya intentan crear el stream con `TaskManager.ScreencastingRequest`.
- si `nodeId` no llega o el stream no entra en estado utilizable, la UI muestra la tarjeta base con icono y el texto `Preview unavailable`.
- la implementacion sobria y comprobada resulto mas fiable que las variantes con diagnosticos extra o propiedades auxiliares no necesarias.
- `plasmoidviewer` no es una plataforma confiable para validar esta funcionalidad bajo Wayland; la verificacion debe hacerse en el panel real de Plasma.

### nota de empaquetado 2026-07-11

- se detecto que el archivo `dist/punchi-dock-remastered.plasmoid` estaba siendo generado desde la raiz completa del repositorio.
- eso hacia que el paquete incluyera `build/`, `src/`, `backup/`, `scripts/`, `scratch/` y otros artefactos de desarrollo, inflando el peso hasta `520M` y ralentizando el proceso.
- el criterio correcto de distribucion queda reducido a `metadata.json`, `LICENSE` y `contents/`.
- al reconstruirse con esa lista blanca, el artefacto quedo en aproximadamente `1.2M`.

## sexta revision

- los menus popop no se ven en el dock modo panel zona inferior chocan desapareciendo de la visual de usuario por que el panel recorta su vista.
- las ventanas vista previa necesitan mejora solo visual no poseen icono de cierrre, en lo posible hay que imitar a win 7 .
- si se habren muchas ventanas de un mismo app no se acoplan como tal. se requiere esa opcion en config-ventanas parrafo comportamiento de venantas.
- no hay configuracion para determinar el numero maximo de items a mostrar al tener muchas ventanas abiertas para no colapsar el dock.
- dejar pendiendiente el modo vertical del docl y poner nota respectiva en config que aun esta apendiente el comportamiento vertical. para trabajar de forma limpia con horizontal.
- los item del dock no apilan las ventanas del mismo app ejemplo:
si tengo mas de 4 ventans de konsole se deberian apilar y estas no deben ecceder el alto maximo de la pantalla se debe calcular y debe ser configurable.

### plan de accion sexta revision

#### fase 6.1 - corregir posicion y recorte de popups

- corregir `popupDialogLocation`: `PlasmaCore.Dialog.location` debe recibir el borde real del panel, no el borde opuesto. En un panel inferior, `BottomEdge` posiciona el popup por encima del item.
- aplicar el mismo criterio a carpetas, calendario, papelera, notas y selector de ventanas, manteniendo siempre `visualParent` en el item que origino la accion.
- validar primero panel horizontal inferior y despues horizontal superior, incluyendo items cercanos a ambos extremos de la pantalla.
- criterio de aceptacion: ningun popup queda dentro del area recortada del panel ni fuera de la geometria disponible.

#### fase 6.2 - mejorar visualmente las tarjetas de ventanas

- conservar el boton de cierre general del popup y reubicar el cierre individual existente como accion superpuesta en la esquina superior derecha de cada miniatura.
- usar icono simbolico del tema, fondo de contraste y estado hover/foco, tomando como referencia la claridad de Windows 7 sin copiar su apariencia literalmente.
- mantener el tooltip ligero como vista informativa; las acciones de activar y cerrar deben concentrarse en el popup interactivo para evitar cierres accidentales durante hover.
- validar tarjeta con miniatura disponible, miniatura ausente, ventana activa, titulo largo y tema claro/oscuro.

### implementacion fase 6.2 2026-07-11

- antes de intervenir se creo `backup/punchi-dock-remastered-thumbnails-working-2026-07-11.tar.gz`; este respaldo corresponde al estado confirmado donde las miniaturas funcionan.
- el hover abre el `AppletPopup` interactivo despues de una espera corta; si el puntero sale antes de abrirse se cancela, pero una vez visible no existe temporizador de cierre durante el trayecto hacia las miniaturas.
- el selector usa exactamente `popupDirection`, `floating` y `removeBorderStrategy` del popup Grid, de modo que nace junto al borde del panel con la separacion administrada por Plasma.
- el selector no se oculta al cambiar la ventana activa, porque Plasma interpreta el cruce desde el panel como una desactivacion antes de registrar la entrada del puntero; se cierra al activar una ventana o mediante el cierre general.
- el tooltip queda suprimido mientras el selector de ese item esta visible.
- el cierre individual se superpone en la esquina superior derecha de la miniatura sin modificar `WindowLiveThumbnail` ni su `Loader`.

#### fase 6.3 - agrupar ventanas por aplicacion

- agregar en `ConfigWindows.qml` el bloque `Comportamiento de ventanas` con una opcion de agrupacion: `Agrupar por aplicacion` como valor predeterminado y `Mostrar cada ventana` como alternativa.
- mantener el modelo nativo sin reordenamiento por activacion y realizar la agrupacion estable en `TaskModelController.qml` mediante `AppId`.
- representar cada grupo dinamico con un solo item, contador e indicador; un clic con varias ventanas abre el selector y un clic con una sola ventana activa o minimiza.
- conservar el comportamiento ya existente para lanzadores fijados, que actualmente si acumulan sus filas por aplicacion.
- validar aplicaciones nativas, Flatpak, `gtk-launch`, ventanas sin `AppId` y cambios al abrir o cerrar ventanas.

#### fase 6.4 - limitar densidad del dock y del popup

- agregar configuraciones separadas para `maximo de grupos dinamicos en el dock` y `maximo de filas visibles en el popup`.
- no ocultar ventanas silenciosamente: cuando se supere el maximo del dock, mostrar un item de desbordamiento que abra la lista restante.
- mantener orden estable y aplicar el limite despues de agrupar, evitando que cuatro ventanas de Konsole consuman cuatro posiciones.
- calcular la altura maxima del popup con la geometria disponible de la pantalla y el numero configurado de filas; conservar `ScrollView` para el contenido adicional.
- usar rangos seguros iniciales: 3 a 20 grupos dinamicos y 1 a 8 filas visibles, sujetos a validacion visual local.

#### fase 6.5 - declarar alcance horizontal temporal

- mostrar en `ConfigWindows.qml` una nota informativa cuando el plasmoide este en un panel vertical: el comportamiento vertical continua disponible, pero su ajuste visual avanzado queda pendiente.
- no eliminar ni bloquear el modo vertical; evitar introducir nuevas reglas especificas hasta completar y validar el flujo horizontal.

### implementacion fase 6.4 2026-07-12

- se agregan limites configurables independientes para grupos dinamicos (`3` a `20`, predeterminado `8`) y filas visibles de popup (`1` a `8`, predeterminado `4`);
- `TaskModelController` aplica el limite despues de construir la agrupacion estable y publica por separado los grupos visibles y los grupos desbordados;
- el dock representa el excedente con un item explicito que abre una lista desplazable; ninguna ventana se descarta silenciosamente;
- una entrada del desbordamiento activa directamente una ventana simple o abre el visor principal de miniaturas cuando contiene varias;
- el visor de miniaturas limita su altura usando el numero de filas configurado y `availableScreenRect`, conservando `ScrollView` para el contenido adicional.

### implementacion fase 6.5 2026-07-12

- `ConfigWindows.qml` muestra una nota informativa cuando el plasmoide esta en un panel vertical;
- la nota aclara que el modo vertical sigue disponible y que el ajuste visual avanzado se concentra temporalmente en paneles horizontales;
- ninguna opcion ni interaccion vertical se elimina, bloquea o modifica como parte de esta fase.

#### orden de implementacion y pruebas

1. implementar y probar solamente la posicion de popups;
2. mejorar la tarjeta y el cierre individual sin cambiar agrupacion;
3. agregar agrupacion configurable en el controlador;
4. agregar limites y desbordamiento;
5. incorporar la nota de alcance vertical y completar documentacion;
6. ejecutar `qmllint`, compilacion, empaquetado limpio y pruebas locales despues de cada bloque.

La primera fase se apoya en `kde-sdk/frameworks/plasma-framework/src/plasmaquick/dialog.cpp`, donde `BottomEdge` coloca el dialogo sobre el `visualParent` y `TopEdge` debajo. Las fases restantes se consideran cambios de comportamiento y requieren validacion local antes de avanzar al siguiente bloque.

### avance fase 6.1 2026-07-11

- la primera correccion, basada solamente en igualar `PlasmaCore.Dialog.location` con el borde del panel, no resolvio el recorte en el panel inferior.
- se corrige el diagnostico anterior: la captura inferior corresponde al popup de carpeta `Favorites (Grid)`, no al tooltip de `DockItem`.
- como prueba controlada, solo `folderPopupDialog` migra a `PlasmaCore.AppletPopup`, con direccion explicita hacia el exterior del panel y `visualParent` conservado en el item que abre la carpeta.
- para el panel inferior se usa `Qt.TopEdge`; para el superior `Qt.BottomEdge`; para el izquierdo `Qt.RightEdge`; y para el derecho `Qt.LeftEdge`.
- `floating: false` en modo panel permite que Plasma extienda el area de anclaje hasta el borde visible de la ventana del panel, evitando posicionar el popup dentro de ella.
- la prueba local del popup de carpeta fue confirmada como correcta en el panel.
- tras esa confirmacion, calendario, papelera, confirmacion de vaciado, notas y selector de ventanas adoptan el mismo contenedor `PlasmaCore.AppletPopup`.
- `popupDialogLocation` se elimina porque ya no quedan popups interactivos basados en `PlasmaCore.Dialog` dentro de `main.qml`.
- el tooltip informativo de `DockItem` permanece separado: no forma parte de los popups interactivos cubiertos por esta correccion.
- durante la extension se detecto en Plasma 6.7.2 que `AppletPopup.StandardBackground` y `AppletPopup.NoBackground` se evaluaban como `undefined`; se mantienen los valores compatibles `PlasmaCore.Types.StandardBackground` y `PlasmaCore.Types.NoBackground`.
- calendario y papelera seguian sin aparecer; el journal confirmo `trying to show an empty dialog`.
- la causa era el patron `implicitWidth: width` e `implicitHeight: height`: `AppletPopup` asigna inicialmente el tamaño del `mainItem`, el ancho y alto podian pasar por cero y arrastraban tambien el tamaño implicito a cero.
- todos los contenidos de popup calculan ahora su tamaño implicito de manera independiente; `width` y `height` siguen ese tamaño solo como valor inicial.

## Cierre documental 2026-07-12

Estado: cerrada.

- las fases 6.1 a 6.5 quedaron implementadas, documentadas, empaquetadas e instaladas en Plasma local;
- el selector agrupado queda como visor principal de miniaturas, con tarjetas compactas, cierre individual externo al marco y escala configurable;
- la agrupacion estable, los limites de densidad, el item de desbordamiento y la nota de alcance horizontal quedaron integrados;
- las comprobaciones visuales en panel vertical, escalas extremas y cantidades altas de grupos permanecen como validacion manual no bloqueante, no como implementacion pendiente;
- cualquier defecto nuevo o ajuste adicional se registrara desde `revision_12-07-26.md` para no mezclarlo con este ciclo ya cerrado.
