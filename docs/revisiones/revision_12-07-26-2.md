# Revision del plasmoide

Fecha: 2026-07-12-2

Estado: abierta.

## Contexto

Esta revision abre una nueva sesion de pruebas despues del cierre de las revisiones anteriores del 2026-07-11 y 2026-07-12.

La validacion se centra en un unico bug real reportado por el usuario durante pruebas manuales en entorno local.

Entorno de referencia para esta sesion:

- Fedora 44 actualizado;
- KDE Plasma 6;
- validacion prioritaria en runtime real del panel.

## Observaciones

La presente sesion comenzo con un solo hallazgo funcional, despues incorporo una segunda revision sobre politica visual y de anclaje de popups en modo flotante, y ahora suma una tercera revision sobre carga de iconos en carpetas por categoria.


## validacion del usuario en entorno local

- quedo funcional la primera revision.
- segunda revision quedo funcional, falta un ajuste en config pero se vera mas adelante.
- tercera revision funcional, carga el icono correspondiente de la categoria.

## Primera revision

- en config-item configure app muestra que existe habilitar menu con rigth-click comands / enable right click menu, pero estos no son visibles aun por que no existe popup como tal habilitado ni accion del mouse para mostrar clic derecho un menu sobre el panel global del dock en modo panel y/o modo flotante.



## segunda revision
- existe un comportanmiento de los popups y menus en modo flotante, no nacen donde esta el item como lo hacen en modo panel,
- en modo flotante los pupop en generar, esto incluye a miniaturas de ventanas deben estar alejados por defecto 5 pixeles ya que no poseen el mismo comportamiento que en modo panel.

## tercera revision

- al añadir app/configure folder- type: container | content: application category| al pulsar load content no carga el icono por defecto de la categoria. 

## Hallazgos confirmados

- la primera revision queda ya resuelta en esta sesion: la configuracion de items expone la opcion de menu de clic derecho y ahora existe una ruta runtime funcional para apps con acciones configuradas;
- la revision estatica confirma que la configuracion si persiste la estructura de acciones para apps y permite habilitar o deshabilitar ese menu contextual;
- el bloque implementado conecta deteccion de clic derecho, popup contextual de app y ejecucion de comandos sugeridos o configurados;
- la segunda revision introduce un frente adicional distinto del menu contextual: la politica de nacimiento y separacion de popups en modo flotante;
- el comportamiento esperado en modo flotante difiere del modo panel: el popup debe nacer visualmente desde el item correspondiente y conservar una separacion mayor, de `5 px`, para no parecer pegado al fondo del dock;
- el alcance de este segundo frente incluye menus contextuales, popups generales y miniaturas de ventanas, por lo que afecta una politica comun de anclaje y margen, no un componente aislado.
- la validacion del usuario en entorno local confirma que la segunda revision queda funcional, aunque se deja constancia de un ajuste menor de configuracion para revisar mas adelante;
- la tercera revision abre un frente nuevo en el flujo de carpetas configuradas como `container` con `content: application category`;
- el comportamiento reportado indica que al pulsar `Load content` no se carga el icono por defecto de la categoria, por lo que la brecha probable esta en la resolucion o asignacion de icono para carpetas generadas desde categoria y no en la carga de items en si.

## Plan de accion

1. conservar la primera revision como bloque ya implementado y validado por el usuario en entorno local;
2. conservar la segunda revision como bloque funcional confirmado por el usuario y dejar su ajuste menor de configuracion fuera del alcance inmediato si no bloquea la tercera revision;
3. revisar el flujo de `configure folder` cuando `type: container` y `content: application category` para identificar donde deberia resolverse el icono por defecto de la categoria;
4. confirmar si el problema esta en la deteccion de categoria, en la asignacion del icono al item carpeta o en la sincronizacion visual posterior al `Load content`;
5. mantener la revision abierta hasta contar con evidencia suficiente de validacion de la tercera revision y de cualquier regresion asociada.

## Validacion

- validacion manual del usuario, primera revision: queda funcional en entorno local;
- validacion manual del usuario, segunda revision: queda funcional en entorno local; se menciona un ajuste menor de configuracion para revisar mas adelante;
- validacion manual del usuario, tercera revision: al usar `configure folder` con `type: container` y `content: application category`, `Load content` no aplica el icono por defecto de la categoria;
- validacion local del agente, tercera revision: se implementa una asignacion explicita de icono por categoria al refrescar contenido de carpetas fuente `category`; queda pendiente confirmacion manual en Plasma real;
- revision estatica del agente: la ruta de configuracion existe, la señal de clic derecho existe y ahora tambien la apertura runtime para apps con acciones configuradas;
- validacion sintactica: `qmllint` superado para `contents/ui/main.qml`, `contents/ui/components/DockItem.qml` y `contents/ui/components/AppActionsPopup.qml`;
- validacion sintactica adicional: `qmllint` superado para `contents/ui/config/ConfigItems.qml`, `contents/ui/config/components/ActionDialog.qml` y `contents/ui/config/ItemActionEditor.qml` tras el ajuste de tercera revision;
- cierre de la revision: no procede todavia, porque aunque la primera y la segunda revision ya fueron confirmadas por el usuario, la tercera aun no fue diagnosticada ni validada.

## Implementacion revision N° 1 - 2026-07-12 - Sesion 2

- `DockItem.qml` incorpora la nocion explicita de `supportsContextMenu`, habilitando `Qt.RightButton` y el acceso por tecla de menu solo cuando el item realmente dispone de acciones contextuales o es `trash`;
- `main.qml` ahora deriva las acciones contextuales validas desde los datos del item, distingue apps normales de `trash` y abre un popup especifico para acciones de aplicacion;
- se crea `AppActionsPopup.qml` como popup contextual reutilizable para listar y ejecutar acciones configuradas mediante `runtimeService.launchCommand()`;
- el criterio funcional aplicado en esta fase es estricto: solo debe mostrarse menu contextual en el item que tenga acciones configuradas y con comando valido;
- no se modifica aun la logica de configuracion relacionada con limites visuales avanzados del menu, porque el bug actual estaba en la ausencia del popup runtime.
- `configItems.js` incorpora un catalogo inicial de acciones sugeridas para apps conocidas como Firefox, Konsole y Dolphin;
- `configItemsFormHelper.js` aplica una precarga no destructiva: si el item de app aun no tiene acciones ni una desactivacion explicita, y su identidad coincide con un preset conocido, se crean automaticamente acciones sugeridas;
- la precarga no sobrescribe menus existentes ni revive menus desactivados manualmente mediante `actionsEnabled = false`.

## Implementacion revision N° 2 - 2026-07-12 - Sesion 2

- `main.qml` incorpora la propiedad comun `popupMargin`, que conserva `2 px` en modo panel y eleva la separacion a `10 px` en modo flotante como refinamiento posterior de la segunda revision;
- `DockItem.qml` incorpora un `popupAnchorItem` proxy para modo flotante: conserva la coordenada del item en el eje principal, pero extiende el area de anclaje hasta el fondo completo del dock flotante;
- la funcion `popupAnchor(visualParent)` usa ese ancla proxy en modo flotante y mantiene el item real en modo panel, evitando elegir entre dos extremos incorrectos: anclar solo al icono o anclar solo al `dockWrapper`;
- el ajuste se aplica de forma uniforme a popups de carpeta, calendario, papelera, acciones de app, notas, miniaturas de ventanas, desbordamiento y confirmacion de papelera;
- el objetivo real de esta fase queda afinado: en modo flotante el popup debe separarse `10 px` del fondo del dock y, al mismo tiempo, conservar la alineacion horizontal o vertical correspondiente al item que lo origina;
- aun no se declara resuelta la segunda revision hasta confirmar manualmente el comportamiento en Plasma real.

### correccion de criterio durante la segunda revision

- una primera interpretacion incompleta hacia nacer el popup directamente desde el item en modo flotante;
- eso recuperaba la coordenada del icono, pero perdia la distancia correcta respecto del fondo del dock flotante;
- el criterio corregido mantiene ambas cosas: distancia respecto del fondo del dock y alineacion con el item mediante un ancla proxy.

### Soluciones ya intentadas para no repetir

- segunda revision, intento 1: anclar el popup flotante directamente al item; esto recuperaba la coordenada del icono, pero perdia la distancia correcta respecto del fondo del dock flotante;
- segunda revision, intento 2: anclar el popup flotante al `dockWrapper`; esto conservaba la distancia respecto del fondo, pero hacia perder la alineacion del item en el eje principal;
- segunda revision, intento 3: introducir un `popupAnchorItem` proxy hibrido; la primera version del proxy dependia de `panelLocation` y en modo flotante podia escoger mal el eje de anclaje, provocando popups centrados, pisando el icono o desalineados;
- criterio vigente para no repetir: en modo flotante el proxy debe decidir su eje desde la direccion real del popup, no desde una inferencia incompleta de `panelLocation`.
- tercera revision, intento 1: revisar si `Load content` realmente cargaba aplicaciones; el flujo si devolvia apps desde `SystemDiscovery`, por lo que el fallo no estaba en la carga del contenido sino en que `applyContainerApps()` solo reemplazaba `item.apps`;
- tercera revision, intento 2: al detectar `sourceType === category`, asignar un icono canonico fijo por categoria durante `Load content`; esto corrigio la ausencia de icono, pero no garantizo que el icono coincidiera con el real esperado por el sistema, como se evidencio con `Games`;
- tercera revision, intento 3 y criterio vigente: resolver primero el icono real de la categoria desde `SystemDiscovery`, leyendo los `desktop-directories` del sistema, y usar el mapeo fijo de QML solo como fallback cuando el sistema no entregue uno.

## Implementacion revision N° 3 - 2026-07-12 - Sesion 2

- `configItems.js` incorpora `categoryIcon(category)` como fallback local para las categorias soportadas del editor (`Development`, `Game`, `AudioVideo`, `Network`, `Office`, `System`, `Utility`, `Graphics`);
- `SystemDiscovery` incorpora `iconForCategory(category)`, que consulta primero los `desktop-directories` del sistema para recuperar el icono realmente declarado por KDE o el entorno;
- `SystemDiscoveryManager.qml` expone esa resolucion al flujo del KCM;
- `configItemsFormHelper.js` actualiza `applyContainerApps(apps)` para que, cuando la carpeta tenga `sourceType === "category"`, el `Load content` sincronice `item.icon` usando primero el icono real del sistema y solo despues el fallback local;
- el cambio se mantiene acotado al flujo de configuracion y no altera la carga de apps manuales ni carpetas cuyo contenido proviene de una ruta del sistema de archivos.

### Diagnostico estatico previo a implementacion

- `contents/ui/config/ItemActionEditor.qml` y `contents/ui/config/ConfigItems.qml` muestran y gestionan la opcion `Enable right-click menu`;
- `contents/ui/config/code/configItems.js` conserva `actions` cuando el menu esta habilitado y marca `actionsEnabled = false` cuando se desactiva;
- `contents/ui/components/DockItem.qml` emite `contextMenuRequested` al detectar clic derecho, pero la ruta de botones aceptados favorece hoy solo el caso de `trash`;
- `contents/ui/main.qml` recibe `onContextMenuRequested`, aunque actualmente solo llama `openTrashMenu(visualParent)` para items `trash`;
- no se encontro una ruta equivalente para apps normales con `actions` configuradas.

### Comportamiento de autocompletado inicial

- al detectar o configurar una app conocida sin acciones previas, el editor puede precargar acciones sugeridas de forma automatica;
- la precarga solo ocurre si el item aun no tiene acciones y no fue desactivado manualmente;
- esta primera version incluye presets base para Firefox, Konsole y Dolphin;
- la funcionalidad sigue pendiente de validacion manual en Plasma y en el flujo completo del KCM.
