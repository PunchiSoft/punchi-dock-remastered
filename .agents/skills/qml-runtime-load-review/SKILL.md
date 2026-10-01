---
name: qml-runtime-load-review
description: Revisar y validar que Punchi Dock pueda instanciar, mutar y destruir sus componentes QML en Plasma real sin dejar la representacion vacia, emitir errores de ciclo de vida ni derribar plasmashell. Usar al modificar main.qml, imports, tipos QML, propiedades adjuntas, Loader, delegates, modelos, popups, KConfig expuesto a QML, modulos nativos o cualquier componente alcanzable desde la representacion principal; activar tambien ante fondo/iconos desaparecidos, menu contextual sin UI, errores de fullRepresentation/compactRepresentation, accesos nulos durante reconstrucciones o fallos que qmllint no reproduzca.
---

# Revision de carga QML en runtime

## Objetivo

Impedir que una modificacion sintacticamente valida rompa la creacion de la
representacion completa del plasmoide. Tratar `qmllint`, compilacion y
empaquetado como requisitos previos, no como evidencia de carga runtime.

## Clasificar el riesgo

Considerar de carga critica cualquier cambio que afecte:

- `contents/ui/main.qml` o un componente instanciado desde el;
- imports, tipos, aliases, propiedades requeridas o metadata QML;
- propiedades adjuntas como `Layout`, `Keys`, `Accessible` y `ScrollBar`;
- `Loader`, `Component`, `Repeater`, `ListView`, `GridView`, delegates, popups o
  contenido creado perezosamente;
- `Connections`, `Timer`, `Qt.callLater`, `destroy()` y callbacks que puedan
  sobrevivir al objeto que originó la operación;
- reemplazos o mutaciones de modelos que creen y destruyan delegates;
- claves KConfig consumidas durante la inicializacion;
- modulos nativos, plugins y `punchidockintegration.qmltypes`.

Revisar especialmente expresiones agrupadas como
`Controls.ScrollBar.horizontal.policy`. El tipo puede existir y pasar lint,
pero el objeto adjunto intermedio puede ser nulo en runtime si nunca se creo.

## Inventario preventivo de limites dinamicos

Antes de afirmar que existe un bug, construir una cola de revision con los
limites dinamicos del componente modificado y sus consumidores directos:

- creacion: `Component`, `Loader`, delegates y `createObject()`;
- mutacion: cambio o reinicio de modelos, filtros, orden, orientacion o modo;
- trabajo diferido: `Timer`, `Connections`, animaciones y `Qt.callLater`;
- destruccion: `Loader.active = false`, retirada de filas, `destroy()` y cierre
  de popups.

Para cada limite, comprobar si sus bindings o callbacks leen `parent`, ids del
componente exterior, `Loader.item`, `Connections.target`, `modelData` o
propiedades de un objeto que puede estar destruyendose. `visible: false` solo
oculta; no prueba que delegates, conexiones o timers hayan dejado de existir.

Los resultados de esta busqueda son candidatos de revision, no defectos
confirmados. Elevar un hallazgo solo con una ruta reproducible, un warning de
runtime o una contradiccion concreta del contrato de ciclo de vida.

## Gate obligatorio

### 1. Revision estatica

1. Leer el componente, sus consumidores y el diff completo.
2. Comprobar que cada propiedad agrupada o adjunta tenga un objeto real.
3. Ejecutar `qmllint` sobre archivos modificados y consumidores directos.
4. Ejecutar `git diff --check`.
5. Actualizar traducciones si cambiaron textos visibles.

No elevar un baseline para ocultar advertencias nuevas. Calificar accesos o
acotar una supresion solo cuando se confirme un falso positivo.

### 2. Prueba automatizada de ciclo de vida

Cuando la regresion dependa de carga perezosa, reconstruccion de modelos o
destruccion, añadir una prueba Qt Quick que:

1. reproduzca el warning contra la implementacion anterior cuando sea posible;
2. cree el componente y active su contenido perezoso;
3. mute o vacie el modelo, cambie el modo relevante y destruya el host;
4. repita el ciclo para cubrir callbacks encolados y ordenes variables;
5. quede registrada en CTest.

Toda prueba ejecutada con `qmltestrunner` debe convertir los warnings
inesperados en fallo. Usar por defecto `failOnWarning(/.?/)` en `init()`; usar
`ignoreWarning()` solo para un mensaje ambiental exacto, confirmado y explicado
en la prueba. Un resultado `PASS` que contiene `QWARN`, `TypeError` o
`ReferenceError` no supera el gate.

No limitar la asercion al estado final. Incluir la transicion que destruye o
recrea los objetos, esperar a que se vacie la cola de eventos y verificar que
el componente pueda volver a instanciarse.

### 3. Prueba automatizada de carga integral

Añadir o ampliar una prueba del applet completo cuando el cambio alcance
`main.qml`, imports globales, representaciones, configuracion inicial, modulos
nativos o varios componentes que solo fallan al conectarse entre si.

La prueba debe, segun las APIs disponibles en el minimo compatible:

1. aislar rutas con `QStandardPaths::setTestModeEnabled(true)` o un equivalente
   temporal y exponer una copia completa del paquete;
2. descubrir y cargar el identificador real mediante el cargador publico de
   Plasma;
3. comprobar applet no nulo, `launchErrorMessage()` vacio y
   `PlasmaQuick::AppletQuickItem` disponible;
4. forzar la creacion de las representaciones y contenido perezoso alcanzado
   por el cambio;
5. cambiar entre estados que reconstruyan el arbol, procesar eventos, destruir
   el applet y cargar una segunda instancia limpia;
6. convertir warnings y excepciones QML en fallo con diagnostico del primer
   error.

Una prueba aislada del componente sigue siendo necesaria para localizar la
causa, pero no sustituye esta barrera cuando el fallo depende del grafo total.
La prueba integral offscreen tampoco demuestra KWin, compositor, panel o foco
global; conservar la carga real de las secciones posteriores.

El patron esta respaldado por
`kde-sdk/frameworks/plasma-framework/autotests/applet/applettest.cpp`, que usa
`Plasma::PluginLoader`, comprueba `launchErrorMessage()` y obtiene
`PlasmaQuick::AppletQuickItem`. Consultar la version efectiva y no asumir que el
snapshot del SDK eleva automaticamente el minimo declarado.

### 4. Construccion y paquete

1. Compilar el modulo nativo.
2. Ejecutar CTest.
3. Crear el artefacto con `scripts-dev/distro/<perfil>-package.sh`
   (`fedora-package.sh`, `debian13-package.sh`, `arch-package.sh`).
4. Inspeccionar que el paquete contenga las fuentes QML y recursos esperados.

Detenerse si falla cualquier etapa. Un paquete valido todavia no demuestra que
`QQmlObjectCreator` pueda completar la instancia.

### 5. Instalacion local controlada

Solicitar autorizacion antes de instalar o reiniciar Plasma. Usar el
orquestador de desarrollo, que compila, instala y reinicia Plasma Shell:

```bash
./scripts-dev/setup.sh --local-test
```

Antes del reinicio, comprobar que la copia instalada coincide con el artefacto
o la fuente esperada. Reemplazar el paquete por completo antes de reiniciar;
evitar dejar que el proceso activo observe un arbol parcialmente actualizado.
Preservar la configuracion y la instancia del plasmoide.
El fallo de reinicio es bloqueante: no continuar a diagnostico ni anunciar exito
si no existe un PID nuevo; no ocultar `restart_plasma_shell` con `|| true`.

### 6. Carga real

Despues del reinicio:

1. confirmar que `plasma-plasmashell.service` esta activo;
2. confirmar un PID nuevo y que permanece vivo durante al menos cinco segundos;
3. consultar el journal desde el instante exacto del reinicio y filtrarlo por
   el PID nuevo, por ejemplo con `journalctl --user _PID="$current_pid"
   --since "$restart_started_at"`;
4. buscar `Error loading QML`, `QQmlComponent`, `QQmlObjectCreator`,
   `fullRepresentation`, `compactRepresentation`, `TypeError`,
   `ReferenceError`, propiedades nulas, binding loops y el id del plugin;
5. abrir cada popup, Loader o flujo modificado para instanciar contenido
   perezoso;
6. comprobar visualmente fondo, iconos, geometria e interaccion esencial.

No validar con una ventana temporal amplia y un `grep` como unica fuente: puede
mezclar `qmltestrunner`, procesos anteriores u otros plasmoides. Una busqueda
amplia puede complementar el diagnostico, pero el veredicto corresponde al PID
nuevo. El recolector debe devolver error cuando encuentre una firma bloqueante;
no ocultarla con `|| true` mientras informa instalacion exitosa.

### 7. Matriz manual de mutaciones

Derivar una matriz minima del dominio modificado. Para vistas respaldadas por
modelos o preferencias, cubrir al menos:

1. abrir el componente y activar contenido perezoso;
2. cambiar entre los modos u orientaciones afectados;
3. crear, reordenar, mover y eliminar una fila o agrupacion cuando aplique;
4. cerrar y reabrir inmediatamente;
5. repetir una mutacion con el popup abierto y otra con el popup cerrado;
6. revisar el journal del PID nuevo despues de cada bloque observable.

Registrar exactamente que accion realizo el usuario y su marca temporal. No
atribuir un error a la ultima accion solo por proximidad: correlacionar archivo,
linea, PID y transicion de estado.

No usar la presencia del menu contextual como prueba de salud. Plasma puede
mantener vivo el contenedor aunque la representacion QML haya fallado.

## Diagnostico de superficie vacia

Si desaparecen fondo e iconos pero el menu contextual responde:

1. clasificarlo como posible fallo de inicializacion de
   `fullRepresentation`/`compactRepresentation`;
2. consultar primero el journal, antes de cambiar configuraciones del usuario;
3. localizar el primer error QML, no las advertencias en cascada;
4. relacionar la linea instalada con la fuente actual;
5. aplicar el cambio minimo y reconstruir el paquete completo;
6. reiniciar solo cuando la instalacion ya sea consistente;
7. comprobar el journal del PID nuevo, separandolo del proceso anterior.

Si Plasma cae durante una actualizacion en caliente, no concluir que la
correccion fallo. Verificar la copia instalada y realizar un segundo arranque
limpio con el arbol ya estable.

## Criterios de cierre

Declarar la revision tecnica superada solo cuando:

- lint, compilacion, pruebas y paquete pasan;
- las pruebas QML del alcance no emiten `QWARN` inesperados;
- la carga integral automatizada existe y pasa cuando el cambio alcanza el
  grafo principal, o su ausencia queda justificada por una limitacion concreta;
- la copia instalada es la esperada;
- Plasma permanece activo con PID nuevo;
- el journal delimitado por PID y tiempo no contiene errores de carga ni de
  ciclo de vida relacionados;
- la representacion principal aparece;
- cada componente modificado de carga perezosa fue abierto;
- las mutaciones relevantes crean, reconstruyen, destruyen y reabren sin error;
- la validacion manual distingue claramente lo comprobado de lo pendiente.

Cuando haga falta decidir frecuencia, entorno o dominios complementarios, leer
la [matriz compartida de pruebas](../testing/references/test-matrix.md).

Registrar la regresion y la solucion en `docs/revisiones/`; actualizar
`bitacora/` cuando el incidente produzca una regla durable.
