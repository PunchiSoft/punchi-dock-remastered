# Revision del plasmoide

Fecha: 2026-07-12

Estado: abierta.

## Contexto

Esta revision inicia un ciclo nuevo despues del cierre de las revisiones del 11-07-26. Los temas se incorporaran a medida que se validen en Plasma local.

## Observaciones

## primera revision

- los indicadores de applicacion activa estan siempre activos corregir.
- los popup generales como grid no poseen la distanca simlar a las miniaturas del borde de un panel en modo panel.
- en modo flotante los popup deben nacer desde el borde del plasmoid osea el fondo donde estan alojas respetando el espacio de 2 pixeles de separacion.
- al seleccionar limpiar papelera el popup de confirmacion desaparece al instante y tampoco respeta la regla de que en modo panel debe salir a 2 pixeles del borde del panel.
- añadir regla que todo popup menu que se añada visualmente debe salir de 2 formas diferentes en modo panel debe nacer desde el borde del panel a 2 pixeles como regla general.en modo flotante a 2 pixeles desde el borde donde se aloja el dock.

## segunda revision

- visualmente la lista de grupos de ventanas posee x en la esquina superior derecha que es perfecto adaptado al tema plasma y simple minimalista.se debe generalizar este aspecto para respetar que todos los popup e item que tengan esta interaccion respeten esa estructura visual.
- los indicadores, aun no detectan la app activa.
- los items/iconos dinamicos al estar habilitada el soporte de ventanas no poseen un minimo de X1 item y maximo a elegir por el usuario manteniendo brechas seguras.
- que sucede si colapsa el dock con iconos simplemente creece? visualmente no es correcto que plan de accion y mejora se puede aplicar?.
- en config en general (para todos ecepto items) hay desorden visual falta de simpleza y no se respetan las directrices.

## Hallazgos confirmados

- el indicador se dibujaba para toda aplicacion con ventanas abiertas porque su visibilidad dependia solo de `count > 0`, aunque `IsActive` fuera falso;
- carpetas, calendario, papelera y notas no declaraban el margen real que ya usaban los popups de ventanas;
- en modo flotante los popups se anclaban al item individual y no al fondo completo del dock;
- la confirmacion de papelera se mostraba en el mismo ciclo en que su menu perdia foco, permitiendo que se ocultara inmediatamente.

## Plan de accion

1. mostrar el indicador solo para la ventana activa o una demanda de atencion;
2. aplicar una politica comun de anclaje y separacion de `2 px` a todos los popups;
3. estabilizar la transicion entre el menu de papelera y su confirmacion;
4. validar panel inferior/superior y modo flotante en Plasma local.

## Implementacion primera revision 2026-07-12

- `TaskIndicator` deja de representar como activo cualquier item que solo tenga ventanas abiertas;
- todos los `AppletPopup` usan un margen real de `2 px`;
- en modo panel el anclaje permanece en el item de origen y en modo flotante se traslada a `dockWrapper` para nacer desde el borde del fondo;
- la confirmacion de papelera se abre mediante `Qt.callLater` y no se oculta al perder foco durante la transicion desde el menu.

## Validacion

- registrar entorno, orientacion del panel, pasos de reproduccion y resultado esperado para cada hallazgo cuando corresponda.

## Implementacion segunda revision - bloque funcional 2026-07-12

- `TaskModelController` escucha la señal dedicada `TasksModel.activeTaskChanged` y fuerza la actualizacion visual del dock;
- la fila activa se resuelve mediante la propiedad publica `TasksModel.activeTask`, usando `IsActive` solo como respaldo cuando no existe un indice activo valido;
- lanzadores fijados, grupos dinamicos y tarjetas de ventanas comparten la misma funcion de resolucion de actividad;
- el limite de grupos dinamicos permite ahora valores de `1` a `20`; el excedente continua accesible mediante el item de desbordamiento.

### correccion de diagnostico del indicador

- la primera adaptacion de `activeTask` fue incorrecta: convirtio `QModelIndex.row` y podia volver a la misma lectura de `IsActive` que ya habia fallado;
- se elimina esa inferencia y se adopta la comparacion exacta de indices usada por el Task Manager oficial y el proyecto legacy: `taskIndex === tasksModel.activeTask`;
- `activeTaskChanged` entra ahora por el refresco diferido del controlador, evitando estados visuales parciales durante el cambio de foco.

### correccion de renderizado del indicador

- se confirma una segunda causa posible en presentacion: linea, punto y cuadro mantenian anclas condicionales simultaneas hacia `top` y `bottom`;
- esas anclas se sustituyen por una sola figura con coordenadas `x` e `y` deterministas, evitando estados transitorios estirados al cambiar posicion, tipo o visibilidad;
- el aro tambien usa coordenadas explicitas y el contenedor completo se oculta cuando no existe tarea activa ni demanda de atencion.

### ajuste pendiente aplicado al indicador activo

- la comparacion directa entre `tasksModel.index(row, 0)` y `tasksModel.activeTask` seguia siendo fragil en QML y podia dejar varios items marcados;
- el controlador pasa a resolver la fila activa por interseccion exacta de `WinIdList`, usando `IsActive` solo como respaldo cuando el modelo no expone ids de ventana;
- `activatePreferredTaskRow()` reutiliza ahora la misma deteccion para no seleccionar una ventana distinta al item realmente activo.

### estado historico del bug antes de la version 4

- antes de la version 4, el indicador de app activa seguia marcando todos los items del dock segun validacion manual;
- ninguna de las soluciones de ese periodo debe recuperarse: comparacion por `row`, comparacion directa de `QModelIndex` ni interseccion de `WinIdList`;
- en ese momento se investigaron estos puntos:
  - resolucion de identidad entre lanzadores fijados y tareas del modelo;
  - agregacion por `appId` dentro de `taskStateForDockItem()`;
  - datos que entrega `TasksModel.activeTask` en runtime real frente a lo esperado por inspeccion estatica;
  - una condicion visual posterior que interprete cualquier item con ventanas abiertas como activo.

### soluciones ya intentadas para no repetir

- version 1: visibilidad del indicador dependia de `count > 0`; esto explicaba que cualquier app con ventanas abiertas pareciera activa, pero no resolvio el bug completo;
- version 2: se intento usar `tasksModel.activeTask` comparando filas o indices directamente; tampoco debe repetirse como solucion final sin evidencia nueva en runtime;
- version 3: se intento resolver actividad por `WinIdList`; queda registrada como hipotesis probada pero no confirmada como arreglo;
- mantener esta seccion actualizada antes de cada nuevo intento para evitar volver a las mismas ramas de diagnostico.

### descarte previo obligatorio: copia instalada frente al repositorio

- se detecta que `scripts/watch-plasmoidviewer.sh` observaba cambios y reiniciaba `plasmoidviewer`, pero no actualizaba el paquete instalado que el visor carga mediante el identificador del plasmoide;
- esto permitia editar `TaskIndicator.qml` y `TaskModelController.qml` mientras el visor continuaba ejecutando una copia anterior, invalidando las comparaciones visuales y haciendo parecer que las correcciones no tenian efecto;
- el watcher ahora empaqueta e instala la revision actual antes del primer arranque y repite la actualizacion antes de cada reinicio del visor;
- antes de introducir una cuarta estrategia para resolver `IsActive`, se debe repetir la prueba con este flujo corregido;
- evidencia adicional: en la captura aparecen puntos sobre papelera y separador, aunque ambos reciben `taskIndicatorCount: 0`; el `TaskIndicator` vigente no puede dibujarse en esos elementos, por lo que la captura no corresponde de forma confiable al estado actual del componente.

### referencia oficial para el siguiente descarte

- `kde-sdk/plasma-workspace/libtaskmanager/abstracttasksmodel.h` define `IsActive` como la tarea actualmente activa;
- `kde-sdk/plasma-workspace/libtaskmanager/waylandtasksmodel.cpp` calcula ese rol comparando cada ventana con la ventana activa de Wayland;
- `kde-sdk/plasma-workspace/libtaskmanager/tasksmodel.cpp`, en `TasksModel::activeTask()`, busca precisamente la primera fila cuyo rol `IsActive` sea verdadero;
- por tanto, si el problema se reproduce despues de confirmar la copia instalada, el siguiente diagnostico debe registrar los roles del modelo en runtime y no volver a inferir actividad desde `count`.

### implementacion limpia del indicador - version 4

- ante la persistencia del fallo se reemplaza por completo la ruta de resolucion de actividad, manteniendo las configuraciones de forma, posicion, grosor y opacidad;
- se eliminan del controlador la comparacion con `TasksModel.activeTask`, la interseccion de `WinIdList`, sus fallbacks encadenados y la instrumentacion temporal asociada;
- `isTaskRowActive()` queda reducido a leer y convertir a booleano exclusivamente el rol oficial `AbstractTasksModel.IsActive` de la fila evaluada;
- `DockItem` incorpora una frontera visual explicita: `TaskIndicator` solo puede mostrarse cuando el item es de tipo `app` y tiene al menos una ventana;
- esta frontera impide que papelera, separadores, carpetas, calendario o notas dibujen el indicador incluso si reciben accidentalmente estado residual desde otra ruta;
- `ConfigAspect.qml`, `contents/config/main.xml` y los bindings de configuracion del indicador no se modifican.

### codigo retirado para evitar superposiciones futuras

- `taskWindowIdsForIndex()`;
- `rowDebugData()`;
- `buildIndicatorDebugSnapshot()`;
- `logIndicatorDebugSnapshot()`;
- `taskIndicatorDebugMode`, `debugIndicatorResolution` y `lastIndicatorSnapshot`.

### validacion manual y correccion de alcance del indicador

- validacion manual del 2026-07-12: la implementacion limpia resolvio correctamente la aplicacion enfocada, pero oculto por error el indicador de las demas aplicaciones abiertas o minimizadas;
- se corrige el alcance: `count > 0` controla la presencia del indicador de aplicacion en ejecucion, mientras `IsActive` controla un realce adicional y no su existencia;
- las aplicaciones abiertas o minimizadas muestran el indicador con opacidad secundaria; la aplicacion enfocada y las demandas de atencion usan la intensidad completa configurada;
- criterio protegido para cambios futuros: no se debe confundir "aplicacion abierta" con "aplicacion activa", ni reintroducir las rutas eliminadas de `activeTask` o `WinIdList`;
- la configuracion del indicador forma parte del comportamiento requerido y debe conservar siempre tipo (`line`, `dot`, `square`, `ring` o `none`), posicion cuando corresponda, grosor y opacidad;
- seleccionar `none` debe continuar permitiendo ocultar completamente el indicador sin alterar la deteccion interna de ventanas.

### revision de superposicion visual y coste

- validacion funcional confirmada: los indicadores de aplicaciones abiertas y minimizadas se muestran correctamente;
- se comprueba que no existian dos instancias de `TaskIndicator` superpuestas: cada `DockItem` contiene una sola instancia y esta dibuja una sola geometria segun el tipo configurado;
- el mayor contraste de la aplicacion enfocada provenia de combinar dos señales: opacidad completa del indicador y fondo de resaltado activo;
- este comportamiento no pinta una segunda geometria sobre el indicador ni representa una carga significativa: solo cambia la opacidad de la misma instancia y muestra el fondo ya existente de `DockItem`;
- se conserva el comportamiento validado: las aplicaciones abiertas o minimizadas usan el 50% de la opacidad configurada y la aplicacion enfocada usa el 100%; el fondo activo permanece como realce adicional;
- se intento retirar temporalmente el cambio de opacidad al interpretar incorrectamente una consulta como solicitud de modificacion; ese ajuste se revirtio inmediatamente y no forma parte del estado final;
- la demanda de atencion conserva su color especifico, pero no crea una segunda figura;
- las configuraciones de tipo, posicion, grosor, opacidad y ocultacion con `none` se mantienen intactas.

### hipotesis descartada durante el diagnostico: choque entre dos indicadores activos

- se revisa la posibilidad de que existan dos detectores distintos de ventana activa, uno para el punto superior y otro para el resaltado principal del icono;
- queda descartado como causa primaria: ambos efectos visuales dependen de la misma propiedad `taskIsActive` dentro de `DockItem.qml`;
- el punto superior lo dibuja `TaskIndicator` con `active: taskIsActive`;
- el fondo resaltado del item tambien usa `taskIsActive` en `hoverBackground.opacity`;
- conclusion vigente: no existen dos instancias de indicador superpuestas; el realce activo combina la opacidad de una sola figura con el fondo del item.

### orden visual de la configuracion de ventanas

- `ConfigWindows` se reorganiza en secciones claras: visibilidad, previews, agrupacion y limites, e integracion con panel;
- los textos de apoyo pasan a un tono secundario y con sangria consistente para reducir ruido visual;
- se mantiene el comportamiento funcional existente, pero con una jerarquia mas simple para la siguiente revision visual en Plasma.

### correccion del layout de configuraciones

- se corrige el criterio visual pendiente: los selectores ya no deben ocupar de forma agresiva todo el ancho disponible del KCM;
- `ConfigAspect` y `ConfigWindows` pasan a usar anchos maximos de lectura para combos, sliders y textos de ayuda;
- `ConfigAspect` ahora oculta la fila de posicion cuando la forma elegida no la usa (`ring` o `none`) y la sustituye por una explicacion contextual;
- los combos de apariencia y ventanas sincronizan su valor visible mediante una rutina explicita de `syncComboValue()` para evitar lecturas ambiguas del estado actual durante cambios en el KCM;
- este ajuste busca reducir la sensacion de parpadeo o reacomodo interno al cambiar `indicator shape` y `indicator position`, pero aun requiere validacion visual en Plasma para confirmar que no persistan repintados del preview o del dock.

## Implementacion consolidada vigente - indicadores 2026-07-12

Estado: funcional, confirmado mediante validacion manual del usuario.

### comportamiento final

- cada aplicacion abierta, incluida una aplicacion con ventanas minimizadas, muestra un unico `TaskIndicator`;
- una aplicacion abierta no enfocada usa el 50% de la opacidad elegida en configuracion;
- la aplicacion que contiene la ventana actualmente enfocada usa el 100% de la opacidad elegida;
- el fondo de `DockItem` tambien resalta la aplicacion enfocada, pero no crea ni superpone otro indicador;
- una demanda de atencion reutiliza la misma figura con el color de atencion del tema;
- carpetas, papelera, calendario, notas, separadores y espaciadores no pueden mostrar este indicador de tareas.

### implementacion actual

- `TaskModelController.qml` obtiene el foco exclusivamente desde `AbstractTasksModel.IsActive`, convertido directamente a booleano;
- `taskStateForDockItem()` mantiene separados `count` e `isActive`: `count` representa ventanas abiertas y `isActive` representa foco;
- `DockItem.qml` crea una sola instancia de `TaskIndicator` cuando `itemType === "app"` y `taskIndicatorCount > 0`;
- `TaskIndicator.qml` dibuja una sola geometria segun el tipo seleccionado y cambia solo su opacidad entre estado abierto y activo;
- no se usan comparaciones de `QModelIndex`, intersecciones de `WinIdList` ni indicadores duplicados.

### configuracion preservada

- forma: `line`, `dot`, `square`, `ring` o `none`;
- posicion: superior o inferior cuando la forma lo permite;
- grosor o tamano visual;
- opacidad base;
- `none` oculta completamente la figura sin alterar el seguimiento interno de ventanas.

### validacion vigente

- validacion manual: aplicaciones abiertas y minimizadas detectadas; aplicacion enfocada diferenciada correctamente;
- revision estatica: existe una sola instancia de `TaskIndicator` por `DockItem`;
- `qmllint` superado para `TaskIndicator.qml`, `DockItem.qml`, `TaskModelController.qml` y `main.qml`;
- configuracion verificada desde `contents/config/main.xml` y `ConfigAspect.qml` hasta los bindings de `main.qml` y `DockItem.qml`.
